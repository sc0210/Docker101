# Docker 101 🐳

A personal knowledge base for Docker — basics → common commands → intermediate
topics → end-to-end workflows — written with one core motivation:

> **Windows / macOS and Linux often need to "look the same" at runtime.**
> Docker gives us a clean, isolated, identical Linux environment to share —
> regardless of which host OS each teammate uses.

🌐 **Read it as a website:** https://sc0210.github.io/Docker101/

---

## The guide

The chapters live in [`docs/`](./docs/):

| Track | # | Chapter | What you'll learn |
|-------|---|---------|-------------------|
| — | — | [Home / Overview](./docs/index.md) | Roadmap, mental model, quick start |
| **Learn** | 1 | [Basics](./docs/01-Basics.md) | Why Docker, images vs containers, first commands, Docker vs a VM |
| | 2 | [Intermediate](./docs/02-Intermediate.md) | Volumes, networking, Dockerfile best practices, multi-stage, Compose |
| | 3 | [End-to-End](./docs/03-End-to-End.md) | Identical-env handoff, build→ship→run, debugging runbook, hot reload |
| **Guides** | 4 | [Use Cases & Recipes](./docs/04-Use-Cases-and-Recipes.md) | Operate · data · ports · SSH framework + ready-to-run stacks |
| | 5 | [Operations & Maintenance](./docs/05-Operations-and-Maintenance.md) | Disk & cache, safe cleanup, logs, Docker Desktop VM disk |
| **Reference** | 6 | [Cheatsheet](./docs/06-Cheatsheet.md) | Commands, aliases, tips, gotchas, Win/macOS ↔ Linux checklist |
| | 7 | [Resources](./docs/07-Resources.md) | Curated, link-checked docs, cheat sheets, case studies, videos |

## What else is in here

```
.
├── docs/                               # the guide (Markdown)
├── examples/
│   ├── hello-app/                      # minimal Python HTTP service + Dockerfile
│   ├── frontend-multistage/            # Node build stage → nginx runtime
│   ├── compose/                        # web + postgres + redis full stack
│   ├── use-cases/                      # ssh-box · postgres · nginx-site
│   └── recipes/                        # caddy-static · uptime-kuma · monitoring
├── scripts/aliases.sh · aliases.ps1 · docker-disk-report.sh · check-links.sh
├── Makefile                            # make help  (build / run / smoke / clean / disk)
├── mkdocs.yml                          # static-site config (MkDocs Material)
├── requirements-docs.txt
└── .github/workflows/
    ├── docker-publish.yml              # CI: multi-arch build + smoke test + GHCR
    ├── deploy-pages.yml                # CD: build docs → GitHub Pages
    └── link-check.yml                  # CI: verify every URL in docs/ still resolves
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
2. URLs are already configured in [`mkdocs.yml`](./mkdocs.yml) for this repo
   (`site_url`, `repo_url`, `edit_uri`).
3. Push to `main` — the workflow builds and publishes automatically.
   Live at **https://sc0210.github.io/Docker101/**.

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
