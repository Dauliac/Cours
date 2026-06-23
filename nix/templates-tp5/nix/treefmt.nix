_: {
  config.perSystem =
    { ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          yamlfmt.enable = true;
        };
      };
    };
}
