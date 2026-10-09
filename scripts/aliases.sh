#!/usr/bin/env sh
# Docker 101 aliases — bash/zsh/Git Bash/WSL.
# Load with:   source scripts/aliases.sh
# Or append to ~/.zshrc / ~/.bashrc / ~/.bash_profile.

# --- listing ---------------------------------------------------------------
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dpa='docker ps -a'
alias di='docker images'
alias dv='docker volume ls'
alias dn='docker network ls'

# --- interaction -----------------------------------------------------------
alias dex='docker exec -it'          # dex <container> sh
alias dlog='docker logs -f --tail 100'
alias dsh='docker run --rm -it --entrypoint sh'

# --- compose ---------------------------------------------------------------
alias dc='docker compose'
alias dcu='docker compose up -d --build'
alias dcd='docker compose down -v'
alias dcl='docker compose logs -f'

# --- cleanup ---------------------------------------------------------------
alias dstop='docker ps -q | xargs -r docker stop'
alias drm='docker ps -a -q | xargs -r docker rm'
alias dclean='docker system prune -f'
alias dnuke='docker system prune -a --volumes -f'   # ⚠️ wipes unused images+volumes

# --- helpers ---------------------------------------------------------------
# Which container owns a published port?  usage: dport 8080
dport() { docker ps --format '{{.Names}} {{.Ports}}' | grep -- "$1"; }
# Shell into a running container by (partial) name. usage: dshel <name>
dshel() { docker exec -it "$(docker ps --format '{{.Names}}' | grep -- "$1" | head -1)" sh; }
