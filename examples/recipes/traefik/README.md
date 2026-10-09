# Traefik — reverse proxy with local HTTPS

A Docker-native reverse proxy. Services self-register by **labels**; TLS here is
served from a **locally-generated certificate** (mkcert or openssl).

```bash
sh gen-local-certs.sh          # create certs/ (mkcert if installed, else openssl)
docker compose up -d
curl -k --resolve whoami.localhost:8443:127.0.0.1 https://whoami.localhost:8443/
# or trust the cert and drop -k:
#   mkcert path:  curl --cacert certs/whoami.localhost.pem ...
docker compose down
```

> HTTP→HTTPS redirect is left commented in the compose file: it targets port 443,
> so enable it when you publish `80:80`/`443:443` (production), not on 8443.

- **Operate**: `docker compose up -d`; the dashboard is not exposed by default.
- **Data**: `./certs` (git-ignored) + Traefik's own state; ACME would live in a volume.
- **Ports**: `8080→80`, `8443→443` (use `80`/`443` in production).
- **SSH**: none.
- ⚠️ Mounting the Docker socket is powerful — mounts are `:ro` here; prefer a socket
  proxy in shared environments.

See the write-up in [`docs/04-Use-Cases-and-Recipes.md`](../../../docs/04-Use-Cases-and-Recipes.md).
