#!/usr/bin/env sh
# Verify every http(s) URL referenced in docs/ still resolves.
# Read-only: makes outbound requests, changes nothing. Exits non-zero on failure.
# Usage: sh scripts/check-links.sh            (or: make linkcheck)
#        STRICT=1 sh scripts/check-links.sh   # also fail on 403/429 (rate limits)
set -u

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR" || exit 1
STRICT="${STRICT:-0}"

# Collect unique URLs from markdown, dropping local/placeholder hosts and
# trailing punctuation. Localhost/dev URLs are intentionally never fetched.
urls=$(grep -rhoE 'https?://[^ )"<>`]+' docs --include='*.md' \
  | sed -E 's/[.,;:]+$//' \
  | grep -Ev '^https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])' \
  | grep -Ev '(example\.(com|org|net)|yourdomain|mydomain)' \
  | grep -Ev '^https?://[^./:]+(:[^/]*)?(/|$)' \
  | sort -u)

total=0
fails=0
warns=0

while IFS= read -r url; do
  [ -z "$url" ] && continue
  total=$((total + 1))

  code=""
  attempt=1
  while [ "$attempt" -le 3 ]; do
    code=$(curl -s -o /dev/null -w '%{http_code}' \
      -A 'Mozilla/5.0 (compatible; docker101-link-check)' \
      -L --max-time 30 "$url" 2>/dev/null || echo 000)
    case "$code" in
      2*|3*) break ;;
    esac
    attempt=$((attempt + 1))
    [ "$attempt" -le 3 ] && sleep 2
  done

  case "$code" in
    2*|3*) printf 'ok    %s  %s\n' "$code" "$url" ;;
    403|429)
      warns=$((warns + 1))
      if [ "$STRICT" = "1" ]; then
        fails=$((fails + 1))
        printf 'FAIL  %s  %s (rate-limited)\n' "$code" "$url"
      else
        printf 'warn  %s  %s (rate-limited; not counted)\n' "$code" "$url"
      fi
      ;;
    *)
      fails=$((fails + 1))
      printf 'FAIL  %s  %s\n' "$code" "$url"
      ;;
  esac
done <<EOF
$urls
EOF

printf '\n%d URL(s) checked · %d failed · %d rate-limited\n' "$total" "$fails" "$warns"
[ "$fails" -eq 0 ]
