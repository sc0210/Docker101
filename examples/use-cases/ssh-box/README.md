# Use case: SSH login into a container

**When you actually need this:** interactive access that must survive on its own
(shared jump box, a service you can't `exec` into, tooling that speaks SSH).
For normal local work, prefer `docker exec` — see
[docs/04-Use-Cases-and-Recipes.md](../../docs/04-Use-Cases-and-Recipes.md).

## Run it

```bash
cp ~/.ssh/id_ed25519.pub authorized_keys     # your public key (or the example)
docker compose up -d --build
ssh -p 22022 dev@localhost 'hostname; whoami; cat /etc/os-release | head -1'
docker compose down
```

> No key yet? `ssh-keygen -t ed25519 -C you@example.com` (defaults to `~/.ssh/id_ed25519`).

## The four things to notice

| Aspect | Here |
|---|---|
| **Operate** | `docker compose up -d --build` / `logs -f` / `exec -it ssh-box sh` / `down` |
| **Data** | Key files bind-mounted **read-only** (`:ro`). Container is stateless → disposable |
| **Ports** | `127.0.0.1:22022:22` — host 22022 → container SSH 22, **localhost only** |
| **SSH** | `dev@localhost -p 22022`, key auth, root login disabled |

## Why not put sshd in every image?

- It adds attack surface and package weight (openssh + libs).
- It duplicates what `docker exec` already does, without keys/ports.
- Containers are meant to run **one foreground process**, not an init + sshd.

Use this pattern deliberately, not by default. Full discussion in
[`docs/04-Use-Cases-and-Recipes.md`](../../docs/04-Use-Cases-and-Recipes.md#3-ssh-login-three-patterns).
