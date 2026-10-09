# 04 — End-to-End Flows

Three complete, copy-pasteable flows that tie everything together.

---

## Flow A — "Give a teammate an identical environment"

**Goal**: You're on macOS, teammate on Windows, third on Linux — all three must
run the exact same stack with one command each.

### Step 1 — Define the environment

```
myproject/
├── docker-compose.yml      ← the environment definition (the real deliverable)
├── .gitattributes          ← force LF line endings
├── .dockerignore
├── app/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── ...
└── README.md               ← "just run: docker compose up -d --build"
```

`.gitattributes` (kills the CRLF/LF class of bugs immediately):

```
* text=auto eol=lf
*.bat text eol=crlf
*.png binary
```

### Step 2 — Write the compose file

See the full annotated example at [`examples/compose/docker-compose.yml`](./examples/compose/docker-compose.yml).

Minimum shape:

```yaml
services:
  app:
    build: ./app
    ports: ["8080:8000"]
    environment:
      DB_HOST: db
    depends_on: [db]
  db:
    image: postgres:16
    volumes: [pgdata:/var/lib/postgresql/data]
    environment:
      POSTGRES_PASSWORD: devpass
volumes:
  pgdata:
```

### Step 3 — Verify it works locally (you)

```bash
docker compose down -v && docker compose up -d --build
docker compose ps                      # all healthy?
docker compose logs -f app
curl http://localhost:8080
docker compose down -v                 # reset before committing
```

### Step 4 — Hand it off

```bash
git add -A && git commit -m "dockerized env" && git push
```

Teammate (any OS):

```bash
git clone <repo> && cd <repo>
docker compose up -d --build
```

✅ Same images, same Linux containers, same ports, same data setup — everywhere.

### Step 5 — Iterate

- Change deps → `docker compose up -d --build`
- Just code changes with live-mount → usually nothing (bind mount + hot reload)
- Weird state → `docker compose down -v && docker compose up -d --build`
- Need a shell → `docker compose exec app sh`

---

## Flow B — Build → Ship → Run (CI/CD style)

**Goal**: turn a repo into a versioned image anyone can pull.

```bash
# 1. Build with a reproducible tag (git SHA)
docker build -t ghcr.io/myorg/myapp:$(git rev-parse --short HEAD) .

# 2. Smoke test
docker run --rm -d --name smoke -p 8080:8000 ghcr.io/myorg/myapp:$(git rev-parse --short HEAD)
sleep 2 && curl -fsS http://localhost:8080/healthz && docker stop smoke

# 3. Push
echo $GHCR_TOKEN | docker login ghcr.io -u myorg --password-stdin
docker push ghcr.io/myorg/myapp:$(git rev-parse --short HEAD)
docker tag  ghcr.io/myorg/myapp:$(git rev-parse --short HEAD) ghcr.io/myorg/myapp:latest
docker push ghcr.io/myorg/myapp:latest

# 4. Deploy anywhere (server, teammate, laptop)
docker pull ghcr.io/myorg/myapp:latest
docker run -d --restart unless-stopped -p 8080:8000 --name myapp ghcr.io/myorg/myapp:latest
```

CI equivalent (GitHub Actions sketch):

```yaml
- uses: docker/build-push-action@v6
  with:
    push: true
    tags: ghcr.io/myorg/myapp:${{ github.sha }}
    platforms: linux/amd64
```

---

## Flow C — Debug a misbehaving container (runbook)

Symptom: app container exits / hangs / 500s.

```bash
# 1. See the state
docker ps -a                       # Exited? Restarting? Up?
docker inspect --format '{{.State.ExitCode}} {{.State.Error}}' NAME

# 2. Read the logs
docker logs --tail 200 -f NAME

# 3. If it exits too fast to catch — run interactively, keep the shell
docker run --rm -it --entrypoint sh NAME     # same image, manual entrypoint
#   cat /proc/1/… , env, ls -la, try the CMD by hand

# 4. If it's up but wrong — jump in
docker exec -it NAME sh
#   ps aux        → who's running?
#   curl localhost:PORT → is the service listening?
#   env          → are variables what you expect?
#   cat /etc/resolv.conf → DNS issues?

# 5. Filesystem & mounts suspicious?
docker diff NAME                   # what changed at runtime
docker inspect --format '{{json .Mounts}}' NAME | jq   # is the bind path right?

# 6. Network issues
docker network inspect <net>       # same network? right IP?
docker run --rm -it --network <net> alpine wget -qO- http://service:port

# 7. Nuclear-ish resets
docker restart NAME
docker compose down -v && docker compose up -d --build   # recreate clean
docker system df                   # out of disk? → docker system prune
```

**Quick diagnosis table**

| Observation | Likely cause | Fix |
|---|---|---|
| `Exited (1)` immediately | app crash / bad CMD | logs + `--entrypoint sh` |
| `Exited (137)` | OOM-killed | raise `--memory` |
| `Exited (126/127)` | permission / command not found | check exec bit, path, CRLF |
| `restart loop` | depends_on not ready | add healthcheck + `service_healthy` |
| Connection refused from host | wrong `-p` order / app binds 127.0.0.1 | `-p host:container`, app must listen `0.0.0.0` |
| Works on Linux, fails on Mac/Win | arm64 vs amd64 image | build with `--platform linux/amd64` |
| Permission denied on mount | UID mismatch | `-u $(id -u)` or fix in Dockerfile |

---

## Flow D — Dev loop with hot reload (day-to-day)

```yaml
# compose fragment
services:
  api:
    build: ./app
    command: uvicorn app:app --host 0.0.0.0 --reload
    volumes:
      - ./app:/app          # edit on host → reload inside container
    ports: ["8000:8000"]
```

```bash
docker compose up -d --build
# ... write code in your editor, app auto-reloads
docker compose logs -f api
```

You get: isolated Linux runtime + native editor + instant reload.

Next: [05-Tips-and-Shortcuts.md](./05-Tips-and-Shortcuts.md)
