# TP 4: SDLC Tooling Workshop

## Learning Objectives

By the end of this practical, you will be able to:

1. **Set up** a reproducible developer shell that provides every project dependency
2. **Build** a distroless container image with zero (or near-zero) CVEs
3. **Automate** all project tasks through a task runner
4. **Enforce** code quality and security with git hooks
5. **Generate** an SBOM and scan for CVEs as automated tasks
6. **Apply** linters and formatters across multiple file types

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

Choose one approach:

| Tool | Radar rating | Link |
|------|-------------|------|
| Nix flakes + `devShells` | Poulet | <https://nixos.org/> |
| mise | Poulet | <https://mise.jdx.dev/> |
| devenv | Poulet | <https://devenv.sh/> |

### 3. A task runner

Expose every action the project supports: `build`, `lint`, `test`, `container`, `sbom`, `cve`, etc.
Running the task runner with **no arguments** should list all available tasks.

| Tool | Radar rating | Link |
|------|-------------|------|
| go-task (Taskfile) | Poulet | <https://taskfile.dev/> |
| Just | Good | <https://github.com/casey/just> |
| Nix flakes | Poulet | <https://nixos.org/> |
| Make | Meh | <https://www.gnu.org/software/make/> |

### 4. A container image

The image must be:

- **Distroless or scratch-based** -- no shell, no package manager
- Running as a **non-root user**
- Target: **0 CVE** (or as close as possible)
- Small: **< 20 MB** for Go/Rust

Choose one or more container builders:

| Tool | Radar rating | Link |
|------|-------------|------|
| Dagger | Good | <https://dagger.io/> |
| Earthly | Good | <https://earthly.dev/> |
| Nix `dockerTools` | Poulet | <https://nixos.org/> |
| Docker multi-stage | Good | <https://www.docker.com/> |
| Podman | Poulet | <https://podman.io/> |
| Buildah | Good | <https://buildah.io/> |

### 5. Git hooks

Hooks must run **before every commit** and check:

- Linting and formatting
- Credential / secret detection

| Tool | Radar rating | Link |
|------|-------------|------|
| lefthook | Poulet | <https://evilmartians.com/chronicles/lefthook-succession-of-git-hooks> |
| hk | Good | <https://github.com/jdx/hk> |
| pre-commit | Meh | <https://pre-commit.com/> |
| Husky | Meh | <https://typicode.github.io/husky/> |

### 6. Security tasks

Integrate the following into the task runner:

- **Credential / secret scanning** on the codebase (e.g. [gitleaks](https://gitleaks.io/))
- **SBOM generation** for the container image (e.g. [Syft](https://github.com/anchore/syft))
- **CVE scanning** on the container image (e.g. [Grype](https://github.com/anchore/grype) or [Trivy](https://trivy.dev/))

| Tool | Radar rating | Link |
|------|-------------|------|
| Trivy | Poulet | <https://trivy.dev/> |
| Grype | Good | <https://github.com/anchore/grype> |
| Syft (SBOM) | Good | <https://github.com/anchore/syft> |
| gitleaks | Poulet | <https://gitleaks.io/> |
| Cosign | Good | <https://docs.sigstore.dev/cosign/overview/> |

### 7. Linters and formatters

Add **as many as reasonable** for your language, config files, Dockerfiles, shell scripts, markdown, etc.

| Tool | What it lints | Link |
|------|--------------|------|
| treefmt | Multi-language formatter orchestrator | <https://github.com/numtide/treefmt> |
| typos | Spell checker for source code | <https://github.com/crate-ci/typos> |
| taplo | TOML | <https://taplo.tamasfe.dev/> |
| hadolint | Dockerfile | <https://github.com/hadolint/hadolint> |
| shellcheck | Shell scripts | <https://www.shellcheck.net/> |
| markdownlint | Markdown | <https://github.com/DavidAnson/markdownlint> |
| yamllint | YAML | <https://github.com/adrienverge/yamllint> |
| golangci-lint | Go | <https://golangci-lint.run/> |
| clippy | Rust | <https://doc.rust-lang.org/clippy/> |
| rustfmt | Rust | <https://github.com/rust-lang/rustfmt> |
| gofmt / goimports | Go | <https://pkg.go.dev/golang.org/x/tools/cmd/goimports> |
| EditorConfig | Editor settings | <https://editorconfig.org/> |

______________________________________________________________________

## Reference Implementations

Two complete examples are provided in this directory:

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
| SBOM and CVE scan are **automated tasks** | Medium |
| Number and quality of **linters** | Medium |
| Code and config are **clean and well-organized** | Medium |
| Container image is **small** (< 20 MB for Go/Rust) | Medium |
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
| Linting at scale | Multiple linters covering code, config, docs, and containers |

### The Big Picture

This TP ties together everything from the course:

1. **TP 1** gave you reproducible builds with Nix
2. **TP 2** taught container fundamentals and their limits
3. **TP 3** showed how Nix produces minimal, reproducible containers
4. **TP 4** (this one) asks you to assemble a complete, production-grade pipeline with the tools of your choice

The tools will change over time. The principles stay: **reproducibility, minimality, automation, and security**.
