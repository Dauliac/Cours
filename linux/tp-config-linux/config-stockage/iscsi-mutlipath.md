# Multipathing

le multipathing consiste en l'utilisation de plusieurs chemin réseaux SAN pour accèder au même périphérique de stockage afin de redonder l'accès à celui-ci.

le driver linux dm_multipath (dm pour device mapper) ajoute une surcouche au driver de stockage afin de gérer cette redondance.

![moultipath](../../../images/Multipath-scsi.png)

Suivant l'infrastructure de stockage, baie de strockage, réseaux, et surtout la carte HBA, le driver de multipathing peu être directement intégré au driver de la carte HBA.

Nous présentons et testons ici un réseaux SAN iscsi et le module dm_multipath ; le principe reste le même sur un SAN en fibre channel et avec un driver dédié.

## Présentation ISCSI

SCSI Small Computer System Interface est à la fois un format de bus physique et un protocole de communication spécialisé pour le transport de bloc de données.

l'initiator est un client SCSI la target est le serveur de stockage.

le I de [iscsi](https://fr.wikipedia.org/wiki/ISCSI) est pour internet, ISCSI c'est l'encasulation du protocol SCSI dans des packet IP.

## Mise en oeuvre

### mise en place d'une target sous debian11

sur une debian11 avec un petit disque secondaire

#### Présentation tagretcli

Targetcli est un server iscsi avec une interface interactive en ligne de commande assez fluide à l'utilisation.

```bash
sudo apt-get -q -y install targetcli-fb
```

La configuration est représenté dans une arborescence, la tabulation permet de lister les commandes possibles : en premier lieux : `create` / `delete` afin de créer ou supprimer les objets de configuration.
On navique dans l'arbo avec `cd` et on consulte avec `ls` : La première commande à essayer : `ls /`
le résultat de la configuration est sauvagrdé ici : `/etc/rtslib-fb-target/saveconfig.json` et peu être restorer avec la commande `/usr/bin/targetctl restore`

#### déploiment et utilisation d'un LUN iscsi

**TL;DR** : `vagrant up`

Le sortie d'écran ci dessous présente :

* Création d'un backstore 'disk01' qui s'appuie sur un disque local (/dev/sdb) (d'autre choix son possible)
* Création de la target iscsi iqn.2023-02.local.lab:thetarget
* Création d'un LUN sur cette target (un lien vers le backstore)
* et enfin d'une acl contenant
  * l'intiator iqn.2023-02.local.lab:theinitiator
  * un login et un mot de passe.

```bash
root@target:~# targetcli 
Warning: Could not load preferences file /root/.targetcli/prefs.bin.
targetcli shell version 2.1.53
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 0]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 0]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]
/> cd backstores/block 
/backstores/block> ls
o- block ...................................................................................................... [Storage Objects: 0]
/backstores/block> create disk01 /dev/sdb
Created block storage object disk01 using /dev/sdb.
/backstores/block> ls
o- block ...................................................................................................... [Storage Objects: 1]
  o- disk01 ........................................................................... [/dev/sdb (256.0MiB) write-thru deactivated]
    o- alua ....................................................................................................... [ALUA Groups: 1]
      o- default_tg_pt_gp ........................................................................... [ALUA state: Active/optimized]
/backstores/block> cd /iscsi
/iscsi> create iqn.2023-02.local.lab:thetarget
Created target iqn.2023-02.local.lab:thetarget.
Created TPG 1.
Global pref auto_add_default_portal=true
Created default portal listening on all IPs (0.0.0.0), port 3260.
/iscsi> cd iqn.2023-02.local.lab:thetarget/tpg1/luns 
/iscsi/iqn.20...get/tpg1/luns> ls
o- luns .................................................................................................................. [LUNs: 0]
/iscsi/iqn.20...get/tpg1/luns> create /backstores/block/disk01 
Created LUN 0.
/iscsi/iqn.20...get/tpg1/luns> cd ../acls 
/iscsi/iqn.20...get/tpg1/acls> create iqn.2023-02.local.lab:theinitiator
Created Node ACL for iqn.2023-02.local.lab:theinitiator
Created mapped LUN 0.
/iscsi/iqn.20...get/tpg1/acls> cd iqn.2023-02.local.lab:theinitiator/
/iscsi/iqn.20...:theinitiator> set auth userid=iscsilog
Parameter userid is now 'iscsilog'.
/iscsi/iqn.20...:theinitiator> set auth password=iscsipass
Parameter password is now 'iscsipass'.
/iscsi/iqn.20...:theinitiator> exit
Global pref auto_save_on_exit=true
Configuration saved to /etc/rtslib-fb-target/saveconfig.json
root@target:~# ss -napt | grep 3260 
LISTEN 0      256          0.0.0.0:3260      0.0.0.0:*                                                          
root@target:~# systemctl enable rtslib-fb-targetctl
Synchronizing state of rtslib-fb-targetctl.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable rtslib-fb-targetctl
```

### mise en place d' un initiator sous debian11

#### Installation sur un host en debian11

```bash
root@initiator:~# apt-get install open-iscsi
Reading package lists... Done
Building dependency tree... Done
.../...
$ service open-iscsi start
.../...
```

#### Configuration open-iscsi

Définition du nom de l'initiator iscsi et découverte du la target

```bash
root@initiator:~# sed -i 's/InitiatorName=.*/InitiatorName=iqn.2023-02.local.lab:theinitiator/' /etc/iscsi/initiatorname.iscsi
root@initiator:~# iscsiadm -m discoverydb -t st -p 192.168.56.10:3260 --discover -l
192.168.56.10:3260,1 iqn.2023-02.local.lab:thetarget
Logging in to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.56.10,3260]
iscsiadm: Could not login to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.56.10,3260].
iscsiadm: initiator reported error (24 - iSCSI login failed due to authorization failure)
root@initiator:~# iscsiadm -m discoverydb -t st -p 192.168.33.10:3260 --discover -l
192.168.33.10:3260,1 iqn.2023-02.local.lab:thetarget
Logging in to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.33.10,3260]
iscsiadm: Could not login to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.33.10,3260].
iscsiadm: initiator reported error (24 - iSCSI login failed due to authorization failure)
```

La target est bien vue mais il n'est pas possible de s'authentifier ; Nous definissons alors les crédentials à utiliser pour s'authentifié sur la target :

```bash
root@initiator:~# cp /etc/iscsi/iscsid.conf /etc/iscsi/iscsid.conf.orig
root@initiator:~# vi /etc/iscsi/iscsid.conf
root@initiator:~# diff /etc/iscsi/iscsid.conf /etc/iscsi/iscsid.conf.orig
42c42
< node.startup = automatic
---
> # node.startup = automatic
45c45
< # node.startup = manual
---
> node.startup = manual
59d58
< node.session.auth.authmethod = CHAP
72,73d70
< node.session.auth.username = iscsilog
< node.session.auth.password = iscsipass
83d79
< discovery.sendtargets.auth.authmethod = CHAP
89,90d84
< discovery.sendtargets.auth.username = iscsilog
< discovery.sendtargets.auth.password = iscsipass
112,113c106
< #node.session.timeo.replacement_timeout = 120
< node.session.timeo.replacement_timeout = 0
---
> node.session.timeo.replacement_timeout = 120
root@initiator:~# systemctl restart iscsid open-iscsi
```

le parametrage `node.session.timeo.replacement_timeout = 0` sera utilisé pour le multipathing il permet de ne pas attendre pour déclarer l'un des chemin ko.

#### Utilisation

on découvre les devices iscsi a disposition :

```bash
root@initiator:~# iscsiadm -m node -L all
Logging in to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.56.10,3260]
Logging in to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.33.10,3260]
Login to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.56.10,3260] successful.
Login to [iface: default, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.33.10,3260] successful.
root@initiator:~# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   20G  0 disk 
└─sda1   8:1    0   20G  0 part /
sdb      8:16   0  256M  0 disk 
sdc      8:32   0  256M  0 disk 
```

Nous avons bien récupèrer le disque mais il aparait une fois par connection iscsi, ici c'est en double, il peu arriver aussi qu'il apraisse en quadruple.

Configurations:

* le nom du client iscsi : /etc/iscsi/initiatorname.iscsi
* Configuration du daemon : /etc/iscsi/iscsid.conf
  * pour mettre le node en démarrage automatique : node.startup = automatic
* les targets:
  * configuration de découverte /etc/iscsi/send_targets/\$TARGET-IP,\$PORT/st_config
  * configuration complete de la session : less /etc/iscsi/nodes/\$IQN/\$TARGET-IP,\$PORT,$SESSION/default

#### Remanence au boot

avec la commande iscsiadm on modifie la configuration des targets et on constate le résultat dans le fichier de configuration

Avant :

```bash
root@initiator:~# grep node.startup /etc/iscsi/nodes/iqn.2023-02.local.lab\:thetarget/192.168.56.10\,3260\,1/default 
node.startup = manual
```

Après :

```bash
root@initiator:~# iscsiadm --mode node -T iqn.2023-02.local.lab:thetarget -p 192.168.56.10:3260 -o update -n node.startup -v automatic
root@initiator:~# grep node.startup /etc/iscsi/nodes/iqn.2023-02.local.lab\:thetarget/192.168.56.10\,3260\,1/default 
node.startup = automatic
```

On applique la configuration sur chaque path

```bash
root@initiator:~# iscsiadm --mode node -T iqn.2023-02.local.lab:thetarget -p 192.168.33.10:3260 -o update -n node.startup -v automatic
```

#### opération sur les sessions iscsi

redécouverte complete après modification sur la baie:

```bash
root@initiator:~# iscsiadm -m session -R
Rescanning session [sid: 10, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.56.10,3260]
Rescanning session [sid: 11, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.33.10,3260]
```

Pour se déconnecter d'une target:

```bash
root@initiator:~# iscsiadm  -m node  --targetname "iqn.2023-02.local.lab:thetarget" --portal "192.168.56.10:3260" --logout
Logging out of session [sid: 8, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.56.10,3260]
Logout of [sid: 8, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.56.10,3260] successful.
root@initiator:~# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0   20G  0 disk 
└─sda1   8:1    0   20G  0 part /
sdc      8:32   0  256M  0 disk 
```

la path /dev/sdc a disparu, on suprime le second :

```bash
root@initiator:~# iscsiadm  -m node  --targetname "iqn.2023-02.local.lab:thetarget" --portal "192.168.33.10:3260" --logout
Logging out of session [sid: 9, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.33.10,3260]
Logout of [sid: 9, target: iqn.2023-02.local.lab:thetarget, portal: 192.168.33.10,3260] successful.
root@initiator:~# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  20G  0 disk 
└─sda1   8:1    0  20G  0 part /
```

pour suprimer les target définitivement:

```bash
root@initiator:~# rm -fr /etc/iscsi/nodes/iqn.2023-02.local.lab\:thetarget/
root@initiator:~# rm -fr /etc/iscsi/send_targets/192.168.56.10,3260
root@initiator:~# rm -fr /etc/iscsi/send_targets/192.168.33.10,3260
reboot
```

> A retenir :
>
>* configuration de l'initiator:
>   * /etc/iscsi/initiatorname.iscsi
>   * /etc/iscsi/iscsid.conf
>* Découverte des targets par socket (a faire sur tout les socket):
   `iscsiadm -m discoverydb -t st -p 192.168.33.10:3260 --discover`
   cette commande créé la configuration 'node' si inexistante
>* Login sur la target (a faire sur tout les socket):
   `iscsiadm  -m node --targetname "iqn.2023-02.local.lab:thetarget" --portal "192.168.33.10:3260" --login`
>* mise en rémanence au boot (a faire sur tout les socket):
   `iscsiadm --mode node -T iqn.2023-02.local.lab:thetarget -p 192.168.56.10:3260 -o update -n node.startup -v automatic`
>* Login sur toute les target connues :
   `iscsiadm -m node -L all`
>* redécouverte sur toute les sessions :
   `iscsiadm -m session -R`

### Multipathing sous debian

#### Installez et configurez multipath sur l'initiator

```bash
root@initiator:~# apt-get -q -y install multipath-tools
.../...
```

On ajout de la configuration à celle par défaut

```bash
root@initiator:~# ls /etc/multipath.conf
ls: cannot access '/etc/multipath.conf': No such file or directory
root@initiator:~# vi /etc/multipath.conf
root@initiator:~# cat /etc/multipath.conf
defaults {
  user_friendly_names yes
  find_multipaths yes
  path_grouping_policy failover
  features "1 queue_if_no_path"
  no_path_retry 100
}
root@initiator:~# systemctl restart multipath-tools.service
root@initiator:~# lsblk
NAME     MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda        8:0    0   20G  0 disk  
└─sda1     8:1    0   20G  0 part  /
sdb        8:16   0  256M  0 disk  
└─mpatha 254:0    0  256M  0 mpath 
sdc        8:32   0  256M  0 disk  
└─mpatha 254:0    0  256M  0 mpath 
root@initiator:~# multipath -l
mpatha (360014058e5d16554dba4910a18c6f228) dm-0 LIO-ORG,disk01
size=256M features='1 queue_if_no_path' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=0 status=active
| `- 1:0:0:0 sdb 8:16 active undef running
`-+- policy='service-time 0' prio=0 status=enabled
  `- 2:0:0:0 sdc 8:32 active undef running
root@initiator:~# ls -al /dev/mapper/mpatha 
lrwxrwxrwx 1 root root 7 Feb 26 11:59 /dev/mapper/mpatha -> ../dm-0
root@initiator:~# ls -al /dev/dm-0 
brw-rw---- 1 root disk 254, 0 Feb 26 11:59 /dev/dm-0
```

Le lien mpatha est créé vers le device mapper dm qui point vers /dev/sdb et relayra les io sur dbc en cas de probleme sur sdb.

#### Tests

##### Préparation de l'environement

```bash
root@initiator:~# fdisk /dev/mapper/mpatha 

Welcome to fdisk (util-linux 2.36.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0x05a40c39.

Command (m for help): p
Disk /dev/mapper/mpatha: 256 MiB, 268435456 bytes, 524288 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 4194304 bytes
Disklabel type: dos
Disk identifier: 0x05a40c39

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (1-4, default 1): 
First sector (8192-524287, default 8192): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (8192-524287, default 524287): 

Created a new partition 1 of type 'Linux' and of size 252 MiB.

Command (m for help): p
Disk /dev/mapper/mpatha: 256 MiB, 268435456 bytes, 524288 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 4194304 bytes
Disklabel type: dos
Disk identifier: 0x05a40c39

Device                   Boot Start    End Sectors  Size Id Type
/dev/mapper/mpatha-part1       8192 524287  516096  252M 83 Linux

Command (m for help): w
The partition table has been altered.
Failed to add partition 1 to system: Invalid argument

The kernel still uses the old partitions. The new table will be used at the next reboot. 
Syncing disks.

root@initiator:~# mkfs -t ext4 /dev/mapper/mpatha-part1
mke2fs 1.46.2 (28-Feb-2021)
Creating filesystem with 258048 1k blocks and 64512 inodes
Filesystem UUID: cbef8540-adc9-434b-a1e8-08a2c3875182
Superblock backups stored on blocks: 
 8193, 24577, 40961, 57345, 73729, 204801, 221185

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done 

root@initiator:~# mkdir /mnt/iscsidisk
root@initiator:~# mount -t ext4 /dev/mapper/mpatha-part1 /mnt/iscsidisk
root@initiator:~# ls /mnt/iscsidisk
lost+found
root@initiator:~# 
```

##### Test

on a 4 sessions ouvertes :

* sur la target ou nous allons simuler des pannes en déconfigurant une carte réseau : `date ; ifdown eth1` ; `date ; ifup eth1`
* sur l'initiator
  * On suit les messages systeme `tail -f /var/log/messages` pour voir les bascules multipath
  * On lance un écriture permanent sur le filesystème `while true; do date >> /mnt/iscsidisk/date; done`
  * On lance régulièrement la commande `multipath -l` pour suivre l'évolution

Statut multipath avant la panne simulé :

```bash
root@initiator:~# date ; multipath -l
Sun Feb 26 12:49:34 UTC 2023
mpatha (360014058e5d16554dba4910a18c6f228) dm-0 LIO-ORG,disk01
size=256M features='1 queue_if_no_path' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=0 status=active
| `- 1:0:0:0 sdb 8:16 active undef running
`-+- policy='service-time 0' prio=0 status=enabled
  `- 2:0:0:0 sdc 8:32 active undef running
```

Résultats du test:

Sur la target on simule une panne à 12:50:46 rétablie à 12:51:19

```bash
root@target:~# date ; ifdown eth1
Sun Feb 26 12:50:46 UTC 2023
root@target:~# date ; ifup eth1
Sun Feb 26 12:51:19 UTC 2023
```

sur l'initiator:

les logs systeme:

```bash
Feb 26 12:50:52 bullseye kernel: [ 7470.860369]  connection13:0: detected conn error (1022)
Feb 26 12:50:57 bullseye kernel: [ 7475.976977]  session13: session recovery timed out after 5 secs
Feb 26 12:50:57 bullseye kernel: [ 7475.990031] device-mapper: multipath: 254:0: Failing path 8:16.
Feb 26 12:50:57 bullseye kernel: [ 7476.006417] sd 2:0:0:0: alua: port group 00 state A non-preferred supports TOlUSNA
Feb 26 12:51:27 bullseye kernel: [ 7506.398684] device-mapper: multipath: 254:0: Reinstating path 8:16.
```

La pannes est détecté après 6 secondes 12:50:52 le kernel essaye de restaurer cette session et échou après 5 secondes et bascule multipath

```bash
Sun Feb 26 12:50:48 UTC 2023
mpatha (360014058e5d16554dba4910a18c6f228) dm-0 LIO-ORG,disk01
size=256M features='1 queue_if_no_path' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=0 status=active
| `- 1:0:0:0 sdb 8:16 active undef running
`-+- policy='service-time 0' prio=0 status=enabled
  `- 2:0:0:0 sdc 8:32 active undef running
```

12:50:48 multipath n'a pas détecté la panne et les io sont bloquée :

```bash
root@initiator:/mnt/iscsidisk# awk '$0!=prev {print $0" "count;prev=$0;count=0}; $0==prev {count++}' /mnt/iscsidisk/date | less
.../...
Sun Feb 26 12:50:45 UTC 2023 842
Sun Feb 26 12:50:46 UTC 2023 828
Sun Feb 26 12:50:47 UTC 2023 831
Sun Feb 26 12:50:57 UTC 2023 96
Sun Feb 26 12:50:58 UTC 2023 341
Sun Feb 26 12:50:59 UTC 2023 828
Sun Feb 26 12:51:00 UTC 2023 848
```

des io on été bloqué pendant 10 secondes, mais le service à repris.

à 12:50:53 multipath n'a toujours pas basculé :

```bash
root@initiator:~# date ; multipath -l
Sun Feb 26 12:50:53 UTC 2023
mpatha (360014058e5d16554dba4910a18c6f228) dm-0 LIO-ORG,disk01
size=256M features='1 queue_if_no_path' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=0 status=active
| `- 1:0:0:0 sdb 8:16 active undef running
`-+- policy='service-time 0' prio=0 status=enabled
  `- 2:0:0:0 sdc 8:32 active undef running
```

la bascule est effective à 12:50:58

```bash
root@initiator:~# date ; multipath -l
Sun Feb 26 12:50:58 UTC 2023
mpatha (360014058e5d16554dba4910a18c6f228) dm-0 LIO-ORG,disk01
size=256M features='1 queue_if_no_path' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=0 status=enabled
| `- 1:0:0:0 sdb 8:16 failed faulty running
`-+- policy='service-time 0' prio=0 status=active
  `- 2:0:0:0 sdc 8:32 active undef running
```

J'ai pour ma part re-effectué les tests après avoir ajouter quelques paramétrages multipath:

* polling_interval 2 (à la place de 5)
* max_polling_interval 8 (à la place de 20)
* fast_io_fail_tmo 3 (à la place de 5)

```bash
root@initiator:~# cat /etc/multipath.conf 
defaults {
 user_friendly_names yes
 find_multipaths yes
 path_grouping_policy failover
 no_path_retry 100
 features "1 queue_if_no_path"
 polling_interval 2
 max_polling_interval 8
 fast_io_fail_tmo 3
}
```

resultats :

incident :

```bash
root@target:~# date ; ifdown eth1
Sun Feb 26 13:14:06 UTC 2023
root@target:~# date ; ifup eth1
Sun Feb 26 13:14:31 UTC 2023
```

trace système :

```bash
Feb 26 13:14:15 bullseye kernel: [ 8874.229334]  connection13:0: detected conn error (1022)
Feb 26 13:14:15 bullseye kernel: [ 8874.230720] sd 1:0:0:0: [sdb] tag#80 FAILED Result: hostbyte=DID_TRANSPORT_DISRUPTED driverbyte=DRIVER_OK cmd_age=9s
Feb 26 13:14:15 bullseye kernel: [ 8874.232755] sd 1:0:0:0: [sdb] tag#80 CDB: Test Unit Ready 00 00 00 00 00 00
Feb 26 13:14:18 bullseye kernel: [ 8877.297492]  session13: session recovery timed out after 3 secs
Feb 26 13:14:18 bullseye kernel: [ 8877.304492] device-mapper: multipath: 254:0: Failing path 8:16.
Feb 26 13:14:18 bullseye kernel: [ 8877.319403] sd 2:0:0:0: alua: port group 00 state A non-preferred supports TOlUSNA
Feb 26 13:14:36 bullseye kernel: [ 8894.986415] device-mapper: multipath: 254:0: Reinstating path 8:16.
```

impact sur les I/O

```test
Sun Feb 26 13:14:05 UTC 2023 815
Sun Feb 26 13:14:06 UTC 2023 794
Sun Feb 26 13:14:07 UTC 2023 796
Sun Feb 26 13:14:08 UTC 2023 814
Sun Feb 26 13:14:09 UTC 2023 824
Sun Feb 26 13:14:10 UTC 2023 807
Sun Feb 26 13:14:18 UTC 2023 564
Sun Feb 26 13:14:19 UTC 2023 52
Sun Feb 26 13:14:20 UTC 2023 840
Sun Feb 26 13:14:21 UTC 2023 842
```

une latence de 8 seconde est tout de même apparue.
