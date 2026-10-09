# 10 — Recipes: Ready-to-Run Stacks

A cookbook of common self-hosted / production-ish stacks. Each recipe gives you
the Compose file **and** the four answers from
[07-Use-Cases](./07-Use-Cases.md): **Operate · Data · Ports · SSH**.

> These are **starting points**, not hardened production configs. Read the old
> faithful: [docker/awesome-compose](https://github.com/docker/awesome-compose)
> says the same about its samples. Harden before exposing to the internet
> (see [Security & supply chain](./08-Resources.md#9-security--supply-chain)).

Runnable copies of select recipes live in
[`examples/recipes/`](../examples/recipes/).

## Choosing guide

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

---

## 1. Caddy — reverse proxy with automatic HTTPS

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

## 2. Traefik — Docker-native reverse proxy

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
- ⚠️ Mounting the Docker socket grants control of the daemon — prefer a **read-only**
  socket (`:ro`) or socket proxy; never expose Traefik's API publicly.

## 3. Monitoring — Prometheus + Grafana + cAdvisor + node-exporter

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
    ports: ["3000:3000"]
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin}
    volumes: [grafana_data:/var/lib/grafana]
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

- **Operate**: `up -d`; Grafana `admin`/`admin` (set `GRAFANA_PASSWORD`); import
  dashboard [15798](https://grafana.com/grafana/dashboards/15798-docker-monitoring/)
- **Data**: `prom_data`, `grafana_data` named volumes
- **Ports**: `9090` (Prometheus), `3000` (Grafana), `8081` (cAdvisor)
- **SSH**: none. `privileged: true` for cAdvisor is a real risk — run on trusted hosts only.

## 4. Uptime Kuma — status page

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

## 5. Gitea — self-hosted Git

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

## 6. Vaultwarden — password vault

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

## 7. n8n — automation

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

## 8. Dozzle — container logs in the browser

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

## 9. Watchtower — automatic image updates

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

## 10. WordPress + MySQL (the classic)

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

---

## Cross-cutting notes

- **Secrets**: use `${VAR:?}` (fail fast if unset), a git-ignored `.env`, or Compose
  [`secrets`](https://docs.docker.com/compose/how-tos/use-secrets/) — never hardcode.
- **Backups**: `docker run --rm -v <vol>:/src -v "$PWD:/dst" alpine tar czf /dst/bk.tgz -C /src .`
- **Reverse proxy in front** for anything internet-facing (recipes 1–2).
- **Pin versions** (`image: caddy:2-alpine`, not `:latest`) so `up -d` is predictable.
- **Disk**: these stacks create volumes; manage them with
  [09-Maintenance-and-Disk.md](./09-Maintenance-and-Disk.md).

Next: browse more in [08-Resources.md](./08-Resources.md).
