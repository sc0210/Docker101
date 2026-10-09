# 02 — Docker Command Cheatsheet

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

> **Full playbook**: [09-Maintenance-and-Disk.md](./09-Maintenance-and-Disk.md) —
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

Next: [03-Intermediate.md](./03-Intermediate.md)
