# How to install `nix`

This guide will walk you through installing Nix using the [Lix](https://lix.systems/) installer. The installation process is the same for macOS and Linux. However, Windows users must first set up the Windows Subsystem for Linux (WSL) before proceeding.

## Prerequisites for Windows Users

If you are on Windows, you need to install **WSL (Windows Subsystem for Linux)** before proceeding:

1. **Install WSL**:

   - Open **PowerShell as Administrator** and run:
     ```powershell
     wsl --install
     ```
   - If prompted, restart your computer.

1. **Install a Linux distribution**:

   - After enabling WSL, install a Linux distribution from the **Microsoft Store** (e.g., Ubuntu).

1. **Launch the installed Linux distribution** and proceed with the Nix installation below.

## Installing Lix (macOS, Linux, and WSL)

1. **Open a terminal** (on macOS/Linux or inside WSL on Windows).

1. **Download and run the Lix installer**:

   ```bash
   curl -sSf -L https://install.lix.systems/lix | sh -s -- install
   ```

1. **Follow the on-screen instructions**: The installer will guide you through the process. You may need to enter your administrator password.

1. **Restart your terminal** to load the Nix environment.

## Configuring Nix

Run the following block to write a recommended configuration. The commands are idempotent and safe to re-run:

```bash
mkdir -p ~/.config/nix

cat > ~/.config/nix/nix.conf << 'EOF'
# Enable flakes and the unified CLI
experimental-features = nix-command flakes

# Trust flake.nix nixConfig sections
accept-flake-config = true

# Build from source if a substitute fails instead of erroring
fallback = true

# Use all CPU cores for parallel builds
max-jobs = auto

# Pass all cores to individual builders via NIX_BUILD_CORES
cores = 0

# Deduplicate identical files in /nix/store using hard links
auto-optimise-store = true

# Always fetch from substituters even when derivations set allowSubstitutes=false
always-allow-substitutes = true

# Remote builders pull from caches instead of waiting for uploads
builders-use-substitutes = true

# Prevent GC from collecting build-time deps
keep-outputs = true

# Silence noisy "Git tree is dirty" warnings during dev
warn-dirty = false

# Show more tail on build failure
log-lines = 50

# Faster failure on unreachable substituters (default 300s)
connect-timeout = 10
EOF
```

## Authenticating with GitHub

When many people share the same network (e.g., a classroom), GitHub rate-limits unauthenticated requests and Nix operations will fail. Use [nix-auth](https://github.com/numtide/nix-auth) to authenticate with your own GitHub token.

1. **Install nix-auth**:

   ```bash
   nix profile install 'github:numtide/nix-auth'
   ```

1. **Log in with GitHub**:

   ```bash
   nix-auth login github
   ```

   This opens a browser window where you authorize the application. The token is stored locally and Nix will use it automatically for all GitHub fetches.

1. **Verify it works**:

   ```bash
   nix-auth status
   ```

## Verifying the Installation

To confirm that Nix has been installed correctly, run:

```bash
nix --version
```

If the installation was successful, this will display the installed version of Lix.

You can install programs with:

```bash
# Search
nix search nixpkgs <package>
# Install
nix profile install 'nixpkgs#git'
```

## Additional Resources

- [Lix Official Website](https://lix.systems/)
- [Lix Installation Documentation](https://lix.systems/install/)
- [Nix Official Documentation](https://nixos.org/manual/nix/stable/)
- [Microsoft WSL](https://learn.microsoft.com/fr-fr/windows/wsl/install)

If you encounter any issues or have questions, refer to the official Lix documentation for support.
