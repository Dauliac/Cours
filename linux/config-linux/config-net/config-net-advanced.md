# Configuration réseaux avancée

Ce cours/tuto vous permet de mettre en place les configuration réseaux avancé sous linux

[toc]

## Présentation

En production sur des hosts physiques, on intègre en général du 802.1q (vlan tagging) sur du 802.ab (bonding) afin d'offrir de une redondence d'accès réseaux sur plusieurs vlan.

Pour la virtualisation/conteneurisation on pourra aussi utiliser des Bridges nous permettant de virtualiser un switch et d'y connecter des interface virtuelle

Cela nécessitera de charger des modules du moyau offrant ces fonctionalités et **un environnement réseaux compatible**.

## Vlan tagging

Le kernel supporte la gestion des vlan via le module 8021q :

```bash
ls /lib/modules/`uname -r`/kernel/drivers/kernel/net/8021q/8021q.ko
modprobe 8021q
```

> Le kernel est par ailleur capable d'utiliser à la fois une interface en mode trunk et en mode natif.

La gestion se fait simplement via la commande standard ip

**Configuration manuelle sur l'interface `INTERFACE` du vlan `Y` :**

```bash
ip link add link INTERFACE name vlanY type vlan id Y
ip link set vlanY up
```

### Persistance de la configuration vlan

(valide au prochain boot)

#### tagging Sous RH

Le module 8021q est chargé par défaut

```bash
modinfo 8021q
```

Fichier /etc/sysconfig/network-scripts/ifcfg-INTERFACE

```bash
DEVICE=INTERFACE
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
```

Fichier /etc/sysconfig/network-scripts/ifcfg-INTERFACE.Y :

```bash
DEVICE=INTERFACE.Y
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
USERCTL=no
IPADDR=192.168.58.10
NETMASK=255.255.255.0
VLAN=yes
```

#### tagging Sous Debian

Chargement du module au boot :

Fichier /etc/modules :

```bash
8021q
```

Fichier /etc/network/interfaces:

```bash
iface INTERFACE.Y inet manual
    vlan-raw-device INTERFACE
    address 192.168.58.11
    netmask 255.255.255.0
```

## Bonding

Le bonding est un driver intermédiaire du noyau permettant de regrouper plusieurs interfaces physique en une seule virtuel. (etherchannel, port truncking, vlan trunking…)
Sa mise en place nécessite la présence du module bonding,  de carte réseaux compatible mii-tool et d'une **configuration spécifique sur les interface réseaux coté switch**

**Configuration manuelle d'un bonding `bond0` sur les interface `INT1` et `INT2` :**

```bash
modprobe bonding
ip link add bond0 type bond
ip link set bond0 type bond miimon 100 mode active-backup
ip link set INT1 down
ip link set INT1 master bond0
ip link set INT2 down
ip link set INT2 master bond0
ip link set bond0 up
```

Pour détacher l'interface INT2 du bonnding :

```bash
ip link set INT2 down
```

Mode de bonding :

le mode du bonding bond0 est visible là : `cat /proc/net/bonding/bond0`

- 0 : balance-rr , équilibrage de charge
- 1 : active-backup , la tolérance de panne.
- 2 : balance-xor , répartition par mac de destination
- 3 : broadcast , multiplication des trames
- 4 : 802.3ad , agrégées de façon dynamique selon la norme IEEE et nécéssitant une infra réseaux compatible (LACP)
- 5 : balance-tlb , seule la sortie est load balancée. Le flux entrant est en actif passif (bascule de mac address)
- 6 : balance-alb , tlb + load balancing entrant au niveau ARP réécriture d'adresse MAC sur les packet

paramètres du module :

- miimon : fréquence (ms) du monitoring (via mii ou ethtool)
- downdelay : délai (ms) avant considéré une interface down
- updelay : délai (ms) avant de remettre une interface active
- primary : définie l'interface préféré (Act-Bac)

### Persistance de la configuration bonding

#### bonding Sous RH

Le module est déja chargé par défaut

```bash
modinfo bonding
```

Fichier /etc/sysconfig/network-scripts/ifcfg-bond0 :

```bash
DEVICE=bond0
NAME=bond0
TYPE=Bond
BONDING_MASTER=yes
NM_CONTROLLED=no
BOOTPROTO=none
ONBOOT=yes
IPADDR=192.168.58.10
NETMASK=255.255.255.0
BONDING_OPTS='mode=1 miimon=100'
```

Fichier /etc/sysconfig/network-scripts/ifcfg-INTX:

```bash
DEVICE=INTX
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
```

#### Bonding Sous Debian

Configuration de l'interface bond0 :

Dans certains cas (debian 8 et inférieur) il conviens de définir les interface de bonding au niveau du noyau en configurant des alias au module bonding, cependant cela est fait automatiquement dans les plupart des cas avec la configuration du fichier /etc/network/interfaces

```bash
$ ls /lib/modules/`uname -r`/kernel/drivers/net/bonding/bonding.ko
$ vi /etc/modprobe.d/bonding.conf
alias bond0 bonding
options bond0 -o bond0 mode=1 miimon=100 downdelay=400 updelay=600
$ modprobe bonding
```

> Si nous configurons plusieur bonding il conviendra d'ajouter d'autre alias dans le fichier bonding.conf

Fichier /etc/network/interfaces :

```bash
auto INT1
iface INT1 inet manual

auto INT2
iface INT2 inet manual

auto bond0
iface bond0 inet static
  address 192.168.58.11
  netmask 255.255.255.0
    slaves INT1 INT2
    bond-mode active-backup
    bond-primary INT1
    bond-miimon 100
    bond-downdelay 400
    bond-updelay 600
```

## Bridge

Un bridge est un switch virtuel il permet de lier plusieurs interfaces réelle ou virtuelle sur un réseaux niveau 2 OSI
Nécessite les bridge-utils et le module du noyau :

```bash
ls /lib/modules/`uname -r`/kernel/net/bridge/bridge.ko
yum install bridge-utils
```

**Configuration du Bridge `br0` sur l'interface `INT1`**

On utilise la commande `brctl` package 'bridge-utils'

```bash
brctl addbr br0
brctl addif br0 INT1
```

Le bridge est un switch, attention au spanning tree ! :

```bash
brctl stp br0 on #-> off
brctl showstp br0
brctl showmacs br0
brctl setbridgeprio br0 X
brctl setpathcost br0 port X
brctl maxage br0 time
brctl sethello br0 time
brctl setfd br0 time
```

### Persistance de la configuration

#### RedHat

Fichier /etc/sysconfig/network-scripts/ifcfg-INT1

```bash
DEVICE=INT1
BOOTPROTO=none
ONBOOT=yes
NM_CONTROLLED=no
BRIDGE=br0
```

Fichier /etc/sysconfig/network-scripts/ifcfg-br0

```bash
DEVICE=br0
TYPE=Bridge
IPADDR=192.168.58.10
NETMASK=255.255.255.0
ONBOOT=yes
BOOTPROTO=none
NM_CONTROLLED=no
DELAY=0
```

Debian :

Fichier /etc/network/interfaces

```bash
auto INT1
iface INT1 inet manual
auto  br0
iface br0 inet static
    address 192.168.10.25
    netmask 255.255.255.0
    bridge_ports INT1
    bridge_stp off
    bridge_fd 0
    bridge_waitport 0
```

## Conclusion

Ces configurations sont compatible entre elles. On peu trés bien faire un bridge sur un vlan sur un bonding :

exemple, INT1 et INT2 sont les interfaces physiques, nous créons alors un bonding sur ces deux interfaces puis un vlan 100 sur ce bonding, puis un bridge sur ce vlan :

### RedHat like

/etc/sysconfig/network-scripts/ifcfg-INT1:

```bash
DEVICE=INT1
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
```

/etc/sysconfig/network-scripts/ifcfg-INT2:

```bash
DEVICE=INT2
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
```

/etc/sysconfig/network-scripts/ifcfg-bond0 :

```bash
DEVICE=bond0
NAME=bond0
TYPE=Bond
BONDING_MASTER=yes
NM_CONTROLLED=no
BOOTPROTO=none
ONBOOT=yes
BONDING_OPTS='mode=1 miimon=100'
```

Fichier /etc/sysconfig/network-scripts/ifcfg-bond0.100 :

```bash
DEVICE=bond0.100
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=none
USERCTL=no
VLAN=yes
BRIDGE=br0
```

Fichier /etc/sysconfig/network-scripts/ifcfg-br0

```bash
DEVICE=br0
TYPE=Bridge
IPADDR=192.168.58.10
NETMASK=255.255.255.0
ONBOOT=yes
BOOTPROTO=none
NM_CONTROLLED=no
DELAY=0
```

### Debian like

INT1 et INT2 sont les interfaces physiques :

```bash
auto INT1
iface INT1 inet manual
auto INT2
iface INT2 inet manual
auto bond0
iface bond0 inet static
    slaves INT1 INT2
    bond-mode active-backup
    bond-miimon 100
    bond-downdelay 200
    bond-updelay 200
auto bond0.100
iface bond0.100 inet manual
    vlan-raw-device bond0
auto br0
iface br0 inet static
    address 192.168.58.11
    netmask 255.255.255.0
    bridge_ports bond0.100
    bridge_stp off
    bridge_fd 0
    bridge_waitport 1
```
