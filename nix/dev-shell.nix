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
        valeStylesPath = mkOption {
          description = mdDoc "The path to the vale style";
          type = types.singleLineStr;
          default = "./.vale/styles";
        };
        mdbookMermaidStylesPath = mkOption {
          description = mdDoc "The path to the mdbook mermaid style";
          type = types.singleLineStr;
          default = "./.mermaid";
        };
        valeMicrosoft = mkOption {
          description = mdDoc "The vale Microsoft style";
          type = types.package;

          default = pkgs.runCommand "vale-microsoft-links" { } ''
            ln -sf ${inputs.valeMicrosoft}/Microsoft $out
          '';
        };
        valeJoblint = mkOption {
          description = mdDoc "The vale Joblint style";
          type = types.package;
          default = pkgs.runCommand "vale-joblint-links" { } ''
            ln -sf ${inputs.valeJoblint}/Joblint $out
          '';
        };
        valeWriteGood = mkOption {
          description = mdDoc "The vale Write-Good style";
          type = types.package;
          default = pkgs.runCommand "vale-write-good-links" { } ''
            ln -sf ${inputs.valeWriteGood}/write-good $out
          '';
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
        valeConfiguration = mkOption {
          description = mdDoc "The vale configuration file";
          type = types.package;
          default = pkgs.writeText ".vale.ini" ''
            StylesPath = styles
            MinAlertLevel = suggestion
            Packages = Microsoft, write-good, Joblint
            StylesPath = "${config.valeStylesPath}"
            # Vocab = Courses
            [./CHANGELOG.md]
            BasedOnStyles = Vale
            Vale.Spelling = NO
            Vale.terms = NO
            [src/**/*.md]
            BasedOnStyles = Vale, Microsoft, write-good, Joblint
            Microsoft.Accessibility = NO
            [*.mermaid]
            BasedOnStyles = Vale, write-good, Joblint
          '';
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
        docsPackages = mkOption {
          description = mdDoc "Packages used to generate the documentation";
          default = with pkgs; [
            tagref
            vale
            tokei
            eza
            vhs
            fd
            mdformat
            markdownlint-cli2
            mdbook
            mdbook-toc
            mdbook-cmdrun
            mdbook-emojicodes
            mdbook-footnote
            mdbook-graphviz
            mdbook-katex
            mdbook-linkcheck
            mdbook-mermaid
            mdbook-pdf
            mdbook-toc
          ];
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
        nativeBuildInputs = with pkgs; [
          drawio
          go-task
          lefthook
          marp-cli
          marp-cli
          mdbook
          mdbook-cmdrun
          mdbook-d2
          mdbook-emojicodes
          mdbook-epub
          mdbook-footnote
          mdbook-katex
          mdbook-linkcheck
          mdbook-man
          mdbook-mermaid
          mdbook-open-on-gh
          mdbook-pdf
          mdbook-plantuml
          mdbook-toc
          mermaid-cli
          termbook
          typos
          ungoogled-chromium # NOTE: required by mdbook-pdf
          vhs
          aichat
          vale
        ];
        shellHook = ''
          ${config.documentationShellHookScript}
        '';
      };
    };
}
