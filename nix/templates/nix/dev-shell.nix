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
          # mdbook
          # vhs
          # reuse
          # TODO: add you project deps hereyou project deps here
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
