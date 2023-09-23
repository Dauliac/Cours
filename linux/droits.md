# Droits Unix

## Présentations

Chaque fichier ou dossier du système possède des **"droits"** (ou **"permissions"**). Ces droits déterminent quel utilisateur a le droit d'accéder ou non à un fichier ou dossier donné.

On définit les droits pour chaque fichier ou dossier pour le compte propriétaire(**U**ser), les membres du groupe propriétaire (**G**roup) et tout les autres (**O**thers).

**Sur un fichier** : Simplement `rwx` pour les droits : **R**ead, **W**rite, e**X**ecute.

**Sur un dossier** :
En considérant un dossier comme un fichier qui liste les entrées qu'il "contient" et une jonction de l'arborescence. l'interprétation des droits est plus simple :

* r : le droit de lister le contenu (la lecture du répertoire)
* w : le droit de créer ou supprimer une entrée dedans (écrire dedans)
* x : traverser le répertoire effectuer une action dedans ou dans un de ces sous répertoire  

## Le mode

Les droits sont un ensemble de flags sur les attributs de fichier ayant une valeur à 0 ou 1.
Pour chacun des User, Group et Other(tous les autres) : on a une suite de 3 flags pour les droits **R**ead **W**rite e**X**ecute.

Exemple :  
`r-x`
**R**ead oui : 1 , **W**rite non : 0 , **E**xecute oui : 1
En binaire 0b101 et en Octal : `1*4 + 0*2 + 1*1 = **5**`

Le mode associé à ces droits est la suite des 3 octaux donc 3 valeurs allant de 0 à 7 pour les user, group et autres.

Exemple de codage complet :  
`rwxr-xr--` : 0x111 0x101 0x100 : le mode associé est 754.

## Les droits avancés

Le **setuid bit** est positionné en général sur un exécutable, il autorise la prise d'identité du propriétaire de l'éxécutable pendant son exécution (s'il fait l'appel system correspondant).

Le **setgid bit** est positionné en général sur un répertoire, tout fichiers créés dans ce répertoire hérite du group propriétaire du répertoire.

Le **sticky bit**, sur un répertoire limite le droit de supression des fichiers qu'il contient à leur propriétaire.

Les droits avancés sont représentés par un **s** pour le setuid et le setgid bit et par un **t** pour le stiky bit, **en lieu et place du x** pour execute.

Il sera en minuscule si le `x` est présent et en majuscule si le `x` est absent.

Exemple : `rwsr-sr-T` : pour `rwxr-xr--` avec setuid, setgid et sticky.

Les set uid, set gid et sticky bit **sont codés sur un autre octal, placé devant les 3 autres.**  
Il vaut 0 si aucun n'est positionné (on omet alors de le préciser).

Puis de la même façon :  
`101` pour `--S --- --T` devient 5 à placer devant le mode standard : ici on a 000, le mode est donc 5000  
`100` pour `--S --- ---` devient 4 à placer devant le mode standard : ici on a 000, le mode est donc 4000  
`001` pour `--- --- --T` devient 1 à placer devant le mode standard : ici on a 000, le mode est donc 1000  

## Commandes

* `chown` : change le owner utilisable par root uniquement
* `chgrp` : change le groupe owner
* `chmod` : modifie les droits sur le fichier/dossier

Pour  `chmod` on utlisera :

* soit la notation avec le mode :
  * `644` ou `640`
* Soit une notation litérale :
  * `u+rwxs` : on ajout `rwx` et setuid pour l'utilisateur
  * `+x` : on ajoute le droits d'exécution à tous
  * `o-w` : On enlève le droits d'écriture à other

## `umask`

Cette commande definie la valeur par défaut du mode pour tout nouveau fichier ou répertoire.  
`umask` : retourne le umask courant  
`umask 022` : spécifie le umask à la valeur 022

C'est le complément octal du mode : 022 pour les droits par défaut 755

Expliquez les umask : 0027 / 027 / 022 / 007.

> **Attention** : le droit d'exécution n'est jamais mis par défaut à la création de fichier il doit être ajouté explictement (`chmod +x`).

Le umask est aussi une valeur utilisée dans les fichiers de configuration de service (exemple ftp) pour spécifier les droits sur les fichiérs créés par ce service.

## TD

### Back office

Dans le cadre de la gestion d'un environement de production d'une application.

Utilisant une arborecence issue de la norme [FHS](../majeure/normes.md#fhs-ou-fsstnd) (bin, lib, var, )

Aves deux groupes de traitements distincts disposant chacun d'un compte et d'un groupe :

* La maintenance de la production : root root
* la livraion de l'applicatif : delivery delivery
* les traitements de l'application : appli appli

Décrivez les droits (owner.groupe mode) pour :

* la racine de l'application
* les dossiers de la racine de l'application
  * bin
  * lib
  * var
  * var/data
  * var/log
  * var/upload
  * etc
* les fichiers de chacun de ces dossiers

### Application Web

Une application web dévelopée en php appli utilisant une organisation standard d'application web sous linux (racine dans /var/www/appli)

Nous avons maintenant 3 groupes de traitement :

* le serveur web : www-data.www-data
* la livraison d'une nouvelle version : delivery.delivery
* Un back office applicatif qui retraite des fichiers uploader : appli.appli

Décrivez les droits (owner.groupe mode) pour :

* la racine de l'application /var/www/appli
* les dossiers de la racine de l'application
  * src (le code php)
  * media
  * upload
  * etc
* les fichiers de chacun de ces dossiers
