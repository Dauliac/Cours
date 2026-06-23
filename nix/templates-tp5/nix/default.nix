{ inputs, ... }:
let
  nixFiles = builtins.filter (name: name != "default.nix") (
    builtins.filter (name: builtins.match ".*\\.nix" name != null) (
      builtins.attrNames (builtins.readDir ./.)
    )
  );
  localImports = map (name: ./${name}) nixFiles;
in
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ] ++ localImports;
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
