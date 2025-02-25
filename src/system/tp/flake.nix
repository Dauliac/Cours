# SPDX-License-Identifier: AGPL-3.0-or-later
{
  description = "Open source system tp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        tpPackages = [
          pkgs.go-task
          pkgs.podman
          pkgs.rustfmt
          pkgs.trivy
          pkgs.hadolint
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.dapr-cli
            pkgs.stdenv
            pkgs.go
            pkgs.glibc.static
          ] ++ tpPackages;
        };
      }
    );
}
