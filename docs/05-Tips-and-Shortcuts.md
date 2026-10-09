# 05 — Tips, Shortcuts & Gotchas

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

← Back: [Home](./index.md)
