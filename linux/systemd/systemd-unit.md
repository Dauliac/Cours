# tp unité systemd

## myapp

Soit l'appli suivante qui consomme du cpu, de la ram et génère des fichiers :

```bash
#!/bin/bash
######################
#
# Fake app
#
#
######################

dest=${rickoutput:-"./out"}
loadto=${rickloadto:-"/dev/shm"}
loadcount=${rickloadcount:-"409600"}

ram="$loadto/consume.$$"

trap getout 1 2 3 15

function getout() {
  echo end
  rm $ram
  exit 0
}

test -d $dest || mkdir $dest
test -d "$loadto" && test -w "$loadto" || exit 122

dd if=/dev/zero of=$ram count=$loadcount > /dev/null 2>&1

i=0
while true
do
  ((rnd=10 + $RANDOM*20 / 65535))
  echo working for $rnd
  timeout -s 3 $rnd cat /dev/random > /dev/null
  ((i+=1))
  if test "$i" -ge "5"
  then
    tt=`date +%s`
    # start to work
    echo start > $dest/.fic$tt.out
    # consume ram
    dd if=/dev/zero of=$ram.$tt count=$loadcount > /dev/null 2>&1
    sleep 10
    # free ram and finish the file
    rm $ram.$tt
    echo done >> $dest/.fic$tt.out
    mv $dest/.fic$tt.out $dest/fic$tt.out
    echo I build this $dest/fic$tt.out
    i=0
  fi
done
```

Vous l'installerez sous /opt/rsanchez/bin/myapp

## TP

### Services

#### summer

- Definisser l'unité systemd summer qui lance cette appli
  - via le lien symbolique de /opt/summer/bin/summer vers /opt/rsanchez/bin/myapp
  - depuis le compte summer et
  - depuis le dossier /opt/summer
  - vous creez le compte, le dossier, le lien symbolique et l'unité systemd /etc/systemd/system/summer.service
  - vous sauvegarderez la sortie du systemd status summer.service

#### morty

- Definisser l'unité systemd morty qui lance cette même appli
  - via le lien symbolique de /opt/morty/bin/morty vers /opt/rsanchez/bin/myapp
  - avec le compte morty et
  - depuis le dossier /opt/morty et
  - en chargeant le fichier d'environement /opt/morty/.env.
  - vous creez le compte, les dossier, le liens symbolique et l'unité systemd /etc/systemd/system/morty.service
  - vous crerez créez le fichier.env avec les variables
    - `rickoutput` à /opt/morty/didthis
    - `rickloadto` à /opt/morty/usingthis
    - `rickloadamount` à 20480
  - vous sauvegarderez la sortie du systemd status morty.service

### Slices / cgroup

- creez un drop-in folder pour chacune de ces services :
  - `/etc/systemd/system/summer.service.d`
  - `/etc/systemd/system/morty.service.d`
- ajoutez un fichier de configuration dans ces dossier afin que ces unités fassent partie du même cgroup/slice `sanchezfamilly`

  ```ini
  root@bullseye:~# cat /etc/systemd/system/summer.service.d/00-slice.conf 
  [Service]
  Slice=sanchezfamilly.slice
  MemoryAccounting=yes
  CPUAccounting=yes
  ```

  - vous sauvegarderez le status du slice sanchezfamilly.slice
- ajoutez un fichier 10-ressources.conf dans le drop-in de l'unité summer avec :

  ```ini
  [Service]
  CPUQuota=20%
  MemoryLimit=120M
  ```

  - vous redemarrez les service et regarderez les resultat des commandes  `systemd-cgls` et `systemd-cgtop`
    - vous sauvegarderez le status du service summer.service
- Apprès quelques itération summer plante
  - pourquoi
  - la mémoire a-t-elle été libérée (fichier dans /dev/shm/) pourquoi ?
  - vous supprimrez la MemoryLimit pour la suite

### killing services

- après avoir lu/survollé le 'man systemd.kill'
  - vous definirez explicitement la valeur adequat pour le token `KillMode` pour les deux unités
  - vous surchargerez la valeur de timeout par defaut en cas d'arret du service à 30 secondes - positionnerez le FinalKillSignal à 3.
  - netoyer les dossiers des éventuel fichiers perdu /dev/shm et /opt/morty/usingthis/
  - redemarrez les services plusieurs fois et vérifier s'il les fichiers sont bien supprimé ou non.

### unité path

<https://www.freedesktop.org/software/systemd/man/systemd.path.html>

- créer un service jessica.service qui vas récupèrer ce que morty construit et le supprimer au fur et a mesure
  - créez le compte jessica
  - créez l'unité jessica.service sans l'activée

  ```bash
  root@bullseye:~# cat /etc/systemd/system/jessica.service
  [Unit]
  Description="jessica eat all what morty is doing"
  After=network.target

  [Service]
  Type=simple
  User=jessica
  Group=morty
  ExecStart=/usr/bin/find /opt/morty/didthis -name 'fic*' -ls -exec rm {} \;
  ```

  - Créez l'unité jessica.path qui déclenche l'unité jessica.service sur changement du dossier /opt/morty/didthis (PathModified)
  - Vous sauvegarderez l'unité.path créé et un extrait du journal qui montre bien l'activation du service jessica à la création du fichier.

### Unité Timer

- supprimez l'unité path et remplacer là path une unité timer.
  - Vous sauvegarderez l'unité.timer créé et la sortie de  la commande `systemctl list-timers` démontrant que le batch à été lancé.
