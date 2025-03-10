_: {
  config.perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      # INFO: Documentation is here:
      #  https://flake.parts/options/treefmt-nix.html
      treefmt = {
        settings.global.excludes = [
          "./book/**/*"
        ];
        programs = {
          shfmt.enable = true;
          shellcheck.enable = true;
          alejandra.enable = true;
          nixfmt.enable = true;
          yamlfmt.enable = true;
          jsonfmt = {
            enable = true;
            excludes = [
              "./book/**/*"
            ];
          };
          mdformat = {
            enable = true;
            excludes = [
              "./book/**/*"
            ];
          };
          toml-sort.enable = true;
          statix.enable = true;
        };
      };
    };
}
