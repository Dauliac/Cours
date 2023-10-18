# TP SDLC

cloner ce repo: [`nuclei`](https://github.com/projectdiscovery/nuclei)
```bash
git clone git@github.com:projectdiscovery/nuclei.git
cd nuclei
# On va basculer sur le commit à partir duquel j'ai écrit le tp
git checkout d051332d
```

ajoutez le fichier [`0001-fix-patch.patch`](./0001-fix-patch.patch) dans le repo de nuclei et appliquez le:
```bash
git apply -v
```

En gros c'est que le repo à 2 problèmes:
- un appel à une API trop lente
- des tests unitaires qui ne passent pas et la suite du tp requiert que les tests passent.

**Si ca marche vous pouvez passer à la section suivante.**

Sinon, vous devriez apprendre à utiliser `git`, mais c'est pas l'objectif du tp, alors faites ca à la main:

```bash
rm -f \
  v2/pkg/protocols/headless/engine/page_actions_test.go \
  v2/internal/runner/runner_test.go \
  v2/pkg/model/worflow_loader.go \
  v2/pkg/protocols/headless/engine/page_actions_test.go
```

Il faudra aussi éditer ce fichier:
```
v2/internal/installer/versioncheck.go
```

Et changer la déclaration de `retryableHttpClient`
```go
var retryableHttpClient = retryablehttp.NewClient(retryablehttp.Options{HttpClient: updateutils.DefaultHttpClient, RetryMax: 2, RetryWaitMax: 10 * time.Second})
```
Il faudra aussi ajouter `"time"` aux imports.

**Note:** `nuclei` est un outil connu de pentesting, il permet de faire des scans de sécurité sur des sites web.

## Installer des outils
Comme nous l'avons vu en cours, la CICD repose sur l'agencement logique d'outils.
Nous allons donc installer la suite d'outil suivant avec `nix` et son `devShell` dans un premier temps.

## Environment de dev
Dans une optique devops, nous allons utiliser `nix` pour créer un environnement de dev.

Ca va nous permettre entre autre de ne pas oublier comment setup le projet, et de le partager plus facilement:

Lors du tp précédent, nous avons vu comment utiliser `flake` pour décrire un projet.
Et nous avons installé direnv pour récupérer automatiquement les dépendences lorsque l'on rentre dans le projet.
Je vous invite à lire son [README](https://github.com/direnv/direnv).

Nous allors créer un fichier `.direnvrc` qui permet de charger l'environment de dev `nix`:
```
# SPDX-License-Identifier: AGPL-3.0-or-later
if ! has nix_direnv_version || ! nix_direnv_version 2.3.0; thn
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.3.0/direnvrc" "sha256-Dmd+j63L84wuzgyjITIfSxSD57Tx7v51DMxVZOsiUD8="
fi
nix_direnv_watch_file flake.nix
nix_direnv_watch_file flake.lock
use flake
```

Vous voyez désormais que direnv va vous demander l'autorisation d'installer les dépendences du projet.
Éxecutez `direnv allow` pour autoriser l'installation des dépendences.

Question: Quel est l'utilité du flake package [`nix-direnv`](https://github.com/nix-community/nix-direnv) par rapport à `direnv` ?

On va aussi ajouter les lignes suivantes au fichier `.gitignore` à la racine:
```gitignore
result
.direnv
```

Il nous manque un flake avec les dépendances du projet.

Dans un premier temps nous allons les ajouter en `devShell` de `nix` pour les obtenir:
```nix 
{
  description = "Nuclei";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    ,
    }:
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowBroken = true;
          allowUnsupportedSystem = true;
        };
      };
    in
    {

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs;
          [
            go
            gopls
            gotools
            go-tools
          ];
      };
    });
}
```

## Build system
On peut voir dans le dossier v2 un `Makefile`, `make` est ce que l'on apelle un task manager.
C'est une bonne pratique qui permet de décrire les tâches à effectuer pour construire le projet.

Cependant aujourdhui il existe des outils plus modernes pour celà gommant les défauts des vieux outils.

```yaml
---

version: '3'

tasks:
  init:go:
    dir: v2
    cmds: 
      - | 
        go mod download
    sources:
      - go.mod
  init:
    desc: Setup project
    deps:   
      - init:go

  build:
    dir: v2
    silent: true
    desc: Build nuclei
    deps: 
      - init
    vars:
      LDFLAGS: -s -w
      BIN_PATH: nuclei
    cmds:
      - go build -v -ldflags '{{.LDFLAGS}}' -o "{{.BIN_PATH}}" cmd/nuclei/main.go
    sources:
      - "**/*.go"
    generates:
      - "{{.BIN_PATH}}"
  default:
    desc: Display help
    silent: true
    deps:
      - init
    cmds:
      - task -l
```

Allez on essaie les nouvelles `tasks` !
```bash
# Documentation
task 

# execution: 
task init
task build
# ou pareil
task init build

```
On a un `nuclei` qui marche super
```bash
./v2/nuclei
```

Renseignez vous sur le mot clef `deps` et ses propriétés dans [la documentation](https://taskfile.dev/usage/), quel est sont plus grand avantage ?

## Pure
Taskfile c'est pas mal, mais vous ne trouvez pas que ca sonne vachement impératif, la recette de cuisine, le fait
de définir un résultat plus qu'une procédure vous vous souvenez ?

Allez on va utiliser les utilitaires de nix pour construire notre package go !

Ajoutons le code à la section `let` de notre `flake`, celà va nous permettre de construire notre binnaire:
```nix
goPackage = pkgs.buildGoModule {
  name = "nuclei";
  version = "v2.9.15";
  src = ./v2/.;
  buildInputs = [
    # required for tests
    pkgs.firefox
  ];
  vendorSha256 = "sha256-3buSAVyXQ8epc4kteFCemEBMZxo68a4SpTEo27EV0Fw=";
  ldflags = [
    "-s"
    "-w"
  ];
};

```
Ajoutez aussi le code suivant dans l'`output` de votre flake:
```nix
packages.default = goPackage;
```


[Voici la documentation de notre helper `buildGoModule`](https://nixos.org/manual/nixpkgs/stable/#ssec-language-go)

**Note:** le fichier `./v2/go.mod` est un index des dépendances go, c'est comme le:
- `requirements.txt` en `python` (y'a un nouveau machin plus moderne je crois maintenant)
- `package.json` en `js`
- `Cargo.toml` en `rust`
- `riendutoutdémerdetoit` en `c++`

Comment faire si le hash du fichier `./v2/go.mod` change et donc la valeur de `vendorSha256` (indice c'est dans la doc)?

Essayons de builder de manière pure:
```bash
# On supprime l'ancien build, nous n'en avons plus besoin
rm ./v2/nuclei
nix build '.'
```

Bon stylé mais y'a rien la ?

Si un dossier `result` contient le build !
```bash
# On peut voir que c'est un lien symbolique vers un dossier étrange
# Le dossier change-il si l'on rebuild ?
ls -la | grep result
ls -la result
# On peut meme le lancer
result/bin/nuclei
```

Les builds dans Nix sont considérés comme "purs" en raison du principe fondamental de "pureté fonctionnelle" dans le modèle de construction de Nix. Voici quelques points qui expliquent pourquoi les builds de Nix sont considérés comme purs :
- Reproductibilité : La pureté fonctionnelle garantit que le build produit sera identique, quel que soit l'environnement dans lequel il est construit. Cela permet une reproductibilité totale du build, ce qui signifie que le même résultat sera obtenu à chaque exécution, indépendamment de l'endroit où le build est effectué.
- Isolation des dépendances : Les dépendances pour la construction d'un paquet Nix sont spécifiées explicitement dans le fichier de recette (fichier .nix). Ces dépendances sont isolées du reste du système, ce qui garantit qu'aucune dépendance système ne peut affecter le build.
- Évitement des effets de bord : Dans Nix, les builds sont conçus pour éviter les effets de bord. Cela signifie que le processus de build ne doit pas dépendre de variables d'environnement externes, de fichiers cachés, ou d'autres facteurs extérieurs qui pourraient altérer le résultat du build. pour ce faire il utilise un dossier `chroot` par target de build !
- Gestion explicite des dépendances : Les dépendances ne sont pas résolues implicitement à partir du système, mais sont déclarées explicitement dans le fichier .nix. Cela signifie qu'un build n'est pas affecté par les changements dans le système global.
- Cache Nix : Nix utilise un cache centralisé pour stocker les résultats des builds (dérivations). Si un build avec les mêmes spécifications a déjà été effectué ailleurs, le résultat peut être récupéré à partir du cache, accélérant ainsi le processus et économisant des ressources.

Appelez moi quand vous en êtes la 😃.

## Container
Regardez maintenant le `Dockerfile` fourni de base dans le repo.
C'est ce qu'on appel un layered `Dockerfile`, que pouvez vous en dire par rapport à votre `Taskfile`.

Essayez d'etre critique.

Allez pour ceux qui lisent plus bas, un indice: renseignez vous sur le principe DRY.

Nous allons le supprimer et utiliser nix a la place:
ajoutez le code suivant dans votre flake dans la section `let` et commentez dans le rapport ses différentes sections et leurs utilité:
```nix
containerImage = pkgs.dockerTools.buildImage {
  name = "tldr-nix";
  copyToRoot = pkgs.buildEnv {
    name = "nuclei";
    paths = [ goPackage ];
    pathsToLink = [ "/bin" ];
  };
};
```

Et le code suivant dans votre section output:
```nix
packages.container = containerImage;
```

Notez: que nous n'avons pas besoin d'utiliser de "layered image" dans ce cas avec nix, mais c'est cependant possible.
Est-ce une mauvais ou une bonne chose selon vous ?

On peut maintenant le builder:
```bash
nix build '.#container'
```
On peut maintenant voir que result n'est plus un dossier mais un fichier:
```
ls -la result
```

C'est une archive de container comme lors du tp précédent !
```bash
# On peut aussi directement lancer des packets nix comme ca !
# C'est vachement pratique pour essayer des trucs
nix run 'nixpkgs#podman' -- load -i result
# On ne peut pas le lancer avec autre chose, il n'y a rien d'autre dans le container
# le -v permet de monter un volume depuis la machine hote vers le container, nuclei à besoin de tmp
# pour fonctionner.

# nix run 'nixpkgs#podman' -- run -it -v /tmp:/tmp localhost/tldr-nix:z4s1w56sg15m477mhhpjrq9pv65sf2wr nuclei
nix run 'nixpkgs#podman' -- run -it -v /tmp:/tmp localhost/tldr-nix:<CHANGEZ MOI> nuclei
```

### Fmt
`nix` met à disposition un output dédié au formatage, et aux vérifications, nous allons les ajouter.

Dans votre section `let`:
```nix
nixFormatterPackages = with pkgs; [
  nixpkgs-fmt
  alejandra
  statix
];
```

Documentez moi dans votre rapport ces différent packages ajoutés et leur utilité.

Ajoutez cette section dans votre output:
```nix
formatter = pkgs.writeShellApplication {
  name = "normalise_nix";
  runtimeInputs = nixFormatterPackages;
  text = ''
    set -o xtrace
    alejandra "$@"
    nixpkgs-fmt "$@"
    statix fix "*.nix"
  '';
};
```

et celle la aussi: 
```nix
checks = {
  inherit goPackage;
  typos = pkgs.mkShell {
    buildInputs = with pkgs; [ typos ];
    shellHook = ''
      typos .
    '';
  };
  yamllint = pkgs.mkShell {
    buildInputs = with pkgs; [ yamllint ];
    shellHook = ''
      yamllint --strict .
    '';
  };
  reuse = pkgs.mkShell {
    buildInputs = with pkgs; [ reuse ];
    shellHook = ''
      reuse lint
    '';
  };
};
```

Modifiez également votre `devShell` pour ajoutez ces dépendances:
```nix
devShells.default = pkgs.mkShell {
  inputsFrom = builtins.attrValues self.checks.${system};
  buildInputs = with pkgs;
  [
    go
    gopls
    gotools
    go-tools
    podman
  ]
  ++ nixFormatterPackages;
};
```

Pour les essayer:
```bash
# Pour le formatage
nix fmt
# POur le check 
nix flake check
```
Allez on fix le projet pour qu'il soit valide !
Bon à la main c'est relou, oui y'a beaucoup de problèmes... et de faux positifs.

On va faire des scripts et de la config !

On va ajouter de quoi fix avec [typos](https://github.com/crate-ci/typos) dans notre `Taskfile`, c'est un outil qui permet de fixer automatiquement les fautes d'orthographe dans les fichiers texte.
```yaml
  lint::typos:
    silent: true
    cmds:
      - |
        nix run nixpkgs#typos -- --write-changes .
  lint:
    silent: true
    desc: 💄Lint jardin
    deps:
      - lint::typos
```

On peut le lancer ! 
```bash
task lint
```

**Note:** Dans le cadre du tp nous n'allons pas nous encombrer à exclure les faux positifs, en temps normal, il aurait fallu le faire grace à un fichier de config de `typos`.

Question: A votre avis quel est l'avantage d'utiliser `nix run nixpkgs#typos` plus qu'un appel direct à `typos` ?

Bon, j'ai abusé on est pas capable de fixer automatiquement avec `yamllint` (linter de `yaml`) et `reuse` (linter de licenses).

Retirez les `checks` de votre `flake.nix` (n'oubliez pas de retirer l'import `check` de votre `devShell`) !

Il devrait maintenant marcher avec:
```bash
nix fmt
nix flake check
# En meme temps il ne fait plus rien que le build et le fmt
```

## `Taskfile` x `nix` les bros:
On va pouvoir modifier notre Taskfile pour arreter de cuisiner:

Changer la task build en `dev:build` et ajoutez une nouvelle task `build` et `build:container` utilisant `nix`:
```yaml
  build:
    silent: true
    desc: Build nuclei
    deps: 
      - init
    cmds:
      - flake nix '.#default'
    sources:
      - "**/*.go"
  build:container:
    silent: true
    desc: Build nuclei container
    deps: 
      - init
    cmds:
      - nix build '.#container'
    sources:
      - "**/*.go"

```

vous pouvez les essayer !
```bash
task build
ls -la result
task build:container
```

## Pre-commit `hooks`:

Vous vous souvenez du shift left ? 

Ce qu'on fait en CICD, il faudrait pouvoir le faire en local !

Pour ca il suffit d'obliger les contributeurs à l'éxécuter en local pour commit !
Ajoutons un fichier `lefthook.yml` à la racine du projet:
```yaml
---
# SPDX-License-Identifier: AGPL-3.0-or-later

skip_output:
  - meta
  - success

pre-commit:
  parallel: false
  commands:
    check:
      tags: check
      run: nix flake check
    formatter-nix:
      tags: formatter
      glob: "*.nix"
      run: nix fmt
      stage_fixed: true
pre-push:
  parallel: true
  commands:
    check:
      tags: nix checks
      run: nix flake check
```

Nous allons ajouer une task `init:pre-commit` hook pour ca:
```yaml
init:pre-commit:
  cmds:
    - | 
      nix run nixpkgs#lefthook install
  sources:
    - ./lefthook.yml
    - ./flake.nix
# modifions aussi la task init
init:
  desc: Setup project
  deps:   
    - init:pre-commit
    - init:go
```
Ajoutez le packet lefthook à votre `devShell` et la section suivante au meme niveau que les `buildInputs`:
```nix
shellHook = ''
  task
'';
```

Expliquex moi ce que vous venez de faire la avec ce `shellHook` ?

On peut essayer le hook:
```bash
# Normalement y'a pas besoin mais au cas ou
task init -f

# On peut voir les hook ici
ls .git/hooks
# On peut le tester avec un commit fake
touch fake.txt
git add fake.txt
git commit -m 'ci(hooks): empty commit to test hooks'
```
Note: `lefthook` permet de lancer les hooks en parallèle, c'est très pratique pour les gros projets.

## Pipeline
On ne va pas faire de pipeline car elle nécessite un runner et un outil de CI.

De plus je voulais vous montrer qu'une bonne CI c'est avant tout un bon build système !

Maintenant que nous avons de belles `tasks` et un joli environnement pure, 
il est facile de les intégré dans une CI.

Vous pouvez par example utiliser des containers `nix` avec [gitlab runner](https://nixos.wiki/wiki/Gitlab_runner) ou github action.

Perso j'utilise `gitlab-ci` mais ils sont tous plus ou moins pareil.

# FIN 
C'est maintenant la fin !

fin !

supprimez le `.git` de `nuclei` et commitez le:
```bash
rm .git/
git add .
git commit --no-verify -m 'docs(tp): send sdlc tp'
git push --no-verify
```
