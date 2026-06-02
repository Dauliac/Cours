# TP 2: Building Containers - The Traditional Way

## Learning Objectives

By the end of this practical, you will be able to:

1. **Explain** what a container is and how it differs from a virtual machine
2. **Write** a Dockerfile following best practices
3. **Build** optimized container images using multi-stage builds
4. **Analyze** image size, layers, and security implications
5. **Identify** the limitations of traditional container builds

## Prerequisites

- Completed [TP 1: Packaging with Nix](../packaging-with-nix/README.md)
- Docker installed (see below)
- Basic understanding of Linux command line

______________________________________________________________________

## Installing Docker

### Linux

Install Docker Engine using the official convenience script:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add your user to the docker group (avoids needing sudo for every command)
sudo usermod -aG docker "$USER"

# Apply the new group (or log out and back in)
newgrp docker

# Verify the installation
docker run hello-world
```

### macOS

Docker Desktop is the recommended way to run Docker on macOS:

1. Download **Docker Desktop** from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. Open the `.dmg` file and drag Docker to your Applications folder
3. Launch Docker Desktop from Applications
4. Wait for the Docker engine to start (the whale icon in the menu bar stops animating)

Alternatively, using [Homebrew](https://brew.sh/):

```bash
brew install --cask docker
# Then launch Docker Desktop from Applications
```

Verify the installation:

```bash
docker run hello-world
```

### Windows (WSL 2)

Docker Desktop integrates with WSL 2 to run Linux containers on Windows:

1. **Enable WSL 2** if not already done:

   ```powershell
   # In PowerShell as Administrator
   wsl --install
   ```

   Restart your machine if prompted.

2. **Install Docker Desktop** from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)

3. During installation, ensure **"Use WSL 2 instead of Hyper-V"** is checked

4. Open Docker Desktop → Settings → Resources → WSL Integration → Enable integration with your Linux distribution

5. Open your WSL terminal and verify:

   ```bash
   docker run hello-world
   ```

> **Note**: All the commands in this TP should be run inside your WSL terminal, not in PowerShell or CMD.

### Alternative: Install via Nix

If you already have Nix installed from TP 1:

```bash
nix profile install nixpkgs#docker
```

> This installs the Docker CLI only. On Linux, you still need the Docker daemon running (`sudo systemctl start docker`). On macOS/WSL, you still need Docker Desktop.

______________________________________________________________________

## Part 1: What Is a Container? (15 min)

### From Physical Machines to Containers

The history of isolation in computing follows a clear trend toward lighter abstraction:

```
Physical Machine → Virtual Machine → Container → Function/Lambda
   (heavy)           (medium)         (light)       (lightest)
```

### Container vs Virtual Machine

| Aspect | Virtual Machine | Container |
| --- | --- | --- |
| Isolation | Full OS with its own kernel | Shares the host kernel |
| Startup time | Minutes | Milliseconds |
| Size | Gigabytes | Megabytes |
| Overhead | High (full OS) | Low (just the process) |
| Security | Strong isolation | Weaker isolation (shared kernel) |

### How Containers Work (Under the Hood)

Containers are not magic. They are built on three Linux kernel features:

1. **Namespaces**: Isolate what a process can *see*
   - PID namespace: the container sees its own process tree
   - Network namespace: the container has its own network stack
   - Mount namespace: the container has its own filesystem

2. **Cgroups** (Control Groups): Limit what a process can *use*
   - CPU limits
   - Memory limits
   - I/O limits

3. **Union Filesystems** (OverlayFS): Layer images efficiently
   - Each instruction in a Dockerfile creates a new layer
   - Layers are shared between images
   - Only the top layer is writable

### The OCI Standard

Containers follow the **Open Container Initiative (OCI)** specification. This means images built by Docker work with Podman, containerd, and Kubernetes. The standard defines:

- **Image format**: How layers and metadata are stored
- **Runtime spec**: How containers are executed
- **Distribution spec**: How images are pushed/pulled from registries

### Check Your Understanding

- What kernel feature prevents a container from seeing host processes?
- Why are containers faster to start than VMs?
- Can you run a Windows container on a Linux host? Why or why not?

______________________________________________________________________

## Part 2: Your First Dockerfile (20 min)

### Step 1: Create a simple application

Let's start with a minimal Python web server. Create a project directory:

```bash
mkdir -p container-tp
cd container-tp
git init  # Safe to run multiple times
```

Create `app.py`:

```python
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        response = {
            "message": "Hello from my container!",
            "hostname": os.uname().nodename,
            "path": self.path
        }
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())

server = HTTPServer(("0.0.0.0", 8080), Handler)
print("Server running on port 8080...")
server.serve_forever()
```

### Step 2: Write a naive Dockerfile

Create a `Dockerfile`:

```dockerfile
FROM python:3.12

WORKDIR /app
COPY app.py .

CMD ["python", "app.py"]
```

### Step 3: Build and run

```bash
docker build -t my-app:v1 .

# Stop any previous run of this container, then start fresh
docker rm -f my-app-v1 2>/dev/null || true
docker run --rm --name my-app-v1 -p 8080:8080 my-app:v1
```

In another terminal:

```bash
curl http://localhost:8080/
```

> **To stop the container**, press `Ctrl+C` in the terminal where it runs. The `--rm` flag ensures it is automatically cleaned up.

You should see a JSON response. It works. But is it good?

### Step 4: Analyze the image

```bash
docker images my-app:v1
```

Note the image size. It is likely **over 1 GB**. For a 20-line Python script. Why?

```bash
docker history my-app:v1
```

The base image `python:3.12` includes:

- A full Debian operating system
- Build tools (gcc, make, etc.)
- Hundreds of system packages you don't need
- The full Python installation

### The Problem

This image has:

- **Unnecessary attack surface**: hundreds of binaries an attacker could exploit
- **Wasted bandwidth**: pushing/pulling 1 GB for every deploy
- **Slow startup**: loading unnecessary layers
- **No reproducibility**: `python:3.12` changes over time (it's a moving tag)

______________________________________________________________________

## Part 3: Making It Better - Multi-Stage Builds (25 min)

### Step 5: Use a slim base image

Replace your Dockerfile:

```dockerfile
FROM python:3.12-slim

WORKDIR /app
COPY app.py .

EXPOSE 8080
CMD ["python", "app.py"]
```

```bash
docker build -t my-app:v2 .
docker images my-app  # Compare v1 and v2 sizes
```

Compare sizes. `slim` removes build tools and documentation, typically cutting the image by 60-70%.

### Step 6: Use a multi-stage build

For compiled languages, multi-stage builds are essential. Let's demonstrate with a Go example.

Create `main.go`:

```go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "os"
)

func handler(w http.ResponseWriter, r *http.Request) {
    hostname, _ := os.Hostname()
    response := map[string]string{
        "message":  "Hello from Go container!",
        "hostname": hostname,
        "path":     r.URL.Path,
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func main() {
    http.HandleFunc("/", handler)
    fmt.Println("Server running on port 8080...")
    http.ListenAndServe(":8080", nil)
}
```

Create `go.mod`:

```
module container-tp

go 1.22
```

Now create a multi-stage Dockerfile for Go, `Dockerfile.go`:

```dockerfile
# Stage 1: Build
FROM golang:1.22 AS builder

WORKDIR /app
COPY go.mod .
COPY main.go .

RUN CGO_ENABLED=0 GOOS=linux go build -o server .

# Stage 2: Run
FROM scratch

COPY --from=builder /app/server /server

EXPOSE 8080
CMD ["/server"]
```

```bash
docker build -f Dockerfile.go -t my-app:v3-go .
docker images my-app
```

**`scratch`** is a completely empty image. The resulting image contains *only* your binary. Typically under 10 MB.

### Understanding Multi-Stage Builds

```
┌─────────────────────────┐
│  Stage 1: "builder"     │
│  - Full Go toolchain    │  ← Thrown away
│  - Source code           │
│  - Compiled binary      │──────┐
└─────────────────────────┘      │
                                  │ COPY --from=builder
┌─────────────────────────┐      │
│  Stage 2: final image   │ ←────┘
│  - Only the binary      │
│  - Nothing else          │
└─────────────────────────┘
```

The build tools stay in the builder stage. Only the artifact moves to the final image.

______________________________________________________________________

## Part 4: Security Best Practices (20 min)

### Step 7: Don't run as root

By default, containers run as `root`. This is dangerous. If an attacker escapes the container, they have root on the host.

```dockerfile
FROM python:3.12-slim

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app
COPY app.py .

# Switch to non-root user
USER appuser

EXPOSE 8080
CMD ["python", "app.py"]
```

### Step 8: Scan for vulnerabilities

```bash
# Install trivy if not available (safe to run multiple times)
command -v trivy >/dev/null || nix profile install 'nixpkgs#trivy'

trivy image my-app:v1
trivy image my-app:v2
```

Compare the CVE counts. The slim image has significantly fewer vulnerabilities because it has fewer packages.

### Step 9: Use pinned digests instead of tags

Tags are mutable. `python:3.12-slim` today is different from `python:3.12-slim` six months ago.

```dockerfile
# Bad: tag can change
FROM python:3.12-slim

# Good: pinned to exact image
FROM python:3.12-slim@sha256:abc123...
```

To get the digest:

```bash
# Pull the image first if you haven't already
docker pull python:3.12-slim 2>/dev/null || true
docker inspect --format='{{index .RepoDigests 0}}' python:3.12-slim
```

### Security Checklist

| Practice | Why |
| --- | --- |
| Use minimal base images | Fewer packages = fewer vulnerabilities |
| Run as non-root | Limit damage if container is compromised |
| Pin image digests | Prevent supply chain attacks |
| Don't store secrets in images | Secrets in layers are visible with `docker history` |
| Use `.dockerignore` | Prevent leaking source code, `.git`, `.env` files |
| Scan images regularly | Catch known CVEs before deployment |

______________________________________________________________________

## Part 5: The Remaining Problems (10 min)

### What Docker Doesn't Solve

Even with all best practices, Docker has fundamental limitations:

**1. Non-reproducible builds**

```dockerfile
RUN apt-get update && apt-get install -y curl
```

This installs *whatever version of curl is in the repo today*. Build the same Dockerfile in 6 months, and you get different packages. Your `flake.lock` from TP 1 solves this for Nix; Docker has no equivalent.

**2. Layer ordering matters**

```dockerfile
# Bad: changing app.py invalidates the COPY layer AND all subsequent layers
COPY . .
RUN pip install -r requirements.txt

# Better: install deps first, copy code second
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
```

Layer caching is fragile and depends on instruction order, not content hashing.

**3. The "minimal image" problem**

To build a truly minimal image, you need to know the exact runtime dependencies of your binary. Miss one shared library and the container crashes. Include too many and you bloat the image.

There is no systematic way to determine the minimal closure of dependencies in Docker.

**4. Build environment leaks**

Even with multi-stage builds, the build environment (network access, timestamps, environment variables) can leak non-determinism into the output.

### Reflection

Think about these questions:

- If you build the same Dockerfile on two different machines, will you get the same image hash?
- How do you know your `slim` image doesn't contain unnecessary packages?
- Is there a way to build a container image without Docker at all?

The answer to the last question is **yes** - and that's what TP 3 is about.

______________________________________________________________________

## Exercises

### Exercise 1: Size comparison table

Build images using different base images and fill in this table:

| Base Image | Size | CVE Count (trivy) | Contains Shell? |
| --- | --- | --- | --- |
| `python:3.12` | ? | ? | ? |
| `python:3.12-slim` | ? | ? | ? |
| `python:3.12-alpine` | ? | ? | ? |
| `gcr.io/distroless/python3` | ? | ? | ? |

### Exercise 2: Multi-stage for your TP1 project

Take the Nix package you built in TP 1 and try to containerize it using a traditional multi-stage Dockerfile. Note the difficulties you encounter.

### Exercise 3: `.dockerignore`

Create a `.dockerignore` file for your project. Build the image with and without it and compare the build context size.

______________________________________________________________________

## Summary

| What you learned | Key takeaway |
| --- | --- |
| Container fundamentals | Namespaces, cgroups, and overlay filesystems |
| Dockerfile best practices | Slim images, multi-stage builds, layer ordering |
| Security hardening | Non-root users, pinned digests, vulnerability scanning |
| Docker limitations | Non-reproducible, no systematic minimality, layer ordering fragility |

### Key Commands Reference

| Command | Purpose |
| --- | --- |
| `docker build -t name:tag .` | Build an image |
| `docker run --rm -p 8080:8080 name:tag` | Run a container (auto-cleanup) |
| `docker images` | List images |
| `docker history <image>` | Show image layers |
| `trivy image <image>` | Scan for vulnerabilities |

### What's Next?

In TP 3, you will discover how **Nix can build container images** that are reproducible, minimal, and secure by design - without even needing Docker to build them.
