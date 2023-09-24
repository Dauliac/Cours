{
  description = "Open source courses";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = inputs @ { self, ... }:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default =
          pkgs.mkShell
            {

              nativeBuildInputs = with pkgs;
                [
                  lefthook
                  go-task
                  marp-cli
                  typos
                  drawio
                ];

              devShellHook = ''
                task init
              '';
            };
      });
}
