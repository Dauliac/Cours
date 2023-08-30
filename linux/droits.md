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

## Exemple

Exemple d'arborescence :

```bash
sudo tree -L 2 -dugp .
.
└── [drwxr-x--- applis   applis  ]  applications
    ├── [drwxrwx--- applis   app1    ]  app1
    ├── [drwxrwx--- applis   app2    ]  app2
    ├── [drwxr-xr-x applis   applis  ]  common  
    └── [drwxrwsr-x applis   applis  ]  share
```

* Seuls les membres du groupe applis ont un accès à l'arbo car aucun droits pour 'Other' sur le dossier
* Chaque application dispose de son espace réservé, accèssible en écriture à tout compte membre du groupe lié à l'appli (rwx sur le groupe)
* Un espace est commun et lisible par tout les comptes membres de applis
* Un espace partagé sans protection des droits
* L'utilisateur applis à tout les droits sur toute l'arbo, il peut alors être utilisé pour l'installation et les mise à jours.
