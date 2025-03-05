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
          default = "./.vale/";
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
        valeConfiguration = mkOption {
          description = mdDoc "The vale configuration file";
          type = types.package;
          default = pkgs.writeText ".vale.ini" ''
            StylesPath = styles
            MinAlertLevel = suggestion
            MinAlertLevel = error
            Packages = Microsoft, write-good, Joblint
            StylesPath = "${config.valeStylesPath}"
            Vocab = Courses
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
        docsPackages = mkOption {
          description = mdDoc "Packages used to generate the documentation";
          default = with pkgs; [
            drawio
            eza
            fd
            go-task
            marp-cli
            mdbook
            mdbook-cmdrun
            mdbook-d2
            mdbook-emojicodes
            mdbook-epub
            mdbook-footnote
            mdbook-graphviz
            mdbook-katex
            mdbook-linkcheck
            mdbook-man
            mdbook-mermaid
            mdbook-open-on-gh
            mdbook-pdf
            mdbook-plantuml
            mdbook-toc
            mdformat
            mermaid-cli
            tagref
            termbook
            tokei
            typos
            vale
            vhs
          ];
        };
      };
    }
  );
}
