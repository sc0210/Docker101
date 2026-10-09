# 07 — Curated Resources

A **filtered**, link-checked set of open-source docs, cheat sheets, case studies,
and videos. Nothing here is a bare link dump — each entry says *why* it earned a
place.

> **Filter criteria** (how a resource gets in):
>
> 1. **Authoritative or actively maintained** — official docs, or a repo/project
>    with recent activity. No abandoned tutorials.
> 2. **Specific and actionable** — teaches a skill or solves a problem, not SEO filler.
> 3. **Primary over rehashed** — prefer the source (Docker docs, upstream repo)
>    over a blog restating it.
> 4. **Free to access** — no paywall required to get value.
> 5. **Link verified** — every URL below returned HTTP 200 on **2026-10-09**.
>
> **Review cadence:** re-check links and "last updated" roughly quarterly; remove
> anything stale. (See [Contributing a link](#contributing-a-link).)

---

## 1. Official documentation (start here, always)

| Resource | Why it made the cut |
|---|---|
| [Docker Docs](https://docs.docker.com/) | The canonical reference; changes ship here first |
| [Get started](https://docs.docker.com/get-started/) | Guided path from zero → first container |
| [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) | Every instruction, spelled out — use while writing `Dockerfile` |
| [Compose file reference](https://docs.docker.com/reference/compose-file/) | The definitive `ports` / `volumes` / `healthcheck` syntax |
| [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/) | The pattern behind our [frontend example](../examples/frontend-multistage/) |
| [Volumes](https://docs.docker.com/engine/storage/volumes/) | Where data lives; backs [§6 of Use Cases](./04-Use-Cases-and-Recipes.md#6-data--the-fine-print) |
| [Publishing ports](https://docs.docker.com/get-started/docker-concepts/running-containers/publishing-ports/) | Clear explanation of `host:container` |
| [`docker container port`](https://docs.docker.com/reference/cli/docker/container/port/) | Inspecting live mappings |
| [Contexts & remote hosts](https://docs.docker.com/engine/manage-resources/contexts/) | `docker context` / Docker over SSH (Use Cases §3, Pattern B) |
| [Docker Scout](https://docs.docker.com/scout/) | Built-in image vulnerability analysis |
| [Build best practices](https://docs.docker.com/build/building/best-practices/) | The official checklist behind our [Intermediate](./02-Intermediate.md) advice |
| [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/) | `linux/amd64` + `linux/arm64` from one command |
| [Buildx Bake](https://docs.docker.com/build/bake/) | Declarative build config — CI-friendly (see [§13](#13-build--ci)) |
| [Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/) | Keep passwords out of `environment:` (recipes §secrets) |
| [Compose `develop` / watch](https://docs.docker.com/reference/compose-file/develop/) | Hot-reload without hand-rolled bind mounts |
| [Rootless mode](https://docs.docker.com/engine/security/rootless/) | Run the daemon as a non-root user |
| [Engine security](https://docs.docker.com/engine/security/) | Threat model, capabilities, seccomp, AppArmor |
| [Use Compose in production](https://docs.docker.com/compose/how-tos/production/) | What Compose *is* and isn't good at |
| [Docker Hardened Images](https://docs.docker.com/dhi/) | Near-zero-CVE, minimal, verifiable base images |
| [Swarm mode](https://docs.docker.com/engine/swarm/) | Built-in orchestration; the pragmatic step before K8s |
| [Docker networks](https://docs.docker.com/engine/network/) | Bridge/overlay/host/macvlan, DNS, isolation |

## 2. Cheat sheets & quick references

| Resource | Why it made the cut |
|---|---|
| [wsargent/docker-cheat-sheet](https://github.com/wsargent/docker-cheat-sheet) | The classic community cheat sheet; concise, widely referenced |
| [Docker official cheatsheet (PDF)](https://docs.docker.com/get-started/docker_cheatsheet.pdf) | Printable one-pager straight from Docker |
| [devhints — Docker](https://devhints.io/docker) | Fast, scannable syntax cards |
| [Docker Labs (Collabnix)](https://dockerlabs.collabnix.com/) | 500+ hands-on labs, beginner → advanced |

## 3. Curated "awesome" lists

| Resource | Why it made the cut |
|---|---|
| [veggiemonk/awesome-docker](https://github.com/veggiemonk/awesome-docker) | The reference Docker ecosystem index (tools, images, guides) |
| [docker/awesome-compose](https://github.com/docker/awesome-compose) | **Official** Compose samples — great starting points per stack |
| [awesome-selfhosted](https://awesome-selfhosted.net/) | Huge, well-maintained catalog of self-hostable apps |
| [hotheadhacker/awesome-selfhost-docker](https://github.com/hotheadhacker/awesome-selfhost-docker) | Self-hosted projects that ship with Compose files |

> The [awesome-compose repo](https://github.com/docker/awesome-compose) explicitly
> labels its samples as *development* starting points, not production templates —
> good, honest framing worth remembering.

## 4. Real-world stories & case studies

| Resource | Why it made the cut |
|---|---|
| [Docker customer stories](https://www.docker.com/customer-stories/) | Index of production adoption write-ups |
| [Cloudflare](https://www.docker.com/customer-stories/cloudflare/) | Scale: ~1,500 images/day, 6,000+ multi-arch images |
| [ZEISS](https://www.docker.com/customer-stories/zeiss/) | Cross-platform portability + GPU in production |
| [IDOM](https://www.docker.com/customer-stories/idom/) | Security outcome with hardened base images (−80% high-severity) |
| [Docker's own migration](https://www.docker.com/customer-stories/) | Deployed Desktop to hundreds of macOS/Windows machines in 24h |

## 5. Video courses & channels

| Resource | Why it made the cut |
|---|---|
| [TechWorld with Nana — Docker Tutorial for Beginners](https://www.youtube.com/watch?v=3c-iBn73dDE) | ~2h zero-to-working; the most consistently recommended free course |
| [NetworkChuck — Docker for beginners](https://www.youtube.com/watch?v=eGz9DS-aIeY) | Fast, high-energy intro to the mental model |
| [Fireship — Docker in 100 Seconds](https://www.youtube.com/watch?v=Gjnup-PuquQ) | Best 2-minute overview to send a teammate |
| [freeCodeCamp — Docker Tutorial for Beginners](https://www.youtube.com/watch?v=fqMOX6JJhGo) | Long-form, full project build |
| [Bret Fisher (@BretFisher)](https://www.youtube.com/@BretFisher) | Deep, production-oriented Docker/K8s content |
| [Docker in 10 Minutes (2026)](https://www.youtube.com/watch?v=ZyWBs0CU2wk) | A recent, compact refresher |
| [Techno Tim (@TechnoTim)](https://www.youtube.com/@TechnoTim) | Self-hosting + Docker Compose, clean production |
| [Christian Lempa (@christianlempa)](https://www.youtube.com/@christianlempa) | Homelab, Traefik, automation, Ansible/Docker |
| [Jim's Garage (@Jims-Garage)](https://www.youtube.com/@Jims-Garage) | Practical self-hosted stacks and hardening |
| [NetworkChuck (@NetworkChuck)](https://www.youtube.com/@NetworkChuck) | Beginner-friendly networking + Docker |
| [Traefik vs Caddy vs Nginx (video)](https://www.youtube.com/watch?v=igInrPwZuzA) | Visual comparison of the three reverse proxies |
| [Buildx Bake (video)](https://www.youtube.com/watch?v=kE2z1b-ZRM4) | Declarative multi-platform builds in practice |
| [Compose Watch (video)](https://www.youtube.com/watch?v=FhorvGysZ6w) | `develop.watch` hot-reload demo |

## 6. Tools worth knowing

| Tool | Type | Why it made the cut |
|---|---|---|
| [Trivy](https://github.com/aquasecurity/trivy) | Scanner | One binary: CVEs, misconfig, secrets, SBOM |
| [Hadolint](https://github.com/hadolint/hadolint) | Linter | Catches Dockerfile mistakes before build |
| [Dive](https://github.com/wagoodman/dive) | Inspector | Visualizes layers to shrink images |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | TUI | Terminal UI for containers/volumes/images |
| [Portainer](https://www.portainer.io/) | Web UI | Manage Docker on a host/self-hosted box |
| [Watchtower](https://github.com/containrrr/watchtower) | Auto-update | Pulls new image tags and restarts containers |
| [Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/) | Images | Ready data-science stacks (see [Use Cases §4.4](./04-Use-Cases-and-Recipes.md#44-data-science--jupyter-port--token-no-ssh)) |

## 7. Remote access & dev containers

| Resource | Why it made the cut |
|---|---|
| [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) | Edits *inside* the container — same env in the editor (pairs with our Ongoing goal) |
| [CircleCI — How to SSH into Docker containers](https://circleci.com/blog/ssh-into-docker-container/) | Balanced walkthrough + why exec is usually better |
| [Dev Containers spec](https://containers.dev/) | The open standard behind `.devcontainer/` |
| [GitHub Codespaces](https://github.com/features/codespaces) | Cloud dev containers, zero local setup |
| [Docker Dev Environments](https://docs.docker.com/desktop/features/dev-environments/) | Share a reproducible dev env from Desktop |

## 8. Orchestration & scaling

| Resource | Why it made the cut |
|---|---|
| [Docker Swarm mode](https://docs.docker.com/engine/swarm/) | Orchestration built into Docker; far simpler than K8s |
| [Kubernetes docs](https://kubernetes.io/docs/home/) | The industry-standard orchestrator; learn it after Compose |
| [k3s](https://k3s.io/) | Lightweight certified K8s — single binary, great on a Pi/homelab |
| [kind](https://kind.sigs.k8s.io/) | K8s clusters in Docker containers, for local testing |
| [Kompose](https://kompose.io/) | Convert `docker-compose.yml` → Kubernetes manifests |
| [Compose specification](https://compose-spec.io/) | The vendor-neutral spec Compose implements |

## 9. Security & supply chain

| Resource | Why it made the cut |
|---|---|
| [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html) | Concise, authoritative hardening rules |
| [Docker Bench for Security](https://github.com/docker/docker-bench-security) | CIS-benchmark audit script for the host + daemon |
| [Dockle](https://github.com/goodwithtech/dockle) | Lints built images for CIS-style misconfig |
| [Grype](https://github.com/anchore/grype) | Fast vulnerability scanner for images/SBOMs |
| [Syft](https://github.com/anchore/syft) | Generates SBOMs (CycloneDX/SPDX) |
| [Cosign](https://github.com/sigstore/cosign) | Sign/verify images; keyless via Sigstore |
| [Sigstore docs](https://docs.sigstore.dev/) | The signing/transparency-log project behind cosign |
| [OWASP DockSec](https://github.com/OWASP/DockSec) | Static analysis of Dockerfiles for security smells |

## 10. Container registries

| Resource | Why it made the cut |
|---|---|
| [Docker Registry (Distribution)](https://github.com/distribution/distribution) | The reference self-hosted registry |
| [Harbor](https://goharbor.io/) | CNCF registry: RBAC, scanning, signing, replication |
| [Harbor (source)](https://github.com/goharbor/harbor) | Active CNCF project repository |
| [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) | Where this repo's [publish workflow](../.github/workflows/docker-publish.yml) pushes |

## 11. Observability

| Resource | Why it made the cut |
|---|---|
| [cAdvisor](https://github.com/google/cadvisor) | Per-container resource metrics, from Google |
| [Prometheus](https://prometheus.io/) | The metrics store + query language standard |
| [Grafana Docker dashboard 15798](https://grafana.com/grafana/dashboards/15798-docker-monitoring/) | Import-and-go dashboard for the stack above |
| [Dozzle](https://github.com/amir20/dozzle) | Live container logs in the browser, no setup |
| [Glances](https://github.com/nicolargo/glances) | Cross-platform top-style monitor (runs in a container) |

## 12. Dev environments & testing

| Resource | Why it made the cut |
|---|---|
| [Testcontainers](https://testcontainers.com/) | Throwaway Docker deps (DB, queue) inside integration tests |
| [Dagger](https://dagger.io/) | Portable CI pipelines built from containers |
| [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) | (also listed in §7) |
| [Dev Containers spec](https://containers.dev/) | (also listed in §7) |

## 13. Build & CI

| Resource | Why it made the cut |
|---|---|
| [Buildx Bake](https://docs.docker.com/build/bake/) | One declarative file for many targets/tags (also §1) |
| [Bake guide](https://docs.docker.com/guides/bake/) | Step-by-step walkthrough of the above |
| [Kaniko](https://github.com/GoogleContainerTools/kaniko) | Build images inside a container, no daemon/socket |
| [Buildpacks](https://buildpacks.io/) | Turn source into an image without a Dockerfile |
| [Multi-platform builds](https://docs.docker.com/build/building/multi-platform/) | (also §1) |

---

## Contributing a link

Match the [filter criteria](#08--curated-resources) above, then add a row to the
right table. In the PR, state: **what it teaches, who it's for, and when it was
last updated.** A link that fails any criterion gets rejected — the value of this
page is in what it *excludes*.

Back: [06-Cheatsheet.md](./06-Cheatsheet.md) · [Home](./index.md)
