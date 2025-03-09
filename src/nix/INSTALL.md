# How to install `nix`

This guide will walk you through installing Nix using the Determinate Nix Installer. The installation process is the same for macOS and Linux. However, Windows users must first set up the Windows Subsystem for Linux (WSL) before proceeding.

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

## Installing Nix (macOS, Linux, and WSL)

1. **Open a terminal** (on macOS/Linux or inside WSL on Windows).

1. **Download and run the installer script**:

   ```bash
   curl -L https://install.determinate.systems/nix | sh
   ```

1. **Follow the on-screen instructions**: The script will guide you through the installation. You may need to enter your administrator password.

1. **Enable Flakes and the Nix Command**:

   Edit your Nix configuration file:

   ```bash
   rm -rf ~/.config/nix/nix.conf
   mkdir -p ~/.config/nix
   echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
   ```

1. **Restart your terminal** to apply the necessary configurations.

## Verifying the Installation

To confirm that Nix has been installed correctly, run:

```bash
nix --version
```

If the installation was successful, this will display the installed version of Nix.

You can install programs with:

```bash
# Search
nix search nixpkgs <package>
# Install
nix profile install 'nixpkgs#git'
```

## Additional Resources

- [Nix Official Documentation](https://nixos.org/manual/nix/stable/)
- [Determinate Nix Installer GitHub Repository](https://github.com/DeterminateSystems/nix-installer)
- [Microsoft WSL](https://learn.microsoft.com/fr-fr/windows/wsl/install)

If you encounter any issues or have questions, refer to the official documentation or the GitHub repository for support.
