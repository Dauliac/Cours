{
  inputs,
  config,
  ...
}:
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
          allowUnfree = true;
        };
      };
    };
}
