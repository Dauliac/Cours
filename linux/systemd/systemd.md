# systemd

[TOC]

## Présentation

### Principe

`systemd` a pour principale fonction d'être le **processus init** des distributions GNU/Linux (init au sens POSIX); le processus de **PID 1**. Tout comme les autres versions d'init, au démarrage du système, il effectue les opérations d'initialisation du système comme démarrer les daemons ou monter les systèmes de fichier.

Historiquement d'autres version d'init ont existé:

- Init systemV ou BSD (historique UNIX)
- GNU/dnd (init du projet GNU/hurd, il est peu utilisé)
- upstart (version précédant `systemd` proposant aussi de la parallélisation au démarrage)
- Initng (il était le concurent direct de `systemd`)
- launchd (init utilisé sur MacOS, `systemd` s'en est beaucoup inspiré)
- bien d'autres tentatives anecdotiques du processus init (pinit, finit, speedboot ... )

Chacun de ces pocessus Init s'apuis sur des scripts (de démarrage ou d'arret des services et autre actions necessaire au système).
Ces scripts effectuant souvant **les mêmes opérations** (chargement de variables d'environement, demarrage du service, sauvegarde du pid file, reload du service par kill du pidfile etc...) utilise des bibliothèques shell propre à chaque distribution.
Systemd via la prise en charge de ces actions directement dans son fonctionnement permet d'**unifier les distributions linux** sur cet aspect. il n'y a plus à gerer un script de démarrage valable sous redhat/centOS/rocky et un sous Debian/ubuntu mais juste une unité systemd.

Bref, `systemd` de part sa simplicité, sa complétude, sa modularité, et la **normalisation** qu'il propose est devenu la version contemporaine d'**init** de référence pour les distribution les plus largement utilisées.

### La controverse

Systemd a été trés controversé lors de son adoption sur les distributions GNU/Linux et a donné lieu a certain fork, exemple : [devuan](https://www.devuan.org/). La principale oposition est le non repsect des principes majeur d'unix suivant :

- Keep It Simple
- Faire une seule chose et la faire bien

En effet systemed est un bloc complet qui viens replacer plusieurs processus qui étaient auparavant optionnel et interchangeable (crond, incrond, inetd, xinetd, rsyslogd, syslog-ng)

En contrepartie systemd apporte une standardisation en proposant une solution global et unifiée de gestion du 'userspace' des system GNU/Linux

### Rapidité du démarrage

`systemd` permet de réduire de façon importante le temps de démarrage du système car il ordonnance de façon précise l'exécution des opérations de démarrage en les parallélisant un maximum.

Notamment, la résolution des dépendances entre les services est grandement accélérée par :

- La création de l'ensemble des sockets de communication pour les daemons avant de lancer les daemons eux-mêmes.
- L'attente de l'obtention du nom **D-Bus** pour passer au service suivant, plutôt que d'attendre la fin du démarrage complet du service.

Pour démarrer, un *service* n'attend plus la fin du démarrage des *services* dont il dépend car il dispose d'un accès en avance de phase de leurs socket et de leurs noms dbus.

La commande suivante fournie une analyse de la séquence du boot dans une image *(plot)* ou un résumé du chemin critique textuel :

```bash
root@bullseye:~# systemd-analyze plot > /vagrant/plot.svg
root@bullseye:~# systemd-analyze critical-chain | cat
The time when unit became active or started is printed after the "@" character.
The time the unit took to start is printed after the "+" character.

graphical.target @3.467s
└─multi-user.target @3.466s
  └─ssh.service @3.003s +23ms
    └─network.target @963ms
      └─networking.service @842ms +119ms
        └─apparmor.service @346ms +477ms
          └─local-fs.target @344ms
            └─local-fs-pre.target @344ms
              └─systemd-tmpfiles-setup-dev.service @327ms +15ms
                └─systemd-sysusers.service @279ms +46ms
                  └─systemd-remount-fs.service @190ms +59ms
                    └─systemd-journald.socket @162ms
                      └─system.slice @148ms
                        └─-.slice @148ms
```

### Organisation plus souple

`systemd` propose une organisation plus aboutie des services à démarrer aux boot.  
Là ou systemV proposait au maximum 4 niveaux de services (les niveaux 1 2 3 4 5), chacun modélisé par une liste de services à démarrer un par un. `systemd` propose une organisation arborescente de *targets* et d'*unités*. Chaque *target* intègre des *unités* à démarrer ou d'autres *targets* (pouvant à leur tour contenir des *unités*).

> les niveau system V 0 et 6 définissent respectivement le systeme arrêté et le reboot. d'ou les commandes `init 0` et `init 6` pour arrêter ou rebooter le systeme.

**Une *unité* systemd est une unité de configuration du système** : un daemon démarré, l'accès à un système de fichiers ou une configuration réseaux, l'activation d'un socket TCP, des tache planifiées.

Une *target* est une *unité* spéciale regroupant les autres *unités* permetant de définir des point de synchronisation dans l'arbre des dépendances entre les services.

La *target* par défaut est en générale `multi-user.target` ou `graphical.target` (système avec GUI) c'est la racine de l'arbre de dependances des unité, elle definie le **niveau de service** attendu par le systeme au boot et en fonctionnement normal.

### Complétude

`systemd` offre de grandes possibilités de gestion du système en raison de :

- son intégration avec D-Bus et la publication d'API `systemd` qui y est faite
- sa gestion intégrée des cgroups et des namespaces

### Mais encore

`systemd` intègre aussi de façon modulaire d'autre composants des systèmes UNIX en les remplaçant par des solutions plus modernes et normalisées.

![systemd](https://lcom.static.linuxfound.org/images/stories/41373/Systemd-components.png)

#### Daemons potentielement déprécies par systemd

- `crond` : avec des *unités* de type `.timer`
- `incrond` : avec les unité de type `.path`
- `inetd` ou `xinetd` : avec des *unités* de type `.socket`
- la syslog (`rsyslogd` ou sysog-ng) : avec le daemon `journald`

#### Fichiers protentielement dépréciés par systemd

- inittab : avec les *unités* de type `.target`
- le fichier `/etc/fstab` : avec des *unités* de type `.mount`

#### Outils de gestion système propres à chaque distribution

- script de gestion réseau et/ou le daemon `NetworkManager` avec le daemon `systemd-networkd`
- les outils `systemd-resolved`, `hostnamectl`

## Utilisation

### `systemctl`

`systemctl` pour simplement activer (`enable`), démarrer (`start`), désactiver (`disable`) ou arrêter (`stop`) un *service* :

Lorsqu'on install un service, ici, apache2, L'unité systemed est créé et activée :

```bash
root@bullseye:~# apt-get install apache2
Reading package lists... Done
Building dependency tree... Done
.../...
Enabling conf serve-cgi-bin.
Enabling site 000-default.
Created symlink /etc/systemd/system/multi-user.target.wants/apache2.service → /lib/systemd/system/apache2.service.
Created symlink /etc/systemd/system/multi-user.target.wants/apache-htcacheclean.service → /lib/systemd/system/apache-htcacheclean.service.
Processing triggers for man-db (2.9.4-2) ...
Processing triggers for libc-bin (2.31-13+deb11u6) ...
```

```bash
root@bullseye:~# systemctl status apache2
● apache2.service - The Apache HTTP Server
     Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2023-09-16 12:34:20 UTC; 2min 2s ago
       Docs: https://httpd.apache.org/docs/2.4/
   Main PID: 1835 (apache2)
      Tasks: 55 (limit: 1114)
     Memory: 9.0M
        CPU: 48ms
     CGroup: /system.slice/apache2.service
             ├─1835 /usr/sbin/apache2 -k start
             ├─1837 /usr/sbin/apache2 -k start
             └─1838 /usr/sbin/apache2 -k start

Sep 16 12:34:20 bullseye systemd[1]: Starting The Apache HTTP Server...
Sep 16 12:34:20 bullseye apachectl[1834]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name>
root@bullseye:~# systemctl stop apache2
root@bullseye:~# systemctl status apache2
● apache2.service - The Apache HTTP Server
     Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
     Active: inactive (dead) since Sat 2023-09-16 12:37:24 UTC; 2s ago
       Docs: https://httpd.apache.org/docs/2.4/
    Process: 2125 ExecStop=/usr/sbin/apachectl graceful-stop (code=exited, status=0/SUCCESS)
   Main PID: 1835 (code=exited, status=0/SUCCESS)
        CPU: 85ms

Sep 16 12:34:20 bullseye systemd[1]: Starting The Apache HTTP Server...
Sep 16 12:34:20 bullseye apachectl[1834]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name>
Sep 16 12:34:20 bullseye systemd[1]: Started The Apache HTTP Server.
Sep 16 12:37:24 bullseye systemd[1]: Stopping The Apache HTTP Server...
Sep 16 12:37:24 bullseye apachectl[2127]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name>
Sep 16 12:37:24 bullseye systemd[1]: apache2.service: Succeeded.
Sep 16 12:37:24 bullseye systemd[1]: Stopped The Apache HTTP Server.
```

```bash
root@bullseye:~# systemctl disable apache2
Synchronizing state of apache2.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install disable apache2
Removed /etc/systemd/system/multi-user.target.wants/apache2.service.
root@bullseye:~# systemctl enable apache2
Synchronizing state of apache2.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable apache2
Created symlink /etc/systemd/system/multi-user.target.wants/apache2.service → /lib/systemd/system/apache2.service.
```

Déterminer la *target* par défaut :

```bash
# systemctl get-default
multi-user.target
```

Définir la *target* par défaut au démarrage du systeme :

```bash
# systemctl set-default multi-user.target  
```

### Les autres composants de systemd

#### La configuration réseaux

L'unité systemd-networkd.service une fois active Permet la gestion de la configuration réseaux du systeme au travers :

- d'unité .network .link et .netdev
- de la commande networkctl

L'unité systemd-resolved.service offre la gestion de la résolution réolution dns du systeme.  

l'utilisation de ces deux composant est traité dans le [tp networkd](../config-linux/config-net/systemd-net.md)

#### les commande de configuration système

- hostnamectl : permetant de connaitre ou de definir le hostname (il maintien notamment /etc/hostname)
- timedatectl : Permetant de definir la date et l'heure system
- bootctl : Permet de gérer des éléments de la configuration EFI et du boot loader EFI.
- loginctl : Permet la gestion des sessions utilisateur (y compris graphique)
- journalctl : outil de requete sur le la journalisation systeme.
- busctl : permet le contrôle de dbus
- systemd-analyze : analyse le démarrage du system

## Configuration `systemd`

La 'personalisation' se fait dans : `/etc/systemd/`.

On y retrouve, la configuration des composants `system.conf`, `journald.conf`, `resolved.conf`, etc. Ces fichiers contiennent à chaque fois les valeurs par défaut commentées que nous pouvons alors dé-commenter et éditer.

```bash
root@bullseye:~# find /etc/systemd/ -name "*.conf"
/etc/systemd/timesyncd.conf
/etc/systemd/system.conf
/etc/systemd/pstore.conf
/etc/systemd/resolved.conf/
/etc/systemd/networkd.conf
/etc/systemd/logind.conf
/etc/systemd/sleep.conf
/etc/systemd/user.conf
/etc/systemd/journald.conf
```

il est à noter que leur configuration peu être ammendé lors des installation de paquet logiciel via le dépot de fichier dans :

```bash
/usr/lib/systemd/*.conf.d/
/usr/local/lib/systemd/*.conf.d/
/etc/systemd/*.conf.d/*.conf
```

Aussi certaines configurations peuvent être modifiées pour certains namespace, exemple pour journald :

```bash
/etc/systemd/journald@NAMESPACE.conf
```

### Les *unités* et *targets*

La sous-arborescence `/etc/systemd/system/` contient la définition courigé ou effective des *targets* et *unités*. C'est la configuration proposée par l'éditeur de la distribution GNU/Linux puis maintenue par l'adminsys.  
Les *unités* et *targets* peuvent être redifinies ici, surchargées ou complémentées. Ils peuvent aussi n'être que des liens symboliques vers les définitiosn connues (par `systemd`) des ces *unités* dans l'arborescence `/lib/systemd` ou `/usr/lib/systemd/system`.

La commande `systemctl daemon-reload` est utilisée après chaque modification des fichier des dossiers `/etc/systemd/system/`, `/lib/systemd` et `/usr/lib/systemd/system` pour qu'elle soit prise en compte par systemd.

Cette sous-arborescence définie les relations effective entres les *unités* une fois activée.

Les *unités* de type ***target*** seront ici représentées par des **dossiers** `xxxx.target.wants`. xxxx représentant le nom de l'unité. Exemple :

```bash
root@bullseye:~# ls -al /etc/systemd/system/multi-user.target.wants
total 8
drwxr-xr-x 2 root root 4096 Sep 16 12:38 .
drwxr-xr-x 8 root root 4096 Jun 15 18:41 ..
lrwxrwxrwx 1 root root   35 Sep 16 12:38 apache2.service -> /lib/systemd/system/apache2.service
lrwxrwxrwx 1 root root   34 Jun 15 18:41 chrony.service -> /lib/systemd/system/chrony.service
lrwxrwxrwx 1 root root   32 Jun 15 18:40 cron.service -> /lib/systemd/system/cron.service
lrwxrwxrwx 1 root root   38 Jun 15 18:41 networking.service -> /lib/systemd/system/networking.service
lrwxrwxrwx 1 root root   36 Jun 15 18:40 remote-fs.target -> /lib/systemd/system/remote-fs.target
lrwxrwxrwx 1 root root   35 Jun 15 18:40 rsyslog.service -> /lib/systemd/system/rsyslog.service
lrwxrwxrwx 1 root root   31 Jun 15 18:41 ssh.service -> /lib/systemd/system/ssh.service
lrwxrwxrwx 1 root root   47 Jun 15 18:41 unattended-upgrades.service -> /lib/systemd/system/unattended-upgrades.service
```

celui-ci contenant les *unités* (en fait des liens vers ces unité) devant être démarrées avec cette *unité* de type *target*.

```bash
root@bullseye:~# ls -al /etc/systemd/system/
total 40
drwxr-xr-x 8 root root 4096 Jun 15 18:41 .
drwxr-xr-x 5 root root 4096 Jun 15 18:40 ..
lrwxrwxrwx 1 root root   34 Jun 15 18:41 chronyd.service -> /lib/systemd/system/chrony.service
lrwxrwxrwx 1 root root   45 Jun 15 18:40 dbus-org.freedesktop.timesync1.service -> /lib/systemd/system/systemd-timesyncd.service
drwxr-xr-x 2 root root 4096 Jun 15 18:40 default.target.wants
-rw-r--r-- 1 root root  304 Jun 15 18:41 generate-sshd-host-keys.service
drwxr-xr-x 2 root root 4096 Jun 15 18:40 getty.target.wants
drwxr-xr-x 2 root root 4096 Sep 16 12:38 multi-user.target.wants
drwxr-xr-x 2 root root 4096 Jun 15 18:41 network-online.target.wants
-rw-r--r-- 1 root root  568 Jun 15 18:41 set-grub-install-device.service
lrwxrwxrwx 1 root root   31 Jun 15 18:41 sshd.service -> /lib/systemd/system/ssh.service
drwxr-xr-x 2 root root 4096 Jun 15 18:41 sysinit.target.wants
lrwxrwxrwx 1 root root   35 Jun 15 18:40 syslog.service -> /lib/systemd/system/rsyslog.service
lrwxrwxrwx 1 root root    9 Jun 15 18:41 systemd-timesyncd.service -> /dev/null
drwxr-xr-x 2 root root 4096 Jun 15 18:41 timers.target.wants
```

Nous retrouvons donc :

- Des *unités* : des fichiers ou des liens symboliques vers les définition de ces *unités*
- Des dossiers `$target$.target.wants/` contenant les *unités* (fichiers ou liens) qui constituent alors les *unités* de type *target*.
- Mais aussi d'éventuels dossiers `$unit$.$unittype$.requires/` contenant des liens vers les *services* dont dépendent *l'unité*

Les *unités* connues par le système peuvent être :

- **`enable`** : existant dans `/etc/systemd/system`, en tant que fichier ou lien symbolique vers sa définition
- **`disable`** : inexistant dans `/etc/systemd/system`, mais avec une définition dans `/lib/systemd/system` ou `/usr/lib/systemd/system`
- **`masked`** : existant en tant que lien depuis `/etc/systemd/system` mais pointant vers `/dev/null` plutot que sa définition (interdit à l'activation)

> il est donc possible de créé des unité target avec des dépendance de type require via un dossier xxxxx.requires, l'unité ansi créé sera lié fortement lié aux unités requises.
>
> - si l'unité target est démarré alors toutes les unité requises le seront aussi tout comme le .wants
> - mais si l'une des unité requise échoue, l'unité taget qui la requière échoura aussi via cette dépendance. (échouer au sens failled)

## Configuration des unités

Les *unités* `systemd` sont donc des définitions de ressources système.

L'objectif de `systemd` est de maintenir leur état souhaité :

- *Active* : pour démarré (donc l'*unité* est *enabled* ou *loaded*)
- *Inactive* : si arrêté  (normal pour une *unité* *disabled* ou après un arrêt manuel)

L'unité sera *Failed* si le démarrage de *l'unité* échoue ou s'il n'est pas possible de la maintenir dans l'état souhaité

Il en existe plusieurs types :

- $unit$.target,
- $unit$.service,
- $unit$.socket,
- $unit$.timer,
- $unit$.path,
- et d'autres encore ($unit$.device, $unit$.slice, $unit$.scope, $unit$.mount, $unit$.automount, $unit$.swap)

Elles sont définies au travers de fichiers type `.ini` :

avec des **sections** et des **tokens**

```ini
[section]
token = value
othertoken = anothervalue
```

On retrouvera leur documentation dans les manuels associés.

Pour les *unités* dans leur globalité :

```bash
man systemd.unit
```

Ou pour les *unités* de type $unittype$ :

```bash
man systemd.unittype
```

Exemple

```bash
man systemd.service
```

### Les sections

En regardant dans l'ensemble des *unités* on peut retrouver les sections existantes :

```bash
root@bullseye:~# grep "\[" /lib/systemd/system/* 2>/dev/null | grep -v "^ +#" | cut -d[ -f2 | cut -d\] -f1 | sort | uniq -c | sort -g | tail -7
      2 Path
      7 Mount
      8 Timer
     14 Socket
     47 Install
    104 Service
    209 Unit
```

Les principales sections des *unités* sont :

- `[Unit]` : la définition de *l'unité*
- `[Service]` : la définition de la gestion d'un *service* (démarrage, arrêt, reload...)
- `[Install]` : la définition de l'activation d'une *unité* (où elle se situe dans l'arborescence des unités configurées (`/etc/systemd/system`)

`[Path]`, `[Mount]`, `[Timer]`, `[Socket]` sont des sections dédidées aux unités de ces types.

### Les tokens de configuration des unités

Ils sont spécialisé aux sections dans lesquels ils sont utilisé et permete de définir ou paramétrer une unité.

Il y en a beaucoup :

```bash
root@ubuntu-bionic:~# grep -r "=" /etc/systemd/system/ /usr/lib/systemd/ /lib/systemd/system/ | grep -v "^ +#" | cut -d: -f2 | cut -d= -f1 | sort | uniq -c | sort -g | tail -30
     12 EnvironmentFile
     12 IgnoreSIGPIPE
     12 SystemCallArchitectures
     13 ConditionDirectoryNotEmpty
     13 StandardOutput
     15 StopWhenUnneeded
     16 AllowIsolate
     16 RefuseManualStart
     17 SocketMode
     19 ListenStream
     21 TimeoutSec
     22 Restart
     23 ConditionVirtualization
     23 Environment
     23 ExecStop
     24 KillMode
     28 ConditionKernelCommandLine
     39 Wants
     46 RemainAfterExit
     52 ConditionPathExists
     55 Requires
     67 Conflicts
     78 WantedBy
    114 Before
    124 Type
    140 DefaultDependencies
    153 ExecStart
    156 After
    217 Documentation
    265 Description
```

Pour les sections **`[Unit]`** et **`[install]`**`: la description de *l'unité* et la définition de ses dépendances et interdependances avec les autres *unités*

- `Description`,
- `Documentation`,
- `Requires` : les *unités* qu'il **faut démarrer** pour démarrer celle-ci,
- `Requisite` : les *unités* qui **doivent déjà** être démarrées afin de pouvoir démarrer celle-ci (elle sera failled sinon)
- `wants` : les *unités* que l'on essaye de démarrer avec celle-ci
- `Conflict` : la liste des *unités* en conflit avec celle-ci et qui seront donc stoppées
- `Before`, `After` : les *unités* devant être démarrées avant ou après celle-ci
- `DefaultDependencies`: `yes` par défaut et `no` sinon. Lorsque mis à `no`, ce token altère la gestion des dépendances. Exemple : une *unité* de type *target* démarre toutes les *unités* requises (`Requires`) ou souhaitées (`Wants`) sauf si elles sont elles-mêmes spécifiées avec le `defaultDepenencies` à `no`.

Pour la section **`[Install]`** : on définit ici comment cette *unité* sera activée, où elle sera placée dans l'arborescence des *targets* dans `/etc/systemd/system`

- `WantedBy` : dans quel dossier `$target$.target/wants` cette *unité* doit être définie
- `RequiredBy` : dans quel dossier `$unit$.$unittype$.requires` cette *unité* doit être définie
- `Also` : quelles *unités* doivent être installées ou désinstallées en même temps que celle-ci
- `Alias` : un second nom pour ce service sera défini dans `/etc/systemd/system` (un autre lien symbolique), le *service* sera alors activé sous ses deux noms (exemple mariadb et mysqld)

Les autres sections sont attachées aux types *d'unité* et doivent donc être étudiée avec les autre type d'unités.

### Commande de gestion des spécifications *d'unités*

Voir une *unité* `systemd` :

```bash
$ systemctl cat sshd.service
.../...
$
```

Ou l'éditer :

```bash
$ sudo systemctl edit --full cron.service
.../...
$
```

Cette commande crée une copie de la définition de *l'unité* (depuis `/lib` ou `/usr/lib`) vers le dossier `/etc/systemd/system` afin de permettre une modification de ses spécifications.

On peut aussi créer une surcharge sur *l'unité* existante :

```bash
$ sudo systemctl edit docker.service
.../...
$
```

> Cette commande créera un dossier drop-in `/etc/systemd/system/$name$.service.d/override.conf` permettant d'ajouter du contenu ou de surcharger les *unités* par défaut.

Ou aussi voir ou modifier un token (de gestion des ressources):

```bash
root@bullseye:~# systemctl show nginx.service -p MemoryMax
MemoryMax=infinity
root@bullseye:~# sudo systemctl set-property nginx.service MemoryMax=1G
root@bullseye:~# systemctl show nginx.service -p MemoryMax
MemoryMax=1073741824
root@bullseye:~# systemctl status nginx.service
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
    Drop-In: /etc/systemd/system.control/nginx.service.d
             └─50-MemoryMax.conf
```

> systemctl set-property utilisé avec l'option *--runtime* permet dee modifier la valeure que pour le service actuelement en fonction et n'est pas inscrite dans un fichier drop-in de modification du service

### Les *unités* de type *target*

Sous `systemd`, une `target` remplace la notion de run level, il est défini :

- par une *unité* spéciale `$target$.target` (sous `/lib/systemd/system`) définissant la `target` et ses dépendances
- et si activé, un dossier `/etc/systemd/system/$target$.target.wants` contenant des liens vers les fichiers de définition des *unités* `systemd` constituant cette *target*

On poura toutes les lister :

```bash
root@bullseye:~# systemctl list-unit-files -t target 
UNIT FILE                     STATE    VENDOR PRESET
basic.target                  static   -            
blockdev@.target              static   -            
bluetooth.target              static   -            
boot-complete.target          static   -            
cryptsetup-pre.target         static   -            
cryptsetup.target             static   -            
ctrl-alt-del.target           alias    -            
default.target                alias    -            
.../...
```

Exemple *d'unité* de type *target* :

```bash
root@bullseye:~# cat /lib/systemd/system/multi-user.target
#  SPDX-License-Identifier: LGPL-2.1-or-later
#
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.

[Unit]
Description=Multi-User System
Documentation=man:systemd.special(7)
Requires=basic.target
Conflicts=rescue.service rescue.target
After=basic.target rescue.service rescue.target
AllowIsolate=yes
```

Son dossier sous `/etc/systemd/system/` une fois activé sur le système :

```bash
root@bullseye:~# ls -al /etc/systemd/system/multi-user.target.wants
total 8
drwxr-xr-x 2 root root 4096 Sep 16 12:38 .
drwxr-xr-x 8 root root 4096 Jun 15 18:41 ..
lrwxrwxrwx 1 root root   35 Sep 16 12:38 apache2.service -> /lib/systemd/system/apache2.service
lrwxrwxrwx 1 root root   34 Jun 15 18:41 chrony.service -> /lib/systemd/system/chrony.service
lrwxrwxrwx 1 root root   32 Jun 15 18:40 cron.service -> /lib/systemd/system/cron.service
lrwxrwxrwx 1 root root   38 Jun 15 18:41 networking.service -> /lib/systemd/system/networking.service
lrwxrwxrwx 1 root root   36 Jun 15 18:40 remote-fs.target -> /lib/systemd/system/remote-fs.target
lrwxrwxrwx 1 root root   35 Jun 15 18:40 rsyslog.service -> /lib/systemd/system/rsyslog.service
lrwxrwxrwx 1 root root   31 Jun 15 18:41 ssh.service -> /lib/systemd/system/ssh.service
lrwxrwxrwx 1 root root   47 Jun 15 18:41 unattended-upgrades.service -> /lib/systemd/system/unattended-upgrades.service
```

### *Unités* de type *service*

Les scripts de démarrage historiques (non encore intégrés à `systemd`) exécutaient normalement toujours les mêmes actions :

- Démarrer le processus avec certains arguments en gérant
  - Ses entrée/sorties
  - Son PID (sauvegardé dans un fichier)
  - Ses éventuelles dépendances
- Envoyer un signal avec `kill` sur le PID (pour reload ou pour stopper le service)

`systemd` a intégré ces actions et permet lors de l'intégration d'un produit dans une distribution de ne plus avoir à re-créer un script de démarrage.

les unités service:

```bash
root@bullseye:~# systemctl list-unit-files -t service
UNIT FILE                              STATE           VENDOR PRESET
apparmor.service                       enabled         enabled      
apt-daily-upgrade.service              static          -            
apt-daily.service                      static          -            
autovt@.service                        alias           -            
chrony-dnssrv@.service                 static          -            
chrony.service                         enabled         enabled      
chronyd.service                        alias           -            
.../...
```

Exemple *d'unité* :

```bash
root@bullseye:~# systemctl cat sshd.service
# /lib/systemd/system/ssh.service
[Unit]
Description=OpenBSD Secure Shell server
Documentation=man:sshd(8) man:sshd_config(5)
After=network.target auditd.service
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Service]
EnvironmentFile=-/etc/default/ssh
ExecStartPre=/usr/sbin/sshd -t
ExecStart=/usr/sbin/sshd -D $SSHD_OPTS
ExecReload=/usr/sbin/sshd -t
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartPreventExitStatus=255
Type=notify
RuntimeDirectory=sshd
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
Alias=sshd.service
```

Dans la section **`[Service]`** de *l'unité* : on spécifie simplement le *service*.

Le type de *service* est défini *via* le token **`Type`** décrivant comment le processus va se comporter une fois allumé (utile pour le monitoring du service notamment) :

- `**simple**` : un daemon (`sshd`)
- `forking` : le processus lancé vas 'Forker' le daemon (`apachectl` pour httpd) il faudra préciser le token PIDFile= qui sera créé par le daemon forké pour permettre à systemed de le controler.
- `dbus` : un daemon avec un nom D-Bus
- `notify` : un daemon qui notifie la fin de son démarrage à `systemd`
- `idle` : un daemon qui sera démarré à la fin du processus de démarrage complet de la *target* (au pire dans 5 secondes)
- `**oneshot**` : une simple commande a lancer une seule fois, le token `RemainAfterExit = yes` précise alors que l'état du service est maintenu une fois la commande passée :
  - avec un code retour 0 : `active`
  - avec un autre code retour : `failed`

La spécification des commandes permettant le démarrage, l'arrêt ou le reload de la config :

- `ExecStop`
- `ExecStart`
- `ExecReload`
- `ExecStartPre`, `ExecStartPost`, `ExecStopPost`, etc.

Les spécifcations nécessaires à l'exécution de celle-ci :

- `TimeoutSec` : le timeout
- `Restart` : est-ce que `systemd` redémarre le service s'il plante : `no`, `on-success`, `on-failure`, `on-abnormal`, `on-watchdog`, `on-abort`, ou `always`
- `KillMode` : comment le service est killé si le stop échoue
- `StandardOutput`, `StandardError` : comment on gère les sorties du processus (voir `man systemd.exec`)
- `Environment` : permet de valoriser des variables d'environnement (voir `man systemd.exec`)
- `EnvironmentFile` : idem mais les variables sont spécifiées dans un fichier
- etc.

> on retrouvera dans la documentation toutes les options propre aux service <https://www.freedesktop.org/software/systemd/man/systemd.service.html> ou plus précisément au lancement d'un processus par systemd: <https://www.freedesktop.org/software/systemd/man/systemd.exec.html> ou a son arrêt: <https://www.freedesktop.org/software/systemd/man/systemd.kill.html>
>
> On notera pour le hardening de service :
>
> - NoNewPrivileges=true qui empèche les élévation de privilège
> - SecureBits=keep-caps,no-setuid-fixup,noroot, et leur pendant -locked qui lists les flag securebit a ajouter sur le service, eux même permettant de limiter les changements sur les capabilities allouées aux threads des processus issue du service
> - MemoryDenyWriteExecute=True qui empèche d'exécuter du code d'un mappig mémoire accessible en écriture
> - SELinuxContext= et AppArmorProfile= qui permet de binder le service sur un contexte selinux ou sur un profile apparmor
> - SystemCallFilter= permettant de limiter les appels system à un subset prédéfinie (man systemd.exec)

#### Gestion des cgroups

Par défaut systemd créé pour chaque service un cgroup sous system.slice

la commande `systemd-cgls` permet de les lister

```bash
root@bullseye:~# systemd-cgls -u system.slice
Unit system.slice (/system.slice):
├─systemd-udevd.service 
│ └─207 /lib/systemd/systemd-udevd
├─cron.service 
│ └─275 /usr/sbin/cron -f
├─systemd-journald.service 
│ └─186 /lib/systemd/systemd-journald
├─unattended-upgrades.service 
│ └─340 /usr/bin/python3 /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal
├─ssh.service 
│ └─550 sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups
├─rsyslog.service 
│ └─284 /usr/sbin/rsyslogd -n -iNONE
├─chrony.service 
│ ├─346 /usr/sbin/chronyd -F 1
│ └─347 /usr/sbin/chronyd -F 1
├─dbus.service 
│ └─276 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
├─system-getty.slice 
│ └─getty@tty1.service 
│   └─341 /sbin/agetty -o -p -- \u --noclear tty1 linux
├─ifup@eth0.service 
│ └─315 /sbin/dhclient -4 -v -i -pf /run/dhclient.eth0.pid -lf /var/lib/dhcp/dhclient.eth0.leases -I -df /var/lib/dhcp/dhclient6>
└─systemd-logind.service 
  └─291 /lib/systemd/systemd-logind
```

Si on précise dans notre unité.service une branche de cgroup (un slice), ici customslice :

```ini
Slice=customslice.slice
ProtectControlGroups=true
```

Notre service sera attaché à ce cgroup précisément nous permettant de regrouper plusieurs service au seins d'un même cgroupe.

#### gestion des ressources

via la surcharge des unité par exemple via un drop-in folder, il est possible d'intégrer des modification sur les unité et ainsi :

un fichier : 00-slice.conf qui associé le service à un cgroup(slice)

```ini
[Service]
Slice=customslice.slice
```

un autre fichier : 10-control-ressources.conf qui active l'accounting et définie des limitation :

```ini
MemoryAccounting=yes
CPUAccounting=yes
IOAccounting=yes
IPAccounting=yes
CPUWeight=512
CPUQuota=50% 
MemoryMax=512M
OOMPolicy=continue, stop or kill
```

> <https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html>

### *Unités* conditionnant l'activation d'un *service*

#### *Unité* de type *socket*

Le *socket-based activation* vient remplacer la daemon `xinetd`.  
Pour rappel, `xinetd` est le super serveur sous GNU/Linux. Il lit un ensemble de spécifications de services réseau, et ouvre les sockets réseau correspondants auprès du kernel, en leur nom. Si une requête réseau est reçue sur le socket alors le processus correspondant est lancé et la requête lui est transmise.

Le daemon `systemd` propose le même type de solution.

Il en existe déjà sur le systeme:

```bash
root@bullseye:~# systemctl list-unit-files -t socket
UNIT FILE                        STATE    VENDOR PRESET
dbus.socket                      static   -            
ssh.socket                       disabled enabled      
syslog.socket                    static   -            
systemd-fsckd.socket             static   -            
systemd-initctl.socket           static   -            
systemd-journald-audit.socket    static   -            
systemd-journald-dev-log.socket  static   -            
systemd-journald-varlink@.socket static   -            
systemd-journald.socket          static   -            
systemd-journald@.socket         static   -            
systemd-networkd.socket          disabled enabled      
systemd-rfkill.socket            static   -            
systemd-udevd-control.socket     static   -   
systemd-udevd-kernel.socket      static   -            

14 unit files listed.
```

On garde une spécification de *service* mais le service n'est pas activé sur le système *(enabled)*.

`/etc/systemd/system/helloworld.service` :

```ini
[Unit]
Description=socket based helloworld Service
After=network.target helloworld.socket
Requires=helloworld.socket

[Service]
Type=simple
Environemennt=FLASK_APP=app.py
WorkingDirectory=/opt/app
ExecStart=flask run --host=0.0.0.0
TimeoutStopSec=5

[Install]
WantedBy=default.target
```

Une unité de type *socket* déclanchera le *service* :

`/etc/systemd/system/helloworld.socket` :

```ini
[Unit]
Description=helloworld Socket
PartOf=helloworld.service

[Socket]
ListenStream=127.0.0.1:5000

[Install]
WantedBy=sockets.target
```

```bash
# systemctl disable --now helloworld.service
# systemctl enable --now helloworld.socket
#  
```

Pour avoir plus d'infos sur les tokens de la section `[Socket]`

```bash
$ man systemd.socket
.../...
$
```

#### Unité de type *timer*

Les *unités* de type *timer* offrent une alternative à cron.

Les tokens de spécification *timer* utilisés :

```bash
root@bullseye:~# systemctl list-unit-files -t timer
UNIT FILE                    STATE    VENDOR PRESET
apt-daily-upgrade.timer      enabled  enabled      
apt-daily.timer              enabled  enabled      
chrony-dnssrv@.timer         disabled enabled      
e2scrub_all.timer            enabled  enabled      
fstrim.timer                 enabled  enabled      
logrotate.timer              enabled  enabled      
man-db.timer                 enabled  enabled      
systemd-tmpfiles-clean.timer static   -            

8 unit files listed.
```

On étudiera les possibilités dans le `man` :

```bash
$ man systemd.timer
.../...
$
```

Voici un exemple d'utilisation :

- On garde une définition de *service*

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=script de backup

[Service]
Type=oneshot
ExecStart=/opt/backup/backup.sh
RemainAfterExit=True

[Install]
WantedBy=multi-user.target
```

- Puis une activation *via* une *unité* de type *timer* :

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Start backup.sh daily

[Timer]
OnCalendar=*-*-* 04:00:00

[Install]
WantedBy=timers.target
```

- qu'on active et démarre

```bash
root@bullseye:~# systemctl enable backup.timer
Created symlink /etc/systemd/system/timers.target.wants/backup.timer → /etc/systemd/system/backup.timer.
root@bullseye:~# systemctl start backup.timer
```

- On dispose d'une vue globale sur les *timers* déclenchés par `systemd` :

```bash
root@bullseye:~# systemctl list-timers
NEXT                        LEFT          LAST                        PASSED UNIT                         ACTIVATES
Sun 2023-09-17 00:00:00 UTC 5h 5min left  n/a                         n/a    logrotate.timer              logrotate.service
Sun 2023-09-17 00:00:00 UTC 5h 5min left  n/a                         n/a    man-db.timer                 man-db.service
Sun 2023-09-17 03:10:55 UTC 8h left       n/a                         n/a    e2scrub_all.timer            e2scrub_all.service
Sun 2023-09-17 04:00:00 UTC 9h left       n/a                         n/a    backup.timer                 backup.service
Sun 2023-09-17 06:18:09 UTC 11h left      n/a                         n/a    apt-daily-upgrade.timer      apt-daily-upgrade.servi>
Sun 2023-09-17 12:40:25 UTC 17h left      Sat 2023-09-16 12:40:25 UTC 6h ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.>
Sun 2023-09-17 14:27:53 UTC 19h left      n/a                         n/a    apt-daily.timer              apt-daily.service
Mon 2023-09-18 00:17:39 UTC 1 day 5h left n/a                         n/a    fstrim.timer                 fstrim.service

8 timers listed.
Pass --all to see loaded but inactive timers, too.
```

le service sera alors lancé automatiquement sur la planification définie.

#### *Unité* de type *path*

Cette *unité* permet de déclencher un *service* sur une modification de fichier.

```bash
root@bullseye:~# systemctl list-unit-files -t path
UNIT FILE                         STATE  VENDOR PRESET
systemd-ask-password-console.path static -            
systemd-ask-password-wall.path    static -            

2 unit files listed.
```

*Unité* `/etc/systemd/system/replicate.path` :

```ini
[Unit]
Description=check for filechange

[Path]
PathChanged=/opt/backup/database.dump
Unit=replicate.service

[Install]
WantedBy=multi-user.target
```

Le *service* qui sera déclenché `/etc/systemd/system/replicate.service` :

```ini
[Unit]
Description=replicate when file has changed.

[Service]
Type=oneshot
ExecStart=/opt/backup/replicate.sh

[Install]
WantedBy=multi-user.target
```

Le script `/opt/backup/replicate.sh` :

```bash
#!/bin/bash
while pidof /opt/backup/backup.sh
do
  echo waiting five minutes for backup process to finish
  sleep 300
done
scp -i ~/.ssh/backup-id-rsa /opt/backup/database.dump backup@othersite.away.com:/opt/replicated/database.dump
```

### unités système

#### unité device

Ces unité sont géré par le service `systemd-udevd.service` de systemd qui vas créé dynamiquement une unité de type device pour chaque device du noyau Linux (et annoté systemd, principalement les device réseaux et en mode block). Cela permet de disposer de relation de dépendance automatiquement entre les  autre unité  et les périphérique dont ils dépendent.

#### unité mount

Ces unités gèrent le montage des systèmes de fichier.

Historiquement les systemes de fichier que nous administrons sont défini et maintenu dans /etc/fstab.
Au boot ces définitions seront convertis dynamiquement en unité systemd par systemd-fstab-generator et donc disponible pour la gestion des dépendances entre les unité. Les systemes de fichiers montés à la vollée seront aussi controlée par systemd au montage.

il est possible de créé ces unité à la vollé via la commande `systemd-mount`.

Il reste possible de créé des fichier d'unité de type $mount$ statique en indiquant des valeurs au tokens dédiés à la section `[mount]` : `What=` et `Where=`, `Type=`, `Options=` ...   :

```bash
root@bullseye:~# systemctl list-unit-files -t mount
UNIT FILE                     STATE     VENDOR PRESET
-.mount                       generated -            
dev-hugepages.mount           static    -            
dev-mqueue.mount              static    -            
proc-sys-fs-binfmt_misc.mount disabled  disabled     
sys-fs-fuse-connections.mount static    -            
sys-kernel-config.mount       static    -            
sys-kernel-debug.mount        static    -            
sys-kernel-tracing.mount      static    -            

8 unit files listed.
root@bullseye:~# systemctl status sys-kernel-config.mount
● sys-kernel-config.mount - Kernel Configuration File System
     Loaded: loaded (/proc/self/mountinfo; static)
     Active: active (mounted) since Sat 2023-09-16 12:25:16 UTC; 2 days ago
      Where: /sys/kernel/config
       What: configfs
       Docs: https://www.kernel.org/doc/Documentation/filesystems/configfs/configfs.txt
             https://www.freedesktop.org/wiki/Software/systemd/APIFileSystems
      Tasks: 0 (limit: 1114)
     Memory: 8.0K
        CPU: 2ms
     CGroup: /sys-kernel-config.mount

root@bullseye:~# mount | grep configfs
configfs on /sys/kernel/config type configfs (rw,nosuid,nodev,noexec,relatime)
```

C'est ainsi que sont géré les points de montage spécifiques et necessaire au kernel.

les unités de type mount disposent implicitement des dépendances :

- Pour la gestion du démontage au shitdown :
  - Before=unoumt.target
  - Conflicts=umount.target
- Pour le montage
  - After=local-fs-pre.target
  - Before=local-fs.target
- Pour les points de montage resaux :
  - After=remote-fs-pre.target, network.target, network-online.target
  - Before=remote-fs.target

> la documentation est plutot claire <https://www.freedesktop.org/software/systemd/man/systemd.mount.html>

##### unité automount

Il reste possible de ces automontage dans /etc/fstab. Nous avons maintenant aussi l'option de créer des fichiers unités permetant de définir un montage automatique à la vollée.

Une section lui est dédiée `[automount]` et elle contiendra les token : `Where=`, `ExtraOptions=`, `DirectoryMode=`, `TimeoutIdleSec=`.

#### unité swap

Cette unité système gére les nameespace de mémoire virtuelle afin de la rendre disponible au kernel ou non dans la gestion de la mémoire du systeme

```bash
$ systemctl status swapfile.swap
● swapfile.swap - /swapfile
     Loaded: loaded (/etc/fstab; generated)
     Active: active since Sat 2023-09-16 11:18:21 CEST; 6 days ago
       What: /swapfile
       Docs: man:fstab(5)
             man:systemd-fstab-generator(8)
      Tasks: 0 (limit: 9063)
     Memory: 32.0K
        CPU: 4ms
     CGroup: /system.slice/swapfile.swap
```

Ici l'unité à été créé à la vollée via la définition de la swap à $l'ancienne$ dans /etc/fstab, l'unité retranscri l'activation de la swap définie dans /etc/fstab.

Aussi ces unités disposent automatiquement des token définissant les dépendances par défaut permettant sont ordonancement : `BindsTo=` et `After=` l'unité device ou mount auquel il se réfère

## Conclusion

Avec ces cours nous avons pus voir les aspects principaux de systemd mais nous sommes loin d'avoir tout vue.

Nous retiendrons que dans un systeme autonome (sans interaction direct avec le systeme) systemd peu prendre en charge toute l'automatisation de la gestion du userspace :

- ordonancement du boot
- mise à disposition des ressources systemes
- démarrage et maintenance des services
- reprise sur erreur de certain services (Restart=on-failure, OnFailure=, OnSuccess=)

Aussi sa maitrise nous offre des options nous permettant de controler le systéme et les applications qui y sont lancées. (gestion des ressource des cgroup, filtre sur les syscalls, context selinux, profile apparmor, etc...)
