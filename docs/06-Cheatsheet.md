# 06 — Command Cheatsheet, Tips & Shortcuts

Daily-driver commands grouped by task. `docker <noun> <verb>` is the pattern.

---

## Images

```bash
docker pull IMAGE[:tag]              # download
docker images [-a] [--format '{{.Repository}}:{{.Tag}}  {{.Size}}'
docker build -t NAME:TAG DIR         # build from Dockerfile in DIR ('.' = here)
docker build -f path/Dockerfile DIR  # custom Dockerfile path
docker buildx build --platform linux/amd64,linux/arm64 -t NAME .  # multi-arch
docker tag SRC NAME:TAG              # alias an image
docker rmi IMAGE                     # remove image
docker history IMAGE                 # layer sizes (find bloat)
docker save IMAGE -o file.tar        # export image to a tar file
docker load -i file.tar              # import image from a tar file
docker inspect IMAGE                 # deep JSON details
```

## Containers — run

```bash
docker run [OPTIONS] IMAGE [CMD]
```

Most useful option combos:

```bash
# Background + named + ports + env + volume  (the everyday template)
docker run -d --name api \
  -p 8080:8080 \
  -e DATABASE_URL=postgres://db:5432/app \
  -v $(pwd)/data:/data \
  --rm \
  myapi:1.0

# Interactive shell (alpine/busybox → sh; ubuntu → bash)
docker run --rm -it alpine sh

# Override the entrypoint/cmd temporarily (debugging)
docker run --rm -it --entrypoint sh myimage -y

# Run one-off command and exit
docker run --rm myimage:1.0 python -c "print('hi')"

# Auto-restart on failure/daemon restart
docker run --restart unless-stopped -d ...

# Limit resources (protect your laptop)
docker run --memory 512m --cpus 1 ...
```

## Containers — manage

```bash
docker ps [-a] [--size]              # list (all / with sizes)
docker logs [-f] [--tail 100] NAME   # follow logs
docker exec -it NAME sh              # jump into a RUNNING container
docker exec NAME cat /etc/hosts      # one-off command, no TTY
docker start|stop|restart|kill NAME
docker pause|unpause NAME
docker rm NAME                       # remove stopped (-f to force running)
docker inspect NAME                  # config, IPs, mounts
docker top NAME                      # processes inside
docker stats                         # live CPU/mem of all containers
docker diff NAME                     # filesystem changes made at runtime
docker cp NAME:/path ./local         # copy out   (container:path → host)
docker cp ./local NAME:/path         # copy in
docker rename OLD NEW
```

## Volumes

```bash
docker volume ls
docker volume create NAME
docker volume inspect NAME           # find mount point on host
docker volume rm NAME
docker volume prune                  # remove ALL unused volumes ⚠️

# Usage
docker run -v NAME:/container/path ...      # named volume (preferred for data)
docker run -v /host/abs/path:/container ... # bind mount (share a folder)
```

| Named volume | Bind mount |
|---|---|
| Docker manages location | You specify the host path |
| Good for DB data, caches | Good for live code editing |
| Portable across OSes | Path syntax differs per OS |

## Networks

```bash
docker network ls
docker network create NET
docker network inspect NET
docker network rm NET
docker network disconnect NET CONTAINER
docker run --network NET ...            # containers in same NET reach
docker run --network none ...           # no network at all (air-gapped)
docker port CONTAINER                   # show port mappings
docker logs / exec → containers talk by CONTAINER NAME as hostname
```

## Compose (multi-container)

```bash
docker compose up [-d] [--build]       # create + start everything
docker compose down [--volumes]        # stop + remove (‑‑volumes also data)
docker compose ps
docker compose logs [-f] [SERVICE]
docker compose exec SERVICE sh         # shell into a service
docker compose restart SERVICE
docker compose pull                    # refresh base images
docker compose config                  # validate + print merged config
docker compose up SERVICE --build      # rebuild one service
```

> Compose v2 is `docker compose` (subcommand). The old `docker-compose`
> (hyphen) is legacy.

## System / maintenance

```bash
docker system df [-v]        # disk usage (‑v = per-image breakdown)
docker system prune -a       # ⚠️ reclaim everything unused
docker builder prune         # clear build cache only
docker buildx du             # build-cache size (BuildKit)
docker info                  # daemon config, storage driver, plugins
docker version               # client & server versions
docker context ls            # multiple Docker hosts (local, remote, test)
```

> **Full playbook**: [05-Operations-and-Maintenance.md](./05-Operations-and-Maintenance.md) —
> what grows, the safe cleanup ladder, log rotation, and the Docker Desktop VM disk.

## Inspection / debugging one-liners

```bash
docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' NAME
docker inspect --format '{{.State.ExitCode}}' NAME      # exit code
docker top NAME; docker stats --no-stream               # who eats CPU?
docker events --since 10m                               # recent daemon events
docker run --rm -it --entrypoint sh IMAGE               # debug an image
```

## Naming & formatting shortcuts

```bash
# Stop ALL running containers (Idiomatic, no wildcards needed)
docker ps -q | xargs docker stop

# Remove ALL exited containers
docker ps -a --filter status=exited -q | xargs docker rm

# Pretty custom output
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

# Tag image with git short SHA
docker build -t app:$(git rev-parse --short HEAD) .
```


---

## Tips, aliases & gotchas

## Shell aliases (bash/zsh — add to `~/.zshrc` or `~/.bashrc`)

```bash
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'          # dex <container> sh
alias dlog='docker logs -f --tail 100'
alias dprune='docker system df; docker container prune -f; docker image prune -f'
alias dc='docker compose'
alias dcu='docker compose up -d --build'
alias dcd='docker compose down -v'
alias dcl='docker compose logs -f'
alias dstop='docker ps -q | xargs -r docker stop'
alias drm='docker ps -a -q | xargs -r docker rm'

# remove all stopped containers AND dangling images in one go
alias dclean='docker system prune -f'
```

PowerShell profile equivalents:

```powershell
function dps { docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}`t{{.Ports}}" }
function dcu  { docker compose up -d --build }
function dcd  { docker compose down -v }
```

## Keyboard / UX shortcuts

| Situation | Shortcut |
|---|---|
| Leave `docker logs -f` / attached session | `Ctrl+C` (detaches from `-f`; stops container if attached without `-d`) |
| Detach from `-it` session **without stopping** | `Ctrl+P` then `Ctrl+Q` |
| Inside `sh` container | `exit` (stops container unless it was `exec`'d) |
| Kill slow `docker stop` | `docker kill` (immediate SIGKILL) |
| Tab-complete docker & compose commands | install `bash-completion` / use modern shell (zsh+oh-my-zsh has it built-in) |

## Everyday one-liners

```bash
# Tail logs of every container of a compose project
docker compose logs -f --tail 50

# Which container uses this port?
docker ps --format '{{.Names}} {{.Ports}}' | grep 8080

# Bash into a container that has no sh but has bash
docker exec -it NAME bash
# no shell at all? copy a static busybox in:
docker cp /usr/local/bin/busybox NAME:/tmp/busybox && docker exec -it NAME /tmp/busybox sh

# Run a command as root inside a container running as non-root
docker exec -u 0 -it NAME sh

# Save/restore an image for air-gapped machines
docker save app:1.0 -o app.tar && docker load -i app.tar

# Quick local registry for team image sharing
docker run -d -p 5000:5000 --name registry registry:2
docker tag app:1.0 localhost:5000/app:1.0 && docker push localhost:5000/app:1.0

# Time a build
time docker build -t app:1.0 .

# Show what a container is doing at the syscall level (needs --cap-add)
docker run --cap-add SYS_PTRACE --security-opt seccomp=unconfined -it alpine
```

## The "clean alignment" checklist (Windows/macOS ↔ Linux)

Use this whenever teammates must share an identical runtime:

1. **Commit the environment, not instructions** — `docker-compose.yml` + `Dockerfile` in repo; README says only `docker compose up -d --build`.
2. **Force LF line endings** — `.gitattributes` with `* text=auto eol=lf` (CRLF breaks `#!/bin/sh` scripts → `exit 126/127`).
3. **Lock the platform** — build/push `linux/amd64` (or multi-arch buildx), so Apple Silicon users don't ship an arm64-only image.
4. **Pin image versions** — `postgres:16.4`, not `postgres:latest`.
5. **Bind-mount paths per OS** — prefer `$(pwd)` in scripts; document absolute paths per OS; keep project inside a Docker-shared folder (WSL: under the WSL filesystem or an allowed mount; Docker Desktop: file-sharing list).
6. **Use named volumes for data** — portable across OSes; never hardcode host data paths into the app.
7. **Put host-specific stuff in `docker-compose.override.yml`** — never in the shared file.
8. **Verify with one command** — `docker compose ps` all healthy + a smoke `curl`.
9. **Keep secrets out of the image** — `.dockerignore` env files; inject at runtime.
10. **Standardize the shell in images** — if some teammates use PowerShell, everything host-side should also work in Git Bash/WSL so commands are copy-paste identical.

## Common gotchas (quick reference)

| Gotcha | Why | Fix |
|---|---|---|
| `-p 80:8080` confusion | order is `host:container` | `-p 8080:80` = host 8080 → container 80 |
| App can't be reached from host | app listens on `127.0.0.1` inside container | listen on `0.0.0.0` |
| `exec format error` | image built for wrong arch | `--platform linux/amd64` rebuild |
| Container exits instantly | CMD/ENTRYPOINT wrong or app crashes | `docker run --rm -it --entrypoint sh` to debug |
| Permission denied on volume | UID mismatch (Linux hosts) | `-u $(id -u)` or chmod/chown in Dockerfile |
| "port already allocated" | leftover container | `docker ps` → `docker rm -f` |
| Disk full over time | old images/build cache | `docker system df` → `docker system prune` |
| Changes to code not showing | forgot the bind mount / wrong path | `docker inspect --format '{{json .Mounts}}'` |
| `latest` tag behaves differently per machine | each pulled at a different time | pin tags or digests |
| Compose v1 vs v2 syntax | `version:` key deprecated | drop `version:`, use `docker compose` |
| Named container conflicts on `up` | old container still around | `docker compose down` first |

## Good habits

- Always `--rm` for one-off/throwaway containers.
- `docker compose down -v` between test runs when state matters.
- `docker history` + `.dockerignore` when an image is unexpectedly fat.
- Prefer `docker compose exec` over `docker exec` inside compose projects (correct network/namespace).
- Read `docker inspect` before guessing — it answers 90% of questions.
- Rebuild base images weekly (`docker compose build --no-cache`) to pick up security patches.

---

Next: [07-Resources.md](./07-Resources.md) · Back: [Home](./index.md)

