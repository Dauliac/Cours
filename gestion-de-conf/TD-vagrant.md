# TD Vagrant

En premier lieu, installez vagrant en suivant la documentation officielle <https://www.vagrantup.com/downloads>

## Premiers pas

Vous trouverez un environement déjà prêt pour ces exercices dans le dossier tp-vagrant de ce dépot git.

Depuis ce dossier, suivez les indication pas à pas.

### Demarrez une simple VM CentOS/7

Utilisez vagrant init :

```bash
~ $ cd first-test/
first-test $ vagrant init centos/7
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
```

Avec la commande `vagrant init` vous créez un Vagrantfile basic avec un grand nombre d'options commentés.

Si on cache les commentaires et ligne vide , il ne reste que 3 lignes de code :

```bash
first-test $ grep -v -e "^ *#" Vagrantfile | grep .
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
end
```

Puis lancez la vm :

```bash
first-test $ vagrant up --provider virtualbox
.../...
```

Lisez bien le retour de cette commande pour comprendre les actions effectuée par vagrant.

Connecter vous ensuite en ssh à la VM :

```bash
first-test $ vagrant ssh
[vagrant@localhost ~]$ cat /etc/redhat-release
CentOS Linux release 7.3.1611 (Core)
[vagrant@localhost ~]$ ip a | grep " inet "
    inet 127.0.0.1/8 scope host lo
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
[vagrant@localhost ~]$ exit
```

et enfin détruisez la VM :

```bash
first-test $ vagrant destroy -f
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...
```

> Résumé : Une VM centOS 7 standard à été créée, vous vous y êtes connecté en ssh, puis vous l'avez détruite.

### Configuration simple d'une VM

Dans le fichier suivant (Vagrantfile-1) on effectue les confugurations suivantes :

- ajout d'une ip sur un réseaux host-only,
- on supprime la vérification de la version de la box (box_check_update = false),
- définition d'un hostname,
- lancer quelques commandes de **provision**
- et aussi lancer la console graphique VirtualBox(vb.gui = true). (juste pour vous montrer car elle est inutile)

```bash
first-test $ cp Vagrantfile-1 Vagrantfile
first-test $ grep -v -e "^ *#" Vagrantfile | grep .
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.box_check_update = false
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.hostname = "Master"
  config.vm.provision "shell", inline: <<-SHELL
    uptime
    echo "up"
  SHELL
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
  end
end
```

> A voir : les options de pour la vm : <https://www.vagrantup.com/docs/vagrantfile>

Lancement :

```bash
first-test $ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'centos/7'...
==> default: Matching MAC address for NAT networking...
.../...
==> default: Configuring and enabling network interfaces...
==> default: Rsyncing folder: /home/alan/first-test/ => /vagrant
==> default:  17:15:18 up 0 min,  0 users,  load average: 0.38, 0.10, 0.03
==> default: up
first-test $
```

Connexion ssh et destruction:

```bash
first-test$ vagrant ssh
[vagrant@Master ~]$ ip a | grep " inet "
    inet 127.0.0.1/8 scope host lo
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0
    inet 192.168.56.10/24 brd 192.168.56.255 scope global eth1
[vagrant@Master ~]$ ls /vagrant
Vagrantfile  Vagrantfile-1  Vagrantfile-2  Vagrantfile-3
[vagrant@Master ~]$ exit
logout
Connection to 127.0.0.1 closed.
first-test$ vagrant destroy -f
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...
first-test$
```

> Vous Noterez :
>  
> - La console graphique qui s'affiche
> - La sortie des commandes “uptime” et “echo up” penadant la conviguration Vagrant
> - Le réseaux host-only créer par vagrant sur VirtualBox (si non existant)
> - Sur le guest : la config IP, et le dossier /vagrant ...
> - La connexion ssh au travers de votre interface loopback

## Gestion de plusieurs VM

Jusque ici nous n'avosn pas vraiment défini de VM `config.vm.define`. En l'absence de cette définition Vagrant considère une VM par défaut nommée default.

> **Warning.** Pour la suite veillez à bien instancier systématiquement toutes les configs de VM avec un “vm.define” :

On utilise le second fichier fournit en exemple :

```bash
first-test $ cp Vagrantfile-2 Vagrantfile
first-test $ cat Vagrantfile  
Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.define "master" do |master|
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.hostname = "master"
  end
  (1..2).each do |i|
    config.vm.define "slave-#{i}" do |slave|
      slave.vm.box = "centos/7"
      slave.vm.network "private_network", ip: "192.168.56.3#{i}"
      slave.vm.hostname = "slave-#{i}"
    end
  end
end
first-test $ vagrant up
../..
first-test $ vagrant destroy -f
```

> Vous noterez aussi dans le `Vagrantfile` :
>  
> - Une valeure est définie par défaut au niveau de la définition de la box (config.vm.box="centos/7"),
> - puis celle-ci est surchargée un peu plus loin au niveau de la machine (slave.vm.box = "centos/7")
> - Une boucle sur plusieurs vm en utilisant une iteration sur une liste : (1..2).each do |i|

*N’oubliez pas de détruire les VM de votre projet avant de changer de projet ! : Avec la commande `vagrant destroy -f` vous netoyez les vm associées à votre dossier projet (voir le contenu du dossier ./.vagrant)*

## Le provisionning

Il est possible de definir des provisions de vm `config.vm.provision` : file, shell, et ausse outil de gestion de configurations (ansible, chef, puppet, saltstack etc…)

Rappels des commandes :

- `vagrant up` : création de l’environnement et provisionning initiale ou simple démarrage de l’environnement existant (vagrant halt pour l’ arrêt)
- `vagrant destroy` : destruction de tout
- `vagrant provision` : re-déploiement de l’environnement en re-jouant les provisionneur

### Définitions de provisionning

<https://www.vagrantup.com/docs/provisioning/>

```bash
first-test $ cp Vagrantfile-3 Vagrantfile
first-test $ cat Vagrantfile
Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.provision "data", type: "file",
    preserve_order: true,
    source: "../sources",
    destination: "/tmp/"
  config.vm.define "master" do |master|
    master.vm.network "private_network", ip: "192.168.56.10" 
    master.vm.hostname = "master"
    master.vm.provision "data", type: "file",
      source: "../src",
      destination: "/tmp/"
  end
  (1..2).each do |i|
    config.vm.define "slave-#{i}" do |slave|
      slave.vm.network "private_network", ip: "192.168.56.3#{i}"
      slave.vm.hostname = "slave-#{i}"
      slave.vm.provision "slave-only", type: "shell", inline: <<-EOF
        echo "up inside"
      EOF
    end
  end
end
first-test $
```

> Vous noterez :
>  
> - Le nommage des provisionneurs en plus de la définition du Type “file” (Ce n'est pas dans la documentation officielle)
> - La surcharge du provisionneur nommé data (défini par défaut puis pour les VM slave-1 et slave2)
> - La définition d’un provisionneur slave-only localisé à un “vm.define” (dans la boucle sur les VM)

Lancement :

```bash
first-test $ vagrant up
Bringing machine 'master' up with 'virtualbox' provider...
Bringing machine 'slave-1' up with 'virtualbox' provider...
Bringing machine 'slave-2' up with 'virtualbox' provider…
../..
==> master: Rsyncing folder: /home/alan/first-test/ => /vagrant
==> master: Running provisioner: data (file)…
../..
==> slave-1: Rsyncing folder: /home/alan/first-test/ => /vagrant
==> slave-1: Running provisioner: data (file)...
==> slave-1: Running provisioner: slave-only (shell)…
    slave-1: Running: inline script
==> slave-1: up inside
../..
==> 31
==> slave-2: Running provisioner: data (file)...
==> slave-2: Running provisioner: slave-only (shell)...
    slave-2: Running: inline script
==> slave-2: up inside
```

> on constate bien les différente exécution de provisions sur les vm master slave-1 et slave-2

la provision "data" s'exprime bien différament sur la vm master et sur les slaves :

```bash
first-test $ vagrant ssh master
[vagrant@master ~]$ ls -ald /tmp/src/
drwxrwxr-x. 2 vagrant vagrant 6 Nov 11 18:24 /tmp/src/
[vagrant@master ~]$ ls -ald /tmp/sources/
ls: cannot access /tmp/sources/: No such file or directory
[vagrant@master ~]$ exit
logout
Connection to 127.0.0.1 closed.
first-test $ vagrant ssh slave-1
[vagrant@slave-1 ~]$ ls -ald /tmp/src/
ls: cannot access /tmp/src/: No such file or directory
[vagrant@slave-1 ~]$ ls -ald /tmp/sources/
drwxrwxr-x. 2 vagrant vagrant 6 Nov 11 18:25 /tmp/sources/
```

### Déploiement sélectif

__Avec la surcharge de provisionneur :__

Si on ajoute des fichiers en local dans les dossier src et source et qu'on relance le provisionning `file` nommé `data`

```bash
first-test $ touch src/for-master2
first-test $ touch source/for-slave2
first-test $ vagrant provision --provision-with data
==> master: Running provisioner: data (file)...
==> slave-1: Running provisioner: data (file)...
==> slave-2: Running provisioner: data (file)...
first-test $ vagrant ssh master
[vagrant@master ~]$ ls /tmp/src/
for-master
for-master2
[vagrant@master ~]$ logout
Connection to 127.0.0.1 closed.
first-test $ vagrant ssh slave-2
[vagrant@slave-2 ~]$ ls /tmp/sources
for-slave
for-slave2
[vagrant@slave-2 ~]$ logout
Connection to 127.0.0.1 closed.
first-test $
```

> on constate
>  
> 1. Les nouveaux fichier sont bien poussés sur les cibles.
> 2. On utilise bien un seul nom de provisionneur `data` qui effectue des actions différentes suivant les hosts sur lesquels ils s'applique.

__Restreindre à un provisionneur, à une VM ou les deux :__

```bash
first-test $ vagrant provision --provision-with slave-only
==> slave-1: Running provisioner: slave-only (shell)...
    slave-1: Running: inline script
==> slave-1:  18:56:57 up 31 min,  0 users,  load average: 0.00, 0.01, 0.03
==> slave-1: up inside
==> slave-2: Running provisioner: slave-only (shell)...
    slave-2: Running: inline script
==> slave-2:  18:56:59 up 30 min,  0 users,  load average: 0.00, 0.01, 0.05
==> slave-2: up inside
first-test $ vagrant provision master
==> master: Running provisioner: data (file)...
first-test $ vagrant provision --provision-with slave-only slave-2
==> slave-2: Running provisioner: slave-only (shell)...
    slave-2: Running: inline script
==> slave-2:  18:57:08 up 31 min,  0 users,  load average: 0.00, 0.01, 0.05
==> slave-2: up inside
first-test $ vagrant provision --provision-with data,slave-only slave-2 master
==> slave-2: Running provisioner: data (file)...
==> slave-2: Running provisioner: slave-only (shell)...
    slave-2: Running: inline script
==> slave-2:  06:27:00 up 12:00,  0 users,  load average: 0.00, 0.01, 0.05
==> slave-2: up inside
==> master: Running provisioner: data (file)...
```

## Exemple d’utilisation sur un projet

Dans le cadre d'un projet on Pourra alors utiliser vagrant afin de founir un environnement de test grandeur nature aux developpeurs :

Vous avez déja une arborescance projet à disposition  :

```bash
first-test $ cd ../projet
projet $ tree  
.
├── src
│   ├── process.yml
│   └── testapp.js
└── vagrant
    ├── task
    │   ├── apply.sh
    │   ├── build.sh
    │   └── init.sh
    └── Vagrantfile
```

- Le script init.sh : installera node.js et pm2
- Le script build.sh : ce script construit l’application ( config / compile)
- Le script apply.sh : prise en compte de la nouvelle version: relance des services.

> Dans l’exemple de vagrant file ci-après, vous noterez les options:
>  
> - l'utilisation de variables
> - run: always : afin de forcer l’exécution à chaque up ou reload des vm. Par défaut c’est seulement au premier up de la VM qu’il est lancé (run: once)
> - preserve_order: true : afin de garder l’ordre d’exécution des provision

Vagrantfile  :

```ruby
BASEIP = "192.168.56.3"
BASEHOSTNAME = "web"
Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  (1..1).each do |i|
    config.vm.define "#{BASEHOSTNAME}-#{i}" do |web|
      web.vm.hostname = "#{BASEHOSTNAME}-#{i}"
      web.vm.network "private_network", ip: "#{BASEIP}#{i}"
      web.vm.provision "init",
        type: "shell",
        preserve_order: true,
        run: "once",
        inline: <<-EOF
          echo "#### runing initalisation of environement"
          sudo /vagrant/task/init.sh
          echo "#### initialized"
        EOF
      web.vm.provision "sources", type: "file",
        preserve_order: true,
        source: "../src",
        destination: "/opt/"
      web.vm.provision "build", type: "shell",
        preserve_order: true,
        run: "always",
        inline: <<-EOF
          echo "#### runing build "
          sudo /vagrant/task/build.sh
          echo "#### builded"
        EOF
      web.vm.provision "apply", type: "shell",
        preserve_order: true,
        run: "always",
        inline: <<-EOF
          echo "#### applying version "
          sudo /vagrant/task/apply.sh
          echo "#### builded"
        EOF
    end
  end
end
```

Lancement :

```bash
projet $ vagrant up
.../...
```

Commandes de provisioning :

```bash
projet $ vagrant provision --provision-with sources,build,apply
.../...
```

Vous reprovisionner les sources, vous builder l’appli, puis vous redémarer les services

re-installation des dépendances  

```bash
projet $ vagrant provision --provision-with init
.../...
```
