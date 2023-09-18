# Utilisation de LVM

<!-- vim-markdown-toc GitLab -->

* [Mise en place](#mise-en-place)
  * [Création d'un volume groupe](#création-dun-volume-groupe)
  * [Création de filesystem](#création-de-filesystem)
  * [Montage des filesystemes](#montage-des-filesystemes)
  * [Tests d'écritures](#tests-décritures)
* [Agrandir un volume et un filesystem existant](#agrandir-un-volume-et-un-filesystem-existant)
  * [Modifier la taille du volume logique](#modifier-la-taille-du-volume-logique)
  * [Agrandissement du système de fichiers *ext*](#agrandissement-du-système-de-fichiers-ext)
* [Migration de stockage à chaud](#migration-de-stockage-à-chaud)
  * [Mise en place](#mise-en-place-1)
    * [Remise à plat de l'environnement](#remise-à-plat-de-lenvironnement)
    * [Création d'un nouveau LV](#création-dun-nouveau-lv)
    * [Formatage (création du FS)](#formatage-création-du-fs)
    * [Montage et utilisation](#montage-et-utilisation)
  * [Méthode 1 : déplacment à chaud des données](#méthode-1-déplacment-à-chaud-des-données)
    * [Déplacez les blocs de données utilisés](#déplacez-les-blocs-de-données-utilisés)
    * [Réduire le Volume Group](#réduire-le-volume-group)
  * [Méthode 2 : utilisation du *mirroring*](#méthode-2-utilisation-du-mirroring)
    * [Mise en place du RAID](#mise-en-place-du-raid)
    * [Suppression du RAID](#suppression-du-raid)
  * [Conclusion](#conclusion)
* [Les snapshots](#les-snapshots)
  * [Remise à plat](#remise-à-plat)
    * [répartition des PE sur les PV](#répartition-des-pe-sur-les-pv)
    * [Formatage et utilisation](#formatage-et-utilisation)
    * [Création de snapshot](#création-de-snapshot)
    * [Utilisation du snapshot](#utilisation-du-snapshot)
* [Conclusion](#conclusion-1)

<!-- vim-markdown-toc -->

## Mise en place

### Création d'un volume groupe

Vous exécuterez la mise en place par vous même, pas de copier coller pour cette partie.

* Ajoutez 3 disques de 200MB à une nouvelle VM
* Découverte des disques ajoutés :

  ```bash
  [root@localhost ~]$ dmesg | grep disk
  sd 2:0:0:0: [sda] Attached SCSI disk
  sd 3:0:0:0: [sdb] Attached SCSI disk
  sd 4:0:0:0: [sdc] Attached SCSI disk
  sd 5:0:0:0: [sdd] Attached SCSI disk
  ```

* Création des volumes physiques (PV) avec la commande `pvcreate` à appliquer sur deux des nouveaux disques
* Consultation des volumes physiques (PV) avec la commande `pvdisplay`
* Création du Volume Groups `vgdata` (VG) avec la commande `vgcreate` (sur les deux premiers PV)
* Création et test d'un volume logique (LV) `lv1` sur le Volume Group (VG) `vgdata`
* Avec la commande `pvdisplay` vérifier l'usage des PE (*Physical Extent*) sur les différents volumes physiques (PV)
* Le volume est alors visible au travers du *"device mapper"* :

  ```bash
  [root@localhost ~]$ ls -al /dev/mapper/
  total 0
  drwxr-xr-x.  2 root root    120 Jan 18 22:41 .
  drwxr-xr-x. 19 root root   3740 Jan 18 22:41 ..
  crw-rw----.  1 root root 10, 58 Jan 18 22:13 control
  lrwxrwxrwx.  1 root root      7 Jan 18 22:41 vgdata-lv1 -> ../dm-2
  lrwxrwxrwx.  1 root root      7 Jan 18 22:13 VolGroup-lv_root -> ../dm-0
  lrwxrwxrwx.  1 root root      7 Jan 18 22:13 VolGroup-lv_swap -> ../dm-1
  ```

### Création de filesystem

**Sur le volume logique (LV) `lv1` et sur le 3ème disque :**

```bash
[root@localhost ~]$ mke2fs -t ext3 /dev/dm-2
…/…
Maximum filesystem blocks=67371008
10 block groups
8192 blocks per group, 8192 fragments per group
2048 inodes per group
Superblock backups stored on blocks:
 8193, 24577, 40961, 57345, 73729
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
…/…
[root@localhost ~]$ mke2fs -t ext3 /dev/sdd
mke2fs 1.41.12 (17-May-2010)
/dev/sdd is entire device, not just one partition!
Proceed anyway? (y,n) y
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
…/…
```

### Montage des filesystemes

```bash
[root@localhost ~]$ mkdir /mnt/sdd /mnt/lv1
[root@localhost ~]$ mount -t ext3 /dev/dm-2 /mnt/lv1
[root@localhost ~]$ mount -t ext3 /dev/sdd /mnt/sdd
[root@localhost ~]$ df
Filesystem           1K-blocks   Used Available Use% Mounted on
/dev/mapper/VolGroup-lv_root
                       6795192 796232   5647116  13% /
tmpfs                   251020      0    251020   0% /dev/shm
/dev/sda1               487652  57575    404477  13% /boot
/dev/mapper/vgdata-lv1
                         79327   5663     69568   8% /mnt/lv1
/dev/sdd                198337   5663    182434   4% /mnt/sdd
```

### Tests d'écritures

Avec la commande `dd` :

```bash
[root@localhost ~]$ dd if=/dev/zero of=/mnt/lv1/zerofile bs=512 count=40960
40960+0 records in
40960+0 records out
20971520 bytes (21 MB) copied, 0.147763 s, 142 MB/s
[root@localhost ~]$ dd if=/dev/zero of=/mnt/sdd/zerofile bs=512 count=40960
40960+0 records in
40960+0 records out
20971520 bytes (21 MB) copied, 0.174145 s, 120 MB/s
```

On réalisera plusieurs opérations de ce type pour tester la vitesse d'écriture.

> On constate que le surcoût lié à l'utilisation de LVM est très légr sur les écritures.

## Agrandir un volume et un filesystem existant

> Cette opération peut être faite sans démonter le système de fichiers.

le volume `lv1` :

```bash
[root@localhost ~]$ lvs
  LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup -wi-ao----   6.71g
  lv_swap VolGroup -wi-ao---- 816.00m
  lv1     vgdata   -wi-ao----  80.00m
```

### Modifier la taille du volume logique

Avec la commande `lvresize` :

```bash
[root@localhost ~]$ lvresize -l +10 /dev/mapper/vgdata-lv1
  Size of logical volume vgdata/lv1 changed from 80.00 MiB (20 extents) to 120.00 MiB (30 extents).
  Logical volume lv1 successfully resized
[root@localhost ~]$ lvs
  LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup -wi-ao----   6.71g
  lv_swap VolGroup -wi-ao---- 816.00m
  lv1     vgdata   -wi-ao---- 120.00m
```

Mais le filesystem, lui, n'a pas changé de taille :

```bash
[root@localhost ~]$ df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                      6.5G  786M  5.4G  13% /
tmpfs                 246M     0  246M   0% /dev/shm
/dev/sda1             477M   57M  395M  13% /boot
/dev/mapper/vgdata-lv1
                       78M   26M   48M  35% /mnt/lv1
/dev/sdd              194M   26M  159M  14% /mnt/sdd
```

### Agrandissement du système de fichiers *ext*

Avec la commande `resize2fs` :

```bash
[root@localhost ~]$ resize2fs /dev/mapper/vgdata-lv1 120M
resize2fs 1.41.12 (17-May-2010)
Filesystem at /dev/mapper/vgdata-lv1 is mounted on /mnt/lv1; on-line resizing required
old desc_blocks = 1, new_desc_blocks = 1
Performing an on-line resize of /dev/mapper/vgdata-lv1 to 122880 (1k) blocks.
The filesystem on /dev/mapper/vgdata-lv1 is now 122880 blocks long.
[root@localhost ~]$ df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                      6.5G  786M  5.4G  13% /
tmpfs                 246M     0  246M   0% /dev/shm
/dev/sda1             477M   57M  395M  13% /boot
/dev/mapper/vgdata-lv1
                      117M   26M   85M  24% /mnt/lv1
/dev/sdd              194M   26M  159M  14% /mnt/sdd
```

> **Pour les systèmes de fichiers `xfs`, on utilisera la commande `xfs_growfs`.**

## Migration de stockage à chaud

### Mise en place

#### Remise à plat de l'environnement

On démonte les filsystems, et on supprime `lv1` :

```bash
[root@localhost ~]$ umount /mnt/sdd
[root@localhost ~]$ umount /mnt/lv1
[root@localhost ~]$ lvremove /dev/vgdata/lv1
Do you really want to remove active logical volume lv1? [y/n]: y
  Logical volume "lv1" successfully removed
[root@localhost ~]$ lvs
  LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup -wi-ao----   6.71g
  lv_swap VolGroup -wi-ao---- 816.00m
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 196.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 196.00m
```

#### Création d'un nouveau LV

Avec la commande `lvcreate` on recréer un lv `lv1`, on constate que tous les blocs sont sur `/dev/sdb` :

```bash
[root@localhost ~]$ lvcreate -l 20 vgdata --name lv1
  Logical volume "lv1" created.
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 116.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 196.00m
```

#### Formatage (création du FS)

```bash
[root@localhost ~]$ mke2fs -t ext3 /dev/mapper/vgdata-lv1
mke2fs 1.41.12 (17-May-2010)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=0 blocks, Stripe width=0 blocks
20480 inodes, 81920 blocks
4096 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=67371008
10 block groups
8192 blocks per group, 8192 fragments per group
2048 inodes per group
Superblock backups stored on blocks:
 8193, 24577, 40961, 57345, 73729

Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

This filesystem will be automatically checked every 30 mounts or
180 days, whichever comes first.  Use tune2fs -c or -i to override.
```

#### Montage et utilisation

Notez que le volume peut avoir plusieurs noms ou chemins :

```bash
[root@localhost ~]$ ls -al /dev/mapper/vgdata-lv1
lrwxrwxrwx. 1 root root 7 Jan 19 22:46 /dev/mapper/vgdata-lv1 -> ../dm-2
[root@localhost ~]$ mount -t ext3 /dev/dm-2 /mnt/lv1
```

Nous allons utiliser un `bash` et la commande `while` attachée à un terminal `screen`. Ceci pour simuler un processus qui écrit en permanance sur le volume logique (LV) :

```bash
[root@localhost ~]$ yum install screen
…/...
[root@localhost ~]$ screen bash
[root@localhost ~]$ while true; do echo `date` >> /mnt/lv1/timer; sleep 1; done &
[root@localhost ~]$
```

`screen` est un serveur de terminal, indépendant du terminal sur lequel il tourne. **On peut le quitter avec la succession de touches : `[Ctrl]+a [Ctrl]+d`**.

### Méthode 1 : déplacment à chaud des données

#### Déplacez les blocs de données utilisés

Avec la commande `pvmove`, de `sdb` vers `sdc` :

```bash
[root@localhost ~]$ pvmove /dev/sdb /dev/sdc
  /dev/sdb: Moved: 5.0%
  /dev/sdb: Moved: 100.0%
```

Les blocs ont bien été déplacés :

```bash
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 196.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 116.00m
```

#### Réduire le Volume Group

Nous pouvons sortir `sdb` du Volume Group (VG) `vgdata` vu que tous ses PV sont libres :

Nous utilisons la commande `vgreduce` :

```bash
[root@localhost ~]$ vgreduce vgdata /dev/sdb
  Removed "/dev/sdb" from volume group "vgdata"
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb            lvm2 ---  200.00m 200.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 116.00m
```

`sdb` n'est plus affecté à un Volume Group (VG), le processus ne s'est pas arrété et a continué d'accéder au volume :

```bash
[root@localhost ~]$ screen -r
[root@localhost ~]$ tail -f /mnt/lv1/timer
…/…
[Ctrl]+a [Ctrl]+d
```

### Méthode 2 : utilisation du *mirroring*

#### Mise en place du RAID

Remettez le volume physique (PV) `sdb` dans le Volume Group (VG).

```bash
[root@localhost ~]$ vgextend vgdata /dev/sdb
  Volume group "vgdata" successfully extended
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 196.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 116.00m
```

Convertissez le volume en volume "mirroré" (RAID 1) avec la commande `lvconvert` et l'option `-m` pour miroir et `1` pour le nombre de copie.

```bash
[root@localhost ~]$ lvconvert -m 1 --mirrorlog core /dev/vgdata/lv1
vgdata/lv1: Converted: 15.0%
vgdata/lv1: Converted: 100.0%
```

Vous pouvez constater que maintenant les deux volumes physiques (PV) sont occupés à hauteur de 80MB :

```bash
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 116.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 116.00m
[root@localhost ~]$ lvdisplay -v /dev/vgdata/lv1
    Using logical volume(s) on command line.
  --- Logical volume ---
  LV Path                /dev/vgdata/lv1
  LV Name                lv1
  VG Name                vgdata
  LV UUID                022lG2-cjAk-1X8U-xkBZ-Qpz8-AAjC-CMU3At
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2016-01-19 22:39:41 +0100
  LV Status              available
  # open                 1
  LV Size                80.00 MiB
  Current LE             20
  Mirrored volumes       2
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:2
```

#### Suppression du RAID

Vous pouvez reconvertir le LV en non mirroré et en choisissant le volume physique (PV) sur lequel le mirroir doit être supprimé : `sdc`.

```bash
[root@localhost ~]$ lvconvert -m 0 /dev/vgdata/lv1 /dev/sdc
  Logical volume lv1 converted.
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 116.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 196.00m
```

Nous pouvons alors sortir le volume physique (PV) `sdc` du Volume Group (VG) :

```bash
[root@localhost ~]$ vgreduce vgdata /dev/sdc
  Removed "/dev/sdc" from volume group "vgdata"
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 116.00m
  /dev/sdc            lvm2 ---  200.00m 200.00m
```

### Conclusion

Nous avons migré les données du PV `sdb` vers `sdc` puis du PV `sdc` vers `sdb`. Nous pouvons enfin valider que l'utilisation du volume n'est pas impacté et du coup l'arrêter :

`fg` pour rappeler la commande `while` en premier plan et l'arrêter avec un `[ctrl]c`.

```bash
[root@localhost ~]$ screen -r
…/…
[ctrl]c
[root@localhost ~]$ fg
while true; do
    echo `date` >> /mnt/lv1/timer; sleep 1;
done
[ctrl]c
```

## Les snapshots

### Remise à plat

On démonte et supprime le volume logique (LV) puis on remet `sdc` dans le Volume Group (VG) :

```bash
[root@localhost ~]$ umount /dev/mapper/vgdata-lv1
[root@localhost ~]$ df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                      6.5G  787M  5.4G  13% /
tmpfs                 246M     0  246M   0% /dev/shm
/dev/sda1             477M   57M  395M  13% /boot
[root@localhost ~]$ lvremove /dev/vgdata/lv1
Do you really want to remove active logical volume lv1? [y/n]: y
  Logical volume "lv1" successfully removed
[root@localhost ~]$ vgextend vgdata /dev/sdc
  Volume group "vgdata" successfully extended
```

On retrouve un Volume Group (VG) `vgdata` avec 2 PV `sdb` et `sdc`

```bash
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 196.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 196.00m
```

#### répartition des PE sur les PV

Création d'un volume en utilisant la fonction stripe permettant de répartir les blocs logiques sur les volume physique :

```bash
[root@localhost ~]$ lvcreate -l 20 vgdata --name lv1 --stripes 2
  Using default stripesize 64.00 KiB.
  Logical volume "lv1" created.
[root@localhost ~]$ pvs
  PV         VG       Fmt  Attr PSize   PFree
  /dev/sda2  VolGroup lvm2 a--    7.51g      0
  /dev/sdb   vgdata   lvm2 a--  196.00m 156.00m
  /dev/sdc   vgdata   lvm2 a--  196.00m 156.00m
```

Dans le cas de l'utilisation de disque physique et non virtuel cela permet de répartir les lectures et écritures sur les 2 disques.

#### Formatage et utilisation

```bash
[root@localhost ~]$ mke2fs -t ext3 /dev/mapper/vgdata-lv1
…/…
[root@localhost ~]$ mount -t ext3 /dev/mapper/vgdata-lv1 /mnt/lv1
[root@localhost ~]$ df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                      6.5G  787M  5.4G  13% /
tmpfs                 246M     0  246M   0% /dev/shm
/dev/sda1             477M   57M  395M  13% /boot
/dev/mapper/vgdata-lv1
                       78M  5.6M   68M   8% /mnt/lv1
```

On ajoute des données sur le volume logique (LV) `lv1` :

```bash
[root@localhost ~]$ cp /var/log/* /mnt/lv1/
cp: omitting directory `/var/log/audit'
[root@localhost ~]$ ls -al /mnt/lv1/
total 869
drwxr-xr-x. 3 root root   1024 Jan 19 23:29 .
drwxr-xr-x. 4 root root   4096 Jan 18 22:47 ..
-rw-------. 1 root root   4550 Jan 19 23:29 anaconda.ifcfg.log
-rw-------. 1 root root  19984 Jan 19 23:29 anaconda.log
…/…
```

#### Création de snapshot

Création d'un snapshot `lv1-snap` du volume `lv1` de 10 PE (40 MB) :

```bash
[root@localhost ~]$ lvcreate -l 10 --snapshot /dev/vgdata/lv1 --name lv1-snap
  Logical volume "lv1-snap" created.
[root@localhost ~]$ lvs
  LV       VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root  VolGroup -wi-ao----   6.71g
  lv_swap  VolGroup -wi-ao---- 816.00m
  lv1      vgdata   owi-aos---  80.00m
  lv1-snap vgdata   swi-a-s---  40.00m      lv1    0.03
```

#### Utilisation du snapshot

Suppression d'une partie des fichiers :

```bash
[root@localhost ~]$ rm -f /mnt/lv1/*log
[root@localhost ~]$ ls -al /mnt/lv1/*log
ls: cannot access /mnt/lv1/*log: No such file or directory
```

Création d'un point de montage et montage (en lecture seule) du snapshot :

```bash
[root@localhost ~]$ mkdir /mnt/lv1-snap
[root@localhost ~]$ mount -t ext3 -o ro /dev/vgdata/lv1-snap /mnt/lv1-snap
```

Nous pouvons alors récupérer nos fichiers :

```bash
[root@localhost ~]$ ls -al /mnt/lv1-snap/*log
-rw-------. 1 root root   4550 Jan 19 23:29 /mnt/lv1-snap/anaconda.ifcfg.log
-rw-------. 1 root root  19984 Jan 19 23:29 /mnt/lv1-snap/anaconda.log
-rw-------. 1 root root  27224 Jan 19 23:29 /mnt/lv1-snap/anaconda.program.log
-rw-------. 1 root root  99452 Jan 19 23:29 /mnt/lv1-snap/anaconda.storage.log
-rw-------. 1 root root  41511 Jan 19 23:29 /mnt/lv1-snap/anaconda.syslog
-rw-------. 1 root root   2606 Jan 19 23:29 /mnt/lv1-snap/anaconda.yum.log
-rw-r--r--. 1 root root   1590 Jan 19 23:29 /mnt/lv1-snap/boot.log
-rw-r--r--. 1 root root 374236 Jan 19 23:29 /mnt/lv1-snap/dracut.log
-rw-r--r--. 1 root root 146000 Jan 19 23:29 /mnt/lv1-snap/lastlog
-rw-------. 1 root root      0 Jan 19 23:29 /mnt/lv1-snap/maillog
-rw-------. 1 root root      0 Jan 19 23:29 /mnt/lv1-snap/tallylog
-rw-------. 1 root root    256 Jan 19 23:29 /mnt/lv1-snap/yum.log
[root@localhost ~]$ lvs
  LV       VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root  VolGroup -wi-ao----   6.71g
  lv_swap  VolGroup -wi-ao---- 816.00m
  lv1      vgdata   owi-aos---  80.00m
  lv1-snap vgdata   swi-aos---  40.00m      lv1    0.14
```

Puis supprimer le snapshot :

```bash
[root@localhost ~]$ umount /mnt/lv1-snap
[root@localhost ~]$ lvremove /dev/vgdata/lv1-snap
Do you really want to remove active logical volume lv1-snap? [y/n]: y
  Logical volume "lv1-snap" successfully removed
[root@localhost ~]$ lvs
  LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup -wi-ao----   6.71g
  lv_swap VolGroup -wi-ao---- 816.00m
  lv1     vgdata   -wi-ao----  80.00m
```

## Conclusion

Nous n'avons pas tout vu. En revanche, nous en avons vu assez pour comprendre que LVM est incontournable dans la gestion du stockage des systèmes Unix.
