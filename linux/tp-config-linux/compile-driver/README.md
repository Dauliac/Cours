# Compilattion de drivers

Dans certaine situation, il peut être necessaire de compiler un driver par sois même.

Le module pré-compilé n'est pas disponible en package pour la distribution ou celui founi ne réponds pas aux attentes (version, bug , instabilité etc...)

## Principes

A partir du code source du driver, les headers du kernel et avec le compilateur gcc. il est possible de construir en quelques minute l'objet kernel (Kernel Object, fichier .ko)

Malheureusement ce module n'est compatible qu'avec le kernel courant, il sera necessaire de le recompiler après chaque upgrade du kernel.

## Compilation d'un driver

A partir d'une ubuntu bionic avec les packages suivants :

Build-essential fakeroot dpkg-dev perl libssl-dev bc gnupg dirmngr libncurses-dev libelf-dev flex bison lsb-release rsync dwarves

Après avoir installé les headers du kernel courant :

```bash
sudo apt-get install linux-headers-`uname -r`
```

### 1 - Vous récupèrer les sources du driver

D'une carte Ethernet 10/25GB Marvell FastLinQ 41XXX

### 2 - Vous installer le driver sur le system

En suivant les consignes définie dans le code source

### 3 - Vous charger puis supprimer le module `qed` dans le noyau

Avec la command modprobe puis rmmod

vous metrez en évidence avec une commande le fait que le module ai bien &été chargé puis supprimé du noyaux.
