# Syllabus

## Presentation de la majeur

- Contexte
- L'offre technologique de l'open source
- avantage et inconvénients
- L'open sources et le libre
  - les valeurs
- Organisation des cours et des évaluations
  - le projet de fin de majeure

## Rappels à propos des systeme linux

- Le userspace (vs kernel)
  - bibliothèque et dépendances
  - package rpm apt, yum deb
  - Le principe d'une distribution
- L'arborescence
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
  - Td Configuration stockage
    - les schedulers d'I/O
    - tp multi pathing
      - mise en oeuvre d'un mini san open-iscsi
      - mise en place du module dm_multipath
    - tp lvm
      - utilisation de lvm afin de simplifier la gestion des volumes SAN

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

## systemd

- Présentation
  - Principe
  - La controverse
  - Rapidité du démarrage
  - Organisation plus souple
  - Complétude
  - Mais encore
    - Daemons potentielement déprécies par systemd
    - Fichiers protentielement dépréciés par systemd
    - Outils de gestion système propres à chaque distribution
- Utilisation
  - systemctl
  - Les autres composants de systemd
    - La configuration réseaux
    - les commande de configuration système
  - systemd-analyze
- Configuration systemd
- Configuration des unités
  - Les sections
  - Les tokens de configuration des unités
  - Commande de gestion des spécifications d'unités
  - Les unités de type target
  - Unités de type service
    - Gestion des cgroups
    - Gestion des ressources
  - Unités conditionnant l'activation d'un service
    - Unité de type socket
    - Unité de type timer
    - Unité de type path
  - unités système
    - unité device
    - unité mount
    - unité automount
    - unité swap
- Conclusion

## Software delivery life cycle

- Software delivery life cycle
  - Objectif du module
- Introduction à la CICD
  - Définitions
  - QQOQCCP
  - 5 Pourquoi de la CICD
  - Les entités
- DEVOPS et CICD
  - Le non fonctionnel
  - KPIs
- Architecture d’une CICD
  - Géographie de la CICD
  - Temporalité de la CICD
  - Monorepo vs polyrepo
  - Versiong flow
- Méthodes
  - Agilité
  - Nommage
  - Gitops
  - Revue de code par les paires
  - Releases management
  - Release train
    - RACI
  - Votre rôle dans tout ça
- shell
  - Bases
  - Bonnes pratiques shell
  - Un exemple de script cool
  - Stack de dev shell
- Outillage
- Bonnes pratiques

## les Licences Open source

- historique des brevet en france
- logiciel et droit d'auteur
- tentative de brevet logiciel (orange/free)
- Abus patent troll
- L'histoire de la freebox
- logiciel libre et money
- licence BSL le debut de la merdification

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

