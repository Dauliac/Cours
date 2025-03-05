{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    ./dev-shell.nix
    ./treefmt.nix
    ./vale.nix
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
