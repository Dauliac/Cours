# Scripting bash

## Présentation

Faire simple c'est compliqué!

Il faut savoir quand scripter et quoi.

Un script masque un certain niveau de complexité a son utilisateur.

- une forme de pense bète :
  - comment on fait ça déja ?
  `script -h`
  `usage: script -a arguement`
- une simplification :
  - pull-updates.sh
  toutes les actions de mise à jour on été placé dans le script
- une standardisation :
  - create-new-instance.sh
  Toutes les instances sont maintenant créé de la même façon, en modifiant ce script on met à jour le standard d'une instance

exemple de scripts:

- Reservation d'une ip sur un lan
- monitoring d'un nouveau host
- mise à jour d'une application
- initialisation d'un dépot

le script est une solution temporaire qui perdure jusqu'a ce que l'entité investise dans un meilleur outil ;)

## Langages

- sh: c'est brut! Légé mais vraiment rude
- bash: c'est surtout pour des actions utilitaires
- sed awk : c'est pour eviter d'utiliser les mlangage plus évoluer
- perl: bon c'est chacun sont goût, moi j'évite, ça a vraiment son charme (posix sh sed regex) mais il faut de la pratique
- python: on peu vraiment traiter des sujets ici attention agarder son code bien lisible et bien gerer les erreursb (try: except: explicite)
- ansible: spécialisé sur les opérations d'admin courantes, il facilite grandement l'idempotence mais attention au coût de dev et maintenace

en vrai tous ces outils doivent être connus

## Principes

- Fail Fast, le script gère les erreur d'usage
- sauf exception le script est **idempotent**
- on évite la gestion des problématiques métiers, le script est agnostique. (**les métiers autre que le notre!**)
- le script est simple, si le code deviens trop complexe c'est que l'on a pas le bon langage de scripting (python c'est mal du tout)
- un cartouche décris le script, son usage, ses dépendances
- une aide d'usage simple est disponible avec l'option -h

> Afin de permettre une maintenance efficace on ne traite dans un script que de réduire la complexité pour l'utilisateur du script. Il ne doit pas contenir de la gestion métier autre que le métier de l'utilisateur du script.

## Exemple Bash

Simple, Simple, lisible

```bash
#!/bin/bash
###################
# 
# ce début de script traite une ip
#
# versions :
#        - v0.1
#
##################

function log {
    echo $*
}

function error {
     rt=$1
     log error: code:$*
     usage
     exit $rt
}

function usage {
     echo usage: 
     echo    $0 adresse-ip
}

## recupération de variable
ip=$1

## fail fast
test -z "$ip" && error 3 "il faut une ip"

## Main
echo traitement de l\'ip $ip
exit 0
```

## Exemple

La plus grosse contrainte c'est de gerer les bonnes pratiques afin de permettre (et pas uniquement faciliter) la maintenance.

### Théorie

- Des script bash locaux aux hosts qui:
  - masquent les spécificités locale (scripts identique mais avec une config locale)
  - execute des opérations unitaire simple avec idempotence
- Un outil centrale qui orchestre les appels aux scripts locaux et réalise l'ensemble d'un processus
  - provisioning / deprovisioning
  - migration / renommage

### exemple concret

mise à jour d'un certificat :

- un script local dans une unité systemd.timer qui check la présence d'un nouveau certificat ssl 'newcert'
- s'il est présent et qu'il a une config associé :
  - destination 'oldcert'
  - commande de prise en compte
- test la validité de newcert s'il est valide,
  - renome l'ancien en .old
  - lance la commande de prise en compte
- si le code retour de la prise en compte est non null
  - on remet l'ancien et genere un warning

Orchestration :

- le playbook ansible de redéploiement du nouveau certificat se contente de placer le certificat dans le dossier pour les nouveau certficvat sur tout les hosts qui l'utilisent, chacun s'occupant de sa mis à jour.
- le role ansible de déploiement d'un certificat :
  - créer le dossier pour les nouveau certficat
  - l'unité sustemd et la config

Nous créon un standard de gestion des renouvelement de certificats SSL en offrant une api au équipes de dev qui les utilisent :

- Ils déploient le certificat avec le role ansible fourni
- Livre la commande de prise en compte des nouveau certificat : `nginx -t && systemctl restart nginx || exit 2`

## Conclusion

l'open source nous permet via l'automatisation de nous eviter le traitement de taches récurente et fastidueuse la maitrise que quelques kangage de scripting est indispenssable a notre métier

> [scripting bash](./scripting.md)
