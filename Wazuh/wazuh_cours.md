# WAZUH

## Sommaire :
```toc
 style: bullet
 min_depth: 1
 max_depth: 4
```

--- 

## Intro 
### ELK 
ELK est un acronyme qui désigne la stack open source utilisée pour la gestion et l'analyse des données de logs. 
1. **Elasticsearch** : Il s'agit d'un moteur de recherche et d'analyse de données distribué. 
2. **Logstash** : Il permet de collecter des données à partir de diverses sources, de les transformer en un format cohérent et de les envoyer à Elasticsearch.
3. **Kibana** : est une interface utilisateur web
### OpenSearch
AWS a créé un fork d'ELK en réponse à une embrouille suite aux changements de licence en 2021 d'Elastic.
## Wazuh
### Qu'est ce que c'est
Wazuh est un outil qui s'intègre aux deux stacks mentionnés précédemment, unifiant les fonctions suivantes :
1. **SIEM (Security Information and Event Management)** : Il s'agit d'une technologie qui facilite la collecte, l'agrégation, l'analyse et la corrélation des données de sécurité provenant de multiples sources, telles que les journaux (logs) _centralisation_
2. **XDR (Extended Detection and Response)** : corréler ces données en vue de détecter des IOC (Indicators of Compromise).

### Composants
Il est composé des éléments suivants :
1. [[#Agent]] : 
	- est installé sur l'endpoint à monitorer, 
	- il **envoi** les logs au serveur, 
	- execute des commandes et retourne les outputs au serveur
2. [[#Server]] : 
	- analyse les données reçues des agents, 
	- chaque logs passe par un [[#decoder]]
	- puis y appliques des [[#rules]]
	- génère les alertes 
	- Il peut aussi être utilisé pour une [[#Gestion centralisée]] des agents
3. [[#Indexer]] : 
	- Stocke les alertes générées par le serveur
	- Puis les indexe afin de pouvoir effectuer des recherches
5. [[#Dashboard]] : 
	- Permet une visualisation des données via une UI web

![[wazuh-components.png]]
https://documentation.wazuh.com/current/_images/wazuh-components-and-data-flow1.png

![[wazuh-architecture.png]]
https://documentation.wazuh.com/current/_images/deployment-architecture1.png

#### Indexer
L'indexeur de Wazuh (OpenSearch) fonctionne comme un moteur de recherche similaire à Google, DuckDuckGo, Yandex, etc. Il repose sur [Lucene](https://lucene.apache.org/), un logiciel open source développé par Apache.

La structure de l'indexeur se compose :
1. Du **Cluster** qui est une collection de nœuds qui travaillent ensemble.
2. Les **Nœuds (Nodes)** sont des instances qui exécutent des opérations.
3. Les **Shards** sont des partitions de données au sein d'un index, permettant une distribution efficace des données sur plusieurs nœuds.
4. Les **Index** sont des regroupements **logiques** de documents. (Mais dans ce contexte, ce sont des **index inversés** utilisés pour la recherche)
5. Les **Documents** composent les segments d'index, ce sont des enregistrements de données sous forme de fichiers JSON.

Cette structure le rend scalable surtout dans la façon dont sont gérés les index sur les nodes mais nous n'en parlerons pas ici. 

Comme mentionné précédemment, la technique d'**index inversé** est utilisée par tous les moteurs de recherche. Elle se décompose en plusieurs étapes :
1. [Tokenizing](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenizers.html) : Cette étape consiste à prendre la phrase et à la diviser en mots.
2. [Normalization](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-normalizers.html) : Chaque mot est converti en minuscules, mis au singulier, et des synonymes ainsi que des abréviations peuvent être ajoutés pour le terme original.
3. [Stop words removal](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stop-tokenfilter.html) : Cette étape consiste à retirer les mots inutiles tels que "le, la,..." (mots vides).
4. Ensuite, pour déterminer la pertinence d'un mot dans une recherche, un algorithme mathématique est utilisé que nous ne verrons pas ici. Mais cet algorithme se base sur la fréquence d'apparition du mot dans le texte, la taille du texte, ainsi que sa fréquence d'apparition dans l'ensemble de la collection de documents. Cette analyse attribue un "**poids**" au mot.

![[inverted_index.png]]
https://buildatscale.tech/content/images/2021/11/Drawing-6.sketchpad.png

Tout cela facilite la recherche et l'analyse de grandes quantités de données avec une grande rapidité (quelques millisecondes) grâce à comme nous l'avons vu :
- sa structure orientée documents plutôt que des tables et des schémas
- au lieu de rechercher directement dans le texte, il effectue la recherche dans un index.

Le moteur de recherche offre la possibilité de rechercher divers types de données via différentes méthodes :
1. **lexical** : Il maintient un tableau associant les mots aux listes des documents dans lesquels ils apparaissent.  
2. **Données numériques et de géolocalisation** : Ces données sont stockées à l'aide d'arbres BKD, également connus sous le nom d'"index Block KD-Tree".
3. **Recherche vectorielle** : Cette méthode repose sur la représentation vectorielle du sens des phrases pour trouver des éléments similaires. 


Nous avons vu en détails de la méthode d'index inversé pour le lexical, ce qui est utile dans notre contexte de SIEM. Pour en savoir plus sur les autres techniques, consulté ce [lien]([https://www.elastic.co/fr/blog/what-is-an-elasticsearch-index](https://www.elastic.co/fr/blog/what-is-an-elasticsearch-index)).

Pour effectuer des recherches **Lucene** sur l'indexeur, que ce soit Elasticsearch ou OpenSearch, par défaut, le port utilisé est 9200 : `http://localhost:9200/movies2/_search`.
1. La méthode la plus simple pour rechercher est de spécifier le **champ** avec le paramètre "q". `?q=fields.title:Star Wars`.
2. Il est possible d'effectuer des recherches plus avancées, similaires à du "dorking"
```json
{"query":{
    "bool": {
        "should": { "match": { "fields.directors": "James Cameron" }},
        "must":{ "range": { "fields.rating": {"gte":5 }}},
        "must_not":[
            {"match":{"fields.genres":"Action"}},
            {"match":{"fields.genres":"Drama"}}
        ]
}}}
```

Exemple :
1. caractère inconnu : `machine.os: w?n`
2. approximation : `machine.os: wip~1` `machine.os: wip~0.2` (0.2 plus précis que 1)
3. proximité : `description: "toto tutu"~10` (10 mots d'écart)
4. range : `response: [200 TO 503]` `response: [200 TO *]`
5. regex : `description: /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\`

#### dashboard

Wazuh dashboard permet la visualisation de nos requêtes, et son concept est semblable à celui d'une feuille de calcul Excel.

Il permet de gérer quatre types de données :
- Les **APM** (Application Performance Monitoring) sont utilisées pour surveiller et évaluer les performances des applications.
- Les **logs** enregistrent des événements et des informations textuelles essentiels.
- Les **metrics** fournissent des mesures quantitatives relatives aux performances.
- Les **events** comprennent des événements considérés comme importants ou significatifs dans le contexte de la surveillance.

Il se compose de 3 parties :
- **Discover** : représentation la plus brute de la donnée, nous pouvons y voir les `documents` traités par l'indexer en fonction du temps.
- **Visualize** : représentations graphiques de la donnée, les visualisations sont liées à un index spécifique.
- **Dashboard** : regroupement de plusieurs visualisations, celui-ci n'est pas lié spécifiquement à un index.

Nous pouvons créer des dashboard personnalisés via ces trois composants :
1. Tout d'abord, l'onglet "Discover" nous permet d'explorer les différents champs que nous pouvons filtrer et interroger. Voici quelques tips :
	1. Gardez à l'esprit l'échelle de temps située en haut à droite.
	2. Lorsque vous ajoutez des données, si de nouveaux champs apparaissent, ils ne seront pas reconnus par l'indexeur, il faut le mettre à jour l'index ("Stack Management" > "Index Pattern" > "alert*" > "Refresh").
	3. Vous avez la possibilité de sauvegarder les requêtes que vous créez pour les réutiliser dans vos visualisations.
	4. Il est également possible d'appliquer des filtres, que vous pouvez "pin" pour les conserver, permetant la transition entre les onglets en les maintenant actifs.
	5. Vous pouvez effectuer des recherches Lucene en désactivant DQL, voir la section précédente.
	6. Lors du survol des "Available fields", nous pouvons directement voir les top 5 values.
2. Une fois que nous savons ce que nous souhaitons contrôler, il faut d'abbord créer des **visualisations**
	1. Choix de l'index source `wazuh-alerts`, `wazuh-monitoring`,...
	2. Organisez les données en utilisant des `Metrics` et des `Buckets` :
		    - Les `Metrics` possèdent les options pour quantifier les données : Count, average, sum, etc
		    - Les `Buckets` sont des agrégations de données, triées en fonction des critères de recherche (IPv4 range, termes, dates, etc)
3. On peut ensuite implémenter un **dashboard** en regroupant plusieurs **visualisations**

#### Server

![[wazuh-server.png]]
https://documentation.wazuh.com/current/_images/wazuh-server-architecture1.png

Le wazuh server ets l'application qui execute tous les services :
- gestion de la connection avec les agents 
- gestion de la connection avec les hosts du cluster
- moteur d'analyse, a 
	1. la reception de log en brute > 
	2. decoder pour identifier le type d'informations (windows logs/syslog/applogs etc) + cretation en json avec les différentes key/value interessante (timestamp/ip addr/user/etc) >
	3. passe par des regles qui identifie des modèles spécifiques dans les événements décodés (failed password 3times etc) > 
	4. creation de l'alerte > 
	5. peut declencher des scripts de contremesure
- RESTful API, gestion de la conf etc
- Filebeat Il est utilisé pour envoyer des événements et des alertes à l'indexeur Wazuh. Il lit la sortie du moteur d'analyse Wazuh et envoie les événements en temps réel.

Le serveur Wazuh est l'application centrale qui assure les fonctions essentielles :
1. Gestion des connexions avec les agents.
2. Gestion des connexions avec les hôtes du cluster.
3. Moteur d'analyse :
    - Réception des logs bruts 
    - Décodage des logs pour identifier le type d'informations (Windows, Syslog, etc) puis les convertit en format JSON en extrayant les données principale (timestamp, IP de l'agent, etc)
    - Applique des règles prédéfinies pour identifier des modèles spécifiques dans les logs décodés.
    - Génère des alertes pour signaler les alertes
4. API RESTful (interaction avec le système Wazuh via des requêtes HTTP)
5. Filebeat est utilisé pour envoyer en temps réel les événements et les alertes à l'indexeur.
 
#### Agent

Les agents Wazuh collectent les donnée et les envoient au serveur. 
Les transmissions sont chiffrées symétriquement, l'échange de la clé de chiffrement est unique à chaque agent et c'est faites lors de l'enrollment, chiffré elle aussi via TLS. 

![[agent-wazuh.png]]
https://documentation.wazuh.com/current/_images/agent-architecture1.png

Voici les différente fonctionnalitées, celle jugée les plus interessantes seront détaillées plus tard :
1. security info management
    - security events > detection des patternes
    - integrity > surveillance intégrité des fichiers (comme AIDE)
2. Audit & policy mon
    - policy > ancien contrôle de sécu (remplacé par sca)
    - system > contrôle du système (process, ventilos, etc..)
    - SCA > contrôle de configuration (CIS par défaut)
3. thread detection and response
    - vulnérability > contrôle des cve dans une db
    - Mitte > recherche des techniques mitre
4. regulator compliance
    - PCI DSS > réglementation pour acteurs monétique
    - GDPR > RGPD (protection des données)
    - HIPAA > réglementation pour acteurs de la santée
    - NIST > equivalent iso27000 USA
    - TSC > information sur (dispo/integrité/confidentialité/..)

## TP
monter un wazuh > docker compose up -d + monter un agent fin du tp :D
On vous recommande d'exposer les ports de wazuh uniquement sur votre 127.0.0.1
## security events

Nous allons maintenant voir comment sont gérées chaque ligne de log par le server wazuh pour la fonctionnalitée security events, prenons pour exemple la reception de la ligne :

```bash
Feb 14 12:19:04 192.168.1.1 sshd[25474]: Accepted password for Stephen from 192.168.1.133 port 49765 ssh2
```
### pre-decoding
La première étape consiste au pre-decoding, qui correspond à l'extraction des informations principales présente dans une majorité des formats (timestamp/hostname/program name). 

```bash
timestamp: 'Feb 14 12:19:04'
hostname: '192.168.1.1'
program_name: 'sshd'
```
### decoder

Ensuite le log passe par le decoder, celui-ci ce construit de manière arborescente de façon a match tous les champs pour chaque patterne de log produit par le programme.

```bash
<decoder name="sshd">
  <program_name>^sshd</program_name>
</decoder>

<decoder name="sshd-success">
  <parent>sshd</parent>
  <prematch>^Accepted</prematch>
  <regex offset="after_prematch">^ \S+ for (\S+) from (\S+) port (\S+)</regex>
  <order>user, srcip, srcport</order>
  <fts>name, user, location</fts>
</decoder>
```

Ainsi nous récupérons les champs :
```bash
user: 'Stephen'
srcip: '192.168.1.133'
srcport: '49765'
```

### rules

Les règles représentent la dernière étape de traitement appliquée à chaque ligne de log, elles sont également construites de manière arborescente. Ces règles effectuent un traitement au niveau du "message" généré par l'application/service.

```bash
<rule id="5700" level="0" noalert="1">
  <decoded_as>sshd</decoded_as>
  <description>SSHD messages grouped.</description>
</rule>
  
<rule id="5715" level="3">
  <if_sid>5700</if_sid>
  <match>^Accepted|authenticated.$</match>
  <description>sshd: authentication success.</description>
  <group>authentication_success,pci_dss_10.2.5,</group>
</rule>
```

Lorrsque celle-ci match, elle déclenche la création d'une alerte à laquelle nous associons une description, des groupes, etc pour faciliter leur gestion et leur utilisation ultérieure dans nos dashboards.

## integrity
Le module intégrity permet de surveiller l'intégrité des fichiers, son fonctionnement est similaire à celui du logiciel A.I.D.E. 

Pour expliquer brièvement son principe de fonctionnement, il crée une base de données de référence contenant les hashs de tous les fichiers et dossiers que nous souhaitons contrôler. Cette db est utilisée comme référence, et périodiquement, nous comparons les nouveaux hashs générées avec celles de la base de référence. 

Il peut-être utilisé par exemple pour s'assurer de l'integrité du fichier XML de contrôle de la configuration via le module S.C.A. de wazuh.

## SCA 

Pour compléter la surveillance de nos agents, nous pouvons mettre en place un contrôle de configuration via le module [Security Configuration Assessment](https://documentation.wazuh.com/current/user-manual/capabilities/sec-config-assessment/how-it-works.html) en créant des fichiers XML qui contiennent des instructions. Ces vérifications peuvent inclure l'exécution de commandes système, la recherche dans des fichiers des registres, etc... puis d'évaluer leurs résultats.

exemple :
`c:systemctl is-enabled cups -> r:^enabled`

Comme pour le contrôle d'integrite des scans periodique sont effectués. Il peut être utilisé par exemple, pour contrôler un référenciel de configuration telle que le CIS benchmark

## thread detection and response
### vulnérability 

Wazuh possède un module de détection des vulnérabilités qui fonctionne globalement de la manière suivante :
1. Les agents collectent la liste des applications (et version) installées sur leur système et transmettent ces informations au serveur.
2. Ces données sont ensuite enregistrées en local dans des bases de données SQLite.
3. Simultanément, le serveur Wazuh crée une base de données globale des vulnérabilités en utilisant des sources telles que le NVD (National Vulnerability Database).
4. Ensuite, il effectue une comparaison croisée des données entre les deux bases de données, ce qui permet de détecter les vulnérabilités potentielles.
### Mitre

Le MITRE est une base de données qui recense les techniques courantes d'attaque utilisées par les groupes de menace (APT), il permet :
1. L'analyse et le suivi de l'évolution des TTP (Techniques, Tactics, and Procedures).
2. La comparaison des TTP entre différents attaquants.
3. La hiérarchisation de la détection des attaques.
4. La possibilité de réaliser des simulations de menace.
5. La facilité de partage d'informations.
    
Pour la blueteam, il est particulièrement utile pour établir un processus d'amélioration (une certaine maturité en cybersécurité est nécessaire). Voici un exemple de processus :
1. Sélectionner un TTP sur [ATT&CK](https://attack.mitre.org/)
2. Choisir un test correspondant sur [Atomics](https://github.com/redcanaryco/atomic-red-team/tree/master/atomics)
3. Exécuter le test
4. Analyser les résultats. 
	- On peut utiliser l'outil [DeTT&CT](https://github.com/rabobank-cdc/DeTTECT) pour analyser nos sources de données, y compris les fichiers de logs que nous utilisons. 
	- Si non, il est possible de créer manuellement nos couches d'attaque en utilisant [Navigator](https://mitre-attack.github.io/attack-navigator/)
5. Établir un lien entre l'attaque et la défense [attack-dao-defend](https://d3fend.mitre.org/img/attack-dao-defend.png)
6. Amélioration du SIEM grâce au TTP que nous savons non detectés, ainsi que la maturité du S.I. grâce au module [D3FEND](https://d3fend.mitre.org/).

Le framework est incorporé dans Wazuh, et lié les règles d'alerte aux différentes techniques, ce qui facilite la récupération d'informations directement dans les dashboards.

# regulator compliance

Wazuh intègre plusieurs modules de conformité réglementaire. Ces modules sont conçus pour faire correspondre les exigences obligatoires des normes et démontrer qu'elles sont prises en compte à l'aide de dashboard et d'indicateurs.

Exemple : 

Wazuh permet de se conformer à plusieurs aspects du RGPD et de démontrer une conformité efficace via ses dashboards.

Rappel :
Le RGPD, est une réglementation pour garantir plusieurs droits fondamentaux aux individus concernant leurs données personnelles. Il est entré en vigueur le 25 mai 2018 dans l'UE et qui peut entraîner des amendes allant jusqu'à 4 % du chiffre d'affaires.


1. Le droit d'être informé : il assure la transparence quant à l'utilisation des données personnelles de l'individu.
2. Le droit d'accès : il permet à l'individu d'accéder à ses données personnelles et de comprendre comment elles sont utilisées.
3. Le droit de rectification : il autorise l'individu à faire corriger ses données personnelles si elles sont inexactes ou incomplètes.
4. Le droit à l'effacement : il accorde à l'individu le droit de faire supprimer ses données personnelles.
5. Le droit à la limitation du traitement : il permet de conserver les données personnelles de l'individu sans les traiter.
6. Le droit à la portabilité des données : il offre la possibilité d'obtenir une copie des informations stockées sur l'individu.
7. Le droit d'opposition : il donne le droit à l'individu de s'opposer au traitement de ses données personnelles.
8. Le droit de ne pas être soumis à une prise de décision automatisée et au profilage : il donne le droit de s'opposer aux décisions automatisées basées sur les données personnelles.
    
## Gestion centralisée

Il est possible d'effectuer une gestion centralisée de la configuration. 
Par défaut, il n'y a qu'un seul groupe, mais on peut placer les agents dans un ou plusieurs groupes. On peut alors définir des configurations spécifiques à appliquer à chaque groupe, et chaque agent mergera celles des groupes auxquels il appartient.

Exemple :
- Création d'un groupe web_serveurs, 
- Ajouter tous les serveurs web aux groupes
- On pourra alors modifier la listes des fichiers de logs locaux que nous voulons surveiller

La configuration active, résultant de la fusion de toutes les configurations, est stockée dans `/var/ossec/etc/shared/agent.conf`

Il est possible de faire des configurations très spécifique en utilisant des conditions dans les balises. 
Exemple : `<agent_config name='debian'>`

Mais pour permettre la gestion centralisée, il est nécessaire que le serveur manager puisse envoyer des commandes système aux agents. Personnellement, je préfère éviter cette feature et utiliser Ansible à la place. Mais en fonction de la taille du parc, des processus de vos entreprises, du nombre d'agents, etc.. l'outil peut-être très interessant.

Wazuh fournit aussi plusieurs binaire dans `var/ossec/bin` sur le manager pour la gestion des agents (update/delete/etc)
