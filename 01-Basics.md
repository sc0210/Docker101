# 01 — Docker Basics

## 1. Why Docker?

| Problem without Docker | How Docker fixes it |
|---|---|
| "Works on my machine" (Windows vs macOS vs Linux differences) | Same image → same Linux userspace → identical behavior everywhere |
| Installing DBs/runtimes pollutes your laptop | Run them in containers; delete with one command |
| Slow onboarding: teammates follow long setup guides | `docker compose up` = entire environment in one command |
| Manual deployment scripts | Ship the environment (image), not just the code |

**Your core use case**: teammates on Windows/macOS each run an isolated Linux
container so everyone shares the *exact* runtime environment — same distro,
same packages, same versions, same locale, same ports.

## 2. Core concepts

```
Dockerfile  ──build──▶  Image  ──run──▶  Container
                           ▲
                           └──pull/push──  Registry (Docker Hub, GHCR, private)
```

- **Dockerfile** — recipe: "start from ubuntu, copy code, install deps, run X".
- **Image** — the baked result of that recipe. Read-only, versioned by tags
  (`nginx:1.27`, `python:3.12-slim`). Layers are cached and shared.
- **Container** — a running (or stopped) instance of an image, with its own
  filesystem, network namespace, and process tree. Disposable.
- **Registry** — where images are stored. Docker Hub is the default.
- **Volume** — Docker-managed storage that outlives containers.
- **Network** — a virtual network so containers can find each other by name.

### Image vs Container (one-liner)

> Image = class.  Container = object.  `docker run` = `new`.

## 3. Where Docker runs on your machine

| Host OS | Typical setup | Notes |
|---|---|---|
| Windows | Docker Desktop + WSL2 | Containers are **Linux**; use WSL2 backend (not Hyper-V legacy) |
| macOS | Docker Desktop | Containers run in a small hidden Linux VM |
| Linux | native `dockerd` | No VM overhead; user may need `sudo` or docker group |

⚠️ Containers are always Linux. On Windows you can *also* run Windows containers,
but for "align with Linux" goals, always stay on Linux containers
(Docker Desktop → Settings → Resources → ensure "Linux" engine / no Windows containers mode).

## 4. Your first commands

```bash
# 1. Pull and run an image (auto-pulls if missing)
docker run --rm nginx

# 2. Run in background (-d detached) and publish port 8080 → container 80
docker run --rm -d --name web -p 8080:80 nginx
curl http://localhost:8080        # verify
docker logs -f web                # follow logs
docker stop web                   # --rm cleans it up on stop

# 3. Interactive shell inside a container
docker run --rm -it alpine sh
#   ls /   cat /etc/os-release   exit

# 4. Build your own image (from examples/hello-app)
cd examples/hello-app
docker build -t hello:1.0 .
docker run --rm -p 8080:8000 hello:1.0
curl http://localhost:8000
```

### Flag decoder ring

| Flag | Meaning |
|---|---|
| `-d` | detached (background) |
| `-it` | **i**nteractive + pseudo-**t**ty (needed for shells) |
| `--rm` | auto-remove container when it exits (great for throwaways) |
| `-p host:container` | publish a port to the host |
| `--name X` | give the container a name |
| `-v /host/path:/container/path` | bind mount a host directory |
| `-e KEY=VALUE` | set an environment variable |
| `--network N` | attach to a user-defined network |

## 5. Lifecycle in practice

```bash
docker create ...   # like run, but doesn't start  → docker start
docker start X      # start a stopped container
docker stop X       # SIGTERM then SIGKILL after grace period
docker kill X       # immediate SIGKILL
docker rm X         # delete a stopped container
docker pause X / docker unpause X
docker restart X
```

`docker run` = `create` + `start` (+ attach/log setup).

## 6. Images: pull, tag, inspect

```bash
docker pull python:3.12-slim        # explicit pull
docker images                       # local images (alias: docker image ls)
docker tag hello:1.0 myrepo/hello:1.0   # add another tag
docker rmi hello:1.0                # delete an image
docker inspect <target>             # low-level JSON (config, mounts, IPs)
docker history hello:1.0            # layers + sizes — great for slimming images
```

Tagging = naming. `myorg/api:2026-10-09` is just a label pointing at the same
image ID; pushing pushes by tag.

## 7. Cleanup early habit

```bash
docker system df            # disk used by images/containers/volumes/build cache
docker container prune      # delete ALL stopped containers   (-f to skip prompt)
docker image prune          # delete dangling images
docker system prune -a --volumes   # ⚠️ nukes everything unused (images too)
```

Next: [02-Command-Cheatsheet.md](./02-Command-Cheatsheet.md)
