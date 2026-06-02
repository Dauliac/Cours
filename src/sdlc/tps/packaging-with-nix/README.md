# TP 1: Packaging with Nix

## Learning Objectives

By the end of this practical, you will be able to:

1. **Understand** what Nix is and why reproducible builds matter
2. **Set up** a Nix flake project from scratch using the course template
3. **Use** a reproducible development environment with `devShells`
4. **Package** a simple application with Nix
5. **Inspect** derivations, dependency trees, and closures to understand Nix artefacts
6. **Use** the Nix REPL to interactively explore packages and flake outputs
7. **Explain** the difference between imperative and declarative package management

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
./nix/default.nix    # Auto-imports all .nix files in nix/
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
# Track all generated files (Nix flakes ONLY see git-tracked files!)
git add .

# Enter the development shell
nix develop
```

> **Why `git add`?** Nix flakes use git to determine which files exist. If a file is not tracked by git, Nix cannot see it. This is a common source of "file not found" errors. **Always `git add` new files before running any `nix` command.**

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

### Step 5b: Discover the build tools

Your dev shell includes two tools that make working with Nix much more pleasant:

**`nom` (nix-output-monitor)**: Replaces the default Nix build output with a rich, real-time view showing what's being built, downloaded, and how much is left:

```bash
# Instead of plain "nix build":
nom build
```

You will see a live progress bar with active builds, downloads, and store paths. This is especially useful when building for the first time (many dependencies to fetch).

**`nix-tree`**: An interactive terminal tool to explore the dependency tree of any Nix package:

```bash
# Explore the dev shell's dependencies interactively
nix-tree .#devShells.x86_64-linux.default
```

Navigate with arrow keys, press Enter to expand nodes. This shows you exactly what Nix pulled in and why.

Try both now. You will use them throughout the TPs.

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

```bash
git add hello.sh
```

### Step 9: Create the Nix package definition

Create a file `nix/package.nix`:

```nix
{ pkgs, ... }:
{
  config.perSystem =
    { pkgs, config, ... }:
    {
      packages.default = pkgs.writeShellApplication {
        name = "hello-nix";
        runtimeInputs = with pkgs; [ coreutils ];
        text = builtins.readFile ../hello.sh;
      };

      # Expose the package as a runnable app
      apps.default = {
        type = "app";
        program = "${config.packages.default}/bin/hello-nix";
      };
    };
}
```

**Line by line:**

- `pkgs.writeShellApplication` is a Nix helper that creates a proper shell script package
- `name` is the name of the resulting binary
- `runtimeInputs` are the dependencies available at runtime
- `text` reads our script file
- `apps.default` exposes the package so you can run it directly with `nix run`

> **Remember**: after creating any new `.nix` file, always `git add` it immediately. Nix flakes ignore untracked files.

### Step 10: Track the new file with git

> **Critical rule**: Nix flakes can only see files tracked by git. Every time you create a new `.nix` file, you **must** run `git add` on it before Nix can use it.

```bash
git add nix/package.nix
```

You do **not** need to edit `nix/default.nix`. The template uses auto-import: any `.nix` file you add to the `nix/` directory is automatically picked up, as long as git tracks it.

Open `nix/default.nix` to see how it works:

```nix
# Auto-import all .nix files in this directory (except default.nix itself).
# Just create a new .nix file, run `git add` on it, and it will be picked up automatically.
nixFiles = builtins.filter (name: name != "default.nix") (
  builtins.filter (name: builtins.match ".*\\.nix" name != null) (
    builtins.attrNames (builtins.readDir ./.)
  )
);
```

This reads all `.nix` files in the directory and imports them. No manual registration needed.

### Step 11: Build and run your package

```bash
# Build the package with fancy output
nom build

# The result is a symlink called "result"
ls -la result/

# Run it directly from the build output
./result/bin/hello-nix

# Or run it with nix run (builds + runs in one step)
nix run
```

`nix run` builds the default app and executes it in one command - no need to find the binary yourself. You should see the greeting message. Congratulations, you just built your first Nix package.

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

## Part 5: Understanding Derivations and Dependencies (20 min)

Now that you have a working package, let's look *inside* it. Nix gives you powerful tools to inspect exactly what was built, how, and why.

### Step 13: Inspect the derivation

A **derivation** is the low-level build recipe Nix actually executes. Every `nix build` produces one. Let's look at yours:

```bash
nix show-derivation .#default
```

This outputs JSON describing the exact build plan: the builder, arguments, environment variables, input sources, and input derivations. Notice:

- `"builder"`: the program that runs the build (usually bash)
- `"inputDrvs"`: other derivations this one depends on (coreutils, bash, etc.)
- `"env"`: the environment variables set during the build
- `"outputs"`: where the result will be stored

Every field is deterministic. Change any input, and the output hash changes.

### Step 14: Visualize the dependency tree

Use `nix-tree` to interactively explore what your package depends on:

```bash
nix-tree .#default
```

Navigate with arrow keys and Enter. You will see your package at the top, with its full dependency tree below. Each node shows:

- The store path and its size
- The closure size (total size including all transitive dependencies)

This is the **closure** - the complete set of everything needed to run your package. Nothing more, nothing less.

### Step 15: Measure the closure

```bash
# Show all runtime dependencies with sizes
nix path-info -rsSh .#default
```

This lists every store path in the closure with:

- **NAR size** (`-s`): the size of the path itself
- **Closure size** (`-S`): total size including dependencies
- Human-readable (`-h`)

```bash
# Just the total closure size
nix path-info -Sh .#default
```

For a simple shell script, you should see a closure of around 30-40 MB (mostly coreutils and bash).

### Step 16: Explore with the Nix REPL

The Nix REPL lets you inspect and evaluate Nix expressions interactively. This is the most powerful debugging tool in the Nix ecosystem:

```bash
nix repl
```

Inside the REPL, load your flake:

```
:lf .
```

Now explore:

```
# See all outputs
outputs

# Inspect your package
outputs.packages.x86_64-linux.default

# See its name
outputs.packages.x86_64-linux.default.name

# See its derivation path
outputs.packages.x86_64-linux.default.drvPath

# List attributes of nixpkgs
builtins.attrNames inputs.nixpkgs.legacyPackages.x86_64-linux

# Check a package version
inputs.nixpkgs.legacyPackages.x86_64-linux.python3.version

# Exit
:q
```

The REPL is invaluable for debugging flakes, understanding how packages are composed, and exploring nixpkgs.

### Step 17: Build and run with style

Use `nom` (nix-output-monitor) for a much better build experience:

```bash
# Build with live progress display
nom build

# Build and run in one step
nix run

# Or use the task runner
task build
task run
```

`nom` replaces the default Nix output with a rich, real-time view showing active builds, downloads, and store paths. The `task run` command builds and runs the default app in one step.

### Check Your Understanding

- What is the difference between a derivation and a package?
- How can you find out why a dependency is in your closure?
- What does `:lf .` do in the Nix REPL?

______________________________________________________________________

## Part 6: Code Quality Automation (20 min)

### Step 18: Use the formatter

The template includes `treefmt` for automatic code formatting:

```bash
# Format all code in the project
nix fmt
```

This runs all configured formatters (see `nix/treefmt.nix`): shell formatting, Nix formatting, YAML formatting, and more. All at once, all reproducible.

### Step 19: Use the task runner

The template already includes a `Taskfile.yaml` with useful tasks. List them:

```bash
task --list
```

You should see tasks like `build`, `run`, `test`, `tree`, `closure`, `fmt`, and `check`. Try them:

```bash
# Build with nom (fancy output)
task build

# Build and run the default app in one step
task run

# Show the dependency tree interactively
task tree

# Show closure sizes
task closure

# Format all code
task fmt

# Run all checks (format + build + test)
task check
```

You can customize `Taskfile.yaml` to add your own tasks. For example, add a test that verifies your package output:

```yaml
  test:
    deps:
      - build
    desc: Test the package runs correctly
    cmds:
      - ./result/bin/hello-nix | grep "Hello"
```

### Step 20: Understand git hooks with lefthook

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

## Part 7: Going Further (Bonus)

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
| **Auto-import** | New `.nix` files are picked up automatically (just `git add`) |
| **Packaging** | Built a shell script into a Nix package |
| **Derivations** | Inspected build recipes with `nix show-derivation` |
| **Dependency analysis** | Explored closures with `nix-tree` and `nix path-info` |
| **Nix REPL** | Interactively explored flake outputs and nixpkgs |
| **Build UX** | Used `nom` for fancy builds and `nix run` for instant execution |
| **Code quality** | Used formatters, linters, and git hooks |
| **Task automation** | Used pre-built tasks with `task` |

### Key Commands Reference

| Command | Purpose |
| --- | --- |
| `nix flake init -t <template>` | Initialize a project from a template |
| `nix develop` | Enter the development shell |
| `nom build` | Build the default package with fancy output |
| `nix run` | Build and run the default app in one step |
| `nix fmt` | Format all code |
| `nix flake show` | Show all flake outputs |
| `nix search nixpkgs <name>` | Search for packages |
| `nix show-derivation .#default` | Inspect the build recipe (derivation) |
| `nix-tree .#default` | Interactive dependency tree explorer |
| `nix path-info -rsSh .#default` | Show closure size and dependencies |
| `nix repl` then `:lf .` | Interactive Nix expression explorer |

### What's Next?

In the next TP, you will learn how to build **container images** and understand why reproducibility matters even more in that context.
