# Gestion d'une Infrastucture IT

## Infrastructure IT

__Definition :__
L'ensemble des composants matériels et logiciels assujettis à la fourniture des services de gestion de l'information d'une entitée. Leur configuration, les moyens d'hébergement associés ainsi que les outils permettant leur gestion ; composent l'infrastucture de gestion de l'information de cette entité.

Cela comprend :

* Le datacenter ou la salle blanche avec les arrivées électriques et la climatisation.
* Le matériel acheté ou loué ansi que __les contrats de support__ associés à ceux-ci.
  * Les alimentations electriques et onduleurs
  * réseaux : switch routeur firewall
  * Serveurs et matériels dédiés (Exemple : Le stockage SAN)
  * Les cables réseaux, fibres et électriques
  * Les postes de travail des utilisateurs
* Les systèmes d'exploitation les logiciels ainsi que les droits de licences et support associés.
* Les instances applicatives
* Les éventuels services externes (founisseurs de service)
* Les configurations matériels, logiciels et applicatives
* La donnée métier

L'entité produit __des services métier__ (vente de chocolat, facturation des consomation des clients d'un opérateur de téléphonie, etc... ). Ces services métier reposent sur des services de technologie de l'information: des applications en production.
La DSI a son propre métier qui consiste en la maintenance du système d'information pour la production des services métier de l'entité.

## L'organisation de la DSI

### Les métiers de la DSI

#### L'hébergement

Gestion :

* Du contrat avec le datacenter ou de la salle blanche
* Les accès physiques
* Du matériel : reception des livraisons, gestion du stock, gestion du support matériel, rackage, occupation et capacité des baies (electrique, espace, etc...)

#### Ingénieurie : Réseaux, Stockage, Systèmes et Virtualisation

* Conception
  * Gestion de l'architecture et de ses évolutions
  * Gestion des contrats fournisseurs et de leur support
* Mise en production
  * Gestion des configurations et du déploiement de celles-ci
  * Gestion des référentiels documentaires et des procédures
* Exploitation
  * Gestion des sauvegardes
    * Suivi des plans de sauvegardes et des échecs
    * Externalisation des sauvegardes
  * Gestion du monitoring
    * déploiements
  * __Suivi des capacités__

#### L'intégration

* La gestion projets
  * Planification, coordination, suivi des actions et des coûts
* Gestion des dévelopements
  * Gestion des anomalies et des évolutions logiciels
* Automatisation et gestion des déploiement applicatifs
* Ordonnancement des taches à automatisées
* Gestion des bases de données

#### Le support

Le support est un service fourni aux utilisateurs du systeme d'information c'est le point d'entrée de la DSI. Il permet à ces derniers de formuler des demandes et de déclarer des anomalies.

Cette activité est en général transverse à toute la DSI répartie par niveau de support

Exemple :

* Niveau 1 : Prise d'appels, monitoring, analyse de premier niveau, résolution et traitement simple et en général procédurée (Eq. support)
* Niveau 2 : Analyse et résolution d'anomalies non procèdurées
(Eq. production)
* Niveau 3 : escalades des anomalies et demandes complexes à l'ingénieurie

#### La production métier

C'est l'utilisation du système d'information pour produire les `services métier` en executant les `processus métier` : __La réalisation du métier de l'organisation__

### Les Processus de la DSI

#### Gestion des Alertes et des remontées

La gestion des évènements, des alertes ou des rémontées est souvent rattaché au `support` (niveau 1) ; Lié aux alertes de **monitoring** et aux remontées des utilisateurs (déclaration d'incidents).
L'objectif de ce processus est de s'assurer que les `évènements` sont bien pris en comptes et __traités de bout en bout.__

#### Gestion des Incidents

Souvent associé au `support` (niveau 2), La gestion des incidents ou des anomalies consiste à réduire au minimum le temps d'indisponibilité des services métier et à garantir `le niveau de service attendu`.

Un incident est une indisponibilité avéré ou prédite d'un service métier, ou plus simplement d'une `anomalie de conformité`.

L'objectif est de remettre le service métier 'en route' au plus tot ou d'éviter son blocage.

Exemple :

* Relance de processus système
* Reprise de processus métier
* Augmentation de capacité de certaines ressources
* Application de solution de contournement sur des `erreurs connues`.

__Niveau de service attendu__ (SLA): il s'agit de la définition de la disponibilité souahitée pour tel ou tel service. Exemple disponibilité à 99,98% de 8h à 20h. (On en reparlera)
cf : <https://fr.wikipedia.org/wiki/Service-level_agreement>

#### Gestion des problèmes

Un probleme est la reproduction d'incidents récurents de même type elle peut être aussi associée à une prédiction d'incident majeur.
L'objectif de la gestion de probleme est de définir la source des incidents récurents puis de proposer des solutions permettant de `résoudre le problème`.

Dans un grand nombre de cas la gestion de problème propose des solutions de contournements ; procèdures utilisées dans la cadre de la gestion d'incident pour traiter les occurences des ces anomalies. Dans ce cas l'objectif est alors de permettre de vivre avec le problème alors identifié comme une `erreur connue` en attendant sa résolution.

#### Gestion des Changements et des évolutions

La gestion des changements est le processus permettant de garantir la continuité de la production métier ou la disponibilité des services métier au cours de l'application des modifications de l'infrastructure du système d'information.

Les changements sont classifiés :

* les changements standards sont des opérations procédurées et maitrisées.
* Les changements non standards sont des demandes nécessitant une analyse impliquant un étude d'impact.
* Les changement d'infrastructure necessite de passer par le CAB.

__Le CAB__ : `Change advisory board` ou comité consultatif des changements. Ce comité est consulté afin de valider, plannifier et organiser la réalisation des modifications de l'infrastructure.

Un changements est présenté au CAB de la façon suivante :

présentation de :

* L'objectif du changement (Ou le risque à ne pas faire)
* Le risque associé à la réalisation du changement (le risque à faire)
* Le planning et le plan d'action (comment et quand cela sera fait)
* Les indisponibilités associées (l'impact du déploiement)
* Le plan de communication associé au changement (qui doit être informé)
* Le plan de retour arrière (pour garantir la disponibilité après le changement y compris en cas d'échec de déploiement)

#### Suivi des Capacités

Ce processus à pour objectif d'éviter les saturations des ressources limitées en quantité ou volume. Il s'agit de suivre les consomations et de planifier les `changements` nécessaires afin d'éviter les saturations.

### Les bases de connaissances

#### La doc

__La documentation est obsolète, incomplète, éronnée mais nécessaire.__

* Documentation fournisseur et editeur
  * Documentations et procédures produit
  * Les interfaces de support
    * Interface web, compte, numéro de contrat etc...
    * contact mail ou téléphonique pour escalades
* Documentation technique interne
  * Dossier d'architecture,
  * Dossier d'exploitation,
  * __Les matrices de flux__

Considèrez la documentation que vous produisez comme une communication vers votre "moi" future.

> Un wiki déja c'est bien

#### Les référentiels

* Inventaires de gestion des actifs de l'infrastucture
  * Matériel et support matériel
  * Licences logicielles
  * Certificats ssl
  * Nom de domaines

* Référenciels techniques
  * DCIM : Data Center Infrastructure Managment
  * IPAM : IP adress managment (vlan, ip, subnet, vrf)
  * Les VMs

#### Le ticketing

Les systèmes de ticketing permettent de tracer les opérations, communications relatives aux demandes, incidents, déploiement et problèmes.

C'est un élément __essentiel__ de la base de connaissance car il permet de retrouver, via les métadonnées des tickets, tous les évènements incidents changements liés à un device ou a une des plateformes de service.
