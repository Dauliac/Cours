# Présentation Kubernetes

* [Présentation Kubernetes](#présentation-kubernetes)
  * [Introduction](#introduction)
  * [Architecture de l'application kubernetes](#architecture-de-lapplication-kubernetes)
    * [Rôle master](#rôle-master)
    * [Rôle worker](#rôle-worker)
    * [Le client kubectl](#le-client-kubectl)
    * [La haute disponibilité](#la-haute-disponibilité)
      * [etcd](#etcd)
      * [Topologie des Nodes Master et worker](#topologie-des-nodes-master-et-worker)
      * [Pour le Réseaux](#pour-le-réseaux)
  * [Les objets kubernetes](#les-objets-kubernetes)
    * [Les objets globaux](#les-objets-globaux)
    * [Le pod](#le-pod)
      * [Le cycle de vie du pod](#le-cycle-de-vie-du-pod)
      * [Objets de controle du pod](#objets-de-controle-du-pod)
    * [Les objets réseau](#les-objets-réseau)
      * [Le service](#le-service)
      * [L'ingress](#lingress)
  * [Conclusion](#conclusion)

## Introduction

Kubernetes veux dire Timonier celui qui tiens la barre du bateau. C'est un **orchestrateur de conteneurs**.

C'est une application dévelopé par google gérant l'exécution de ses milliards de containers. Cette application a été reversé à la communauté open-source (via le CNCF).

Il offre une abstraction compléte de l'infrastructure matérielle qui execute les applications.

Nous allons définir des applications sous forme de groupe de containeurs, Kubernetes va assurer leur exécution et simplifier/standardiser leur gestion sur un groupe de serveur physique ou de VM. Ce tout en masquant la complexité de l'infrastructure technique mise en oeuvre.

## Architecture de l'application kubernetes

Kubernete est une application Cloud-native donc avec une architecture microservice conteneurisé.

Pour s'exécuter kubernetes fonctionne sur cluster de machine physique (ou virtuelle)disposant d'un controleur de container : les **nodes**.

Les nodes peuvent avoir les rôles suivants :

* master : c'est un noeud de controle du cluster, il supporte la charge de kubernetes lui même.
* worker : C'est un noeud de ressources de calcule, il supportera la charge des applications déployées sur le cluster kubernetes

Les utilisateurs interagissent avec le cluster au travers d'une interface cli `kubctl`.

![kube archi](../images/kube-archi.drawio.png)

### Rôle master

Il execute Les services : `API serveur`, `etcd`, `scheduler` et `Controller-Manager`

L'**API serveur** expose l'API kubernetes et stocke ses données dans la base de donnée `etcd`.

La base **etcd** stocke les paire de clefs valeurs de l'api

Le **scheduler** : Distribue les conteneurs à démarrer sur les worker en fonction de la charge de chacun des noeuds worker. Il démarre les application nouvelement définies dans la base `etcd`.

Le **Controller-Manager** surveille l'état du cluster et des applications définies et remonte ces informations dans la base `etcd`. Il maintiens l'état attendu de ces application sur le cluster en assurant les fonctions suivantes :

* Nde controleur : surveille l'état des noeud et réagit en fonction de leur panne.
* Replication Controller : maintiens le bon nombre de réplicats de conteneur et re-démarre les eventuels conteneur qui se sont arrêté de façon inatendue.
* Endpoints Controller : maintiens les accès réseaux aux conteneur.
* Service Account & Token Controllers : gestion des droits accès
* Cloud-controller-manager : gestion de l'interface aux worker (quelque soit son type)

### Rôle worker

Il execute Les services : `kubelet`, et `kube proxy`

**Kubelet** : Agent qui s'exécute sur chaque noeud worker du cluster. Il gère la communication avec le Master Il gère les conteneurs.

il assure les fonctions suivantes :

* Reçoit les demandes de création de Pod
* Monte les Volumes des Pods
* Lance les conteneurs
* Il rapporte l’état des conteneurs à l’API-Server

**kube-proxy** : Agent qui maintiens les réseaux du cluster et permet l'accès réseaux aux conteneurs

### Le client kubectl

`kubectl` est un outil en ligne de commande gérant la communication avec l'api serveur du cluster kubernetes et nous permettant d'interagire avec lui.

### La haute disponibilité

Afin de garantir la haute disponibilité du cluster kubernetes ; afin que celui-ci garantisse la disponibilité des applications qu'il porte. Il nous faut definir la topoligie du cluster nous permettant de maintenir disponible le rôle **master** qui pilote les workers et un **nombre sufisant de worker** pour porter la charge des applications.

#### etcd

Le service etcd est le service qui maintiens les données métier du cluster. c'est un service de stockage clefs valeurs distribué et hautement disponible. Il s'apuis sur l'algorythme de concensus distribué Raft qui est trés bien expliqué [ici](http://thesecretlivesofdata.com/raft/).

Il nous faut donc un cluster etcd d'au moins 3 noeud.

Si celui-ci est embarqué sur le role master nous déploie'rons alors 3 noeuds masters :

![from-kubernetes.io](../images/ha-topology-stacked-etcd.drawio.png)

Il est bien sur aussi possible d'utiliser un cluster etcd externe :

![also-from-kubernetes.io](../images/ha-topology-external-etcd.drawio.png)

#### Topologie des Nodes Master et worker

Nous allons déployer un node master par zone hébergeant notre cluster, nous pourrons alors assumer la perte d'une zone sans Impact important sur nos services.

Pour les worker, tout dépend de la charge et la redondance que nous devons offrir aux application hébergé. compton au début 2 par site.

![node-topology](../images/node-topology.drawio.png)

#### Pour le Réseaux

Kubernetes masque la complexité du réseaux dans son modèle et propose une vue logique avec un réseaux interne le `cluster network` et des les objets `services` qui permettent la publication des application.

![cluster-network](../images/kube-cluster-network.drawio.png)

Cela necessite en interne une gestion de réseaux avancé et pour ce faire k8s s'apuis sur un plugin réseaux :

Par défaut, nous avons **Kubenet** le mode le plus basique qui s'apuis sur un bridge linux `cbr0` et deux veth une pour le hosts l'autre pour le conteneur (le pod en fait mais on en parle plus bas). Cela est trés basique et est utilisé pour du test pour un sigle node. Cela permet d'avoir un hébergement kubernetes local de test.

Sinon avec un plugin **CNI** (Container Network Interface) plus évoluer sur notre cluster nous  disposons du réseaux virtuels interne permettant la communication entre nos containeurs (pods) quelque soit le noeud sur lequel ils s'exécutent. Il en existe un grand nombre dans le cas d'un cluster on premise on retiendra :

* Flanel : Qui propose un vxlan ipv4 par cluster.
* Calico : Qui propose plusieurs réseaux ipv4 ou ipv6 par cluster, il fonctionne en sapuyant sur un underlay à base de bgp et IPinIP
* Cilium : Qui popose un sous-réseaux par noeud (niveau 3) en overlay vxlan ou en routage natif (l'underlay est complexe à gérer) il utilise le filtrage reseaux BPF(BerkleyPacketFilter) plus performant que iptables.
* WeaveNet : Qui popose un sous-réseaux par noeud (niveau 3) ou un overlay vxlan.

Chacun dispose d'avantages et d'inconvénients, il faudra les étudier avant de choisir celui qui sera déployé sur le cluster. Certains sont pret pour la prod d'autre moins. a voir, la [présentation dans la doc kubernbete](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

## Les objets kubernetes

Kubernetes propose un modèle pour les objects que nous gérons lorsque nous déployons des applications.

Pour chacun de ces objets nous auront une entrée dans la base etcd qui le représente et assure sa rémanence dans le cluster.

Afin de manipuler ces objets nous les décrirons en yaml.

Exemple :

```yaml
apiVersion: v1
kind: ObjectType
metadata:
  name: unique-name
  namespace: the-namespace
spec:
  Key: Value
```

On notera La version de l'api utilisée, le type d'objet defini, ses meta donnée pour l'identifié et ses sp&écification du type clef: valeur.

Ci dessous une présentation succinte des objets principaux a conaitre.

### Les objets globaux

Ces objets sont visible sur l'ensemble du cluster physique quelques soit le namespace

* Le node: C'est un host du cluster
* Le namespace : C'est un espace de nommage, c'est un cluster virtuel sur notre cluster physique. C'est une façon de regouper des objets logiquement (par equipe projet ou par environement ...)
* Le volume persistant : c'est la définition d'un espace de stockage rémanent sur le cluster

### Le pod

Le pod est un groupe de container (souvent un seul) vue comme une seule entité, un pod est associé à une et une seule adresse ip, les conteneurs qu'il contiens voient tous les mêmes volumes.

#### Le cycle de vie du pod

Le pod peu prendre tour a tour les status suivant :

* **Pending** : Le Pod a été accepté par Kubernetes, il est soit en cours d'affectation sinon le pod est en train de  télécharger les images puis de créer les containers qu'il contiens.
* **Running** : Le pod a été affecté à un nœud et tous les conteneurs ont été créés. Au moins un est en cours d'exécution.
* **Succeeded** : Tous les conteneurs du pod ont terminé avec succès (rc code 0) et ne seront pas redémarrés.
* **Failed** : Tous les conteneurs d'un pod ont terminé, et au moins un conteneur a terminé en échec
* **Unknown** : l'état du pod ne peut pas être obtenu

#### Objets de controle du pod

* Le `ReplicaSet` : Cet objet définie le fait qu'un pod doit être répliqué un certain nombre de fois.
* Le `StatefulSet` : Cet objet lie un **pod**, un **ReplicatSet** ou un **Deployment** a un `volume` (conservant l'état du pod : stateful)
* Le `Deployment` : Cet objet définie Comment le **ReplicatSet** doit être re-déployé
* Le `DaemonSet` : Cet objet définie le fait qu'un pod doit exister sur chacuns (certains)des noeud du cluster
* Le `Job` : **le job est une sorte de pod** qui effectue une tache puis s'arrête, Kubernetes ne s'assure pas que celui-ci fonctionne en permanence mais qu'il s'est exécuté avec succes
* Le `cronjob` : **le job est une sorte de pod** qui est planifié via une ligne de crontab mais dans kubernetes

![pod related objects](../images/pod-related-objects.drawio.png)

### Les objets réseau

De base chaque pod dispose d'une adresse ip et éventuelement d'un nom dns. le pod est donc disponible sur le réseaux interne du cluster (pour d'autre pod par exemple) mais n'est pas accessible à l'utilisateur.

L'accès aux application est défini par les objets `service` et `ingress`.

#### Le service

Le service : le service est l'objet publiant le service réseaux fournie par une application (un groupe de pod)

il peu être publier sur :

* une `ClusterIP` une adresse IP interne accessible uniquement depuis l'intérieur du cluster Kubernetes.
* un `NodePort` un port réseaux `<Node_IP>:<NodePort>` est réservé sur tous les Noeuds du cluster. Chaque noeud écoute sur ce port et redirige le traffic qui arrive vers le service concerné. Le service est alors accessible depuis l'extérieur du cluster.
* un `LoadBalancer` conbfiguration évoluée qui, suivant la configuration d'un loadbalanceur sur votre cluster kubernetes ou chez votre opérateur cloud, va interagir avec l'api de celui-ci afin de répartir les connexions sur les pods qui portent le service.

#### L'ingress

Un Ingress est un objet évoluer permettant de définir des route d'accès en général en https (`https://<server-name>/<url-route>/`) aux services.

Il s'appuis sur un **IngressControler** qu'il faudra definir et déployer sur le cluster afin qu'il agisse comme un proxy offrant l'accès aux applications.

Suivant l'IngressControler déployer il pourra offrie des fonctionalités suplémentaire tel la commande de certificat **let's encrypt** ou le maintiens des sessions sur le même pod etc...

![kube-net-phys](../images/kube-net-logic.drawio.png)

## Conclusion

Vous l'aurez compris il s'agit de revoir notre méthode d'intégration d'applications afin de coller au modele kubernetes. Toute la gestion de l'infrastrcuture d'exécution est masqué par le modèle et l'api kubernetes. Nous ne parlons plus que d'ingress, service, déployment, pod, container, volumes et plus jamais de VM, système, packages etc... car tout ceci est géré par les admins kubernetes.
