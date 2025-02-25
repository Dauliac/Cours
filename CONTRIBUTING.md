# Comment contribuer au projet

## Description

Ce projet est maintenu en markdown, et utilise `mdbook`\]() et ses plugins comme outils de gestion des documentations.
les dépendances, et la chaine de buils sont quand à elle gérée avec nix et flake-parts.

Cependant, il n'est a aucun moment requis d'utiliser ces outils, ils proposent juste une politique de gestion commune et des automatisations pour gérer les documents de cours, tp, etc...

## Setup le projet avec nix

1. Installer nix en utilisant cet installer:
   https://github.com/DeterminateSystems/nix-installer

1. Installer direnv

   ```bash
   nix profile install 'nixpkgs#direnv'
   ```

1. Activer le hook direnv (optionnel):

   https://direnv.net/docs/hook.html

1. Aller dans le projet

   ```bash
   git clone git@gitlab.com/alsim/opensource.git
   cd opensource
   direnv allow
   # NOTE: si direnv n'est pas installé sur votre machine, vous pouvez lancez la commande suivante dans le projet en alternative.
   nix develop
   ```
