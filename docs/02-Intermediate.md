# 02 — Intermediate Topics

## 1. Volumes: where data really lives

Containers are ephemeral — the filesystem dies with `docker rm`. Two ways to persist/share:

```bash
# Named volume (Docker-managed; survives container removal)
docker volume create pgdata
docker run -v pgdata:/var/lib/postgresql/data postgres:16

# Bind mount (host folder ↔ container folder; live editing)
docker run -v "$(pwd)/src:/app/src" -w /app node:22 npm run dev
```

### Windows / macOS ↔ Linux path alignment

| Goal | Windows (PowerShell) | macOS / Linux |
|---|---|---|
| Bind current dir | `-v "${PWD}:/app"` | `-v "$(pwd):/app"` |
| Absolute path | `-v "C:\work\app:/app"` | `-v /home/me/app:/app` |
| Git Bash / WSL | `-v "$(pwd):/app"` ✅ works | — |

**Gotchas that break "identical environment" across OSes:**

- **Line endings**: CRLF (Windows) vs LF (Linux) can break shell scripts inside
  containers. Fix once in the repo: create `.gitattributes` with
  `* text=auto eol=lf` and `*.bat text eol=crlf`.
- **File permissions**: Linux containers see UID/GID numbers. If the container
  runs as UID 1000 and your host file is owned differently, you may get
  permission errors. Options: run container with `-u $(id -u)`, or fix perms in
  the Dockerfile (`chown`), or on Windows/macOS Docker Desktop it usually "just works".
- **Mount the right path**: in WSL, `/mnt/c/...` vs `C:\...`; in Docker Desktop,
  make sure the folder is under a **file-shared** location (Docker Desktop →
  Settings → Resources → File sharing includes your path).

### Named volume vs bind mount — pick by purpose

| Purpose | Use |
|---|---|
| Database data, caches, build artifacts inside container | named volume |
| Live-reload code editing from host | bind mount |
| Sharing exact config files across teammates | bind mount (committed to repo) |

## 2. Networking

```bash
docker network create appnet
docker run -d --name db  --network appnet postgres:16
docker run -d --name api --network appnet -p 8080:8080 myapi
# api reaches DB at http://db:5432  ← container name = DNS hostname
```

- **bridge** (default) — isolated private network per user-defined network.
- **host** — share the host's network stack (Linux only; no `-p` needed).
- **none** — no networking (air-gapped / compliance testing).
- Containers on the *default* bridge can't use name-DNS; **always create a
  user-defined network** for multi-container apps (Compose does this for you).

Port rules: `-p HOST:CONTAINER`, e.g. `-p 8080:80` → host 8080 → container 80.
Multiple: `-p 8080:80 -p 8443:443`. Random host port: `-p 80` + `docker port`.

## 3. Dockerfile best practices

```dockerfile
# examples/hello-app/Dockerfile
FROM python:3.12-slim                 # pin distro+version, prefer slim variants
WORKDIR /app

# Copy dependency files FIRST → layer cache survives code changes
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Then copy source code
COPY . .

# Document & expose (documentation + default port)
EXPOSE 8000

# Run as non-root (security)
RUN useradd -m app && chown -R app:app /app
USER app

CMD ["python", "app.py"]              # exec form: no shell overhead, PID 1
```

Principles:

1. **Order layers by change frequency** — cheap/unchanging first (base image,
   deps), expensive/changing last (source code). Max cache hits.
2. **Pin tags** — `python:3.12-slim`, not `python:latest`.
3. **`.dockerignore`** — exclude `.git`, `node_modules`, `__pycache__`, `.venv`,
   local env files. Shrinks build context from GBs to KBs.
4. **One concern per image** — app image shouldn't contain your DB.
5. **`ENTRYPOINT` vs `CMD`**: entrypoint = the executable; cmd = default args.
   `ENTRYPOINT ["nginx"]` + `CMD ["-g", "daemon off;"]` →
   `docker run IMAGE -t` replaces only the CMD part.
6. **Don't run as root** — `USER` directive.

### Cache mental model

Each Dockerfile instruction = one layer, cached by (instruction + inputs).
Changing line 10 of code only re-runs layers from `COPY . .` onward —
deps layer stays cached. That's why `COPY requirements.txt` comes before `COPY .`.

## 4. Multi-stage builds (small, clean images)

```dockerfile
# ---- build stage ----
FROM node:22 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build          # outputs dist/

# ---- runtime stage ----
FROM nginx:alpine          # only nginx, no node, no source
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

```bash
docker build -t web:1.0 .   # final image contains ONLY the runtime stage
```

Result: 1 GB build tools → ~25 MB final image, fewer CVEs, faster pulls.
Same pattern works for Go (`golang` → `scratch`/`alpine`), Java (JDK → JRE), Python.

▶ **Runnable version**: [`examples/frontend-multistage/`](../examples/frontend-multistage/)
— Node build stage → nginx runtime stage. Try it:

```bash
make frontend-build
docker images docker101-frontend:local   # final image is nginx-sized, no Node
make frontend-run                        # http://localhost:8080
```

The build stage's toolchain (Node, npm, source) is discarded with Stage 1 and
never reaches the final image — only the built `dist/` files are copied over.

Measured on this repo: the `build` stage (Node) is **~157 MB**, while the final
`nginx`-based image is **~47 MB** — and the final image contains no Node, no npm,
and no source code.

## 5. Docker Compose — the whole environment in one file

```yaml
# examples/compose/docker-compose.yml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: app
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5

  api:
    build: ../hello-app
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgres://postgres:devpass@db:5432/app
    ports:
      - "8080:8000"
    volumes:
      - ../hello-app:/app        # live code (dev mode)

volumes:
  pgdata:
```

```bash
docker compose up -d --build   # everyone's identical env, one command
docker compose exec api sh     # debug inside
docker compose down -v         # clean slate (‑v = also drop volumes)
```

Key concepts:

- **`depends_on` + `healthcheck`** — start order that actually waits for readiness.
- **Default network** — services reach each other by service name (`db`, `api`).
- **`docker-compose.override.yml`** — auto-merged local overrides (dev ports,
  extra mounts) that don't pollute the shared file.
- **Profiles** — `profiles: ["debug"]` services only start with
  `docker compose --profile debug up`.

## 6. Images & registries

```bash
docker login
docker tag app:1.0 ghcr.io/you/app:1.0
docker push ghcr.io/you/app:1.0
docker pull ghcr.io/you/app:1.0

# Buildx: build for Linux from any host (macOS/Windows included!)
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/you/app:1.0 --push .
```

> ⚠️ On Apple Silicon, a plain `docker build` makes an **arm64** image — it will
> work locally but break on teammates' amd64 machines/CI. Use
> `--platform linux/amd64` (or multi-arch buildx) when sharing.

## 7. Security & size hygiene

- Run as non-root (`USER`).
- `--read-only` rootfs for services that don't need to write
  (+ explicit `--tmpfs`/volumes for writable paths).
- Prefer official/slim/alpine base images; scan with
  `docker scout` or `trivy image NAME`.
- Never `COPY` secrets; pass at runtime via `-e` / Compose `env_file` /
  `docker secret` (Swarm).
- Pin image digests (`image@sha256:...`) for production reproducibility.

Next: [03-End-to-End.md](./03-End-to-End.md)
