#!/usr/bin/env sh
# Read-only snapshot of Docker disk usage. Safe to run anytime — deletes nothing.
# Usage: sh scripts/docker-disk-report.sh   (or: make disk)
set -eu

hr() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

hr "docker system df"
docker system df

hr "images by size (top 15)"
docker images --format '{{.Size}}\t{{.Repository}}:{{.Tag}}\t{{.ID}}' | sort -hr | head -15

hr "build cache"
if docker buildx du 2>/dev/null; then :; else echo "(buildx not available — skip)"; fi

hr "dangling images"
printf '%s dangling image(s)\n' "$(docker images -f dangling=true -q | wc -l | tr -d ' ')"

hr "stopped containers"
printf '%s exited container(s)\n' "$(docker ps -a -f status=exited -q | wc -l | tr -d ' ')"

hr "unattached volumes"
printf '%s volume(s)\n' "$(docker volume ls -f dangling=true -q | wc -l | tr -d ' ')"

hr "largest container logs"
if [ -d /var/lib/docker/containers ]; then
  sudo du -h /var/lib/docker/containers/*/*-json.log 2>/dev/null | sort -hr | head -10 || true
else
  echo "(not a native Linux Docker host — see Docker Desktop → Disk usage)"
fi

hr "reclaim suggestions (nothing runs automatically)"
cat <<'TIP'
Safe, everyday:     docker container prune -f && docker image prune -f && docker buildx prune -f --keep-storage 10GB
Broad, keeps data:  docker system prune -a -f
DANGER (data loss): docker system prune -a --volumes -f
Bounded cache:      docker buildx prune -f --keep-storage 10GB
TIP
