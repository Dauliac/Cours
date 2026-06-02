# TP 3: Perfect Containers with Nix

## Learning Objectives

By the end of this practical, you will be able to:

1. **Build** OCI container images using Nix, without Docker
2. **Compare** Nix-built images with traditional Docker images
3. **Explain** why Nix images are reproducible and minimal by design
4. **Create** a multi-service container setup with Nix-built images
5. **Evaluate** when to use Nix containers vs traditional Dockerfiles

## Prerequisites

- Completed [TP 1: Packaging with Nix](../packaging-with-nix/README.md)
- Completed [TP 2: Building Containers](../perfect-container-with/README.md)
- Docker or Podman available (for loading/running images)
- Nix with flakes enabled

______________________________________________________________________

## Part 1: The Nix Approach to Containers (15 min)

### Why Build Containers with Nix?

In TP 2, we identified fundamental problems with traditional Docker builds:

| Problem | Docker's answer | Nix's answer |
| --- | --- | --- |
| Reproducibility | Pin digests (manual) | Deterministic by design (automatic) |
| Minimal images | Distroless / scratch (guesswork) | Exact dependency closure (computed) |
| Build consistency | "Same Dockerfile" (not enough) | Same inputs = same output (guaranteed) |
| Layer optimization | Careful ordering (fragile) | Content-addressed layers (automatic) |

### How Nix Builds Container Images

Nix doesn't use Docker to build images. Instead, it:

1. **Computes** the exact set of runtime dependencies (the *closure*)
2. **Creates** OCI image layers from the Nix store paths
3. **Produces** a `.tar.gz` file you can load into any OCI runtime

```
┌──────────────────────────────────────────┐
│           Nix builds the image           │
│                                          │
│  Your app ──→ Nix computes closure ──→ OCI tar
│               (all dependencies)         │
│                                          │
│  No Dockerfile.  No Docker daemon.       │
└──────────────────────────────────────────┘
          │
          ▼
┌──────────────────────────────────────────┐
│       docker load < result              │
│       docker run my-image               │
└──────────────────────────────────────────┘
```

**The closure** is the key concept. When you build a Nix package, Nix knows every single dependency, transitively. When building a container, it includes *exactly* those dependencies and nothing more. No guessing, no extra packages.

### Check Your Understanding

- What is a "closure" in the context of Nix?
- Why doesn't Nix need a Docker daemon to build images?

______________________________________________________________________

## Part 2: Your First Nix Container (25 min)

### Step 1: Set up the project

Start from your TP 1 project, or create a new one:

```bash
mkdir -p nix-container
cd nix-container
git init  # Safe to run multiple times
nix flake init -t 'github:Dauliac/Cours'  # Skip if flake.nix already exists
git add .  # Nix flakes ONLY see git-tracked files!
```

> **If `nix flake init` fails** with "file already exists", it means you already ran this step. You can safely move on.
>
> **Reminder from TP 1**: every time you create a new file (especially `.nix` files), run `git add <file>` before any `nix` command. Nix flakes ignore untracked files.

### Step 2: Create a simple application to containerize

Create `app.sh`:

```bash
#!/usr/bin/env bash
echo "=== Nix Container ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "User ID: $(id -u)"
echo ""
echo "This container contains only what Nix determined is needed."
echo "Nothing else. Truly minimal."
```

### Step 3: Package the application

Create `nix/package.nix`:

```nix
_: {
  config.perSystem =
    { pkgs, config, ... }:
    {
      packages.default = pkgs.writeShellApplication {
        name = "my-app";
        runtimeInputs = with pkgs; [ coreutils hostname ];
        text = builtins.readFile ../app.sh;
      };

      apps.default = {
        type = "app";
        program = "${config.packages.default}/bin/my-app";
      };
    };
}
```

Track the new file and test it before containerizing:

```bash
git add nix/package.nix app.sh
nix run
```

### Step 4: Add the container image definition

Create `nix/container.nix`:

```nix
_: {
  config.perSystem =
    { pkgs, config, ... }:
    {
      packages.container = pkgs.dockerTools.buildImage {
        name = "my-nix-app";
        tag = "latest";

        # copyToRoot includes these in the image
        copyToRoot = pkgs.buildEnv {
          name = "image-root";
          paths = [ config.packages.default ];
          pathsToLink = [ "/bin" ];
        };

        config = {
          Cmd = [ "/bin/my-app" ];
        };
      };
    };
}
```

**Line by line:**

- `pkgs.dockerTools.buildImage`: Nix function that creates OCI images
- `name` / `tag`: The image name and tag
- `copyToRoot`: What goes into the image (our package and its closure)
- `config.Cmd`: The command to run when the container starts

### Step 5: Track and build

> **Remember**: every new `.nix` file must be `git add`ed. The template auto-imports all `.nix` files from `nix/` - no need to edit `default.nix`.

```bash
git add nix/container.nix
nom build '.#container'
```

`nom` (nix-output-monitor) wraps `nix build` with a rich live progress view. This produces a `result` file that is a Docker-compatible image archive.

### Step 6: Load and run the image

```bash
# Load the image into Docker (safe to run multiple times, overwrites previous load)
docker load < result

# Run it (--rm ensures the container is cleaned up when it exits)
docker run --rm my-nix-app:latest
```

You should see the greeting from your application.

### Step 7: Inspect the image

```bash
docker images my-nix-app
docker history my-nix-app:latest
```

Note the image size. Compare it with the Docker images from TP 2. The Nix image contains *only* what your application needs to run.

______________________________________________________________________

## Part 3: Deep Comparison (20 min)

### Step 8: Measure everything

Let's build the same application with Docker and with Nix and compare.

Create a `Dockerfile` for comparison:

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    hostname \
    && rm -rf /var/lib/apt/lists/*

COPY app.sh /usr/local/bin/my-app
RUN chmod +x /usr/local/bin/my-app

CMD ["my-app"]
```

```bash
docker build -t my-docker-app:latest .  # Safe to re-run, overwrites previous build
```

Now compare:

```bash
echo "=== Size comparison ==="
docker images my-nix-app
docker images my-docker-app

echo ""
echo "=== Layer comparison ==="
echo "Nix image layers:"
docker history my-nix-app:latest
echo ""
echo "Docker image layers:"
docker history my-docker-app:latest

echo ""
echo "=== Security comparison ==="
trivy image my-nix-app:latest 2>/dev/null | tail -5
trivy image my-docker-app:latest 2>/dev/null | tail -5
```

### Expected Results

| Metric | Docker (debian-slim) | Nix |
| --- | --- | --- |
| Image size | ~80-150 MB | ~30-50 MB |
| Number of packages | Hundreds | Only what's needed |
| CVEs | Several | Fewer or none |
| Reproducible | No (apt-get update) | Yes (locked inputs) |
| Contains shell | Yes (+ many utilities) | Only if explicitly added |

### Step 9: Verify reproducibility

Build the Nix image twice:

```bash
# -o creates named symlinks (safe to re-run, overwrites previous symlinks)
nix build '.#container' -o result1
nix build '.#container' -o result2

# Compare the checksums
sha256sum result1
sha256sum result2
```

The hashes should be **identical**. The same build, run at any time, on any machine, produces the exact same image. Try the same with `docker build` - the hashes will differ.

### Why the Difference?

Docker images include:

- Timestamps (file modification times, layer creation times)
- Non-deterministic package installation order
- Mutable base images

Nix images have none of these problems because Nix:

- Sets all timestamps to epoch 0 (1970-01-01)
- Computes exact dependency graphs deterministically
- Uses content-addressed store paths

______________________________________________________________________

## Part 4: Advanced Nix Container Patterns (25 min)

### Step 10: Layered images for faster pushes

By default, `buildImage` puts everything in one layer. For production, use `buildLayeredImage` to create separate layers:

Update `nix/container.nix`:

```nix
_: {
  config.perSystem =
    { pkgs, config, ... }:
    {
      packages.container = pkgs.dockerTools.buildLayeredImage {
        name = "my-nix-app";
        tag = "latest";

        contents = [ config.packages.default ];

        config = {
          Cmd = [ "/bin/my-app" ];
        };

        # Maximum number of layers
        maxLayers = 125;
      };
    };
}
```

**Why layered?** When pushing to a registry, unchanged layers don't need to be re-uploaded. Nix creates layers based on the dependency graph, so updating your app only pushes the changed layer, not the entire image.

### Step 11: Add a non-root user

```nix
_: {
  config.perSystem =
    { pkgs, config, ... }:
    let
      # Create a minimal passwd file
      nonRootShadowSetup = { user, uid, gid ? uid }: [
        (pkgs.writeTextDir "etc/shadow" ''
          root:!x:::::::
          ${user}:!:::::::
        '')
        (pkgs.writeTextDir "etc/passwd" ''
          root:x:0:0::/root:${pkgs.runtimeShell}
          ${user}:x:${toString uid}:${toString gid}::/home/${user}:
        '')
        (pkgs.writeTextDir "etc/group" ''
          root:x:0:
          ${user}:x:${toString gid}:
        '')
        (pkgs.writeTextDir "etc/gshadow" ''
          root:x::
          ${user}:x::
        '')
      ];
    in
    {
      packages.container = pkgs.dockerTools.buildLayeredImage {
        name = "my-nix-app";
        tag = "latest";

        contents = [
          config.packages.default
        ] ++ nonRootShadowSetup { user = "appuser"; uid = 1000; };

        config = {
          Cmd = [ "/bin/my-app" ];
          User = "appuser";
        };

        maxLayers = 125;
      };
    };
}
```

This creates a non-root user without needing `useradd` or any system utilities in the image.

### Step 12: A web server container

Let's build something more realistic. Create a Go web server and containerize it.

Create `main.go`:

```go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "runtime"
)

type Response struct {
    Message  string `json:"message"`
    Hostname string `json:"hostname"`
    GoVer    string `json:"go_version"`
    Path     string `json:"path"`
}

func handler(w http.ResponseWriter, r *http.Request) {
    hostname, _ := os.Hostname()
    resp := Response{
        Message:  "Hello from Nix-built container!",
        Hostname: hostname,
        GoVer:    runtime.Version(),
        Path:     r.URL.Path,
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(resp)
}

func main() {
    http.HandleFunc("/", handler)
    fmt.Println("Server running on :8080")
    http.ListenAndServe(":8080", nil)
}
```

Create `nix/go-package.nix`:

```nix
_: {
  config.perSystem =
    { pkgs, ... }:
    {
      packages.go-server = pkgs.buildGoModule {
        pname = "my-go-server";
        version = "0.1.0";
        src = ../.;
        vendorHash = null;  # No external dependencies
        CGO_ENABLED = 0;    # Static binary
      };
    };
}
```

Create `nix/go-container.nix`:

```nix
_: {
  config.perSystem =
    { pkgs, config, ... }:
    {
      packages.go-container = pkgs.dockerTools.buildLayeredImage {
        name = "my-go-server";
        tag = "latest";

        contents = [ config.packages.go-server ];

        config = {
          Cmd = [ "/bin/my-go-server" ];
          ExposedPorts = {
            "8080/tcp" = {};
          };
        };

        maxLayers = 125;
      };
    };
}
```

Build and run:

```bash
git add main.go nix/go-package.nix nix/go-container.nix
nix build '.#go-container'
docker load < result

# Stop any previous run, then start fresh
docker rm -f my-go-server 2>/dev/null || true
docker run --rm --name my-go-server -p 8080:8080 my-go-server:latest
```

In another terminal:

```bash
curl http://localhost:8080/
```

> **To stop the container**, press `Ctrl+C`. The `--rm` flag auto-cleans it. If port 8080 is busy, the `docker rm -f` line above handles leftover containers from previous runs.

Check the final image size:

```bash
docker images my-go-server
```

A statically compiled Go binary in a Nix container typically results in an image under **15 MB**.

______________________________________________________________________

## Part 5: When to Use What? (10 min)

### Decision Matrix

| Scenario | Recommendation |
| --- | --- |
| Quick prototyping | Docker with Dockerfile |
| Team already uses Nix | Nix containers |
| Reproducible builds required | Nix containers |
| Minimal attack surface critical | Nix containers |
| CI/CD pipeline already Docker-based | Docker multi-stage |
| Deploying to Kubernetes in production | Nix containers (ideal) |
| Third-party base image required | Docker (can layer Nix on top) |

### The Trade-offs

**Nix containers are better when:**

- You need bit-for-bit reproducibility
- Security auditing requires knowing every byte in the image
- You want the absolute minimal image
- Your team is already investing in Nix

**Docker is better when:**

- The team doesn't know Nix (learning curve)
- You depend on third-party Dockerfiles
- Rapid iteration matters more than reproducibility
- The ecosystem tooling (Docker Compose, etc.) is essential

### The Best of Both Worlds

You can use Nix inside Docker or Docker around Nix:

```dockerfile
# Use Nix to build, Docker to package
FROM nixos/nix:latest AS builder
COPY . /src
WORKDIR /src
RUN nix build

FROM scratch
COPY --from=builder /src/result/bin/my-app /my-app
CMD ["/my-app"]
```

______________________________________________________________________

## Exercises

### Exercise 1: Containerize your TP 1 package

Take the shell script you packaged in TP 1 and build a Nix container image for it. Compare its size with an equivalent Docker image.

### Exercise 2: Explore the closure in depth

Use `nix-tree` to interactively visualize what goes into your container:

```bash
# Interactive dependency tree of your package
nix-tree '.#default'
```

Navigate with arrow keys and Enter. You can see every transitive dependency, its size, and why it was pulled in. This is the best way to understand *why* your container is the size it is.

Then measure it:

```bash
# Show all runtime dependencies with individual and closure sizes
nix path-info -rsSh '.#default'

# Just the total closure size
nix path-info -Sh '.#default'
```

This is what ends up in your container - nothing more, nothing less. If a dependency seems surprising, use `nix why-depends` to trace the dependency chain:

```bash
# Why does my package depend on glibc?
nix why-depends '.#default' 'nixpkgs#glibc'
```

### Exercise 3: Push to a registry

```bash
# Build and push directly (without Docker)
nix build '.#container'
skopeo copy docker-archive:result docker://registry.example.com/my-app:latest
```

`skopeo` can push Nix-built images to any OCI registry without needing a Docker daemon.

### Exercise 4 (Bonus): Streaming image build

For large images, `streamLayeredImage` avoids writing the full image to disk:

```nix
packages.container = pkgs.dockerTools.streamLayeredImage {
  name = "my-app";
  tag = "latest";
  contents = [ config.packages.default ];
  config.Cmd = [ "/bin/my-app" ];
};
```

```bash
nix build '.#container'
./result | docker load
```

______________________________________________________________________

## Summary

| Concept | What you learned |
| --- | --- |
| **Nix container builds** | Building OCI images without Docker using `dockerTools` |
| **Dependency closures** | Nix computes the exact minimal set of runtime dependencies |
| **Closure inspection** | Using `nix-tree` and `nix why-depends` to understand image contents |
| **Reproducibility** | Same inputs = same image hash, every time |
| **Layered images** | `buildLayeredImage` for efficient registry pushes |
| **Security** | Non-root users, minimal attack surface, no unnecessary packages |
| **Build UX** | Using `nom` for fancy builds and `nix run` for instant execution |
| **Trade-offs** | When Nix containers vs Docker makes sense |

### Key Commands Reference

| Command | Purpose |
| --- | --- |
| `nom build '.#container'` | Build the container image with fancy output |
| `nix run` | Build and run the default app in one step |
| `docker load < result` | Load a Nix-built image into Docker |
| `nix-tree '.#default'` | Interactive dependency tree explorer |
| `nix path-info -rsSh '.#default'` | Show the dependency closure with sizes |
| `nix why-depends '.#default' 'nixpkgs#glibc'` | Trace why a dependency is included |
| `skopeo copy docker-archive:result docker://...` | Push without Docker |

### The Big Picture

Across these three TPs, you have followed the complete arc of modern software delivery:

1. **TP 1**: Reproducible builds and development environments with Nix
2. **TP 2**: Container fundamentals and the limits of traditional approaches
3. **TP 3**: Combining Nix + containers for reproducible, minimal, secure deployments

This is the foundation of a professional CI/CD pipeline. The tools change, but the principles remain: **reproducibility, minimality, automation, and security**.
