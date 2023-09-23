# Gestion de la disponibilité

## Présentation

Dans un contexte de forte contractualisation autour de la gestion des services (y compris en interne), le fournisseur responsable du Maintien en Conditions Opérationel (MCO) d'un infrastructure de service doit s'engager sur un niveau de disponibilité de celui-ci, le SLA (Service Level Agreement) défini précisément cet engagement **négocié** avec le client.

## Niveau de service

A ne pas confondre :

- SLA : c'est l'accords sur la gestion de service dans sa globalité entre le client et son fournisseur.
- SLO : (O pour Objective) c'est une des mesure définie dans le SLA en terme de bonne pratique ces mesure doivent être : Atteignables, Mesurables, Compréhensibles, Significatives, Contrôlables, Abordables, Mutuellement acceptables. (On devra alors préciser comment on la mesure)
- SLR : Niveau de service requis, notamment pour un sous service requis par le service en lui même et nécessaire au maintien du service.
- SLM : Service level Managment, c'est la gestion de ce niveau de service (le sujet de ce document) ou comment on s'assure que le niveau de service est conforme au SLA

**Spécifications de niveau de services :**

- disponibilité : c'est un taux de temps ou le service ciblé est disponible. Il conviendra d'exclure les maintenances planifiées et si possible d'admettre une fenêtre d'ouverture du service.
- fiabilité : on mesure en général taux de réussite sur une opération précise
- le temps de réponses : est défini avec une limite de temps et un taux
de réponse obtenue dans un délai inférieur à cette limite.
- serviceability : temps de rétablissement du service après une défaillance constaté. Cette valeur peut être utilisée pour la durée admisible de bascule du service ou de retour arrière sur une opération.

Au niveau opérationnel on définira plutot :

- Temps de détection d'une défaillance (permet de definir la fréquence de surveillance)
- Temps de prise en compte de celle-ci (plus précisément le temps pris pour enregistrer l'incident)
- Temps de rétablissement

## Gestion des sinistres

A ne pas confondre :

- PCA : le Plan de Continuité d'activité est défini globalement au sein de la structure, un chapitre est dédié au Plan de continuité de l'infrastructure de services
- PRA : le plan de reprise de l'activité ou comment suite à un sinistre majeure on reprend l'activité

la différence entre ces deux terme est l'objectif visé : le PRA admet un arrêt complet alors que le PCA de l'admet pas.
Exemple: le PCA peut admettre que l'entreprise traite des commandes par fax ou par téléphone qui seront par la suite saisie dans le système d'information un fois remis en oeuvre à l'issue du PRA.

**Spécifications des plan de reprise et de continuité :**

- la DMIA : Durée Maximum d'Indisponibilité Admissible (RTO : Recovery Time Objective)
- la PDMA : Perte de Donne Maximum Admissible (ou RPO pour Recovery Point Objective)

Ces deux éléments permetent entre autre de préciser le besoin relatif aux fréquences de sauvegardes et au temps de restauration.

![https://commons.wikimedia.org/wiki/File:RTO_RPO.gif](../images/RTO_RPO.gif)

## La redondance

Le niveau de service est pris en compte dés la conception d'une infrastructure de service. Il conviendra principalement de supprimer les **S**ingle **P**oint **O**f **F**ailure via la mise en oeuvre de redondance et de plan de bascule.

### Au niveau client

Le service DNS est le meilleur exemple la bascule est géré au niveau du resolver (donc le client dns)
resolv.conf :

```bash
options timeout:1 
options attempts:1 
nameserver 10.10.8.8
nameserver 10.10.4.4
```

Cette configuration permet un interrogation du second serveur de noms après une seconde sans réponse du premier serveur, le mode est plutot dégradé car une résolution de nom en une seconde est trés loing d'être suffisant (un cache dns sera nécessaire).

### Au niveau d'un host

#### redondance réseaux

A voir en cours réseaux pour l'infrastructure réseaux (OSPF iBGP etherchannel etc... ). Du coté système la redondance sur les connections réseaux des hosts physique nous mettrons éventuelement en place du [bonding](./config-net-advanced.md#Bonding)

#### redondance des accès au stockage

Bien sur nous utiliserons du raid matériel, logicel ou encore le mode mirroir sur les volume LVM pour le stockage locale.

En revanche dans le cadre d'un stockage SAN il conviendra de configurer proprement le **multipathing** qui consiste en une double (voir quadruple) configuration du stockage SAN qui sera vue comme une seul disque mais accèssible depuis plusieurs carte HBA et liaison au stockage.

![moultipath](../images/Multipath-scsi.png)

Comme pour la redondance réseaux le kernel linux a un module pour ca : `dm-multipath` qui nécéssitera un configuration fine (notammen pour l'iscsi). Cependant le multipathing est fréquement directement géré par les drivers de carte HBA (Fiber Channel FC) qui sont rarement ouvert, on suivra la doc propriétaire.

#### Alimentation électriques

La plupart des serveurs et appliances dispose (souvent en option!) d'une alimentation secondaire. Il convien de disposer de cette alimentation secondaire et de la branche sur une seconde sources d'alimentation (souvent proposer en option sur un rack).

#### La redondance matériel

Une panne matérielle sur un host est l'incident qui ne peu pas être contourné par une configuration système. Cette catégorie d'incident nous impose de bénéficier d'un support matériel. La garantie apporté par le support (temps d'intervention sur site) sera à prendre en compte dans le niveau de service fourni. Dans le pire des cas, le matériel n'est pas sous garantie il conviendra alors de disposer de matériel de spare pour assurer un retour rapide au mode nominale.

### Le clustering

Le **Clustering** peut être intégré dans les solution de virtualisation et les 'appliances' matériel (firewall, switch L4-L7, SAN, NAS mais on est quand même loin de l'open source). Les pannes matériels occasionnent alors une bascule sur le secondaire rapidement permettant de redémarrer le service et de réparrer le noeud défaillant.

Dans sa définition première un cluster est un ensemble de hosts qui colaborent pour la production d'un service.

- Un service redondé : la HA
- Un service distribué : Le loadbalancing
- Une ferme de calculs : la répartition de la charge est géré au niveau applicatif.

#### le cluster HA

Les données sont sur un stockage SAN accessible depuis les deux noeud du cluster

Un system de messages inter-noeud permet a chacun de définir un état des autres noeuds (heartbeat, **corosync**) et de définir un consenssus à partir d'un quorum (nombre de voix minimum pour être élu master) pouvant être basé sur des écriture sur disque sur un des volumes partagés (le disque de quorum)

L'intégrité des données est géré par du **fencing** aussi nommé **stonith** (**S**hoot **T**he **O**ther **N**ode **I**n **T**he **H**ead) permetant d'assurer au master qu'il est le seul noeud disposant des accès en écriture sur les volumes (kill du noeud défaillant, ou coupure des accès SAN).

Un ressource manager (Exemple: **pacemaker**) qui gère l'arrêt et le démarrage des ressources de façon ordonnée afin de remettre le service up sur le nouveau noeux.

> ressource intéressante avec des exemples de configurations de cluster opensource <https://clusterlabs.org/>

#### la VIP

L'une des ressources géré par un cluster est la VIP pour Virtual IP, c'est à dire, l'adresse ip qui porte le service. Celle-ci est capable de basculer d'un noeud à l'autre du cluster avec le service lui permettant de survivre à la défaillance du noeud.

[keepalived](./keepalived.md) est un daemon sous linux permettant de construire un cluster HA simple basé sur deux nodes et une vip (vrrp). Il offre de plus des solutions de loadbalancing niveau réseaux. C'est une solution simple et efficace pour mettre un service en redondance.

#### Le Stockage

Les solutions de stockage disposent d'une redondance intégré :

- Controleur redondé
- Double alimentation électrique
- Controleur réseaux (bonding)
- Les disques sont accéssible par les deux controleur
- Les pool de stockage sont capable de géré la panne d'un ou plusieurs disques (RAID5, RAIDdp, etc...)
- La baie inclu un ou des disques de spare disponible pour remplacer immédiatement un disque en panne.

#### La réplication

Si on n'utilise pas de stockage SAN ou NAS disposant de redondance, il conviens de répliquer la donnée afin que celle-ci reste disponible pour les plan de reprise

La plupart des systemes de gestion de base de données (les SGBD) proposent des solutions de réplications.

La [réplication Mysql](./mysql-replication.md) est simple à mettre en oeuvre et offre beaucoup de schéma de réplications possibles.

Les solutions modernes de gestion de données propose un stockage distribué. Le sharding consiste en la division de la donnée en data set qui sont réparti et répliquer sur plusieur hosts assurant à la fois de la redondance et une distribution de la charge. Celle-ci a en revanche un cout important en terme de ressources et de complexité des alrorythmes de gestion. (exemple de solutions distribué : Couchbase, Elasticsearch, MongoDB)

> [présentation du sharding pour mongoDB](https://docs.mongodb.com/manual/sharding/)

#### Le Consensus

Les cluster de données modernes (Ceux devant ordonnancer des opérations associées à des fragments de données répliquer sur pluseur hosts) nécessitent la mise en place d'un algorythme de consensus. Celui-ci permet de garantir que le groupe de host maitrise l'intégrité des données.

raft est un algorithme de consensus reconnu et largement utilisé : [visualisation raft](http://thesecretlivesofdata.com/raft/)

Chaque base de données répliquer admet son propre algo de consensus on poura consulter en exemple celui des bases de données [redis](https://redis.io/topics/cluster-spec) et [ElasticSearch](https://www.elastic.co/blog/a-new-era-for-cluster-coordination-in-elasticsearch)
