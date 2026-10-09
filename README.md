# Docker 101 🐳

A personal knowledge base for Docker — basics → common commands → intermediate
topics → end-to-end workflows — written with one core motivation:

> **Windows / macOS and Linux often need to "look the same" at runtime.**
> Docker gives us a clean, isolated, identical Linux environment to share —
> regardless of which host OS each teammate uses.

🌐 **Read it as a website:** `https://YOUR-USERNAME.github.io/docker101/`
(replace with your URL after the first deploy — see [Publishing](#publishing))

---

## The guide

The chapters live in [`docs/`](./docs/):

| # | Chapter | What you'll learn |
|---|---------|-------------------|
| — | [Home / Overview](./docs/index.md) | Roadmap, mental model, quick start |
| 1 | [Basics](./docs/01-Basics.md) | Why Docker, images vs containers, first commands |
| 2 | [Command Cheatsheet](./docs/02-Command-Cheatsheet.md) | Daily commands grouped by task |
| 3 | [Intermediate](./docs/03-Intermediate.md) | Volumes, networking, Dockerfile best practices, multi-stage, Compose |
| 4 | [End-to-End](./docs/04-End-to-End.md) | Identical-env handoff, build→ship→run, debugging runbook, hot reload |
| 5 | [Tips & Shortcuts](./docs/05-Tips-and-Shortcuts.md) | Aliases, one-liners, gotchas, Win/macOS ↔ Linux checklist |
| 6 | [Docker vs VM](./docs/06-Docker-vs-VM.md) | What each virtualizes, when to use which |

## What else is in here

```
.
├── docs/                               # the guide (Markdown)
├── examples/
│   ├── hello-app/                      # minimal Python HTTP service + Dockerfile
│   ├── frontend-multistage/            # Node build stage → nginx runtime
│   └── compose/                        # web + postgres + redis full stack
├── scripts/aliases.sh · aliases.ps1    # daily-driver shell helpers
├── Makefile                            # make help  (build / run / smoke / clean)
├── mkdocs.yml                          # static-site config (MkDocs Material)
├── requirements-docs.txt
└── .github/workflows/
    ├── docker-publish.yml              # CI: multi-arch build + smoke test + GHCR
    └── deploy-pages.yml                # CD: build docs → GitHub Pages
```

Quick taste:

```bash
make help                 # list all tasks
make frontend-run         # build & run the multi-stage demo → http://localhost:8080
make compose-up           # full web + postgres + redis stack
```

---

## Publishing

The site is built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/)
and deployed to **GitHub Pages** by
[`.github/workflows/deploy-pages.yml`](./.github/workflows/deploy-pages.yml).

**One-time setup after you push to GitHub:**

1. Repo **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. In [`mkdocs.yml`](./mkdocs.yml), set your real URLs:
   - `site_url: https://<user>.github.io/docker101/`
   - `repo_url: https://github.com/<user>/docker101` (uncomment)
   - `edit_uri: edit/main/docs/`
3. Push to `main` — the workflow builds and publishes automatically.

**Preview locally** (Docker, nothing installed on your machine):

```bash
docker run --rm -it -p 8000:8000 -v "$PWD":/docs -w /docs squidfunk/mkdocs-material serve --dev-addr=0.0.0.0:8000
# → http://localhost:8000
```

Or build the static output into `site/`:

```bash
docker run --rm -v "$PWD":/docs -w /docs squidfunk/mkdocs-material build --clean
```

---

## Repo conventions

- Commands are copy-pasteable in a POSIX shell (bash/zsh/Git Bash/WSL).
- Where a command differs on PowerShell or CMD, it's noted inline.
- Every example prefers `--rm` for throwaway containers so your machine stays clean.
