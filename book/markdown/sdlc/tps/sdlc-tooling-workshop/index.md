# TP 4: SDLC Tooling Workshop

## Learning Objectives

By the end of this practical, you will be able to:

1. **Set up** a reproducible developer shell that provides every project dependency
2. **Build** a distroless container image with zero (or near-zero) CVEs
3. **Automate** all project tasks through a task runner
4. **Enforce** code quality and security with git hooks
5. **Generate** an SBOM and scan for CVEs as automated tasks
6. **Test** at multiple levels: unit, benchmarks, e2e, API contracts, integration with real dependencies
7. **Wire up** a CI pipeline that enforces all checks server-side
8. **Apply** linters and formatters across multiple file types

## Prerequisites

- Completed [TP 1: Packaging with Nix](../packaging-with-nix/README.md)
- Completed [TP 2: Building Containers](../perfect-container-with/README.md)
- Completed [TP 3: Perfect Containers with Nix](../perfect-container-with-nix/README.md)
- Docker or Podman installed
- Git installed

______________________________________________________________________

## Overview

Take a trivial application and wrap it in a **modern, production-grade software delivery pipeline**.

This TP is open-ended: you choose your language, your tools, and your approach.
Two reference implementations are provided to study. Then you build your own variant.

______________________________________________________________________

## What You Must Deliver

A **git repository** containing:

### 1. A small project that compiles to a single static binary

Pick a language you want to learn.
A hello-world is fine to start, but a tiny HTTP server or CLI tool is better
(it gives you something to actually test).

### 2. A reproducible developer shell

The shell must provide **every tool** the project needs.
A new contributor should be able to clone the repo, enter the shell, and build -- nothing else installed on their machine.

Choose one approach from the [Tech Radar](../../../RADAR.md) (look for dev shell tools in the Tools quadrant).

### 3. A task runner

Expose every action the project supports: `build`, `lint`, `test`, `container`, `sbom`, `cve`, etc.
Running the task runner with **no arguments** should list all available tasks.

Pick a tool from the [Tech Radar](../../../RADAR.md) (look for task runners in the Tools quadrant).

### 4. A container image

The image must be:

- **Distroless or scratch-based** -- no shell, no package manager
- Running as a **non-root user**
- Target: **0 CVE** (or as close as possible)

Choose one or more container builders from the [Tech Radar](../../../RADAR.md) (look for container tools in the Tools quadrant).

### 5. Git hooks

Hooks must run **before every commit** and check:

- Linting and formatting
- Credential / secret detection

Pick a git hooks manager from the [Tech Radar](../../../RADAR.md) (look for git hooks tools in the Tools quadrant).

### 6. Security tasks

Integrate the following into the task runner:

- **Credential / secret scanning** on the codebase (e.g. [gitleaks](https://gitleaks.io/))
- **SBOM generation** for the container image (e.g. [Syft](https://github.com/anchore/syft))
- **CVE scanning** on the container image (e.g. [Grype](https://github.com/anchore/grype) or [Trivy](https://trivy.dev/))

Pick security tools from the [Tech Radar](../../../RADAR.md) (look for security/scanning tools in the Tools quadrant).

### 7. Testing

Set up **multiple levels of testing** for your project:

- **Unit tests** -- test your application logic in isolation
- **Benchmark / load tests** -- use a tool like [k6](https://k6.io/) to benchmark your HTTP server (if applicable)
- **End-to-end tests** -- test the full application running in a container (use [k3d](https://k3d.io/), [Docker Compose](https://docs.docker.com/compose/), or similar)
- **API contract tests** -- if your app exposes an API, validate it against a [Swagger / OpenAPI](https://swagger.io/specification/) spec
- **Integration tests with real dependencies** -- use [Testcontainers](https://testcontainers.com/) to spin up real databases or services during tests (this gives you unit-test ergonomics with real infrastructure)

You don't need all of these -- pick the ones that make sense for your project.
At minimum, include **unit tests** and **one other testing level**.

Pick testing tools from the [Tech Radar](../../../RADAR.md) (look for testing & benchmarking tools in the Tools quadrant).

### 8. CI pipeline

Set up a **CI pipeline** (e.g. GitHub Actions, GitLab CI) that runs at minimum:

- **Pre-commit checks** -- linting, formatting, secret detection (same as your git hooks, but enforced server-side)
- **Build** -- compile the project
- **Tests** -- run unit tests (and optionally other test levels)
- **Container build + CVE scan** -- build the image and scan it

The CI must fail if any check fails. This ensures that even if someone skips git hooks locally, the pipeline catches it.

Pick a CI platform from the [Tech Radar](../../../RADAR.md) (look for CI/CD tools in the Tools quadrant).

### 9. Linters and formatters

Add **as many as reasonable** for your language, config files, Dockerfiles, shell scripts, markdown, etc.

Pick linters and formatters from the [Tech Radar](../../../RADAR.md) (look for linting/formatting tools in the Tools quadrant).

______________________________________________________________________

## Reference Implementations

Two complete examples are provided in [this directory](https://github.com/Dauliac/Cours/tree/main/src/sdlc/tps/sdlc-tooling-workshop):

| Directory | Language | Container builder | Task runner | Dev shell | Git hooks | Credential scanner |
|-----------|----------|-------------------|-------------|-----------|-----------|-------------------|
| `rust/`   | Rust     | Dagger            | Taskfile    | mise      | hk        | gitleaks          |
| `go/`     | Go       | Earthly           | Justfile    | mise      | lefthook  | gitleaks          |

### Quick start -- Rust variant

```bash
cd rust/
mise trust && mise install
task
```

### Quick start -- Go variant

```bash
cd go/
mise trust && mise install
just
```

> Study both implementations, then build your own.
> You are free to combine tools differently or use entirely different ones.

______________________________________________________________________

## Container Inspection

Use [dive](https://github.com/wagoodman/dive) to inspect your container layers and verify minimality:

```bash
dive <your-image:tag>
```

______________________________________________________________________

## Grading Criteria

| Criterion | Weight |
|-----------|--------|
| Container has **0 CVE** (or close) | High |
| Dev shell is **one command** to enter | High |
| All tasks are **documented** and listed | High |
| Git hooks catch **secrets and lint errors** before commit | High |
| **Tests exist** (unit + at least one other level) | High |
| **CI pipeline** runs pre-commit, build, tests, and CVE scan | High |
| SBOM and CVE scan are **automated tasks** | Medium |
| Number and quality of **linters** | Medium |
| Code and config are **clean and well-organized** | Medium |
| Container image is **small** (< 20 MB for Go/Rust) | Medium |
| **Benchmarks or load tests** with k6 or similar | Medium |
| **Integration tests** with Testcontainers, k3d, or docker-compose | Bonus |
| Builds are **reproducible** | Bonus |
| Uses Nix for dev shell or container build | Bonus |

______________________________________________________________________

## Summary

| What you learned | Key takeaway |
|------------------|-------------|
| Dev shell setup | One command to get a fully reproducible environment |
| Task automation | Every action exposed and documented through a task runner |
| Container hardening | Distroless images with non-root user and zero CVEs |
| Git hooks | Shift-left quality and security checks before code leaves your machine |
| Supply chain security | SBOM generation, CVE scanning, and credential detection |
| Testing at multiple levels | Unit tests, benchmarks, e2e, API contracts, Testcontainers |
| Linting at scale | Multiple linters covering code, config, docs, and containers |

### The Big Picture

This TP ties together everything from the course:

1. **TP 1** gave you reproducible builds with Nix
2. **TP 2** taught container fundamentals and their limits
3. **TP 3** showed how Nix produces minimal, reproducible containers
4. **TP 4** (this one) asks you to assemble a complete, production-grade pipeline with the tools of your choice

The tools will change over time. The principles stay: **reproducibility, minimality, automation, and security**.