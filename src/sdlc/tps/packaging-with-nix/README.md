# TP 1: Packaging with Nix

## Learning Objectives

By the end of this practical, you will be able to:

1. **Understand** what Nix is and why reproducible builds matter
2. **Set up** a Nix flake project from scratch using the course template
3. **Use** a reproducible development environment with `devShells`
4. **Package** a simple application with Nix
5. **Explain** the difference between imperative and declarative package management

## Prerequisites

- [Nix is installed](../../../nix/INSTALL.md)
- [Comma is installed](../../../nix/COMMA.md)
- Basic command-line skills (cd, ls, cat, git)
- A text editor you are comfortable with

______________________________________________________________________

## Part 1: Why Nix? (15 min)

### The Problem

Imagine this situation: you join a new team. You clone the project, run `npm install`, and...
it fails. A colleague says *"it works on my machine"*. You spend 2 hours debugging.

**This is the problem Nix solves.**

### Traditional package management vs Nix

| Aspect | Traditional (apt, brew, npm) | Nix |
| --- | --- | --- |
| Install location | Global (`/usr/bin`, `/usr/lib`) | Isolated (`/nix/store/...`) |
| Reproducibility | "It works on my machine" | Same input = same output, always |
| Rollback | Difficult or impossible | Built-in, instant |
| Multiple versions | Conflicts | No conflicts, all coexist |
| Dependency tracking | Partial | Complete dependency graph |

### Key Concepts

**Derivation**: A Nix derivation is a *recipe* that describes how to build something. It specifies:

- The source code
- The build dependencies
- The build commands
- The expected output

Think of it like a cooking recipe: given the same ingredients and the same steps, you always get the same dish.

**The Nix Store**: Every package built by Nix lives in `/nix/store/` with a unique hash in its path:

```
/nix/store/abc123...-python-3.11.5/
/nix/store/def456...-python-3.12.1/
```

Both versions coexist without conflict. The hash ensures that if any input changes, the path changes too.

**Flake**: A `flake.nix` file is the modern entry point for a Nix project. It declares:

- **inputs**: where dependencies come from (e.g., nixpkgs)
- **outputs**: what the project provides (packages, dev shells, etc.)

### Check Your Understanding

Before moving on, make sure you can answer:

- Why can two versions of Python coexist in the Nix store?
- What happens to the store path if you change a build dependency?

______________________________________________________________________

## Part 2: Setting Up Your Project (20 min)

### Step 1: Initialize the project

Create a new directory and initialize it with the course template:

```bash
mkdir -p my-first-nix-project
cd my-first-nix-project
git init  # Safe to run multiple times
nix flake init -t 'github:Dauliac/Cours'  # Skip this if flake.nix already exists
```

> **If `nix flake init` fails** with "file already exists", it means you already ran this step. You can safely move on.

### Step 2: Explore what was generated

List the files:

```bash
find . -type f
```

You should see:

```
./flake.nix          # The project's entry point
./nix/default.nix    # Imports all nix modules
./nix/dev-shell.nix  # Development environment definition
./nix/treefmt.nix    # Code formatting configuration
./Taskfile.yaml      # Task runner (like Make, but better)
./.envrc             # Direnv integration (auto-loads the environment)
./lefthook.yaml      # Git hooks configuration
```

### Step 3: Understand the flake structure

Open `flake.nix` and read it carefully:

```bash
cat flake.nix
```

```nix
{
  description = "Changeme";            # <- Describe your project here
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";  # <- Package repository
    flake-parts.url = "github:hercules-ci/flake-parts";  # <- Flake helper
    treefmt-nix.url = "github:numtide/treefmt-nix";      # <- Code formatter
  };
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (_: {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      imports = [ ./nix ];  # <- All Nix configuration lives in ./nix/
    });
}
```

**Key takeaway**: `inputs` declares *where* things come from. `outputs` declares *what* the project provides. The `./nix/` directory contains the actual definitions.

### Step 4: Enter the development environment

```bash
# Track all generated files (Nix flakes require this)
git add .

# Enter the development shell
nix develop
```

You are now inside a reproducible shell. Every tool listed in `nix/dev-shell.nix` is available, regardless of what is installed on your system.

Try it:

```bash
# These tools are available even if you never installed them:
task --version
vale --version
convco --version
```

### Step 5: Understand the dev shell

Open `nix/dev-shell.nix`:

```nix
devShells.default = pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    go-task       # Task runner
    lefthook      # Git hooks
    vale          # Documentation linter
    trufflehog    # Secret scanner
    convco        # Conventional commits
    sops          # Secret management
  ];
  shellHook = ''
    lefthook install --force
  '';
};
```

**`nativeBuildInputs`** lists the tools available in the shell. **`shellHook`** runs commands when you enter the shell (here: installing git hooks).

### Checkpoint

Run these commands and verify they work:

```bash
nix develop
task --list
nix flake show
```

`nix flake show` displays all the outputs of your project. You should see your `devShell` listed.

______________________________________________________________________

## Part 3: Adding Dependencies (15 min)

### Step 6: Add a tool to your dev shell

Let's say your project needs `jq` (a JSON processor) and `curl`. Edit `nix/dev-shell.nix`:

```nix
nativeBuildInputs = with pkgs; [
  go-task
  lefthook
  vale
  trufflehog
  convco
  sops
  jq       # <- Add this
  curl     # <- Add this
];
```

Now reload the shell:

```bash
# If you are inside a nix develop session, leave it first:
# Press Ctrl+D or type 'exit'
# Then re-enter:
nix develop
jq --version   # Verify jq is available
curl --version # Verify curl is available
```

### How to find packages

Search for packages in nixpkgs:

```bash
# From the command line
nix search nixpkgs python

# Or use the web interface: https://search.nixos.org/packages
```

### Step 7: Try with direnv (optional but recommended)

If you have `direnv` installed, the `.envrc` file will automatically load your dev shell whenever you `cd` into the project:

```bash
direnv allow
cd ..
cd my-first-nix-project  # Shell loads automatically
```

No more `nix develop` needed. The environment loads and unloads as you navigate.

______________________________________________________________________

## Part 4: Packaging a Simple Application (30 min)

### Step 8: Write a small program

Create a simple shell script that we will package with Nix.

Create a file `hello.sh`:

```bash
#!/usr/bin/env bash
echo "Hello from my first Nix package!"
echo "Current date: $(date)"
echo "Built with Nix - reproducible by design."
```

### Step 9: Create the Nix package definition

Create a file `nix/package.nix`:

```nix
{ pkgs, ... }:
{
  config.perSystem =
    { pkgs, ... }:
    {
      packages.default = pkgs.writeShellApplication {
        name = "hello-nix";
        runtimeInputs = with pkgs; [ coreutils ];
        text = builtins.readFile ../hello.sh;
      };
    };
}
```

**Line by line:**

- `pkgs.writeShellApplication` is a Nix helper that creates a proper shell script package
- `name` is the name of the resulting binary
- `runtimeInputs` are the dependencies available at runtime
- `text` reads our script file

### Step 10: Register the package

Edit `nix/default.nix` to import the new package module:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    ./dev-shell.nix
    ./treefmt.nix
    ./package.nix    # <- Add this line
  ];
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    };
}
```

### Step 11: Build and run your package

```bash
git add .

# Build the package
nix build

# The result is a symlink called "result"
ls -la result/

# Run it
./result/bin/hello-nix
```

You should see the greeting message. Congratulations, you just built your first Nix package.

### Step 12: Explore the build output

```bash
# See what's in the result
tree result/ 2>/dev/null || find result/ -type f

# See the actual store path
readlink result
```

Notice the `/nix/store/HASH-hello-nix` path. This is your package in the Nix store. The hash is derived from **all** inputs. If you change the script, the hash changes.

### Checkpoint

Verify your understanding by answering:

- What command builds a Nix flake's default package?
- Where does the build output live?
- What would happen if you changed the script text?

______________________________________________________________________

## Part 5: Code Quality Automation (20 min)

### Step 13: Use the formatter

The template includes `treefmt` for automatic code formatting:

```bash
# Format all code in the project
nix fmt
```

This runs all configured formatters (see `nix/treefmt.nix`): shell formatting, Nix formatting, YAML formatting, and more. All at once, all reproducible.

### Step 14: Use the task runner

Open `Taskfile.yaml` and define real tasks:

```yaml
version: '3'
tasks:
  build:
    desc: Build the Nix package
    cmds:
      - nix build
  test:
    deps:
      - build
    desc: Test the package runs correctly
    cmds:
      - ./result/bin/hello-nix | grep "Hello"
  fmt:
    desc: Format all code
    cmds:
      - nix fmt
  check:
    desc: Run all checks
    cmds:
      - task: fmt
      - task: build
      - task: test
  default:
    cmds:
      - task -l
```

Now run:

```bash
task check
```

This formats, builds, and tests in one command. This is the foundation of a CI/CD pipeline.

### Step 15: Understand git hooks with lefthook

The `lefthook.yaml` file ensures code is formatted before every commit:

```yaml
pre-commit:
  commands:
    fmt:
      tags: formatter
      run: nix fmt
      stage_fixed: true
```

This means: every time you `git commit`, Nix automatically formats your code. If formatting changes files, they are re-staged. No more "forgot to format" in code reviews.

______________________________________________________________________

## Part 6: Going Further (Bonus)

These exercises are optional, for students who finish early or want to dig deeper.

### Challenge 1: Package a real program

Instead of a shell script, try packaging a simple Python or Go program:

```nix
# Example: a Python script
packages.default = pkgs.writers.writePython3Bin "my-tool" {
  libraries = with pkgs.python3Packages; [ requests ];
} ''
  import requests
  r = requests.get("https://httpbin.org/ip")
  print(f"Your IP: {r.json()['origin']}")
'';
```

### Challenge 2: Add a second package

Create a `packages.other` in addition to `packages.default`:

```bash
# Build a specific package
nix build .#other
```

### Challenge 3: Pin a specific nixpkgs version

Change the `nixpkgs` input in `flake.nix` to a specific commit and observe how `flake.lock` changes:

```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
```

```bash
nix flake update
git diff flake.lock
```

______________________________________________________________________

## Summary

In this practical, you learned:

| Concept | What you did |
| --- | --- |
| **Nix flakes** | Initialized a project with `nix flake init` |
| **Dev shells** | Created a reproducible development environment |
| **Package management** | Added/removed tools declaratively |
| **Packaging** | Built a shell script into a Nix package |
| **Code quality** | Used formatters, linters, and git hooks |
| **Task automation** | Defined build/test/format tasks |

### Key Commands Reference

| Command | Purpose |
| --- | --- |
| `nix flake init -t <template>` | Initialize a project from a template |
| `nix develop` | Enter the development shell |
| `nix build` | Build the default package |
| `nix fmt` | Format all code |
| `nix flake show` | Show all flake outputs |
| `nix search nixpkgs <name>` | Search for packages |

### What's Next?

In the next TP, you will learn how to build **container images** and understand why reproducibility matters even more in that context.
