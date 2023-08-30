# Scripting bash

## Présentation 

Faire simple c'est compliqué. Il faut savoir quand scripter et quoi.

Un script masque un certain niveau de complexité. Nous nous offrons via quelques scripts une simplification et une standardisation de certaoine opérations de base sur un domaine.

exemple de scripts:

- choix reservation d'ip sur un lan
- déploiement d'une vm
- monitoring d'un host
- deprovisioning d'une ip
- initialisation d'un dépot

le script est une solution temporaire qui perdure jusqu'a ce que l'entité investise dans une meilleur outil ;)

## Principe

* on évite la gestion des problématiques métiers, le script est agnostique.
* sauf exception le script est idempotent
* le script est simple, si le code deviens complexe c'est que l'on a pas lke bon langage de scripting (python s'pa mal du tout)
* une aide simple est disponible
* un cartouche décris le script et son usage

## Bash

Simple, Simple, lisible

```bash
#!/bin/bash
###################
#
#
#
#
#
#
##################

function log {
  
}

function error {
     rt=$1
     shift
     log $*
     exit $rt
}

## fail fast!
test -z "$IP" && error 3 "il faut une ip"

```
