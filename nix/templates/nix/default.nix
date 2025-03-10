{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    ./dev-shell.nix
    ./treefmt.nix
  ];
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          # NOTE: This config  allow to install non free packages.
          allowUnfree = true;
        };
      };
    };
}
