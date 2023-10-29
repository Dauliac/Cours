# Molecule

## Presentation

Molecule est un outils simplifiant le dévelopement de rôle ansible.

Cet outil implante dans la structure arborescente d'un rôle ansible une sous arborescance molecule dédiée à la validation et au test de celui-ci.

> la doc : <https://molecule.readthedocs.io/en/stable/>

## Definitions

- role : le role ansible
- driver : c'est le provider d'instance de test (docker, vagrant, LXC, LXD, Openstack, Linode, azure, digital ocean, EC2 etc...)
- instance : un node au sens Ansible, un "host"
- platform : un ensemble cohérent d'instance
- scenario : un scenario est un plan de test complet définissant une plateforme avec un driver et une séquence d'opérations

## Environement et Installation

Je vais pour ma part utiliser molecule avec vagrant. Ceci afin d'avoir une vm complète pour mon environement de test etr non pas un container qui sera limité en terme de configuration réseaux.

J'ai donc un environement linux + python3.5.2 avec Vagrant, Virtualbox et ansible installé localement.

J'ajoute molecule et plugin molecule-vagrant a mon arc.

```bash
pip3 install molecule molecule-vagrant --user
```

## quick start

### Un test rapide

Aller hop, on teste ça.

> largement inspiré de : <https://molecule.readthedocs.io/en/stable/getting-started.html>

On créer un nouveau rôle :

```bash
$ molecule init role my-new-role -d vagrant
INFO     Initializing new role my-new-role...
[DEPRECATION WARNING]: Ansible will require Python 3.8 or newer on the 
controller starting with Ansible 2.12. Current version: 3.7.3 (default, Jan 22 
2021, 20:04:44) [GCC 8.3.0]. This feature will be removed from ansible-core in 
version 2.12. Deprecation warnings can be disabled by setting 
deprecation_warnings=False in ansible.cfg.
No config file found; using defaults
- Role my-new-role was created successfully
INFO     Initialized role in /opt/src/roles/my-new-role successfully.
$ tree my-new-role/
my-new-role/
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── molecule
│   └── default
│       ├── converge.yml
│       ├── INSTALL.rst
│       ├── molecule.yml
│       └── verify.yml
├── README.md
├── tasks
│   └── main.yml
├── templates
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml

10 directories, 12 files

$ cd my-new-role
my-new-role$
```

Molecule à créer un role avec les main.yml et les dossiers defaults, handlers, meta, tasks et vars ansi qu'une arborescance molecule.
Dans celle-ci, chaque dossier est un scenario de test, le fichier `molecule.yml` défini ce scenario, et le playbook.yml le playbook (utilisant ce role) qui sera testé.

Je modifie le scénario de test afin de definir ma VM de test :

```bash
my-new-role$ vi molecule/default/molecule.yml 
my-new-role$ cat molecule/default/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: vagrant
platforms:
  - name: instance
    box: debian/buster64
    memory: 512
    cpus: 1
provisioner:
  name: ansible
verifier:
  name: ansible
```

J'ajoute simplement une tache debug au nouveau role :

```bash
my-new-role$ vi tasks/main.yml
my-new-role$ cat tasks/main.yml
---
# tasks file for my-new-role
- name: Hi there
  debug:
    msg: Hi, there! seems it's works
```

puis on lance les tests :

```bash
my-new-role$ molecule test
.../...
```

### Analyse de la sortie

Molecule présente la matrice de test qui sera effectué avec le scenario default :

```bash
my-new-role$ molecule test
--> Test matrix
    
└── default
    ├── dependency
    ├── lint
    ├── cleanup
    ├── destroy
    ├── syntax
    ├── create
    ├── prepare
    ├── converge
    ├── idempotence
    ├── side_effect
    ├── verify
    ├── cleanup
    └── destroy
    
```

Puis molecule déroule le début du scénario afin de preparrer l'environement de test jusqua détruire une éventuelle instance de test précédente :

```bash
--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.
--> Scenario: 'default'
--> Action: 'lint'
--> Lint is disabled.
--> Scenario: 'default'
--> Action: 'cleanup'
Skipping, cleanup playbook not configured.
--> Scenario: 'default'
--> Action: 'destroy'
    
    PLAY [Destroy] *****************************************************************
    
    TASK [Destroy molecule instance(s)] ********************************************
    ok: [localhost] => (item=instance)
    
    TASK [Populate instance config] ************************************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    skipping: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
    
```

Puis Molecule déroule les tests : vérification de la syntaxe et création de l'environement de test :

```bash
--> Scenario: 'default'
--> Action: 'syntax'
    
    playbook: .../my-new-role/molecule/default/converge.yml
--> Scenario: 'default'
--> Action: 'create'
    
    PLAY [Create] ******************************************************************
    
    TASK [Create molecule instance(s)] *********************************************
    changed: [localhost] => (item=instance)
    
    TASK [Populate instance config dict] *******************************************
    ok: [localhost] => (item=None)
    ok: [localhost]
    
    TASK [Convert instance config dict to a list] **********************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
--> Scenario: 'default'
```

Molecule préparre l'environement (playbook preparre) avant d'exécuté un playbook jouant le role (playbook converge):

```bash
--> Action: 'prepare'
    
    PLAY [Prepare] *****************************************************************
    
    TASK [Bootstrap python for Ansible] ********************************************
    ok: [instance]
    
    PLAY RECAP *********************************************************************
    instance                   : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
--> Scenario: 'default'
--> Action: 'converge'
    
    PLAY [Converge] ****************************************************************
    
    TASK [Gathering Facts] *********************************************************
    ok: [instance]
    
    TASK [Include my-new-role] *****************************************************
    
    TASK [my-new-role : Hi there] **************************************************
    ok: [instance] => {
        "msg": "Hi, there! seems it's works"
    }
    
    PLAY RECAP *********************************************************************
    instance                   : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
```

Molecule joue une deusieme fois le playbook afin de valider son idempotence puis valide le ré&sultat avec des tests, ici le playbook verify

```bash
--> Scenario: 'default'
--> Action: 'idempotence'
Idempotence completed successfully.
--> Scenario: 'default'
--> Action: 'side_effect'
Skipping, side effect playbook not configured.
--> Scenario: 'default'
--> Action: 'verify'
--> Running Ansible Verifier
    
    PLAY [Verify] ******************************************************************
    
    TASK [Gathering Facts] *********************************************************
    ok: [instance]
    
    TASK [Example assertion] *******************************************************
    ok: [instance] => {
        "changed": false,
        "msg": "All assertions passed"
    }
    
    PLAY RECAP *********************************************************************
    instance                   : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
Verifier completed successfully.
```

Enfin molecule nétoie l'environement de tests et supprime la vm

```bash
--> Scenario: 'default'
--> Action: 'cleanup'
Skipping, cleanup playbook not configured.
--> Scenario: 'default'
--> Action: 'destroy'
    
    PLAY [Destroy] *****************************************************************
    
    TASK [Destroy molecule instance(s)] ********************************************
    changed: [localhost] => (item=instance)
    
    TASK [Populate instance config] ************************************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
--> Pruning extra files from scenario ephemeral directory
my-new-role$ echo $?
0
```

Les tests sont passé le code retour est 0.

## Configuration

le dossier molécule contiendra les playbooks : converge.yml, prepare.yml, clean.yml, et side_effect.yml ; un fichier requirement.yml ; et les tests implémentés.

le fichier molecule.yml viens orchestrer tout ça :

```yaml
---
dependency:
  name: galaxy
lint: |
  yamllint .
driver:
  name: vagrant
platforms:
  - name: instance
    box: debian/buster64
    memory: 512
    cpus: 1
provisioner:
  name: ansible
verifier:
  name: ansible
```

On notera ici :

- la gestion des dépendance avec galaxy (requirement.yml)
- le driver d'instances : vagrant
- le Linter
- la description de plateforme : une instance debian/buster64
- le provisioner ansible
- et enfin les tests ansible, il est aussi possible d'utiliser `testinfra` le driver de test python (voir molecule/default/tests/test_default.py) et la doc : <https://testinfra.readthedocs.io/en/latest/>

> RTFM : <https://molecule.readthedocs.io/en/stable/configuration.html>

## Usage

Nous pouvons utiliser les scénarios complet molecule pour dérouler des test complets mais nous pouvons aussi simplement lancer une des partie du scénrario :

```bash
$ molecule create
--> Test matrix
    
└── default
    ├── dependency
    ├── create
    └── prepare
    
--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.
--> Scenario: 'default'
--> Action: 'create'
    
    PLAY [Create] ******************************************************************
    
    TASK [Create molecule instance(s)] *********************************************
    changed: [localhost] => (item=instance)
    
    TASK [Populate instance config dict] *******************************************
    ok: [localhost] => (item=None)
    ok: [localhost]
    
    TASK [Convert instance config dict to a list] **********************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
--> Scenario: 'default'
--> Action: 'prepare'
    
    PLAY [Prepare] *****************************************************************
    
    TASK [Bootstrap python for Ansible] ********************************************
    ok: [instance]
    
    PLAY RECAP *********************************************************************
    instance                   : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
```

et ainsi disposer d'un environement pour le dev consultable en interactif :

```bash
my-new-role$ molecule login
Warning: Permanently added '[127.0.0.1]:2202' (ECDSA) to the list of known hosts.
Linux instance 4.19.0-5-amd64 #1 SMP Debian 4.19.37-5 (2019-06-19) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Fri Jan 28 18:35:28 2022 from 10.0.2.2
vagrant@instance:~$ exit

```

Jouer son role dessus (converge)

```bash
my-new-role$ molecule converge
--> Test matrix
    
└── default
    ├── dependency
    ├── create
    ├── prepare
    └── converge
    
--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.
--> Scenario: 'default'
--> Action: 'create'
Skipping, instances already created.
--> Scenario: 'default'
--> Action: 'prepare'
Skipping, instances already prepared.
--> Scenario: 'default'
--> Action: 'converge'
    
    PLAY [Converge] ****************************************************************
    
    TASK [Gathering Facts] *********************************************************
    ok: [instance]
    
    TASK [Include my-new-role] *****************************************************
    
    TASK [my-new-role : Hi there] **************************************************
    ok: [instance] => {
        "msg": "Hi, there! seems it's works"
    }
    
    PLAY RECAP *********************************************************************
    instance                   : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
my-new-role$ 
```

Repeter les deux action précente pendant votre dèv puis détruire l'environement

```bash
my-new-role$ molecule destroy
--> Test matrix
    
└── default
    ├── dependency
    ├── cleanup
    └── destroy
    
--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.
--> Scenario: 'default'
--> Action: 'cleanup'
Skipping, cleanup playbook not configured.
--> Scenario: 'default'
--> Action: 'destroy'
    
    PLAY [Destroy] *****************************************************************
    
    TASK [Destroy molecule instance(s)] ********************************************
    changed: [localhost] => (item=instance)
    
    TASK [Populate instance config] ************************************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    
--> Pruning extra files from scenario ephemeral directory
my-new-role$ 
```

> Après avoir push, votre platforme de CI pourra alors re-jouer ces tests automatiquement doc molecule ci : <https://molecule.readthedocs.io/en/stable/ci.html> Attention à l'environement du runner

## Tuneable

En configurant le fichier molecule.yml on pourra définir précisément son environement de test (les instances, les images docker ou les box vagrant) et ce que l'on souhaite tester :

Il sera alors possible :

- de créer/modifier les playbooks playbook.yml(converge), prepare.yml, clean.yml, et side_effect.yml ;  
- gèrer les dépendances galaxy avec un fichier requirement.yml ;
- et implémenter ses tests dans le playbook verify ou en utilisant testinfra [doc](https://molecule.readthedocs.io/en/stable/configuration.html#testinfra)

Il est part ailleurs aussi possible de créer d'autre scenarios de test (init scenario -r role -s nom-scenrario -d driver), basé sur un driver différent par exemple:

```bash
my-new-role$ molecule init scenario -r my-new-role -d docker indocker
--> Initializing new scenario indocker...
Initialized scenario in ...my-new-role/molecule/indocker successfully.
my-new-role$ cat molecule/indocker/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: docker.io/pycontribs/centos:7
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
my-new-role$ 
```

## conclusion

molecule permet d'automatiser l'exécution de scenario de test pour les roles ansible mais dans un environement linux permet aussi de largement simplifier le dévelopement de ces roles.

On notera l'intégration d'ansible, molecule, vagrant, virtualbox sur un laptop a base de linux :)
