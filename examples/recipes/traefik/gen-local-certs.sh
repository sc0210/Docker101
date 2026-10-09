#!/usr/bin/env sh
# Generate a certificate for whoami.localhost into ./certs.
#   - Uses mkcert if available → certificate trusted by your browser/OS.
#   - Otherwise falls back to an openssl self-signed cert (browser warning).
# Run this once before `docker compose up -d`.
set -eu

cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
mkdir -p certs

if command -v mkcert >/dev/null 2>&1; then
  mkcert -install
  mkcert -cert-file certs/whoami.localhost.pem \
         -key-file  certs/whoami.localhost-key.pem \
         whoami.localhost "*.localhost" localhost 127.0.0.1 ::1
  echo "✓ mkcert wrote certs/whoami.localhost.pem (trusted locally)"
else
  openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout certs/whoami.localhost-key.pem \
    -out    certs/whoami.localhost.pem \
    -subj   "/CN=whoami.localhost" \
    -addext "subjectAltName=DNS:whoami.localhost,DNS:localhost,IP:127.0.0.1"
  echo "✓ openssl wrote certs/whoami.localhost.pem (self-signed — expect a browser warning)"
  echo "  Install mkcert for a browser-trusted cert: https://github.com/FiloSottile/mkcert"
fi
