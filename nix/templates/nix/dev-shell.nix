_: {
  config.perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          go-task
          lefthook
          vale
          trufflehog
          convco
          sops
          nix-output-monitor # Fancy build output (nom)
          nix-tree # Explore dependency trees
          # mdbook
          # vhs
          # reuse
          # TODO: add your project deps here
        ];
        # INFO: That run when you come in the project
        # TODO: install direnv on your machine:
        #  https://github.com/direnv/direnv
        shellHook = ''
          lefthook  install --force
        '';
      };
    };
}
