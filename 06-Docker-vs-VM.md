# 06 — Docker vs Virtual Machine

The single most common question when learning Docker is *"isn't this just a VM?"*
Short answer: **no — they virtualize at different layers and trade isolation for
speed and density.** This chapter makes the difference concrete.

---

## 1. The picture

```
                 VIRTUAL MACHINES                              CONTAINERS
        ┌───────────────────────────────┐          ┌───────────────────────────────┐
        │  App A    App B    App C      │          │  App A    App B    App C      │
        ├─────────┬─────────┬───────────┤          ├─────────┬─────────┬───────────┤
        │ Bins/Lib│ Bins/Lib│ Bins/Lib  │          │ Bins/Lib│ Bins/Lib│ Bins/Lib  │
        ├─────────┴─────────┴───────────┤          ├─────────┴─────────┴───────────┤
        │   Guest OS   │  Guest OS      │  ← each  │      Container runtime         │
        │   (full kernel, drivers)      │    VM has│      (share ONE kernel)        │
        ├───────────────────────────────┤    its   ├───────────────────────────────┤
        │        Hypervisor             │    own OS│         Host OS kernel         │
        ├───────────────────────────────┤          ├───────────────────────────────┤
        │        Host OS / Hardware     │          │        Host OS / Hardware      │
        └───────────────────────────────┘          └───────────────────────────────┘
          Heavy: GBs, boots in minutes               Light: MBs, starts in seconds
```

- A **VM** virtualizes *hardware*. The hypervisor emulates a full machine, so each
  VM boots its **own operating system kernel**.
- A **container** virtualizes the *operating system*. All containers (on a host)
  **share the host's kernel** and are isolated by kernel features:
  **namespaces** (what a process can *see*: PIDs, network, mounts, users) and
  **cgroups** (what a process can *use*: CPU, memory).

> Analogy: a VM is a separate house with its own plumbing and wiring. A container
> is a locked apartment in a shared building — separate living space, shared
> foundation (the kernel).

## 2. Side-by-side comparison

| Dimension | Virtual Machine | Container |
|---|---|---|
| **What's virtualized** | Hardware | Operating system (process isolation) |
| **Guest OS** | Full OS + own kernel per VM | None — shares the host kernel |
| **Size** | GBs (2–20 GB typical) | MBs (5 MB–1 GB typical) |
| **Boot / start time** | 30 s–minutes | milliseconds–seconds |
| **Density per host** | a handful | dozens–hundreds |
| **Isolation strength** | Very strong (hardware boundary) | Strong but shares kernel |
| **Boots an OS** | Yes — full init, services, drivers | No — just your process (PID 1) |
| **Performance overhead** | Noticeable (CPU/mem/IO) | Near-native |
| **Image/portability** | Large, hypervisor-specific | Small, OCI-standard, portable |
| **Persistence** | VM disk files | Volumes / bind mounts (ephemeral by default) |
| **Windows + Linux together** | Easy (each VM its own OS) | A *Linux* container needs a Linux kernel (VM/WSL2 on Win/macOS) |
| **Best for** | Different OS kernels, strong tenant isolation, legacy apps | Microservices, CI, dev environments, shipping apps |

## 3. The catch: "containers are Linux"

Containers share a kernel, so **a Linux container needs a Linux kernel**:

| Host | How you get a Linux kernel for containers |
|---|---|
| Linux | The host kernel *is* Linux — native, fastest |
| Windows | **WSL2** (a lightweight Linux VM) or Hyper-V — Docker Desktop uses WSL2 |
| macOS | A small hidden Linux VM (Docker Desktop / colima / Lima) |

So even on macOS/Windows there **is a VM underneath** — but only **one**, shared by
all containers, instead of one per app. And it's why your "identical Linux
environment" promise holds: inside the container it's always the same Linux userspace.

> This is exactly why the Win/macOS ↔ Linux alignment checklist works: the
> differences are pushed into the *host-side engine*, never into the container.

## 4. When a VM is still the better tool

Containers are not "VMs but better" — they solve different problems:

- You need a **different kernel** (e.g. Windows Server workloads, FreeBSD, a
  custom kernel module). Containers can't do this.
- You need the **strongest possible isolation** between untrusted tenants
  (multi-tenant cloud, hostile workloads).
- You need to run **legacy monoliths** that assume a whole machine.
- You need **full-system** state (kernel tuning, custom boot, hardware passthrough).

## 5. The hybrid reality (what you'll actually meet)

```
Cloud / production
  └── Physical bare-metal or VM (hypervisor)
        └── Container runtime (containerd / Docker)
              └── Many containers (your services)

Your laptop (Windows/macOS)
  └── One lightweight Linux VM (WSL2 / Docker Desktop VM)
        └── Many Linux containers  ← all your dev environments
```

Modern stacks are **VMs running containers**: orchestration (Kubernetes) schedules
containers; those containers live on VMs or bare metal for the hard boundary.

## 6. Frequently confused pairs

| Pair | Relationship |
|---|---|
| **Docker vs VM** | Different layers — OS virtualization vs hardware virtualization |
| **Docker vs Kubernetes** | Docker *builds/runs* containers; k8s *orchestrates* many across machines |
| **Image vs container** | Class vs object (`.tar`/layers vs running process) |
| **Container vs process** | A container *is* an isolated process (or few), not a mini-VM |
| **WSL2 vs Docker** | WSL2 is the Linux VM that *hosts* Docker on Windows |
| **Docker vs Podman** | Same OCI images; Podman is daemonless/rootless alternative |
| **Virtual machine vs hypervisor** | The OS instance vs the software that creates it |

## 7. Cheat: measure it yourself

```bash
# Container start time vs a "full OS boot" — watch how fast this returns
time docker run --rm alpine true

# See that containers share the host kernel (same uname on host & container)
uname -r
docker run --rm alpine uname -r      # identical → shared kernel

# See the isolation: different hostname/view, same kernel
docker run --rm alpine hostname      # container's own ID
docker run --rm alpine ps aux        # only your process, not host processes
```

On macOS/Windows the `uname -r` trick reveals Docker's hidden Linux VM — proof
that even there, containers share *one* kernel, not one-per-app.

## 8. Takeaway

- **VM = isolate machines. Container = isolate processes.**
- Containers are lighter, faster, denser, and portable — at the cost of sharing
  the host kernel.
- Use containers for shipping/isolating **apps and dev environments**; use VMs
  for **different OS kernels, hard multi-tenant isolation, and legacy systems**.
- In practice they compose: **VMs host containers.**

---

← Back: [README](./README.md) · Related: [01-Basics](./01-Basics.md)
