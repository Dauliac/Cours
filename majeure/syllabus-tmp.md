# Syllabus

## Presentation de la majeur

- Contexte
- L'offre technologique de l'open source
- avantage et inconvénients
- L'open sources et le libre
  - les valeurs
- Organisation des cours et des évaluations
  - le projet de fin de majeure

## Cours des systèmes

- Introduction
- Objectifs
  - C’est quoi un OS ?
    - Quelle est la proposition d’un OS:
  - Un système simple pour commencer
- BIOS
  - Qu’est ce qu’un BIOS
  - securite
- Kernel
  - Résumé des composants du Noyau
  - Scheduler
    - Comment fait-on pour lancer plusieurs processus ?
    - Ordonnanceur et temporisateur
    - Algorithmes d’ordonnancements
  - Les syscalls
- Processus
  - Premier processus
  - Histoire de l’architecture de la RAM
  - Le layout de la ram
  - Sécurité de la ram
  - Processus states
  - Pagination virtuelle
- Les nouvelles isolations
  - Les machines virtuelles
  - Les containers 🐋
    - Dockerfile
    - Les containers et les syscalls
    - Les lambdas
    - Web assembly
  - Comparaison
- Conclusion

## Rappels a propos des systeme linux

- le userspace (vs kernel)
  - bibliothèque et dépendances
  - package rpm apt, yum deb
  - Le principe d'une distribution
    - tp gestion des clefs gpg
- l'arborescence
  - FSHS /var /lib /etc etc...
  - Rappels sur les droits posix
- TD : definittion des droits linux
- Implication sur le projet
  
## Configuration linux sur serveur physique

- Contexte matériel et environemental
  - L'hébergement physique
  - Le réseaux
  - Les servers
  - Les solutions de stockage
    - Principes de fonctionnement
    - Principe de configuration
- configuration Linux
  - Configuration/matrise du Kernel
  - tp compilation de driver
  - les pilotes de périphérique physiques et les paramètre de modules
  - td configuration réseaux avancée
    - Le Bondig/lacp
    - Les vlan avec le module 802.1q
    - Le module bridge du noyau
  - Les mêmes configuration avec networkd
  - Td Configuration stockage
    - les schedulers d'I/O
    - tp multi pathing
      - mise en oeuvre d'un mini san open-iscsi
      - mise en place du module dm_multipath
    - tp lvm
      - utilisation de lvm afin de simplifier la gestion des volumes SAN

## systemd

- presentation/utilisation/confiuration
- les unités et targets
- les unité de type services
  - les Cgroup
  - La gestion des ressources
- les unité dechanchant des services
  - timer
  - path
  - socket
- Les unités systèmes
  - device
  - mount
  - swap

## les Licences Open source

- historique des brevet en france
- logiciel et droit d'auteur
- tentative de brevet logiciel (orange/free)
- Abus patent troll
- L'histoire de la freebox
- logiciel libre et money
- BSL -> la merdification

## Software delivery life cycle

- Software delivery life cycle
  - Objectif du module
- Introduction à la CICD
  - Définitions:
    - Software delivery life cycle
    - CI
    - Supply chain
    - CD
  - QQOQCCP
  - 5 Pourquoi de la CICD
    - Stabilité
    - Sécurité
    - Aussi
  - Les entités
- DEVOPS et CICD
  - Le non fonctionnel
  - KPIs
    - Mes KPIs prefs
    - DORA metrics
- Architecture d’une CICD
  - Géographie de la CICD
  - Temporalité de la CICD
  - Monorepo vs polyrepo
    - Polyrepo
    - Monorepo
    - Comment découper ?
    - pour la CICD
  - Versiong flow
    - Gitlab flow
    - Github flow
    - Git flow
- Méthodes
  - Agilité
  - Nommage
  - Gitops
  - Revue de code par les paires
    - Merge request vs pull request
    - Commentaires de merge request
    - Environnement de review
  - Releases
    - Commits
    - Versions
    - Changelogs
    - Releases
  - Release train
    - RACI
  - Votre rôle dans tout ça
- shell
  - Bases
  - Mes bonnes pratiques shell
    - Les set
    - Les variables
    - Shebang
    - Fonctions
  - Un exemple de script cool
    - Styleguide et bonnes documentations
    - Ma stack de dev shell
- Outils
  - git
  - git hooks
  - gitlab-ci
  - nix
  - Renovate bot
  - Semantic release
  - Review dog
  - Fuid attack Sast
  - Aqua security - trivy
  - Hors sujet (vraiment ?)
    - Chromatic
    - Bitebase
    - Lokalise
    - n8n et le NOCODE
- Bonnes pratiques

## kubernetes

- Présentation Kubernetes
  - Architecture de l'application kubernetes
    - Les différent roles des noeud du cluster
    - La haute disponibilité
  - Les modèle de kubernetes
    - les pods
      - cycle de vie
      - les controleurs de pod
        - stateful-set, replicat-set, deploiement, job, etc..
      - les accès réseaux
        - service
        - ingress
  - TD: Installation d'un LAB
- cours-TD : déploiement d'application
  - kubectl
  - Les namespaces
  - Les déploiements
    - Un pod
    - Un Service
    - Une config map
    - Un replica set
      - Deploiement
      - Manipulation
    - Un deploiement
- cours-TD : Gestion des volumes
  - gestion des volumes persistants
    - Mise en oeuvre de la gestion de stockage
      - Test unitaire
    - Utilisation des PersistentVolumes
- cours-TD : Le Loadbalanceur MetalLB
  - Déploiement de metalLB
  - Déploiement d'un ReplicatSet derrière le loadbalanceur
- TD : utilisation de helm
  - Installation
  - Exemple d'utilisation
    - Gestion des repository helm
    - Configuration/deploiement de prometheus
    - Configuration/Deploiement de grafana
- TD : Déploiement d'un Ingress
  - Déploiement d'un ingress controler
  - Deploiement d'un service avec un ingress

## L'outil Wazuh

- Introduction sur les moteur de recherche et d'analyse
  - ELK
  - OpenSearch
- Wazuh
  - Présentation
- Composants
  - L'indexer
  - Le dashboard
  - L'agent
- TD: installation de wazuh
- Les évènement de sécurité
  - pre-decoding
  - decoder
  - rules
- Gestion de l'intégrité
- Gestion de la conformité
- detection et réponse
  - Vumnerabilité
  - Mitre
- Conformité aux obligations légales
- gestion centralisé
- TD: détection d'une attaque
