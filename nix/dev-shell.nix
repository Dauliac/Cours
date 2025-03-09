{
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkOption mdDoc types;
  inherit (inputs.flake-parts.lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption (
    {
      config,
      pkgs,
      ...
    }:
    {
      options = {
        mdbookMermaidStylesPath = mkOption {
          description = mdDoc "The path to the mdbook mermaid style";
          type = types.singleLineStr;
          default = "./.mermaid";
        };
        mdbookMermaidStyles = mkOption {
          description = mdDoc "The mdbook mermaid style assets";
          type = types.package;
          default = pkgs.stdenv.mkDerivation {
            name = "mdbook-mermaid-styles";
            src = ../book.toml;
            dontUnpack = true;
            buildPhase = ''
              ln -sf $src book.toml
              ${pkgs.mdbook-mermaid}/bin/mdbook-mermaid install
              mkdir -p $out
              mv mermaid-init.js mermaid.min.js $out
            '';
          };
        };
        documentationShellHookScript = mkOption {
          description = mdDoc "The shell hook to run in devShell";
          default = ''
            export FLAKE_ROOT="$(git rev-parse --show-toplevel)"
            mkdir -p \
              "$FLAKE_ROOT/${config.valeStylesPath}/Microsoft" \
              "$FLAKE_ROOT/${config.valeStylesPath}/Joblint" \
              "$FLAKE_ROOT/${config.valeStylesPath}/write-good" \
              "$FLAKE_ROOT/${config.mdbookMermaidStylesPath}"
            rm -rf \
              "$FLAKE_ROOT/${config.valeStylesPath}/Microsoft" \
              "$FLAKE_ROOT/${config.valeStylesPath}/Joblint" \
              "$FLAKE_ROOT/${config.valeStylesPath}/write-good" \
              "$FLAKE_ROOT/${config.mdbookMermaidStylesPath}" \
              "$FLAKE_ROOT/.vale.ini"
            ln -s ${config.valeMicrosoft} "$FLAKE_ROOT/${config.valeStylesPath}/Microsoft"
            ln -s ${config.valeJoblint} "$FLAKE_ROOT/${config.valeStylesPath}/Joblint"
            ln -s ${config.valeWriteGood} "$FLAKE_ROOT/${config.valeStylesPath}/write-good"
            ln -s ${config.valeConfiguration} "$FLAKE_ROOT/.vale.ini"
            ln -s ${config.mdbookMermaidStyles} "$FLAKE_ROOT/${config.mdbookMermaidStylesPath}"
          '';
        };
      };
    }
  );
  config.perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs =
          with pkgs;
          [
            go-task
            lefthook
            vhs
            aichat
            mdzk
          ]
          ++ config.docsPackages;
        shellHook = ''
          ${config.documentationShellHookScript}
        '';
      };
    };
}
