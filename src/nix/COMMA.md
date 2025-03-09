# How to install Comma

This guide will walk you through installing and using **Comma**, a lightweight tool that allows you to temporarily run software without permanently installing it, using Nix.

## Prerequisites

Before installing Comma, ensure that you have **Nix** installed on your system. If you haven't installed Nix yet, follow this guide [How to install `nix`](./INSTALL.md).

## Installing Comma

1. **Open a terminal** (on macOS, Linux, or inside WSL on Windows).

1. **Run the following command to install Comma**:

   ```bash
   nix profile install 'nixpkgs#comma'
   ```

1. **Wait for the installation to complete**. Once finished, Comma will be available for use.

## Using Comma

Comma allows you to temporarily run software from Nixpkgs without installing it system-wide. To use it, simply type:

```bash
, <command>
```

For example, to run `htop` without installing it permanently:

```bash
, htop
```

You can search packages using nix cli:

```bash
nix search nixpkgs <package>
nix search nixpkgs katana
<!-- cmdrun nix search nixpkgs katana -->
```

This command will fetch and execute `htop` without modifying your system configuration.

## Verifying the Installation

To check if Comma is installed correctly, run:

```bash
, --help
```

This should display usage information for Comma.

## Additional Resources

- [Comma GitHub Repository](https://github.com/nix-community/comma)
- [Nixpkgs Package Listing](https://search.nixos.org/packages)

If you encounter any issues or have questions, refer to the official GitHub repository or Nix documentation for support.
