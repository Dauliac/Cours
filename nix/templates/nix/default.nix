{ inputs, ... }:
let
  # Auto-import all .nix files in this directory (except default.nix itself).
  # Just create a new .nix file, run `git add` on it, and it will be picked up automatically.
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
          # NOTE: This config allows installing non-free packages.
          allowUnfree = true;
        };
      };
    };
}
