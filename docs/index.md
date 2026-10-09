# Docker 101 🐳

A personal knowledge base for Docker: basics → common commands → intermediate topics →
end-to-end workflows. Written with one core motivation in mind:

> **Windows / macOS and Linux often need to "look the same" at runtime.**
> Docker gives us a clean, isolated, identical Linux environment to share —
> regardless of which host OS each teammate uses.

---

## Learning Path (basic → intermediate → end-to-end)

| # | File | What you'll learn |
|---|------|-------------------|
| 1 | [01-Basics.md](./01-Basics.md) | Why Docker, images vs containers, the mental model, first commands |
| 2 | [02-Command-Cheatsheet.md](./02-Command-Cheatsheet.md) | Daily commands grouped by task (image, container, network, volume, system) |
| 3 | [03-Intermediate.md](./03-Intermediate.md) | Networking, volumes, Dockerfile best practices, Compose, multi-stage builds |
| 4 | [04-End-to-End.md](./04-End-to-End.md) | Full flows: first app, debugging, CI-style build → ship → run |
| 5 | [05-Tips-and-Shortcuts.md](./05-Tips-and-Shortcuts.md) | Aliases, one-liners, gotchas, Win/macOS ↔ Linux alignment tricks |
| 6 | [06-Docker-vs-VM.md](./06-Docker-vs-VM.md) | Docker vs virtual machines — what each virtualizes, when to use which |
| 7 | [07-Use-Cases.md](./07-Use-Cases.md) | Recipe cards per use case: how to operate, where data lives, ports, SSH |
| 8 | [08-Resources.md](./08-Resources.md) | Curated, link-checked docs, cheat sheets, case studies and videos |
| 9 | [09-Maintenance-and-Disk.md](./09-Maintenance-and-Disk.md) | Disk & cache: what grows, safe cleanup ladder, logs, Docker Desktop VM disk |
| 10 | [10-Recipes.md](./10-Recipes.md) | Ready-to-run stacks (Caddy/Traefik, monitoring, Gitea, Vaultwarden…) — operate/data/ports/SSH |

Runnable examples live in [`examples/`](../examples/). Also included:

- [`Makefile`](../Makefile) — `make help` for build/run/compose/smoke/clean targets.
- [`scripts/aliases.sh`](../scripts/aliases.sh) · [`scripts/aliases.ps1`](../scripts/aliases.ps1)
  — daily-driver aliases for bash/zsh and PowerShell.
- [`.github/workflows/docker-publish.yml`](../.github/workflows/docker-publish.yml)
  — CI that builds (multi-arch), smoke-tests, and publishes the multi-stage image to GHCR.
- [`.github/workflows/link-check.yml`](../.github/workflows/link-check.yml)
  — CI that verifies every URL in these docs still resolves (keeps Resources honest).
- [`mkdocs.yml`](../mkdocs.yml) — config that publishes this guide as a static site
  (see the repo README for the live URL).

---

## The 60-second mental model

```
┌────────────────────────── Host OS (Windows / macOS / Linux) ─────────────────────────┐
│  Docker Desktop / dockerd                                                            │
│                                                                                      │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                                │
│   │ Container 1 │   │ Container 2 │   │ Container 3 │   ← isolated Linux processes   │
│   │ (nginx)     │   │ (postgres)  │   │ (your app)  │     same image = same env      │
│   └─────────────┘   └─────────────┘   └─────────────┘                                │
│        ▲ built from images pulled from a registry (docker.io, ghcr.io, ...)          │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

- **Image** = frozen snapshot / template (read-only, shareable).
- **Container** = running instance of an image (ephemeral, disposable).
- **Volume** = persistent data that survives container restarts.
- **The key promise**: the *same image* runs identically on Windows, macOS, and Linux —
  because inside the container it's always a Linux userspace.

> Not a tiny VM: a container isolates a **process** using the host's shared Linux
> kernel (namespaces + cgroups). See [Docker vs VM](./06-Docker-vs-VM.md).

---

## Quick start (verify your install)

```bash
docker version          # client + server info
docker run --rm hello-world   # sanity check
docker run --rm -it alpine sh  # tiny interactive Linux shell
```

Expected: `hello-world` prints a success message; the alpine shell drops you into
`/ #` — a real Linux environment, even on Windows or macOS.

---

## Repo layout

```
.
├── README.md                           # repo landing page + live-site link
├── mkdocs.yml                          # static-site config (MkDocs Material)
├── requirements-docs.txt
├── Makefile                            # make help  (build / run / smoke / clean)
├── .gitattributes                      # force LF (Win ↔ Linux safety)
├── scripts/
│   ├── aliases.sh                      # bash/zsh/Git Bash/WSL helpers
│   ├── aliases.ps1                     # PowerShell helpers
│   └── docker-disk-report.sh           # read-only disk usage report (make disk)
├── .github/workflows/
│   ├── docker-publish.yml              # CI: multi-arch build + smoke test + GHCR
│   ├── deploy-pages.yml                # CD: build MkDocs site → GitHub Pages
│   └── link-check.yml                  # CI: verify every URL in docs/ still resolves
├── docs/
│   ├── index.md                        # this page
│   └── 01-Basics.md … 10-Recipes.md    # the guide, read in order
└── examples/
    ├── hello-app/                      # minimal Python HTTP service + Dockerfile
    ├── frontend-multistage/            # Node build stage → nginx runtime (multi-stage)
    ├── compose/                        # web + postgres + redis full stack
    ├── use-cases/                      # ssh-box · postgres · nginx-site
    └── recipes/                        # caddy-static · uptime-kuma · monitoring
```

---

## Repo conventions

- Commands are copy-pasteable in a POSIX shell (bash/zsh/Git Bash/WSL).
- Where a command differs on PowerShell or CMD, it's noted inline.
- Every example prefers `--rm` for throwaway containers so your machine stays clean.
