# Gestion du réseaux avec systemd

- [Gestion du réseaux avec systemd](#gestion-du-réseaux-avec-systemd)
  - [Présentation](#présentation)
    - [Environement de lab](#environement-de-lab)
  - [Commande networkctl](#commande-networkctl)
  - [Configuration réseau](#configuration-réseau)
    - [Exemples de configuration :](#exemples-de-configuration-)
  - [*Unités* *netdev*](#unités-netdev)
    - [Exemple de configuration bonding](#exemple-de-configuration-bonding)
    - [Exemple de configuration VLAN](#exemple-de-configuration-vlan)
  - [Gestion de la résolution DNS](#gestion-de-la-résolution-dns)
    - [Mise en oeuvre](#mise-en-oeuvre)
    - [Configuration resolved](#configuration-resolved)

## Présentation

`systemd` intègre un daemon de configuration réseau appelé `systemd-networkd`, il peut gérer les configurations réseau simples.

Comme pour les *unités* systèmes les *unités* réseau peuvent être définies dans `/lib`, `/run` et `/etc` :

* `/lib/systemd/network`
* `/run/systemd/network`
* `/etc/systemd/network`

Les fichiers qui porte le même nom dans `/etc` prennent la précédence sur ceux de `/run` qui eux-mêmes surchargent ceux de `/lib`.

Il y a trois types d'*unités* liées à ce daemon :

* `unité.link` : pour les liens réseau physiques
* `unité.netdev` : pour les devices virtuels
* et enfin les `unité.network` : de configuration IP des interfaces

La configuration réseau est définie dans les *unités* de type *network*. Nous retrouvons encore toute la documentation dans le `man` associé aux *unités* network, link et netdev :

```bash
$ man systemd.network
.../...
$ man systemd.netlink
.../...
$ man systemd.netdev
.../...
$
```

Les sections principales de ces *unités* sont :

* `Match` : pour identifier si ce fichier s'applique, on définit des conditions, si elle sont remplies alors cette *unité* peut s'appliquer :
  * exemple de token : `MACAddress`, `Host`, `name`(pour le nom de l'interface)
* `Network` : pour la configuration ip
  * exemple de token : `DHCP` (yes/no), `Address`, `Gateway`, `DNS`, `IPForward`
* `Link` : pour paramétrer la couche liaison
  * exemple de token : `MACAddress`, `MTUBytes`, `RequiredForOnline`(`yes` si ce lien est indispensable au *service*)
* `Adsress` : Pour configurer une adresse IP (exemple :  une secondaire)
* `Route` : pour la gestion des route
* le paramétrage DHCP client sera effectué dans la section `DHCP` etc.

### Environement de lab

Nous travaillerons avec 2 vm ubuntu/bionix que nous pouvons set-up avec le vagrant file suivant :

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "256"
     vb.linked_clone = true
  end
  config.vm.define "one" do |one|
    one.vm.network "private_network", ip: "192.168.56.42"
    one.vm.network "private_network", ip: "192.168.56.43"
  end
  config.vm.define "two" do |two|
    two.vm.network "private_network", ip: "192.168.56.44"
    two.vm.network "private_network", ip: "192.168.56.45"
  end
end
```

Il conviendra de commencer par désactiver tout autre daemon de configuration réseau (comme le `NetworkManager`) et d'activer `systemd-networkd`.

Cependant nous surchargerons cette configuration pour nos test (dans /etc)

## Commande networkctl

La commande networkctl founis un status sur la configuration réseaux :

```bash
root@bullseye:~# networkctl status
●   State: routable                        
  Address: 10.0.2.15 on eth0
           192.168.56.42 on eth1
           192.168.56.43 on eth2
           fe80::a00:27ff:fe8d:c04d on eth0
           fe80::a00:27ff:fe9f:d3f5 on eth1
           fe80::a00:27ff:fec9:c35b on eth2
  Gateway: 10.0.2.2 on eth0

Sep 24 21:16:09 bullseye systemd[1]: Starting Network Service...
Sep 24 21:16:09 bullseye systemd-networkd[1577]: eth2: Gained IPv6LL
Sep 24 21:16:09 bullseye systemd-networkd[1577]: eth1: Gained IPv6LL
Sep 24 21:16:09 bullseye systemd-networkd[1577]: eth0: Gained IPv6LL
Sep 24 21:16:09 bullseye systemd-networkd[1577]: Enumeration completed
Sep 24 21:16:09 bullseye systemd[1]: Started Network Service.
```

Avec l'action list, nous avons un statut sur la configuration de ces interface par systemd-networkd

```bash
root@bullseye:~# networkctl list
IDX LINK TYPE     OPERATIONAL SETUP
  1 lo   loopback carrier     unmanaged
  2 eth0 ether    routable    unmanaged
  3 eth1 ether    routable    unmanaged
  4 eth2 ether    routable    unmanaged

4 links listed.
```

## Configuration réseau

Afin d'utiliser systemd-network.

- Nous supprimons la config des interface eth1 et eth2 effectiée par vagrant : 

```bash
root@bullseye:~# ifdown eth1
root@bullseye:~# ifdown eth2
root@bullseye:~# vi /etc/network/interfaces
root@bullseye:~# cat /etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug eth0
iface eth0 inet dhcp
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#auto eth1
#iface eth1 inet static
#      address 192.168.56.42
#      netmask 255.255.255.0
#VAGRANT-END

#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#auto eth2
#iface eth2 inet static
#      address 192.168.56.43
#      netmask 255.255.255.0
#VAGRANT-END
root@bullseye:~# ifup eth1
ifup: unknown interface eth1
root@bullseye:~# ifup eth2
ifup: unknown interface eth2
root@bullseye:~# networkctl list
IDX LINK TYPE     OPERATIONAL SETUP
  1 lo   loopback carrier     unmanaged
  2 eth0 ether    routable    unmanaged
  3 eth1 ether    off         unmanaged
  4 eth2 ether    off         unmanaged
```

### Exemples de configuration : 

Une simple IP statique sur une interface : `/etc/systemd/network/eth1.network`

```ini
[Match]
Name=eth1

[Network]
Address=192.168.0.10/24
Gateway=192.168.0.254
#DNS=192.168.0.254
```

mise en oeuvre: on se contente de reloader la configuration

```bash
root@bullseye:~# networkctl reload
root@bullseye:~# networkctl list
IDX LINK TYPE     OPERATIONAL SETUP
  1 lo   loopback carrier     unmanaged
  2 eth0 ether    routable    unmanaged
  3 eth1 ether    routable    configuring
  4 eth2 ether    off         unmanaged 

4 links listed.
root@bullseye:~# networkctl list
IDX LINK TYPE     OPERATIONAL SETUP
  1 lo   loopback carrier     unmanaged
  2 eth0 ether    routable    unmanaged
  3 eth1 ether    routable    configured
  4 eth2 ether    off         unmanaged 

4 links listed.
```

autre exemple : Activation DHCP pour toute les interfaces en : `/etc/systemd/network/dhcp-on-all.network`

```ini
[Match]
Name=en*

[Network]
DHCP=yes
```

> `systemd.networkd` est evolué, il accepte les notation wildcard comme `Name=en*`. aussi en cas de modification d'une configuration, un simple reload demande à networkd de metre à jour la cofiguration.

## *Unités* *netdev*

Les *unités* *netdev* permettent de définir des devices réseau virtuels. Exemple : le bonding agrégeant 2 liens en master/slave ou en LACP (préférez le master/slave) :

```bash
root@bullseye:~# man systemd.netdev
```

### Exemple de configuration bonding

On ajoute un device virtuel `bond1` de type `bonding` que l'on paramètre:

* `/etc/systemd/network/10-bond1.netdev`:

  ```ini
  [NetDev]
  Name=bond1
  Kind=bond
  
  [Bond]
  Mode=active-backup
  FailOverMACPolicy=active
  TransmitHashPolicy=layer3+4
  LACPTransmitRate=fast
  MIIMonitorSec=1s
  ```
  
  Le `Mode=active-backup` et `FailoverMacPolicy=active` sont nécessaires sans paramétrage spécifique sur les switch (l'interface bond utilisera la mac active)

Pour lequel nous faison une configuration réseau:

* `/etc/systemd/network/10-bond1.network`
  
  ```ini
  [Match]
  Name=bond1
  
  [Network]
  Address=192.168.56.12/24
  BindCarrier=enp0s8 enp0s9
  ```

  nous fixons le status up/down de bond1 à ce que l'une des deux interfaces soit up avec `BindCarrier`

Les interfaces physiques sont alors fixé sur l'interface bond1

* `/etc/systemd/network/10-bond1-s8.network`:
  
  ```ini
  [Match]
  Name=enp0s8
  
  [Network]
  Bond=bond1
  LinkLocalAddressing=no
  ```

* `/etc/systemd/network/10-bond1-s9.network`:
  
  ```ini
  [Match]
  Name=enp0s9
  
  [Network]
  Bond=bond1
  LinkLocalAddressing=no
  ```
  
  On positionne `LinkLocalAddressing=no` afin de préciser que cette interface n'aura pas de configuration ip, cela permet d'avoir un status networkctl à `configured`

### Exemple de configuration VLAN

On ajoute un device virtuel de type VLAN au dessus de l'interface virtuel `bond1` de type `bonding`.

On corrige le bonding défini précédement, afin de supprimer la config ip et d'y insérer un VLAN à la place:

* `/etc/systemd/network/10-bond1.network`:
  
  ```ini
  [Match]
  Name=bond1
  
  [Network]
  BindCarrier=enp0s8 enp0s9
  VLAN=pub
  LinkLocalAddressing=no
  ```

L'interface virtuelle VLAN sera alors aussi définie:

* `/etc/systemd/network/10-vlanpub.netdev`:

  ```ini
  [NetDev]
  Name=pub
  Kind=vlan
  
  [VLAN]
  Id=18
  ```
  
  On précise ici le vlanid

On pourra alors effectuer une config IP sur ce VLAN:

* `/etc/systemd/network/20-pub.network`:
  
  ```ini
  [Match]
  Name=pub
  
  [Network]
  Address=192.168.56.12/24
  ```

Résultat d'une tel configuration :

```bash
root@ubuntu-bionic:~# systemctl restart systemd-networkd
root@ubuntu-bionic:~# networkctl list
IDX LINK             TYPE               OPERATIONAL SETUP
  1 lo               loopback           carrier     unmanaged
  2 enp0s3           ether              routable    configured
  3 enp0s8           ether              carrier     configured
  4 enp0s9           ether              carrier     configured
 19 bond1            ether              carrier     configured
 20 pub              ether              routable    configured
```

## Gestion de la résolution DNS

`systemd` propose un daemon : **`systemd-resolved`** qui gére la configuration du resolver de nom du système.

Il existe plusieurs façons de gérer la configuration de la résolution DNS :

* Utiliser un resolver distant (comme `8.8.8.8` ou sa box)
* Utiliser un resolver distant, mais avec un cache local comme `dnsmaskd`
* Ou disposer en local d'un resolver DNS. A chaque fois il faut configurer plusieurs object.

`systemd` propose une solution qui gère les deux premières solutions simplement.

### Mise en oeuvre

On remplace `/etc/resolv.conf` par un lien vers le fichier géré par `systemd-resolved` et on démarre ce daemon.

```bash
systemctl enable systemd-resolved
mv /etc/resolv.conf /etc/resolv.conf.bak # Create a backup
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl start systemd-resolved.service
```

### Configuration resolved

Dans le fichier `/etc/systemd/resolved.conf`

On notera les tokens :

* `DNS` : les serveurs de nom DNS de forward
* `Cache` : si positionner à `yes` alors le cache est activé
* `Domains` : la liste des domaines par défaut ç essayer lorsqu'on interroge un nom simple (sans domaine)

> Notez que sur réception d'un signal kill SIGUSR2, `systemd-resolved` purge son cache de toute ses entrées, c'est assez pratique des fois.
