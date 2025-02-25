_: {
  config.perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      treefmt = {
        programs = {
          shfmt.enable = true;
          shellcheck.enable = true;
          alejandra.enable = true;
          nixfmt.enable = true;
          yamlfmt.enable = true;
          jsonfmt.enable = true;
          mdformat.enable = true;
          toml-sort.enable = true;
          statix.enable = true;
        };
      };
    };
}
