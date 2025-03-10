# How to install nix flake template

## Prerequisites

Before installing Comma, ensure that you have **Nix** installed on your system. If you haven't installed Nix yet, follow this guide [How to install `nix`](./INSTALL.md).

## Installing template

```bash
nix flake init -t  'github:Dauliac/Cours'
git add .
direnv allow
nix flake show
```
