# 09 — Disk Space & Cache Maintenance

Docker is generous: it caches aggressively and never deletes anything you might
reuse — so an unmaintained machine quietly fills up. This chapter shows **what
eats the disk, what's safe to delete, and how to keep it bounded** without nuking
work you care about.

> **Golden rule:** reclaim in **increasing order of danger**, and measure
> before/after with `docker system df` every time.

---

## 1. What actually consumes disk

```bash
docker system df            # summary
docker system df -v         # per-image / per-container / per-volume breakdown
```

| Type | Where it lives | Typical culprit |
|---|---|---|
| **Images** | data root (`/var/lib/docker/…`) / the Docker Desktop VM | `:latest` pulls, every build tag |
| **Build cache** | BuildKit store | repeated builds; the #1 silent grower |
| **Containers** (writable layers) | overlay2 diff dirs | stopped/`Exited` containers you forgot |
| **Volumes** | `/var/lib/docker/volumes/…` | databases, logs written to volumes |
| **Container logs** | `/var/lib/docker/containers/<id>/<id>-json.log` | chatty apps (unbounded by default!) |
| **Networks** | `docker network ls` | small, rarely the problem |

```
$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          38        6         12.4GB    9.1GB (73%)
Containers      9         1         412MB     380MB (92%)
Local Volumes   14        3         3.8GB     1.2GB (31%)
Build Cache     212       0         7.6GB     7.6GB
```

**RECLAIMABLE** is your target — but "reclaimable" ≠ "safe to delete". Read §3.

---

## 2. Find the biggest offenders

```bash
# Images by size, biggest first
docker images --format '{{.Size}}\t{{.Repository}}:{{.Tag}}\t{{.ID}}' | sort -hr | head -20

# Build cache usage (BuildKit)
docker buildx du
docker buildx du --verbose | head -40

# Volume sizes (there is no native command — approximate via a container)
for v in $(docker volume ls -q); do
  printf '%s\t' "$v"
  docker run --rm -v "$v":/v alpine du -sh /v 2>/dev/null | cut -f1
done

# Largest container logs
sudo du -h /var/lib/docker/containers/*/*-json.log 2>/dev/null | sort -hr | head
# (macOS/Windows: use Docker Desktop's "Disk usage" panel, or `docker system df -v`)

# Which images are dangling (untagged) — usually safe to remove
docker images -f dangling=true
```

A ready-made report: [`scripts/docker-disk-report.sh`](../scripts/docker-disk-report.sh)
(`make disk`).

---

## 3. The safe cleanup ladder

Go top-down. Stop as soon as you've recovered enough.

| Step | Command | Removes | Risk |
|---|---|---|---|
| 1. Report | `docker system df -v` | — | none |
| 2. Stopped containers | `docker container prune` | all `Exited` containers | low — **in-container state lost** |
| 3. Dangling images | `docker image prune` | untagged layers | low |
| 4. Build cache | `docker buildx prune` | BuildKit cache | low — next build is slower |
| 5. Unused images | `docker image prune -a` | images with **no container** | medium — re-pull/rebuild needed |
| 6. Unused volumes | `docker volume prune` | volumes not attached | **HIGH — data loss** |
| 7. Everything | `docker system prune -a --volumes` | 2–6 combined | **HIGHEST** |

```bash
# The everyday safe reclaim (2–4), no prompts:
docker container prune -f
docker image prune -f
docker buildx prune -f

# Everything unused, but KEEP volumes (usually what you want):
docker system prune -a -f

# Include volumes only when you're certain (⚠️ deletes DB data, caches, secrets):
docker system prune -a --volumes -f
```

> `docker system prune` **never** touches a **running** container, a **used**
> volume, or a **tagged** image that a container references. `-a` widens "used"
> to "referenced at all".

### Time- and label-scoped pruning

```bash
# Only reclaim things older than a day:
docker container prune  --filter "until=24h"
docker image prune      --filter "until=24h"
docker buildx prune     --filter "until=24h"
docker system prune     --filter "until=24h"

# Only images carrying a label (e.g. your CI builds):
docker image prune -a --filter "label=org=my-team"
```

`until` accepts durations (`10m`, `24h`, `168h`) and timestamps.

### Free space WITHOUT deleting anything useful

```bash
# Keep a bounded build cache (delete oldest first, stop at 10 GB):
docker buildx prune --keep-storage 10GB

# Keep the last ~30 min of cache for fast iteration:
docker buildx prune --keep-storage 5GB --filter "until=30m"
```

---

## 4. Build cache, in depth (usually the biggest win)

BuildKit keeps every intermediate layer it has ever produced to make rebuilds
fast. It is **not shown by `docker images`** and is **not removed by
`docker image prune`** — only `docker buildx prune` (or `docker system prune`).

```bash
docker buildx du                       # total cache size
docker buildx du --verbose             # per-record breakdown
docker buildx prune                    # clear it all (interactive)
docker buildx prune -f --keep-storage 10GB
docker buildx prune -f --filter "until=168h"   # older than a week
docker buildx ls                       # multiple builders? prune each
docker buildx prune --builder default -f
```

### Stop cache from growing so fast

1. **Order Dockerfile layers well** — deps before source (see
   [03-Intermediate §3](./03-Intermediate.md#3-dockerfile-best-practices)). Good
   ordering means fewer, reused cache entries.
2. **Cache mounts** — keep package downloads out of layers *and* out of the
   final image, while still caching them:

   ```dockerfile
   # syntax=docker/dockerfile:1
   FROM python:3.12-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN --mount=type=cache,target=/root/.cache/pip \
       pip install -r requirements.txt
   COPY . .
   ```

   The pip cache is reused across builds but **never copied into an image layer**.
3. **Bound the cache in CI** — `--cache-to`/`--cache-from` with a size-aware
   backend (registry or GitHub Actions cache):

   ```bash
   docker buildx build \
     --cache-from type=gha --cache-to type=gha,mode=max \
     --tag app:1.0 --load .
   ```

   See [`.github/workflows/docker-publish.yml`](../.github/workflows/docker-publish.yml).
4. **`--no-cache` is not a cleanup tool** — it forces a rebuild but leaves the
   old cache behind. Prune separately.

---

## 5. Container logs — the forgotten disk hog

By default the `json-file` log driver has **no size limit**. One looping app can
produce gigabytes.

**Check current sizes:**

```bash
docker inspect --format='{{.LogPath}}' CONTAINER
docker inspect --format='{{.Name}} {{.LogPath}}' $(docker ps -aq) 2>/dev/null
```

**Configure rotation globally** — `/etc/docker/daemon.json` (and restart Docker):

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

**Per service in Compose** (no daemon restart; applies on recreate):

```yaml
services:
  api:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

> Log options apply to **newly created** containers — recreate them
> (`docker compose up -d --force-recreate`) to take effect.

**Truncate an already-huge log** (Linux host; keeps the file, frees space):

```bash
sudo truncate -s 0 "$(docker inspect --format='{{.LogPath}}' CONTAINER)"
```

---

## 6. Volumes — read twice before pruning

Volumes hold the data you *cannot* rebuild: databases, uploads, keys.

```bash
docker volume ls
docker volume ls -f dangling=true          # not attached to any container
docker volume inspect vpg_pgdata --format '{{.Mountpoint}}'
```

- `docker volume prune` deletes only **unattached** volumes — but "unattached"
  includes a DB volume you stopped 5 minutes ago.
- Prefer **named volumes + `docker compose down` (no `-v`)** to keep data, and
  reserve `-v` for deliberate resets.
- **Back up before deleting** (works on any OS, no host path needed):

  ```bash
  docker run --rm -v mydata:/src -v "$PWD:/dst" alpine \
    tar czf /dst/mydata-$(date +%F).tgz -C /src .
  ```

---

## 7. Docker Desktop (macOS / Windows): the VM disk

On macOS/Windows, Docker runs in a **Linux VM** with a fixed-size *virtual disk*.
Two consequences:

1. `docker system prune` frees space **inside** the VM, but the VM's disk image
   often **does not shrink automatically** on the host.
2. The "used space" you see in Finder/Explorer may stay high after cleanup.

```bash
# 1) Reclaim inside the VM first:
docker system prune -a -f          # + --volumes only if you mean it
docker buildx prune -f

# 2) Then compact the VM disk:
#    - Docker Desktop → Settings → Resources → "Disk usage" (some versions
#      offer a "Clean / Purge data" action).
#    - Or Troubleshoot → "Clean / Purge data".
```

- **WSL2 backend (Windows):** the disk is `ext4.vhdx`. After pruning, shut down
  and compact:
  ```powershell
  wsl --shutdown
  # In an elevated prompt (path varies by distro/version):
  Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\disk\docker_data.vhdx" -Mode Full
  # or: diskpart → select vdisk file="..." → attach vdisk readonly → compact vdisk
  ```
- **macOS:** the sparse image (`Docker.raw`) can be reclaimed via Docker Desktop's
  cleanup/purge options. Prefer `--keep-storage` on `buildx prune` so you never
  rebuild from zero.

> Growing the **max disk size** is a separate setting (Resources → Disk image
> size); it only sets the ceiling.

---

## 8. Prevent bloat at the source

| Habit | Saves |
|---|---|
| `.dockerignore` (`node_modules`, `.git`, caches, `.venv`) | build context + cache size |
| Multi-stage builds ([03-Intermediate §4](./03-Intermediate.md#4-multi-stage-builds-small-clean-images)) | hundreds of MB per image |
| `-slim` / `alpine` base images | 100s of MB |
| `pip --no-cache-dir`, `apt-get clean && rm -rf /var/lib/apt/lists/*` in the **same** `RUN` | 10s–100s MB |
| `RUN --mount=type=cache` for package managers | cache without image bloat |
| Pin tags (no stray `:latest` pulls) | duplicate images |
| `logging` size limits (§5) | unbounded logs |
| Put app data in **named volumes**, not the image | rebuilds stay small |

```dockerfile
# Before
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*        # ← new layer; the lists already bloated

# After — one layer, lists never persisted
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*
```

---

## 9. Automate it

**Schedule a soft prune** (cron / systemd timer / launchd) — reclaims only what's
older than a day, so active work is untouched:

```bash
# crontab -e   →  daily at 03:30
30 3 * * * docker container prune -f --filter "until=24h" && docker image prune -f --filter "until=24h" && docker buildx prune -f --keep-storage 10GB
```

**On macOS with launchd** or **Windows Task Scheduler**, run the same command
line. In this repo:

```bash
make disk          # read-only report (safe to run anytime)
make prune-cache   # container/image/build-cache soft prune
make prune         # existing heavier target (see Makefile)
```

**Watch it before it's a crisis:** if `docker system df` RECLAIMABLE stays above a
threshold you care about, wire `docker system df --format '{{.Size}}'` into your
monitoring.

---

## 10. One-screen cheat sheet

```bash
docker system df -v                          # what's using space
docker images --format '{{.Size}}\t{{.Repository}}:{{.Tag}}' | sort -hr

docker container prune -f                     # stopped containers
docker image prune -f                         # dangling images
docker buildx prune -f --keep-storage 10GB    # build cache (bounded)
docker image prune -a -f                      # unused images
docker volume prune -f                        # ⚠️ unattached volumes (data!)
docker system prune -a -f                     # broad, keeps volumes
docker system prune -a --volumes -f           # ⚠️ everything

docker buildx du                              # build cache size
docker inspect --format '{{.LogPath}}' NAME   # a container's log file
truncate -s 0 "$(docker inspect --format='{{.LogPath}}' NAME)"   # Linux
```

---

← Back: [08-Resources.md](./08-Resources.md) · Home: [index.md](./index.md)
