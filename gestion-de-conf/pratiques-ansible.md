# Pratiques ansible

* [Organisation du code](#organisation-du-code)
  * [La plateforme playbook](#la-plateforme-playbook)
* [Pratiques de developement de Rôles](#pratiques-de-developement-de-rôles)
  * [gestion des variables](#gestion-des-variables)
    * [Variables nécessaires](#variables-nécessaires)
    * [Variables prédéfinies](#variables-prédéfinies)
    * [Variables déduitent](#variables-déduitent)
  * [Les import et include](#les-import-et-include)
  * [les tags](#les-tags)
  * [Les tests de rôles](#les-tests-de-rôles)
* [L'inventaire dynamique](#linventaire-dynamique-avec-netbox)
  * [Installation de netbox avec ansible](#installation-de-netbox-avec-ansible)
  * [Configuration netbox](#configuration-netbox)
  * [Configuration ansible](#configuration-ansible)
  * [Les config contexts](#les-config-contexts)
* [Conclusion](#conclusion)

## Organisation du code

S'il gère une grosse partie de l'infrastructure, le code ansible deviens rapidement complexe et donc difficile à maitenir.

On dévelopera des rôles autonomes que l'on reversera eventuelement à la communauté ansible_galaxy en réclamant votre namespace sur github.

* Les rôles disposent de leur propre dépot
  * Versionné via des tag git
  * Contenant :
    * Un fichier readme présentant le role et comment l'utiliser
    * Ses tests
* Un dépot "ansible" représentera alors une infrastructure ou une partie d'infrastruture gérée.
  * le dépot ansible sera sécurisé et contiendra :
    * L'inventaire des hosts
    * Des variables Locales
    * Des playbooks
    * Un fichier requierement.yml listant les rôles, leur dépot et la version utilisé

La gestion des changements sur la platforme consistera en :

* Le re-déploiement du playbook en mode --check pour valider la cohérence de la configuration avant déploiement.
* La récupération de la nouvelle version du dépot
* Le récupération des nouveaux rôles ou nouvelles versions de rôles via ansible-galaxy
* Le re-déploiement du playbook

Elle est donc automatisable.

> Il conviendra dans ce cas de disposer d'un environement de stagging permettant de valider le changement, cela peu se faire au travers de l'utilisation d'un autre inventaire.

### La plateforme playbook

A l'usage le débugage et l'audit d'un dépot ansible utilisant les hosts vars est complexe et surtout fastidieux.

Afin d'augmenter la lisibilité du codce ansible, un playbook pourrais représenter une platforme de notre infrastructure dans son ensemble. Il listerais les hosts de l'infrastructure, les variables necessaire aux roles a déployer puis les roles.

contrainte importante :

* Dans l'inventaire les **inventory_hostname contiennent le nom du role**
* Cela necessite d'appliquer les pratiques sur les roles définies ci-après

Exemple:

```yaml
- name: platforme plf
  hosts: vm_role1_1, vm_role1_2, vm_role2_1, vm_role2_2

  vars_files:
    - var/vaulted_vars.yml

  vars: 
    - role1_serverid:
      vm_role-1_1: 21
      vm_role-1_2: 22
    - role1_prod_network: 192.168.56.0/24

  roles:
    - role: role1
      when: inventory_hostname is match('role1')
    - role: role2
      when: inventory_hostname is match('role2')
```

Nous disposons ainsi d'une vision complète de la platforme en un seul fichier.

* toute l'instanciation est définie via les hosts et les variables
* toute la complexité du code est déplacé dans des roles réutilisable et testés.

## Pratiques de developement de Rôles

### Documentation

Un fichier `README.md` sera positioné à la racine du rôle.

Il permettra d'expliquer comment utiliser ce rôle dans un playbook et notamment de préciser :

* Quelle variables devras être définie
* Quel [tag](#les-tags) est utilisable et ce qu'il permet de faire
* Comment le role peu être paramétré et les cas d'usage qu'il couvre.

### Gestion des variables

Nous allons préfixer nos variables, celles définies et utilisées dans le rôle par le nom du rôle. Cela nous permetra de retrouver facilement là ou la variable est utilisée et pour quelle raison est est mise en place.

Nous distingons 3 types de variables de rôles et nous les documentons par types

* les variables nécessaires, ce rôle ne peu être déployé sans que ces variables soient définient. elle ne disposent pas de valeur par défaut car cela n'aurais pas de sens. (exemple: un server_name de site web)
* Les variables prédéfinie : elles sont définies dans le fichier defaults/main.yml elles permettent de limiter le nombre de variables à spécifier tout en permetant aussi une surcharge par ailleurs. (exemple le parametrage par défaut d'un service réseaux)
* Les variables déduitent, ces variables sont en fait des templates de variable qui seront évaluer pendant l'exécution. Cela permet de récupèrer l'adresse ip necessaire au template de configuration d'un service réseaux.

#### Variables nécessaires

Elle seront testées en début d'exécution du rôle avec  `ansible.builtin.assert`

Exemple :

```yaml
- name: is role_variable well defined
  ansible.builtin.assert:
    that:
      - role_variable is defined
      - role_variable is string
  quiet: true
```

Les secrets seront aussi forcément stocké à l'extérieur du roles et feront parti des variables necessairement définies.

En revanche elles seront concervées dans un fichier de variable chiffré avec l'outil ansible-vault. ce fichier sera donc présent avec l'inventaire et le playbook (par exemple dans le dossier vars/ situé à coté du playbook)
On l'utilisera comme ceci :

```bash
$ cat role_vaulted_vars.yml
---
secret: 53cR3t
```

il est alors possible de le chiffrer

```bash
$ ansible-vault encrypt role_vaulted_vars.yml
New Vault password:
Confirm New Vault password:
Encryption successful
to view vaulted vars
$ ansible-vault view role_vaulted_vars.yml
Vault password:
---
secret: 53cR3t
```

Coté tasks on utilisera l'argument de taches `no_log: true` afin de s'asurer que les logs d'exécution n'afficherons pas le secret

```yaml
    - name: Ensure API key is present in config file
      ansible.builtin.lineinfile:
        path: /etc/app/configuration.ini
        line: "API_KEY={{ api_key }}"
      no_log: True
```

A l'exéction on utilisera l'option --ask-vault-pass des commandes ansibles ; La clef de déchiffrement sera alors demander afin de dechiffrer les variables avant d'effectuer l'action.

Il est aussi possible de definir dans la configuration la position d'un fichier contenant ou retournant le mot de passe : `vault_password_file = ~/.ansible-vault-pass` (dont les accès seront bien sur restreints)

#### Variables prédéfinies

Les variables prédéfinies du roles sont définies dans le fichier **defaults/main.yml**, elles sont en générale lié au produit géré par le rôle.

Si des valeurs de variables dépendent de la version d'OS sur lequel est déployé le role on définiera une tache, en générale au début des tasks tel que :

```yaml
- name: Gather OS specific variables
  include_vars: "{{ item }}"
  with_first_found:
    - "{{ ansible_distribution|lower }}-{{ ansible_distribution_version }}.yml"
    - "{{ ansible_distribution|lower }}-{{ ansible_distribution_major_version }}.yml"
    - "{{ ansible_distribution|lower }}.yml"
    - "{{ ansible_os_family|lower }}.yml"
```

et des fichiers dans vars/

* redhat
* debian
* centos-7
* debian-10.2
* ...

Le parametre with_first_found va, comme son nom l'indique, prendre le premier fichier qu'il trouve dans la liste.
Cela nous permet de définir une règle dans le fichier le plus bas (Ex : redhat.yml) et plus tard, lors des test ou de la maintenance du rôle, definir des exceptions a cette règle sans modifier la règle de base.

#### Variables déduitent

le role vas de lui même calculer des variables, dans les facts ou par déduction à partir d'autres variables. L'objectif est de réduire le nombre de variable necessaire et ainsi faciliter l'utilisation du rôle.

Exemples :

**1 - variable par hosts :**

Afin d'**éviter les hosts_var d'inventaire** complexe à maintenir on peu utiliser un tableau de variables dont la clef et le nom du host:

Dans le playbook

```yaml
hosts: node1, node2

  vars: 
    - role_variabledehost:
      node1: valeurnode1
      node2: valeurnode2
```

dans vars/main.yml

```yaml
variabledehost: "{{ role_variabledehost[inventory_hostname] }}"
```

**2 - récupération des ip du host :**

pour recupèrer l'adresse ip et l'interface du host associé à un certain réseau; (le réseaux sera alors définie dans une variable necessaire)

dans le playbook:

```yaml
  vars:
    - role_prod_network: 192.168.56.0/24

```

dans vars/main.yml

```yaml
  role_prod_ip: "{% for iface in ansible_interfaces|sort %}{% if vars.ansible_facts[iface]['ipv4'] is defined and vars.ansible_facts[iface]['ipv4']['address'] | ipaddr(role_prod_network) %}{{ vars.ansible_facts[iface]['ipv4']['address'] }}{% endif %}{% endfor %}"
  role_prod_dev: "{% for iface in ansible_interfaces|sort %}{% if vars.ansible_facts[iface]['ipv4'] is defined and vars.ansible_facts[iface]['ipv4']['address'] | ipaddr(role_prod_network) %}{{ vars.ansible_facts[iface]['device'] }}{% endif %}{% endfor %}"
```

**3 - récupération d'ip d'un autre host :**

On peu pour un cluster définir les roles des hosts impliqués dans le playbook

```yaml
  role_network: 192.168.56.0/24
  role_master: node1
  role_slave: node2
```

puis déduire l'ip de l'autre noeud du cluster dans vars/main.yml :

```yaml
role_other_node: "{% if inventory_hostname == role_master %}{{ role_slave }}{% elif inventory_hostname == role_slave %}{{ role_master}}{% endif %}"
role_other_ip: "{% for iface in hostvars[role_other_node].ansible_interfaces|sort %}{% if hostvars[role_other_node].ansible_facts[iface]['ipv4'] is defined and hostvars[role_other_node].ansible_facts[iface]['ipv4']['address'] | ipaddr(role_network) %}{{ hostvars[role_other_node].ansible_facts[iface]['ipv4']['address'] }}{% endif %}{% endfor %}"
```

**4 - récupération d'ip d'un groupe de hosts :**

Dans le playbook on affecte des roles au host en fonction du fait que leur nom contiene le nom du role :

```yaml
hosts: vm_role1_1, vm_role1_2, vm_role2_1, vm_role2_2

roles:
  - role: role1
    when: inventory_hostname is match('role1')
  - role: role2
    when: inventory_hostname is match('role2')
```

Dans le run, chacun des host se vera déployé l'un des deux rôles.

Dans les variables du role1, on vas déduire la liste des host sur lesquels on déploie le role2 (on utilise la variable play_hosts), puis rechercher les ips de ces hosts dans certains réseaux :

```yaml
role1_role2_hosts: "{{ play_hosts | map('regex_search','.*role2.*') | select('string') | list }}"
role1_role2_priv_ips: "{% for node in role1_role2_hosts %}{% for iface in hostvars[node].ansible_interfaces|sort %}{% if hostvars[node].ansible_facts[iface]['ipv4'] is defined and hostvars[node].ansible_facts[iface]['ipv4']['address'] | ipaddr(role1_role2_prod_network) %}{{hostvars[node].ansible_facts[iface]['ipv4']['address'] }}{% endif %}{% endfor %}{% if not loop.last %}_{% endif %}{% endfor %}"
```

la variable role1_role2_priv_ips sera alors de la forme ip1_ip2_ip3

Nous pouvons alors dans les tasks faire un loop sur un split de ces variables :

```yaml
  loop: "{{role1_role2_priv_ips.split('_') }}"
```

Nous traiterons les adresses ip du réseaux de prod de tous les hosts qui dispose du roles2 et nous pourront les utiliser pour, par exemple, coder les règles firewall sur le role1.

### Les import et include

Afin d'organiser les taches nous pourrons dédier un fichier tache a certaines taches puis dans le main.yml inclure les fichier taches un par un ou au travers de conditions.

Exemple de fichier task/main.yml:

```yaml
- import_tasks: validate_variables.yml

- name: Gather OS specific variables
  include_vars: "{{ item }}"
  with_first_found:
    - "{{ ansible_distribution|lower }}-{{ ansible_distribution_version }}.yml"
    - "{{ ansible_distribution|lower }}-{{ ansible_distribution_major_version }}.yml"
    - "{{ ansible_distribution|lower }}.yml"
    - "{{ ansible_os_family|lower }}.yml"

- include_tasks: "install_packages_{{ ansible_pkg_mgr }}.yml"

- include_tasks: configure.yml
```

import vs include : Les **imports** sont préprocessé et sont donc **statique** durant l'exécution du playbook. Les **include** seront traité pendant l'exécution et restent **dynamique**. L'import task échoura pendant le preprocessing s'il utilise une variable qui n'est pas encore connue.

Aussi afin de développer un role fonctionnel pour plusieurs distributions plus simplement, on pourra definir des actions spécifiques à certaines versions de distributions.

```yaml
- name: include OS specific tasks
  include_tasks: "{{ item }}"
  with_first_found:
    - "spec_{{ ansible_distribution|lower }}-{{ ansible_distribution_version }}.yml"
    - "spec_{{ ansible_distribution|lower }}-{{ ansible_distribution_major_version }}.yml"
    - "spec_{{ ansible_distribution|lower }}.yml"
    - "spec_{{ ansible_os_family|lower }}.yml"
    - "spec_default.yml"
```

cette partie du role dépendra de l'os sur lequel le role est déployé.

### Les tags

Les tags sont des mots cléfs associés à des taches, des roles et même des plays ansible. Ils permettent de regrouper un ensemble d'opérations de configuration afin de se restreindre à celles-ci au moment du run du playbook.

On regroupera les taches :

* qui déploie les configurations de l'environement d'hébergement
* qui installe les composants systemes socle
* qui les configure
* et enfin qui déploie les applicatifs spécifiques

Ils sont principalement positionné sur une tache comme l'un de ses arguments tel un condition :

```yaml
- name: configure the component
  ansible.builtin.template:
    .../...
  tags: config
```

Ainsi il sera possible de reconfigurer les briques systeme sans toucher le reste de la platforme.

A l'execution on filtrera les actions de configuration avec les option `--tags` et `--skip-tags`:

* Sélectionera les opérations associé à un tag avec `--tags letag`
* Evitera les action de certains tags avec `--skip-tags [untag, unautre]`

On pourra aussi utiliser des tags par défaut :

* A l'exécution les tags : `all`, `tagged` et `untagged`
* Au development les tags : `nevers`, `always`

> la doc <https://docs.ansible.com/ansible/latest/user_guide/playbooks_tags.html>

### Les tests de rôles

On placera dans le dépot de chaque role un Vagrantfile déployant un environnement de test et un playbook de testant le déploiement du rôle et le résultat du déploiement.

Cela permet de faciliter les tests des évolutions du rôle pendant le dev. Cela est aussi automatisable.

> L'outil ansible molecule permet d'automatiser des scenarios de test ansible, il est très complet et facilement parametrable. doc: <https://molecule.readthedocs.io/en/latest/index.html>

## L'inventaire dynamique avec netbox

il existe des plugins ansible permettan d'utilise un inventaire dynamique, l'application **netbox** en est un.

### Installation de netbox avec ansible

Déployez avec ansible l'application netbox en version **3.0.5** sur le host master

**Depuis le host master et le dossier /opt/src** : Installez les roles necessaire avec ansible-galaxy

```bash
cfg-master@master:/opt/src$ ansible-galaxy install geerlingguy.postgresql davidwittman.redis lae.netbox
Starting galaxy role install process
- downloading role 'postgresql', owned by geerlingguy
- downloading role from https://github.com/geerlingguy/ansible-role-postgresql/archive/3.2.1.tar.gz
- extracting geerlingguy.postgresql to /home/cfg-master/.ansible/roles/geerlingguy.postgresql
- geerlingguy.postgresql (3.2.1) was installed successfully
- downloading role 'redis', owned by davidwittman
- downloading role from https://github.com/DavidWittman/ansible-redis/archive/1.2.9.tar.gz
- extracting davidwittman.redis to /home/cfg-master/.ansible/roles/davidwittman.redis
- davidwittman.redis (1.2.9) was installed successfully
- downloading role 'netbox', owned by lae
- downloading role from https://github.com/lae/ansible-role-netbox/archive/v1.0.2.tar.gz
- extracting lae.netbox to /home/cfg-master/.ansible/roles/lae.netbox
- lae.netbox (v1.0.2) was installed successfully
```

Installez la dependance python pour gèrer postgres avec ansible

```bash
sudo apt-get install python-psycopg2
```

Récupèrez le playbook fournis en example dans le role lae.netbox

```bash
[cfg-master@master src]$ cp ~/.ansible/roles/lae.netbox/examples/playbook_single_host_deploy.yml ./conf_netbox.yml
```

Editez le afin d'ajouter la variable suivante aux variable existantes:

```yaml
    netbox_stable_version: 3.0.5
```

Puis déployez l'application netbox

```bash
cfg-master@master:/opt/src$ ansible-playbook -i master, conf_netbox.yml
```

### Configuration netbox

Connectez vous sur l'url <http://192.168.56.43/> avec le compte admin/netbox

dans l'application il faudra créer :

* un site (mylaptop)
* un manufacturer (virtualbox)
* un type de device (vm) et lui ajouter une interface
* un device_role (master,slave)
* les hosts de votre infra avec :
  * le site manufacturer device_type et device_role
* Les ip des hosts de votre infra que vous associerez à vos hosts **en ip primaire**

Il faudra dans l'interface d'admin django **créer un compte (full admin) et un token** que vous reporterez dans le fichier d'inventaire dynamique afin de pouvoir l'utiliser (un peu plus bas dans ce document).

### Configuration ansible

Vous déployez alors la collection netbox pour Ansible :

```bash
cfg-master@master:/opt/src$ ansible-galaxy collection install netbox.netbox
Starting galaxy collection install process
Process install dependency map
Starting collection install process
Downloading https://galaxy.ansible.com/download/netbox-netbox-3.5.1.tar.gz to /home/cfg-master/.ansible/tmp/ansible-local-841004qjszrf/tmpwbg20ses/netbox-netbox-3.5.1-6rd1_yzl
Installing 'netbox.netbox:3.5.1' to '/home/cfg-master/.ansible/collections/ansible_collections/netbox/netbox'
netbox.netbox:3.5.1 was installed successfully
cfg-master@master:/opt/src$ 
```

> Vous disposer maintenant du plugin d'inventaire netbox et de modules Ansible permettant d'interagir avec le référenciel netbox. doc : <https://docs.ansible.com/ansible/latest/collections/netbox/netbox/index.html>

Afin d'activer le plugin d'inventaire netbox dans ansible, vous ajouterez dans votre configuration ansible :

```ini
[inventory]
enable_plugins = netbox.netbox.nb_inventory, auto, host_list, yaml, ini, toml, script
```

### L'inventaire

L'inventaire ne sera plus un fichier host mais un fichier yaml explicitant l'appel à l'api :

dynamic-inv.yml :

```yaml
plugin: netbox.netbox.nb_inventory
api_endpoint: http://localhost:80
validate_certs: False
token: xxxxxxxxxxxxxxxxxxxxxxx
config_context: True
compose:
  ansible_host: name
group_by:
  - device_roles
query_filters:
  - status: active
device_query_filters:
  - has_primary_ip: 'true'
```

Cet inventaire dynamique peu maintenant être appelé à l'exécution d'Ansible avec l'argument `-i`.

Je préfère génerer un inventaire local avec la commande ansible-inventory et le réutiliser par la suite afin de limiter les appels api vers netbox pour chaque commande ansible.

```bash
cfg-master@master:/opt/src$ ansible-inventory -i dynamic-inv.yml --list -y >> hosts_netbox.yml
cfg-master@master:/opt/src$ ansible -i hosts_netbox.yml slave1 -m ping
slave1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
...
```

### Les config contexts

Dans le menu Netbox tout en bas dans other, le dernier c'est les config contexts
Les configs context sont des dictionaires json associé à des éléments organisationnel de l'inventaire: device_role, device_type, tenant, site, régions, etc...

Permettant de spécifier des variables d'inventaires utilisable ensuite dans les playbooks.

Exemple :

On configure:

* le context default, non associé avec le poid 1000 et le contenu :

  ```json
  {
      "context": "default",
      "security_level": "0"
  }
  ```
  
* le context role_master, associé au device_role master avec le poid 1010 et le contenu :

  ```json
  {
      "context": "master",
      "security_level": "9"
  }
  ```

* le context role_slave, associé au device_role slave avec le poid 1010 et le contenu :

  ```json
  {
      "context": "slave",
      "security_level": "3"
  }
  ```

si on rafraichi l'inventaire on retrouvera les valeurs.
les context json son merger avec pour règle le poid le plus haut prévaux sur le plus faible.

```bash
cfg-master@master:/opt/src$ ansible-inventory -i dynamic-inv.yml --list -y > hosts_netbox.yml
cfg-master@master:/opt/src$ ansible -i hosts_netbox.yml all -m debug -a msg="{{ config_context[0]['security_level'] }}"
master | SUCCESS => {
    "msg": "9"
}
slave1 | SUCCESS => {
    "msg": "3"
}
slave2 | SUCCESS => {
    "msg": "3"
}
cfg-master@master:/opt/src$ ansible -i hosts_netbox.yml all -m debug -a msg="{{ config_context[0]['context'] }}"
master | SUCCESS => {
    "msg": "master"
}
slave1 | SUCCESS => {
    "msg": "slave"
}
slave2 | SUCCESS => {
    "msg": "slave"
}
```

## Conclusion

Via l'application de ces pratiques il est possible de mettre en place

* Une gestion global d'un parc en utilisant un inventaire dynamique et en exécutant automatiquement des playbook d'initialisation system afin de déployer des éléments de configuration globaux (notament pour la gestion de la sécurité)
* Une gestion des briques logiciel via le dévelopement et la maintenance de rôles réutilisable
