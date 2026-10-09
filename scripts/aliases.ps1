# Docker 101 helpers — PowerShell.
# Load with:  . .\scripts\aliases.ps1
# Or add that line to your $PROFILE.

function dps  { docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}`t{{.Ports}}" }
function dpa  { docker ps -a }
function di   { docker images }
function dv   { docker volume ls }
function dn   { docker network ls }
function dex  { param($c, $sh = "sh") docker exec -it $c $sh }
function dlog { param($c) docker logs -f --tail 100 $c }

function dc  { docker compose }
function dcu { docker compose up -d --build }
function dcd { docker compose down -v }
function dcl { docker compose logs -f }

function dstop { docker ps -q | ForEach-Object { docker stop $_ } }
function drm   { docker ps -a -q | ForEach-Object { docker rm $_ } }
function dclean { docker system prune -f }

# Which container owns a published port?  usage: dport 8080
function dport {
    param([string]$Port)
    docker ps --format "{{.Names}} {{.Ports}}" | Select-String -- $Port
}

# Shell into a running container by (partial) name.  usage: dshel web
function dshel {
    param([string]$Match, [string]$Shell = "sh")
    $name = docker ps --format "{{.Names}}" | Select-String -- $Match | Select-Object -First 1
    docker exec -it $name $Shell
}
