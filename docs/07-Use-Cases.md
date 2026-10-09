# 07 — Use Cases: Operate · Data · Ports · SSH

Docker usage varies wildly by project, but every container you deploy needs the
same four decisions answered. This chapter gives you a **recipe-card template**,
then applies it to common use cases.

> **The four questions** — answer these for *any* container and you'll never be lost:
>
> 1. **Operate** — how do I start, stop, upgrade, watch, and get in?
> 2. **Data** — where does state live? Named volume, bind mount, or nothing (ephemeral)?
> 3. **Ports** — what must be reachable, on which host port, exposed to whom?
> 4. **SSH** — do I need a login, and *how* (exec vs sshd vs host tunnel)?

Runnable examples for this chapter live in
[`examples/use-cases/`](../examples/use-cases/).

---

## 1. The recipe-card template

```yaml
# Operate
docker compose up -d --build      # start/update
docker compose ps                 # status + health
docker compose logs -f SERVICE    # observe
docker compose exec SERVICE sh    # get in
docker compose down               # stop (add -v to wipe volumes)

# Data   → choose ONE:
volumes: [ name:/container/path ]  # named volume  (Docker-managed, portable)
# - ./host/path:/container/path    # bind mount    (you own the files)
# (omit entirely)                  # ephemeral     (state lost on recreate)

# Ports  → host:container, and bind to localhost unless you mean to publish
ports: [ "127.0.0.1:8080:80" ]     # localhost only (safe default)
#        "8080:80"                 # all interfaces (LAN/Internet — be sure!)

# SSH    → usually none; see §3. If needed:
ports: [ "127.0.0.1:22022:22" ]    # + sshd in the image + key auth
```

**Where the data physically is:**

| Storage | Host location | Notes |
|---|---|---|
| Named volume | Linux: `/var/lib/docker/volumes/<name>/_data`; **Docker Desktop (Win/mac): inside the VM**, not a normal path | `docker volume inspect <name>` shows the mountpoint |
| Bind mount | The exact host path you typed | Visible/editable directly; path syntax differs per OS |
| tmpfs | RAM only | `--tmpfs /path`; gone on stop; secrets/scratch |
| Ephemeral (none) | Container writable layer | **Deleted with the container**; `docker diff` shows changes |

Rule of thumb: **named volume for app/db data, bind mount for live-edited files,
nothing for stateless services.**

---

## 2. Use-case matrix

| Use case | Image (example) | Ports (host:container) | Data | SSH |
|---|---|---|---|---|
| Static site | `nginx:alpine` | `8080:80` | bind mount (html) | none |
| Reverse proxy / TLS | `traefik` / `nginx` | `80:80`, `443:443` | bind configs | none |
| Web app + DB | `myapp` + `postgres` | `8080:8000` (db internal) | named volume (db) | none |
| Database only | `postgres:16` | `127.0.0.1:55432:5432` | named volume | none |
| Dev environment | language image | app only | bind mount (source) | none (exec) |
| CI runner | `myci` | none | ephemeral | host SSH |
| Data science / Jupyter | `jupyter/scipy-notebook` | `8888:8888` | named or bind (notebooks) | none (token/URL) |
| Cron / batch job | `myjob` | none | none (idempotent) or volume | none |
| Self-hosted service | `vaultwarden`, `gitea`… | service ports | named volumes | none |
| Remote Docker host | any | n/a | n/a | **Docker over SSH** |
| Dedicated login box | `alpine` + sshd | `127.0.0.1:22022:22` | key bind mount | **sshd in container** |

---

## 3. SSH login: three patterns

This is the most-asked "how do I operate it?" question. There are three levels —
**use the lowest one that works.**

### Pattern A — `docker exec` (default; no SSH at all)

```bash
docker exec -it CONTAINER sh          # inside a running container
docker compose exec SERVICE bash      # inside a compose service
```

- ✅ Nothing to install, nothing exposed, no keys to manage.
- ✅ Works identically on Windows/macOS/Linux.
- ❌ Needs the Docker CLI + access to the host daemon.

**Use for ~95% of interactive access.**

### Pattern B — SSH to the *host*, then exec (remote machines)

```bash
ssh user@server
docker exec -it CONTAINER sh
```

Even better: point your local Docker client at a remote host over SSH — then
`docker` commands run locally against the remote engine:

```bash
docker context create remote --docker "host=ssh://user@server"
docker context use remote
docker ps                       # now lists containers on the server
```

Older shortcut: `DOCKER_HOST=ssh://user@server docker ps`.

### Pattern C — run `sshd` inside the container (rare, deliberate)

Only when something must log in *as itself* (shared jump box, SSH-only tooling).
Fully worked example: [`examples/use-cases/ssh-box/`](../examples/use-cases/ssh-box/).

```bash
cd examples/use-cases/ssh-box
cp ~/.ssh/id_ed25519.pub authorized_keys
docker compose up -d --build
ssh -p 22022 dev@localhost 'hostname; whoami'
```

Security checklist for Pattern C:

- [ ] `PermitRootLogin no`, `PasswordAuthentication no`, `AllowUsers <one-user>`
- [ ] Key auth only; mount public keys `:ro`
- [ ] Publish only on `127.0.0.1` unless truly remote; add a firewall + fail2ban
- [ ] Pin the base image; keep the container minimal
- [ ] Rotate keys; never bake secrets into the image

### Bonus — reach a container port *without* publishing it

SSH local port-forwarding tunnels to a container's internal port:

```bash
# On the Docker host:
ssh -L 5433:127.0.0.1:5432 user@server   # then connect locally to :5433
# Or from a container-name/network address reachable by the host.
```

This keeps the DB unpublished (`ports:` omitted) while still letting you in.

---

## 4. Worked use cases

### 4.1 Static site (bind mount + port)

```bash
cd examples/use-cases/nginx-site
docker compose up -d          # edit html/index.html → refresh :8080
docker compose down
```

- **Data**: bind mount `./html` (`:ro`) — the host is the source of truth.
- **Ports**: `8080:80`. **SSH**: none.
- **Operate**: edit-and-refresh; no rebuild because nginx serves files live.

### 4.2 Database with persistence (named volume + localhost port)

```bash
cd examples/use-cases/postgres
docker compose up -d
docker compose exec db psql -U app -d app -c '\dt'
docker volume inspect docker101-postgres_pgdata   # ← where the data actually lives
docker compose down          # data survives…
docker compose up -d         # …and is still here
docker compose down -v       # ⚠️ only this removes the volume
```

- **Data**: named volume `pgdata`. **Ports**: `127.0.0.1:55432:5432` (localhost only).
- **SSH**: none — psql via `exec`. Other containers reach it at `db:5432`.
- **Gotcha**: deleting the *container* keeps data; deleting the *volume* does not.

### 4.3 Full-stack dev environment

See [04-End-to-End.md](./04-End-to-End.md#flow-d--dev-loop-with-hot-reload-day-to-day)
and [examples/compose](../examples/compose/docker-compose.yml):
app bind mounts source for hot reload, DB uses a named volume, ports published
for the app only. **SSH**: none — `docker compose exec`.

### 4.4 Data science / Jupyter (port + token, no SSH)

```bash
docker run --rm -it -p 8888:8888 \
  -v "$PWD/work:/home/jovyan/work" \
  quay.io/jupyter/scipy-notebook:latest
# open the printed http://127.0.0.1:8888/lab?token=... URL
```

- **Data**: bind mount `work/` (notebooks you keep) or a named volume.
- **Ports**: `8888:8888`. **SSH**: none — access is the browser URL + token.
- Docs: [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/).

### 4.5 Batch / cron job (ephemeral, no ports, no SSH)

```bash
docker run --rm \
  -v backups:/data \
  -e TARGET=prod \
  mybackup:1.0          # runs, exits, removes itself
```

- **Data**: a shared named volume (or none, if truly stateless).
- **Ports**: none. **SSH**: none. Schedule with host cron / systemd timer:
  `0 3 * * * docker run --rm -v backups:/data mybackup:1.0`.

### 4.6 Self-hosted service (homelab)

```bash
docker run -d --restart unless-stopped --name vaultwarden \
  -p 127.0.0.1:8080:80 \
  -v vaultwarden-data:/data \
  vaultwarden/server:latest
```

- **Data**: named volume (`/data`). **Ports**: often fronted by a reverse proxy;
  bind to localhost if the proxy runs on the host.
- **SSH**: none. Back the volume up with
  `docker run --rm -v vaultwarden-data:/data -v "$PWD:/bk" alpine tar czf /bk/vw.tgz /data`.

---

## 5. Ports — the fine print

```bash
-p 8080:80                 # all interfaces: host:container
-p 127.0.0.1:8080:80       # localhost only (safe default on a laptop/server)
-p 8080                    # let Docker pick a random host port → docker port NAME
-P                         # publish ALL exposed ports to random host ports
docker port NAME           # show current mappings
docker compose port SERVICE 80   # resolved host port for a service port
```

- **Host firewall ≠ container firewall**: `-p` uses Docker's own NAT rules; a host
  firewall may not block published ports (Docker inserts rules ahead of it).
  Binding to `127.0.0.1` is the reliable way to keep a service private.
- **Containers talk to each other by name** over a user-defined / Compose network
  (`db:5432`) — **no `-p` needed** for service-to-service traffic.
- **App must listen on `0.0.0.0`** inside the container, or the published port
  won't reach it.
- **Port already in use**: `docker ps --format '{{.Names}} {{.Ports}}' | grep 8080`.
- **Pick host ports that don't collide** with services already on your machine
  (a native Postgres on `5432`, an existing container on `2222`, …). Before you
  bind, check both worlds:

  ```bash
  lsof -nP -iTCP:5432 -sTCP:LISTEN        # native process on the host
  docker ps --format '{{.Names}} {{.Ports}}'   # containers already publishing
  ```

  That's why this repo's examples use `55432` (not `5432`) and `22022` (not `2222`).

---

## 6. Data — the fine print

| If you… | Data survives? |
|---|---|
| `docker restart` / `stop`+`start` | ✅ |
| `docker rm` + `docker run` (no volume) | ❌ gone |
| `docker compose down` | ✅ (volumes kept) |
| `docker compose down -v` | ❌ volume removed |
| Named volume `docker volume rm` / `prune` | ❌ gone |
| Image upgrade (`pull` newer tag) | ✅ if data is in a volume; ❌ if in the container |

```bash
docker volume ls
docker volume inspect pgdata        # Mountpoint = real host path (Linux)
docker run --rm -v pgdata:/src -v "$PWD:/dst" alpine \
  tar czf /dst/pgdata-backup.tgz -C /src .      # back up a named volume
```

**Windows/macOS note:** Docker runs Linux containers inside a VM, so named-volume
"host paths" are inside that VM — you won't find them in Finder/Explorer. Use
`docker cp`, `docker exec`, or a tar container (above) to move data in/out. Bind
mounts, by contrast, are real host paths you can open directly.

---

## 7. Operations quick reference

```bash
docker compose up -d --build SERVICE   # rebuild + restart one service
docker compose pull                    # update base images
docker compose ps                      # health/status
docker compose logs -f --tail 100 SERVICE
docker compose exec SERVICE sh         # shell in
docker compose restart SERVICE
docker compose down                    # keep volumes
docker compose down -v                 # wipe volumes too
docker stats                           # live resource use
docker events --since 10m              # daemon event stream
```

Next: [08-Resources.md](./08-Resources.md) — curated, verified learning resources.
