# Code Ansible

* [Preambule](#preambule)
  * [L'idempotence](#lidempotence)
  * [Le YAML](#le-yaml)
* [Les *playbooks*](#les-playbooks)
  * [Exemple](#exemple)
  * [Le Run d'un playbook](#le-run-dun-playbook)
  * [Les *tâches*](#les-tâches)
    * [Les conditions](#les-conditions)
    * [with_items](#with_items)
    * [Les *register*](#les-register)
    * [Configuration de retour](#configuration-de-retour)
    * [A retenir](#a-retenir)
  * [Le templating](#le-templating)
* [Les *rôles*](#les-rôles)
  * [Structure d'un rôle](#structure-dun-rôle)
* [Les variables](#les-variables)
  * [Les variables d'inventaires](#les-variables-dinventaires)
  * [Les facts](#les-facts)
  * [Précedence des variables](#précedence-des-variables)
* [Conclusion](#conclusion)
* [exercice pour valider votre comprehension](#exercice-pour-valider-votre-comprehension)

## Preambule

Pour gérer la configuration d'une infrastructure, nous devons definir l'état attendu ainsi que les actions à réaliser pour atteindre cet état.

### L'idempotence

L'idempotence d'une action signifie que sont résultat sera le même quelque soit le nombre de fois ou elle est exécuté.

exemple : l'ajout d'une entrée dans le fichier /etc/hosts n'est pas une action idempotente. En revanche l'ajout d'une entrée dans le fichier /etc/hosts s'il n'est pas déja présent est une action idempotente.

Les actions idempotentes permetent à la fois de définir l'état attendu et comment l'atteindre, ce qui est plutot confortable.

Certains modules ou certaines actions effectué par ces modules ne sont pas idempotent. Exemple le module shell, quoi qu'il arrive l'action est exécuté. L'utilisation de ces modules sans gérer l'idempotence par ailleurs est **une mauvaise pratique**.

Grace à l'idempotence et l'option --check des commandes : ansible et ansible-playbook (un mode dry run : ne rien exécuté réelement) nous pouvons maitenant controler si une configuration déja déployée est conforme.

J'explique ; Lors de l'exécution d'une commande ad-hoc apt nous avons le retour suivant :

```bash
[cfg-master@master src]$ ansible slave2 -m apt -a "name=tree state=present" --become
slave2 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "cache_update_time": 1563347894,
    "cache_updated": false,
    "changed": true,
.../...
```

le résultat est `CHANGED` et le champs changed est à `true`.

nous avons bien l'état attendu mais avons effectué une action pour l'atteindre.

si on repasse la même commande :

```bash
[cfg-master@master src]$ ansible slave2 -m apt -a "name=tree state=present" --become --check
slave2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "cache_update_time": 1563347894,
    "cache_updated": false,
    "changed": false
}
```

le résultat est alors `SUCCESS` et le champs changed est à `false`.

cela veux dire que :

* L'état est bien celui attendu
* Aucun changement ne serais effectué si l'option --check n'était pas présente

L'état courant est donc bien celui attendu.

Produire du code ansible idempotent est un gage de qualité de ce code et offre un moyen simple de re-valider une configuration déjà déployée.

### Le YAML

Le code Ansible c'est du YAML : **Y**et **A**nother **M**eta **L**anguage , c'est un langage descriptif. Les structures de bases du YAML sont :

* un début de document : "---"

* une *liste* : une suite d'entrée **de même indentation** préfixées par un `-`

  ```yaml
  - élément1
  - élément2
  - élément3
  ```

* *dictionaire* (*dict*) : un enchaînement de `clef: valeur`
  * le séparateur est la suite : **deux points suivis par un espace**
  * la valeur peut être une simple valeur, une liste ou un autre *dictionnaire*

  ```yaml
  - player1:
      name: rick
      friends:
          - morty
          - bart
  - player2:
      name: morty
      friends:
          - bart
  ```

  Nous avons ici une liste de deux *dictionnaires* `player1` et `player2` dont les valeurs sont des *dictionnaires* de deux paires de clef/valeur : `name` et `friends`. La clef `friends` à pour valeur une *liste*.

Vous noterez que l'indentation est **trèèès importante**. Elle est en fait essentielle à un formattage YAML correct. Le fichier sera incorrect si l'indentation est incorrecte.

> Le YAML est en vérité un peu plus complexe et riche que ça mais cela est sufisant pour commencer. **RTFM point !** Vous regarderez [la doc Ansible liée au YAML pour aller plus loin](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html).

## Les *playbooks*

Le playbook est la description complète d'une configuration.

### Exemple

Dans le playbook, Nous allons définir, pour une série de *hosts*, une suite d'actions à réaliser pour atteindre un état donné.

En exemple, créez le fichier [apache-base-config.yml](./tp-ansible/files/apache-base-config.yml) dans le dossier courant et copiez ce contenu :

```yaml
- name: apache base config
  hosts: slave1
  become: yes

  vars:
    http_port: 80
    serveur_admin: webmaster@lab.local

  tasks:
  - name: ensure apache is up to date
    yum:
      name: httpd
      state: latest
  - name: write the apache config file
    template:
      src: templates/httpd.j2
      dest: /etc/httpd/conf/httpd.conf
      backup: yes
    notify:
    - restart apache
  - name: ensure apache is running
    service:
      name: httpd
      state: started

  handlers:
    - name: restart apache
      service:
        name: httpd
        state: restarted
```

Explication :

1. On commence par décrire le *playbook* et comment il va opérer :

   ```yaml
   - name: apache base config
     hosts: slaves
     become: yes
   ```
  
   Quelles sont les cibles du *playbook* (le groupe `slaves`), le fait que l'on devient `root` pour appliquer ce playbook : (`become: yes`)

2. Puis on précise des variables de *playbook* :

   ```yaml
     vars:
       http_port: 80
       serveur_admin: webmaster@lab.local
   ```

3. Une liste de *tâches* (*tasks*) à effectuer. C'est l'équivalent des commandes ad-hoc : un *module* avec des arguements

   ```yaml
     tasks:
     - name: ensure apache is up to date
       yum:
         name: httpd
         state: latest
     - name: write the apache config file
       template:
         src: templates/httpd.j2
         dest: /etc/httpd/conf/httpd.conf
         backup: yes
       notify:
       - restart apache
     - name: ensure apache is running
       service:
         name: httpd
         state: started
   ```

4. Un *handler* c'est une *tâche* qui est déclenchée par une notification ; celle-ci sera exécuté seulement si la tache qui notifie à donner lieu à un changement.

Les *handlers* sont traités à la fin du playbook

   ```yaml
     handlers:
       - name: restart apache
         service:
           name: httpd
           state: restarted
   ```

Vous pouvez récupérer le fichier ***template*** [httpd.j2](../tp-ansible/files/httpd.j2) et le placer dans le dossier src.

Pour tester ce *playbook* depuis le dossier /opt/src du host master:

```bash
$ ansible-playbook apache-base-config.yml
.../...
```

### Le run d'un playbook

L'exécution d'un playbook peu être résumé de façon simplifier comme suis :

* Ansible-playbook se connecte aux `hosts` de l'inventaire et initialise la communication avec le module `setup`
* Ansible-playbook récupère éventuelement les facts sur les hosts (si gather_facts=True)
* Puis chacun des hosts va **exécuter une à une les taches définies** dans le playbook ou les roles qu'il inclu en suivant son propre fil d'exécution. (strategy: linear vs free)
* Si l'une des tache échoue **toutes les taches suivantes sur le host sont annulées**.
* Sauf exception, **les variables définies et utilisées ont une portée locale au fil d'exécution** (chaque host vois la valeur qui lui est sienne)

### Les *tâches*

Chaque *tâche* définit un état à atteindre sur un objet de configuration grâce à un module, en résultat la *tâche* est soit :

* *OK* : déja fait, rien à faire
* *changed* : la *tâche* à été exécutée avec succès
* *failed* : la *tâche* n'a pas pu être exécutée, le reste du *playbook* est avorté

Leurs définitions peuvent inclure des conditions.  
Exemple utilisant la clause `when` :

```yaml
- name: install apache
  yum:
    name: "httpd"
    state: present
  when: ansible_facts['os_family']|lower == 'redhat'
```

On reparlera des *facts* un peu plus loin, mais vous avez sûrement compris le principe.

> La clé `when:` est un argument de *tâche*. Ce n'est PAS un argument du *module* (d'où l'indentation liée à la tâche).

#### Les conditions

Comme vu dans l'exemple la clause when d'une task permet d'emettre une condition sur l'exécution de la tache.

une liste de condition corespond à la réalisation de toutes les conditions qui la constitue :

```yaml
  when:
  - ansible_distribution == 'CentOS'
  - ansible_distribution_major_version == '7'
```

#### with_items

il est possible avec la clause with_items d'effectuer une boucle sur une liste ou une liste de dict :

```yaml
  with_items:
     - { name: Rick, cloneid: 8 }
     - { name: Morty, cloneid: 473573 }
```

dans la tache les valeurs seront accessible via le dict item : `"{{ item.name }}"`

> Attention il existe aussi la clause loop qui prends uniquement une liste d'arguements.

#### Les *register*

Le résultat de l'exécution d'une tache peu être enregistré dans une variable localisé dans le run courant

```yaml
  register: thistask
```

Ansible le résultat de la cette tache sera disponible dans la suite de l'exécution ; Exemples :

* `{{ thistask.changed }}` vaux True si la tache à ete réalisée
* `{{ thistash.stdout }}` Contiendra valeur retourné par thistask `stdout` si elle exits.

#### Configuration de retour

il est possible de parameter la sortie d'une tache de façon contrôler la séquence d'exécution et l'idempotence avec les clauses :

* `changed_when:` permet de définir une condition pour le status changed
* `failed_when:` permet de définir une condition pour le status failed (`failed_when: false` est asser courrant)

#### A retenir

* Une tache est associé à un module pour lequels on passe des pramètres.
* Elle founie en retour un dict qui n'est pas affiché par défaut mais qui est utilisable via une variable sauvegardant ce dictionaire(register).
* Les retour changed et failed sont parametrables
* Elle s'exécute sous condition (when)
* Elle peu être bouclé sur une liste de valeurs (with_items,loop).

### Le templating

Le module ansible `template` permet de livrer un fichier sur le host distant. On utilisera Jinja2 pour décrire les fichiers de configuration à livrer :

```bash
$ cat templates/httpd.j2 
ServerRoot "/etc/httpd"
Listen "{{ ansible_facts['eth1']['ipv4']['address'] }}:{{ http_port }}"
Include conf.modules.d/*.conf
User apache
Group apache
ServerAdmin "{{ serveur_admin }}"
<Directory />
.../...
```

Ici on utilise des variables que l'on vois un peu plus loin.

On pourra aussi utiliser l'ensemble des fonctionalités Jinja2 :

* les variables : `{{ foo['bar'] }}` retourne la valeur bar du dict foo
* test et conditions : `{% if variable is defined %}content{% else %}another-content{% endif %}`
* boucle for `{% for key, value in my_dict.items() %}{{ key }}: {{ value }}{% endfor %}`
* ... etc : <https://jinja.palletsprojects.com/en/3.0.x/>

## Les *rôles*

L'objectif est de disposer de briques réutilisables. Un *playbook* est statique, il définit comment on applique une configuration sur un ensemble de *hosts*.  
En definissant un *rôle*, on crée une brique indépendante de configuration qui sera alors utilisable par plusieurs *playbooks* , sur plusieurs plateformes ou sur plusieurs environements.

### Structure d'un rôle

Le *rôle* est définie par une sous arbo d'un dossier `roles` placé dans :

* ~/.ansible/roles
* ./roles (le chemin relatif au playbook)
* /etc/ansible/roles (les roles globalement connu du système)

Cette sous arboressance permet d'organiser la configuration, et à terme, de garder la complexité sous contrôle.

Exemple :

```bash
$ tree roles
roles
└── apache-base-config
    ├── defaults
    │   └── main.yml
    ├── files
    ├── handlers
    │   └── main.yml
    ├── meta
    ├── tasks
    │   └── main.yml
    ├── templates
    │   └── httpd.j2
    └── vars
        └── main.yml
```

**Les dossiers (au sein d'un rôle) pour les fichiers YAML Ansible :**

* `tasks` : les *tâches* à valider ou exécuter
* `handlers` : les *handlers* dédiés au *rôle*
* `defaults` : les variables par défaut du *rôle*
* `vars` : les variables du *rôle*
* `meta` : la définition des métadonnées liées au *rôle*

Pour ces dossiers, le fichier principal est `main.yml` mais on poura y inclure d'autres fichiers.

**Les dossiers pour des fichiers annexes :**

* `files` contient les fichiers statiques utilisés par le *rôle*
* `templates` contient des *templates* de fichiers (on reviendra sur le *templating* plus loin)

### Exercice : créez le rôle

Dans le cas du *playbook* présenté plus haut. definissez les taches et handlers dans un role, le playbook sera beaucoup plus simple :

```yaml
- name: apache base config
  hosts: slave1
  become: yes

  vars:
    http_port: 80
    serveur_admin: webmaster@lab.local

  roles:
    - apache-base-config
```

Vous créez l'arborescence de fichiers et vous distribuez dans les fichiers `main.yml` les parties qui n'apparaissent plus dans le *playbook* cité plus haut.

## Les variables

Les paramettres de *tâches*, de *handlers*, leurs conditions ainsi que toute la configuration vient dépendre de variables qui sont définies et utilisées à plusieurs endroits. Nous avons déja vu les variables définie dans le playbook

### Les variables d'inventaires

Il est possible de definir des variable de hosts :

directement dans le fichier host

```ini
$ cat src/hosts 
[all:children]
slaves
masters

[masters]
master
master2

[slaves]
slave1
slave2 var="in-hosts-file"
```

avec le module debug on peu affichier le contenu de cette variable

```bash
[cfg-master@master src]$ ansible slave2 -m debug -a "msg={{var}}"
slave2 | SUCCESS => {
    "msg": "in-hosts-file"
}
```

Dans des host_vars ou group_vars ; depuis le dossier racine du code ansible, a coté du fichier host on peu ajouter les dossiers host_vars et group_vars qui contiendront des fichiers ou dossier poratant les noms respectif de hosts et des groupes.

Dans notre environement de test :

```bash
src$ tree
.
├── ansible.cfg
├── apache-base.yml
├── group_vars
│   ├── masters.yml
│   └── slaves
│       └── debug2.yml
├── hosts
├── host_vars
│   ├── slave1
│   │   └── debug.yml
│   └── slave2.yml
└── httpd.j2

src$ for u in host_vars/slave1/debug.yml host_vars/slave2.yml group_vars/masters.yml 
> do echo $u ; cat $u ; echo "---"
> done
host_vars/slave1/debug.yml
var: "in host_vars directory"
---
host_vars/slave2.yml
var: "in host_vars file"
---
group_vars/masters.yml
var: "in group_vars file"
---
src$ cat group_vars/slaves/debug2.yml 
var2: "in group_vars file"
```

si on test :

```bash
[cfg-master@master src]$ ansible all -m debug -a "msg={{var}}"
master | SUCCESS => {
    "msg": "in group_vars file"
}
slave1 | SUCCESS => {
    "msg": "in host_vars directory"
}
master2 | SUCCESS => {
    "msg": "in group_vars file"
}
slave2 | SUCCESS => {
    "msg": "in host_vars file"
}
```

> On notera que pour slave2 la valeur "in-hosts-file" prend le dessus sur la valeur "in host_vars file", Nous y reviendrons

### Les facts

Lors des play ansible, chaque *host* retourne à Ansible, grace au module gather_facts, un ensemble de variables qui le concerne comme : son hostname, le nom de sa distribution, ses adresses IP etc... Ce sont les facts

Ces variables sont utilisables :

* directement, elle sont préfixés par ansible : ansible_*fact*
* *via* le dictionaire `ansible_facts` :

```bash
# Pour récupérer le hostname du host :
{{ ansible_facts['nodename'] }}
```

> Vous noterez l'usage du filtre `|lower`. Les filtres sont puissants et très riches en possibilité : <https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html>

### Les variable interne a ansible

Nous pouvons parfois utiliser les variable interna ansible

* inventory_file : le fichier d'inventaire utilisé par ansible.
* inventory_hostname : le hostname du host courant connu de l'inventaire
* ansible_hostname/ansible_nodename : le hostname courant du système
* group_names : tout les groupes dans lequel est le host courrant
* groups : tout les groupes connu de l'inventaire
* hostvars : toute les variables de tous les hosts de l'inventaire
* playbook_dir : le dossier contenant le playbook en cours de run
* role_path : le path du role courant
* ansible_play_hosts : list des host présent dans le run courrant
* ansible_play_batch : ceux du "batch" courant (tasks/rôles)
* ansible_check_mode : booléen si le run courrant est en `--check`

### test des variables

On utilise le playbook suivant et on l'exécute :

```yaml
- name: tests facts and vars
  hosts: all
  strategy: linear

  tasks:
  - name: show ansible_nodename vs inventory_hostname
    debug:
      msg: "{{ ansible_nodename }} {{ inventory_hostname }}"
  - name: show facts dsitribution
    debug:
      msg: "{{ ansible_facts['distribution'] }}"
  - name: show hostvars and magic vars ansible_play_hosts
    debug:
      msg: "{% for host in ansible_play_hosts %}{{ hostvars[host]['ansible_facts']['nodename'] }}:{{ hostvars[host]['ansible_distribution'] }} {% endfor %}"
```

On constate que :

* chacun des hosts a son propre fil d'exécution et vois ses propre valeur de variable.
* Les hosts voient l'ensemble des variables définie au travers de la magic variable `hostvars`

### Précedence des variables

Des règles de précédence (priorité) viennent régir l'ordre avec lequel les variables peuvent être surchargées. En exemple, les variables par défaut du *rôle* peuvent être surchargées lorsqu'elles sont redéfinies en variables de groupes.

L'ordre utilisé pour la précédence des variables :

1. les valeurs saisies en ligne de commande (`-u user`)
2. les variables par défaut définies dans les *rôles* (`defaults/main.yml`)
3. les variables de groupe de l'*inventaire* (`group_vars/groupe.yml`)
4. les variables de *hosts* définies dans l'*inventaire* (`hosts`)
5. les variables de *hosts* ajouté à l'*inventaire* (`hosts_vars`)
6. les *facts* (voir ci-dessous)
7. les variables de *playbook* (`vars:`, `prompt:` puis `var_files`)
8. les variables de *rôle* (`vars/main.yml`)
9. les extra vars passée en argument de commande ansible (surchargent toutes les autres)

## Conclusion

Nous y voyons un peu plus clair sur comment s'articule l'inventaire, les facts, les roles et les playbook.

L'inventaire defini les cibles de configuration, nous y associons des groupes et variables nous permettant de préciser principalement comment nous les regrouppons et comment nous nous y connectons.

Les facts nous retourne dynamiquement les informations a connaitre sur chacun des hosts sans que nous ayons besoin de les préciser dans l'inventaire.

Les rôles nous permetent de developper des fonctionalités de gestion des configuration (deployer, configurer, mettre à jour, sauvegarder, retaurer, etc...) une solution dans tel ou tel mode de fonctionnement. Le rôles sont donc une unité de code autonome ils pourront disposer de leur propre roadmap, dépot git et tickets.

Les playbooks associent Roles et taches à un inventaire et défini ainsi l'infrastructure à déployer. Nous aurons alors un dépot git contenant un inventaire et les playbooks déployant la configuration sur celui-ci.

## exercice pour valider votre comprehension

Codez un role permettant le déploiement d'une application simple : gitea

Depuis le dossier tp-ansible/src, vous créer le dossier roles/gitea et dedans toute la structure pour le role gitea :

```bash
$ tree -L 3
.
├── src
│   ├── ansible.cfg
│   ├── apache-base.yml
│   ├── httpd.j2
│   └── roles
│       └── gitea
└── Vagrantfile
```

En suivant la documentation [d'installation gitea](https://docs.gitea.io/en-us/install-from-binary/)

* vous créer des variable par défaut
  * gitea_version, gitea_vardir et gitea_etcdir
* vous déclarer les taches respective pour :
  * installer le pakage git
  * créer le compte utilisateur git
  * créer les dossier necessaire à gitea (en utilisant les variables gitea_vardir et gitea_etcdir)
  * télécharger et déposer l'exécutable gitea (en utilisant la variable gitea_version)
  * templater le service systemd avec le fichier [gitea.service](https://github.com/go-gitea/gitea/blob/main/contrib/systemd/gitea.service) que vous editerez afin d'utiliser les variable définie plus haut.
  * et enfin démarrer le service
* vous créer un playbook déployant ce service sur l'un des slave
* vous deployez ce role sur le slave choisi
