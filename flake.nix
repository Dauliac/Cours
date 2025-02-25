{
  description = "Cours Open Sources";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    valeMicrosoft = {
      url = "github:errata-ai/Microsoft";
      flake = false;
    };
    valeWriteGood = {
      url = "github:errata-ai/write-good";
      flake = false;
    };
    valeJoblint = {
      url = "github:errata-ai/Joblint";
      flake = false;
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (_: {
      systems = [ "x86_64-linux" ];
      imports = [
        ./nix
      ];
    });
}
