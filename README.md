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

Runnable examples live in [`examples/`](./examples/).

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

## Repo conventions

- Commands are copy-pasteable in a POSIX shell (bash/zsh/Git Bash/WSL).
- Where a command differs on PowerShell or CMD, it's noted inline.
- Every example prefers `--rm` for throwaway containers so your machine stays clean.
