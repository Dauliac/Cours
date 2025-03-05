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
    {
      system,
      pkgs,
      ...
    }:
    {
      checks = {
        lint =
          pkgs.runCommandLocal "treefmt-check"
            {
              buildInputs = with pkgs; [
                go-task
                vale
              ];
              meta.description = "Run linters using taskfile";
            }
            ''
              set -e
              ${config.documentationShellHookScript}
              task lint --verbose --output prefixed
              touch $out
            '';
      };
    };
}
