# 04 — Use Cases & Recipes

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

See [03-End-to-End.md](./03-End-to-End.md#flow-d--dev-loop-with-hot-reload-day-to-day)
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


---

## Part 2 — Cookbook: ready-to-run stacks

Each recipe is a complete Compose file plus the same four answers. Full, runnable copies live in [`examples/recipes/`](../examples/recipes/).

## Recipe chooser

| Need | Reach for | Why |
|---|---|---|
| Reverse proxy + auto TLS, simple | **Caddy** | 2-line config, HTTPS by default |
| Reverse proxy, Docker-native discovery | **Traefik** | services self-register via labels |
| Metrics & dashboards | **Prometheus + Grafana + cAdvisor** | the de-facto open stack |
| Uptime/status page | **Uptime Kuma** | one container, one volume |
| Git hosting | **Gitea** | lightweight, one binary + DB |
| Password vault | **Vaultwarden** | Bitwarden-compatible, one volume |
| Automation/webhooks | **n8n** | visual workflows |
| Log viewer | **Dozzle** | read-only socket, browser logs |
| Auto image updates | **Watchtower** | pulls + restarts on new tags |
| Photos & videos | **Immich** | official compose; DB is version-coupled |
| Files, calendar, sync | **Nextcloud** | app + MariaDB |
| Network-wide DNS / ad-block | **Pi-hole** | DNS sinkhole with a web UI |
| Smart home | **Home Assistant** | host networking + privileged for devices |

---

## Recipe 1 — Caddy — reverse proxy with automatic HTTPS

```yaml
# examples/recipes/caddy-static/docker-compose.yml
services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "8080:80"          # local; use "80:80" + "443:443" for a real domain
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./html:/srv:ro
      - caddy_data:/data      # certificates + ACME state
      - caddy_config:/config
    restart: unless-stopped
volumes:
  caddy_data:
  caddy_config:
```

```caddyfile
# Caddyfile — local static site on :80
:80 {
    root * /srv
    file_server
}

# For a real domain, replace the block above with (auto HTTPS via Let's Encrypt):
# app.example.com {
#     reverse_proxy api:8000
# }
```

- **Operate**: `docker compose up -d` / `logs -f caddy` / `exec caddy caddy validate --config /etc/caddy/Caddyfile`
- **Data**: `caddy_data` (certs — **keep it**, or you'll re-issue certs), `html` bind-mount (read-only)
- **Ports**: `8080:80`; production also publishes `443:443` and `80:80`
- **SSH**: none

## Recipe 2 — Traefik — Docker-native reverse proxy

```yaml
services:
  traefik:
    image: traefik:v3
    command:
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.le.acme.email=you@example.com
      - --certificatesresolvers.le.acme.storage=/letsencrypt/acme.json
      - --certificatesresolvers.le.acme.tlschallenge=true
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro     # service discovery
      - letsencrypt:/letsencrypt
    restart: unless-stopped

  whoami:
    image: traefik/whoami
    labels:
      - traefik.enable=true
      - traefik.http.routers.whoami.rule=Host(`whoami.example.com`)
      - traefik.http.routers.whoami.entrypoints=websecure
      - traefik.http.routers.whoami.tls.certresolver=le
volumes:
  letsencrypt:
```

- **Operate**: `docker compose up -d` / dashboard via a router on `api@internal`
- **Data**: `letsencrypt` volume (`acme.json` — `chmod 600`)
- **Ports**: `80`, `443`
- **SSH**: none
- **Local HTTPS**: runnable example with generated certs in
  [`examples/recipes/traefik/`](../examples/recipes/traefik/) (mkcert if installed, else openssl)
- ⚠️ Mounting the Docker socket grants control of the daemon — prefer a **read-only**
  socket (`:ro`) or socket proxy; never expose Traefik's API publicly.

## Recipe 3 — Monitoring — Prometheus + Grafana + cAdvisor + node-exporter

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    ports: ["9090:9090"]
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prom_data:/prometheus
    restart: unless-stopped
  grafana:
    image: grafana/grafana-oss:latest
    ports: ["3300:3000"]        # 3000 is commonly taken; map to 3300
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin}
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro   # auto-adds Prometheus datasource
    restart: unless-stopped
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.49.1
    ports: ["8081:8080"]
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    restart: unless-stopped
  node-exporter:
    image: prom/node-exporter:latest
    ports: ["9100:9100"]
volumes:
  prom_data:
  grafana_data:
```

```yaml
# prometheus.yml — scrape the exporters
scrape_configs:
  - job_name: cadvisor
    static_configs: [{ targets: ["cadvisor:8080"] }]
  - job_name: node
    static_configs: [{ targets: ["node-exporter:9100"] }]
```

- **Operate**: `up -d`; Grafana `admin`/`admin` (set `GRAFANA_PASSWORD`) — Prometheus
  is provisioned as the default datasource, so just import dashboard
  [15798](https://grafana.com/grafana/dashboards/15798-docker-monitoring/) and go.
- **Data**: `prom_data`, `grafana_data` named volumes
- **Ports**: `9090` (Prometheus), `3300` (Grafana), `8081` (cAdvisor)
- **SSH**: none. `privileged: true` for cAdvisor is a real risk — run on trusted hosts only.

## Recipe 4 — Uptime Kuma — status page

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    ports: ["3001:3001"]
    volumes: [uptime-kuma:/app/data]
    restart: unless-stopped
volumes:
  uptime-kuma:
```

- **Operate**: first open `http://localhost:3001` to create the admin account
- **Data**: `uptime-kuma` volume (`/app/data`) — back it up; it holds all history
- **Ports**: `3001`; front with Caddy/Traefik for TLS
- **SSH**: none

## Recipe 5 — Gitea — self-hosted Git

```yaml
services:
  gitea:
    image: gitea/gitea:1
    ports: ["3002:3000", "2222:22"]     # 2222 = git-over-SSH
    environment:
      GITEA__database__DB_TYPE: postgres
      GITEA__database__HOST: db:5432
      GITEA__database__NAME: gitea
      GITEA__database__USER: gitea
      GITEA__database__PASSWD: ${GITEA_DB_PASSWORD:?set it}
    volumes:
      - gitea_data:/data
    depends_on: [db]
    restart: unless-stopped
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: gitea
      POSTGRES_PASSWORD: ${GITEA_DB_PASSWORD:?set it}
      POSTGRES_DB: gitea
    volumes: [pgdata:/var/lib/postgresql/data]
    restart: unless-stopped
volumes:
  gitea_data:
  pgdata:
```

- **Operate**: `up -d`, finish setup at `http://localhost:3002`
- **Data**: `gitea_data` (`/data`) + `pgdata` (DB) — back up **both**
- **Ports**: `3002:3000` web, `2222:22` git SSH
- **SSH**: yes, but it's **git-over-SSH**, not a login shell — the container runs gitea, not sshd-for-humans

## Recipe 6 — Vaultwarden — password vault

```yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    ports: ["8080:80"]
    environment:
      SIGNUPS_ALLOWED: "false"        # create your account first, then disable
    volumes: [vw_data:/data]
    restart: unless-stopped
volumes:
  vw_data:
```

- **Operate**: `up -d`, create the first account, then set `SIGNUPS_ALLOWED=false`
- **Data**: `vw_data` (`/data`) — **the vault; back it up religiously**
- **Ports**: `8080:80` — put HTTPS in front (see recipe 1/2); never expose plain HTTP
- **SSH**: none

## Recipe 7 — n8n — automation

```yaml
services:
  n8n:
    image: docker.n8n.io/n8nio/n8n
    ports: ["5678:5678"]
    environment:
      N8N_HOST: localhost
      WEBHOOK_URL: http://localhost:5678
    volumes:
      - n8n_data:/home/node/.n8n
    restart: unless-stopped
volumes:
  n8n_data:
```

- **Operate**: `up -d`, open `http://localhost:5678`
- **Data**: `n8n_data` (workflows, credentials — **encrypted with `N8N_ENCRYPTION_KEY`; set it explicitly** if you want to move/back up)
- **Ports**: `5678`; with a proxy, set `N8N_HOST`/`WEBHOOK_URL` to the public URL
- **SSH**: none

## Recipe 8 — Dozzle — container logs in the browser

```yaml
services:
  dozzle:
    image: amir20/dozzle:latest
    ports: ["8088:8080"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped
```

- **Operate**: open `http://localhost:8088`
- **Data**: none (reads the Docker log files)
- **Ports**: `8088:8080`
- **SSH**: none. Socket is mounted **read-only**; add auth before exposing.

## Recipe 9 — Watchtower — automatic image updates

```yaml
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --schedule "0 0 4 * * *" --cleanup --label-enable
    restart: unless-stopped
```

- **Operate**: label opt-in services with `com.centurylinklabs.watchtower.enable=true`
- **Data**: none
- **Ports**: none
- **SSH**: none
- ⚠️ Auto-updating to moving tags can break production. Prefer pinning + explicit
  upgrades; if you use it, enable per-label and watch the logs.

## Recipe 10 — WordPress + MySQL (the classic)

```yaml
services:
  wordpress:
    image: wordpress:6
    ports: ["8080:80"]
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: ${WP_DB_PASSWORD:?set it}
      WORDPRESS_DB_NAME: wordpress
    volumes: [wp_html:/var/www/html]
    depends_on: [db]
    restart: unless-stopped
  db:
    image: mysql:8
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: ${WP_DB_PASSWORD:?set it}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:?set it}
    volumes: [db_data:/var/lib/mysql]
    restart: unless-stopped
volumes:
  wp_html:
  db_data:
```

- **Operate**: `up -d`, finish install at `http://localhost:8080`
- **Data**: `wp_html` (plugins/uploads) + `db_data` (database) — back up both
- **Ports**: `8080:80`; front for TLS
- **SSH**: none

## Recipe 11 — Immich — self-hosted photo library

Immich ships a maintained, **version-coupled** stack (server + ML + Postgres +
Redis). Don't hand-roll it — start from their official compose (kept in
[`examples/recipes/immich/`](../examples/recipes/immich/)):

```bash
cd examples/recipes/immich
cp example.env .env            # set UPLOAD_LOCATION, DB_DATA_LOCATION, DB_PASSWORD
docker compose up -d
```

- **Operate**: first run at `http://localhost:2283` to create the admin; upgrade with
  `docker compose pull && docker compose up -d` (read the release notes first)
- **Data**: `UPLOAD_LOCATION` (your media) + `DB_DATA_LOCATION` (Postgres) — **bind
  paths on the host; back up both**. The DB image is pinned to the Immich version.
- **Ports**: `2283`
- **SSH**: none
- Docs: [docs.immich.app/install/docker-compose](https://docs.immich.app/install/docker-compose)

## Recipe 12 — Nextcloud — files, calendar & sync

```yaml
services:
  db:
    image: mariadb:11
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    environment:
      MYSQL_ROOT_PASSWORD: ${NEXTCLOUD_DB_ROOT_PASSWORD:?set it}
      MYSQL_PASSWORD: ${NEXTCLOUD_DB_PASSWORD:?set it}
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
    volumes: [db:/var/lib/mysql]
    restart: unless-stopped
  app:
    image: nextcloud:apache
    ports: ["8080:80"]
    environment:
      MYSQL_HOST: db
      MYSQL_DATABASE: nextcloud
      MYSQL_USER: nextcloud
      MYSQL_PASSWORD: ${NEXTCLOUD_DB_PASSWORD:?set it}
      NEXTCLOUD_TRUSTED_DOMAINS: "localhost 127.0.0.1"
    volumes: [nextcloud:/var/www/html]
    depends_on: [db]
    restart: unless-stopped
volumes:
  db:
  nextcloud:
```

- **Operate**: `up -d`, create the admin account at `http://localhost:8080`
- **Data**: `nextcloud` (`/var/www/html` — config + apps) + `db` (MariaDB) — back up both
- **Ports**: `8080:80`; front for TLS, then set `NEXTCLOUD_TRUSTED_DOMAINS`/overwrite vars
- **SSH**: none

## Recipe 13 — Pi-hole — network-wide DNS / ad-block

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8090:80/tcp"                     # web UI
    environment:
      FTLCONF_webserver_api_password: ${PIHOLE_PASSWORD:?set it}
      FTLCONF_dns_listeningMode: ALL
    volumes: [pihole:/etc/pihole]
    cap_add: [SYS_NICE]
    restart: unless-stopped
volumes:
  pihole:
```

- **Operate**: `up -d`, admin at `http://localhost:8090`
- **Data**: `pihole` (`/etc/pihole`) — blocklists + config; back it up
- **Ports**: `53` (DNS, tcp+udp) and `8090:80` (web). If `53` is taken (Docker
  Desktop's own resolver, systemd-resolved, …), you can map `8053:53` and point
  clients at `host:8053` — but DNS is **UDP**, and Docker Desktop's UDP
  forwarding is unreliable, so the clean fix is to run Pi-hole on a Linux host
  that can bind `53` (using `network_mode: host` there)
- **SSH**: none

## Recipe 14 — Home Assistant — smart home

```yaml
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    ports: ["8123:8123"]        # Linux: use network_mode: host instead
    volumes:
      - ha_config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    privileged: true            # USB / Bluetooth device access
    restart: unless-stopped
volumes:
  ha_config:
```

- **Operate**: `up -d`, onboarding at `http://localhost:8123`
- **Data**: `ha_config` (`/config`) — dashboards, integrations, `secrets.yaml`; back it up
- **Ports**: `8123`; on **Linux** prefer `network_mode: host` (and drop `ports:`) so
  mDNS/SSDP device discovery works — host networking is not supported on Docker Desktop
- **SSH**: none

---

## Cross-cutting notes

- **Secrets**: use `${VAR:?}` (fail fast if unset), a git-ignored `.env`, or Compose
  [`secrets`](https://docs.docker.com/compose/how-tos/use-secrets/) — never hardcode.
- **Backups**: `docker run --rm -v <vol>:/src -v "$PWD:/dst" alpine tar czf /dst/bk.tgz -C /src .`
- **Reverse proxy in front** for anything internet-facing (recipes 1–2).
- **Pin versions** (`image: caddy:2-alpine`, not `:latest`) so `up -d` is predictable.
- **Disk**: these stacks create volumes; manage them with
  [05-Operations-and-Maintenance.md](./05-Operations-and-Maintenance.md).

---

Next: [05-Operations-and-Maintenance.md](./05-Operations-and-Maintenance.md)

