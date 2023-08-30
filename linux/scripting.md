# Scripting

## présentation

Un script est une macro opération sur le système, il effectue une série d'opérations unitaires cohérentes, Une suite de lignes de commande.  

Le script est un fichier texte, contenant un programme codé dans un langage interprété.  

Les shell scripts, script en langage shell, sont présents dans presque tous les systèmes Unix.  

Comme tout programme, il devra être versionné et documenté.

> Méthode de dev :
Presque toutes les opérations unitaires d'un script shell peuvent être testées en ligne de commande.
Ma méthode de dev : J'exécute pas à pas le script tout en le développant. J'utilise 2 terminaux, un dans lequel j'exécute les commandes, le second dans lequel j'écris le script.

### Le shebang

Pour beaucoup de langage, le caractère `#` est utilisé pour mettre en commentaire tous les caractères qui le suivent.

On place la chaîne #!/un/chemin/vers/un/executable en début de script définit la ligne de commande d’interprétation du script. Une fois lu par le shell elle sera considéré comme un commentaire. En cas d'exécution elle permet de définir le langage d'interpretation.

Si le fichier premiershell.sh commence par la ligne
`#!/bin/sh`

Alors il serait exécuté via la commande :

```bash
/bin/sh premiershell.sh
```

### Exécution

Le script doit être exécutable pour l'utilisateur l'appelant. La commande suivante donne le [droit](./droits.md) d'exécution pour tout les utilisateurs.

```bash
prompt$ chmod +x premiershell.sh
```

le script n'étant pas dans un répertoire du PATH il faut spécifier son chemin pour l’exécuter.

Exemple:

```bash
prompt$ ./premiershell.sh
```

ou

```bash
prompt$ /home/alan/bin/premiershell.sh
```

dans le cas ou j'ai placer le script dans mon dossier bin personnel. Cependant dans le cas ou se dossier existe à la connexion il est déja ajouté dans mon path.

> question subsidiaire : trouvez pourquoi.

On peu aussi lancer le script en mode debug avec la commande suivante :  

```bash
prompt$ sh -x ./premiershell.sh
```

Le bash affiche alors chaque commande après interpretation et avant son exécution

> Faites donc un script "hello world" qui affiche hello world

## Variables

En plus des variables d’environnement vous pouvez utiliser les variables interne au shell :

### paramètres

* `$0` : la commande courante (l'appel du script)
* `$1...$n` : les arguments du script
* `$*` : L'ensemble des paramètres en une chaine de caractère
* `$@` : L'ensemble des paramètres en plusieurs paramètres : ('arg1' 'arg2' 'arg3')
* `$#` : le nombre de paramètres

La commande interne shift permet d'effectuer une rotation des paramètres : on perd le premier , le second passe premier, le troisième passe second et ainsi de suite

Mise en évidence :

Je créé le script check-args :

```sh
prompt$ cat ./check-args
#!/bin/sh

echo '$@' : $@
echo '$*' : $*
echo '$#' : $#
echo '$1' : $1
echo '$2' : $2
echo '$3' : $3

echo shifting
shift

echo résultat :
echo '$1' : $1
echo '$2' : $2
echo '$3' : $3
```

Je le lance :

```sh
prompt$ ./check-args 1 2 3 4
$@ : 1 2 3 4
$* : 1 2 3 4
$# : 4
$1 : 1
$2 : 2
$3 : 3
shifting
résultat :
$1 : 2
$2 : 3
$3 : 4
```

### variable de contrôle

Déjà vue précédamment dans la gestion des processus

* `$$` : le PID
* `$PPID` : le parent PID
* `$PWD` : le dossier courant
* `$?` : code retour dernière commande (pour savoir si elle s'est bizen passé)
* `$!` : pid de la dernière commande lancé en arrière plan

#### la variable IFS

Pour **I**nternal **F**ield **S**eparator

C'est le séparateur de champs standard interne au shell pour les boucles (entre autres).

Par défaut elle contiens Un espace, Une tabulations et le caractère "fin de ligne" :  

```bash
prompt$ echo "--$IFS--"
--
--
prompt$
```

Utilisation :

Je sauvegarde la valeur de IFS dans la variable `oldIFS` et je la re-déffinie en un caractère "fin de ligne".

Soit en utilisant les double cote encadrant ce caratère :

```bash
prompt$ oldIFS=$IFS
prompt$ IFS="
"
```

Soit en utilisant la combinaison de touche '[ctrl]v' qui supprime la caractère spécicifque de la prochaine touch sur le clavier (tout comme le fait `\` pour une chaine de caractère)

$ IFS=[ctrl]v[entrer][entrer]

> Cette modification de l'environnement permet notamment à la boucle for de traiter des lignes plutot que des mots.

### Utilisation avancée de variables

Attention c'est des tricks!

#### Rognage

il est possible de **rogner** une partie de chaîne de caractères contenue dans une variable.

Syntaxe : ${var[#|##|%|%%]modele}

* var est une variable
* `#` et `##` signifie par la gauche
* `%` et `%%` signifie par la droite
(1 caractère pour la plus petite chaîne 2 caractères pour la plus grande.)
* modele : C'est le modèle de type wildcard de ce qui est rogné de la chaîne.

Exemple :  
Ici le modèle qui sera rogné est une chaine de caractére qui commence ou finie par `:` : `:*` ou `*:`

```bash
prompt$ ligne="val1:val2:val3"
prompt$ echo ${ligne#*:}
val2:val3
prompt$ echo ${ligne##*:}
val3
prompt$ echo ${ligne%:*}
val1:val2
prompt$ echo ${ligne%%:*}
val1
prompt$
```

La variable n'est pas modifiée mais une seule partie de celle-ci sera Utilisé par ces expressions

#### Definir une valeur par défaut : `:-` ou `:=`

Il est possible de substituer une valeur à une variable non définie avec la syntaxe suivante :

```bash
${variable:-valeur}
```

Exemple :

```bash
prompt$ unset home
prompt$ echo ${home:-/home/alan}
/home/alan
prompt$ home=toto
prompt$ echo ${home:-/home/alan}
toto
```

`/home/alan` sera la valeur par défaut de cette expression si la variable home n'existe pas et la valeur de la variable sinon.

On poura aussi definir la variable inexistante avec une valeur par défaut en même temps

```bash
${variable:=valeur}
```

Exemple :

```bash
prompt$ echo ${home:=/home/alan}
/home/alan
prompt$ echo $home
/home/alan
```

> Il sera aussi possible de substituer une valeur aux variables déjà définies en utilisant `:+` mais je n'ai jamais trouvé d'intéret à cette syntaxe.

#### générer une exception

Il sera aussi possible d'interrompre l'exécution de votre script si une variable n'est pas définie en affichant un message d'erreur avec la syntaxe : ${variable:?erreur}  

```bash
prompt$ ( echo start ; echo ${home:?"variable non définie"} ; echo fin )
start
bash: home: variable non définie
prompt$ echo $?
1
prompt$
```

Ici le script ne s'est pas terminé (la commande `echo fin` n'a pas été exécuté) est est sortie avec le code retour 1.

## Gestion des chaines de caractères

*Une grande parties des données traité par le shell se présente sous forme de chaines de caratères (en entrée et en sortie).

Le shell lors de l'évaluation de la ligne de commande procède aux **substitutions** (tout ce qui commence par un `$`) et au traitement des **protections** `\` , `' '` et `“ ”`

* La bare contre-oblique supprime le "caractère spécifique" du caractère qui le suis.
* Le shell n'évalue pas le contenu des chaînes de caractères entre simples quotes `'`.
* Le shell ne traite pas les protections entre double quottes `"` en revanche il traite les substitutions.

Les quottes les plus externes prévalent sur les autres

```bash
prompt$ echo “'$var'”
'val'
prompt$
```  

Les simple quotes sont conservés mais la chaine est évalué

En revanche:

```bash
prompt$ echo '"$var"'
"$var"
prompt$
```

Rien n'est évalué entre les simples quotes

La concaténation est implicite :

```bash
prompt$ echo $var$var
valval
```

### Séquences d'échappement sur les chaines

Une séquence d'échapement permet de définir des caratères spécifiques.

> Attention le `\` est interprété par le shell avant d'être transmis à la commande.

* `\e` : caractère Échap.
* `\f` : saut de page
* `\n` : saut de ligne
* `\r` : retour chariot
* `\t` : tabulation horizontale
* `\v` : tabulation verticale
* `\\` : une barre contre-oblique
* `\0nnn` : le caractère dont le code ASCII est NNN (en octal)

### utilisation de la commande `echo`

Nous avons vue la commande echo qui affiche le reste de la ligne de commande. Cette commande renvois sur la sortie standard une ligne complète incluant le retour à la ligne.

Elle dispose d'options permettant de formater l'affichage :

* `-n` : supprime le retour à la ligne
* `-e` : permet l'utilisation des séquences d’échappement
* `-E` : supprime l'utilisation des séquences d’échappement

Exemple d'usage:

```bash
prompt$ echo -e '"$var"\n'
"$var"

prompt$ echo -n -e '"$var"\n'
"$var"
prompt$ echo -E '"$var"\n'
"$var"\n
```

### `read`

La commande read permet d'attendre des données sur l'entrée standard et de les placer dans les variables passée en arguments. l'entrée est lue ligne par ligne.

Testez l'exemple suivant : le bash attends votre saisie "aaa" sur son entrée standard. Une fois saisie la variable est ensuite présente dans la variable "a".

```bash
prompt$ read a
aaa
prompt$ echo $a
aaa
```

Elle peut être utilisée avec une série de valeurs

```bash
prompt$ read a b c
aaa bbb ccc
prompt$ echo "$a - $b - $c"
aaa - bbb - ccc
```

## les expressions arithmétiques

### la commande `expr`

La commande expr retourne le résultat d'une expression arithmétique ou logique sur des entiers.

Syntaxe :
expr nb1 operateur nb2

Opérateurs :  
Attention les caractères spéciaux doivent être protégé par `\`

* opérateurs simple : `+` `-` `\*` `/` `%`  
* opérateurs de comparaison : `\>` `\>=` `\<` `\<=` `=` `!=`  
* opérateurs logique : `\|` `\&`  

Opérations multiple :
expr **operation1** operateur **operation2**

Avec pour operation1 et 2 quelque chose comme  `\( nb1 operateur nb2 \)`

Exemple :

```bash
prompt$ temps=72 ; demijour=12 ; count=2 
prompt$ expr \( $temps + $demijour \) / $count
42
```

### `((`

La commande (( )) est bien plus simple à être utilisée mais elle n'est pas disponible en sh "pure" :

* Elle ne nécessite pas d'espace entre les arguments et l'utilisation du caractère d’échappement \
* Elle permet d'assigner une valeur à une variable tout en effectuant l'opération
* Elle permet la substitution d'une opération arithmétique par son résultat

Syntaxe :  

Pour assigner le résultat de l'opération **OP** entre **val1** et **val2** dans la variable `var`

```bash
((var=val1OPval2))
```

Pour utiliser le résultat de l'opération dans une ligne de commande  (ben oui il y a un `$` ce sera donc évalué)

```bash
$((val1OPval2))
```

Opérateurs :

* opérateurs simple : `+` `-` `*` `/` `%`  
* opérateurs de comparaison : `>` `>=` `<` `<=` `==` `!=`  
* opérateurs logique : `!` `||` `&&`  
* regroupement d'opérations : ( expression )  

Exemple :

```bash
prompt$ temps=72 ; demijour=12 ; count=2
prompt$ ((var=(temps+demijour)/count))
prompt$ echo $var
42
prompt$ echo $(((temps+demijour)/count))
42
```

## Sturctures de contrôle

### Les expression conditionnelles

#### Les tests logique

Sous Unix le résultat d'un test est le code retour d'une commande.
Si la commande est exécutée avec succès, le code retour est **0** et le test retourne **vrai**, si la commande est exécutée avec une erreur, le code retour est **différent de 0** et le test retourne **faux**.

De ce fait toute commande est un test. Si elle s'est correctement exécuté elle retourne vrai et faux dans le cas contraire.

#### la commande `test`  

La commande interne **et** externe `test` effectue une évaluation logique d'une expression (Voir : help test ou man test)

Elle est équivalente à la syntaxe [[ expression ]]

Elle intègre un grand nombre de tests sur les fichiers, sur les chaînes de caractères et sur des numériques. La commande interne du **bash** peu aussi tester l'existance d'une variable.

Elle utilise un opérateur unaire :

```bash
prompt$ test -z var
prompt$
```

Ou un opérateur binaire :

```bash
prompt$ test "val" = "$var"
prompt$
```

Vous noterez l'utilisation des double cote `"` afin de forcer l'existance de la chaine de caractère `"$var"` dans le cas ou ar serait une variable vide

Attention, les opérateurs de la commande test sur les numériques est litéral :

* `num1 -eq num2` : **EQ**ual  
* `num1 -ne num2` : **N**ot **E**qual  
* `num1 -lt num2` : **L**ess **T**han  
* `num1 -le num2` : **L**ess or **E**qual  
* `num1 -gt num2` : **G**reater **T**han  
* `num1 -ge num2` : **G**reater or **E**qual  

Alors que les opérateur tests sur les chaines de caractères sont des symboles arithmétique

* `STRING1 = STRING2`
* `STRING1 != STRING2`

> Probablement pour ne pas avoir à utiliser `<` ou `>` qui seront interprèté par le shell pour les redirections de flux

#### Structure de controle sur les test : `if then elseif else`

Un exemple :  

```bash
if test "$var" = "val"
  then
  echo le test est valide
elif test "$var" = "valeur"
  then
  echo le premier test est invalide mais le second est valide
else
  echo aucun test n\'est valide
fi
```

On pourra toujours utiliser les [enchainemts conditionnel de commande](./processus.md#Enchainement\ conditionnel) `&&` et `||` vue sur la gestions des processus en ligne de commande.

### Les boucles

#### La boucle `for`

On exècute la suite de commande pour chaque valeur possible de la variable `var` définie dans la `liste de valeurs`

un exemple :

```bash
prompt$ for var in liste de valeurs
> do
>   echo $var
> done
liste
de
valeurs
prompt$
```

En revalorisant IFS en caractère fin de ligne la boucle for traite alors des lignes :  

```bash
prompt$ oldIFS=$IFS
prompt$ IFS="
> "
prompt$ for var in $(tail -1 /var/log/syslog)
> do
> echo $var
> done
Mar 31 16:26:26 al-e6230 kernel: [1161390.320902] brcmsmac bcma0:1: wl0: brcms_c_d11hdrs_mac80211:  txop exceeded phylen 157/256 dur 1762/1504
prompt$ IFS=oldIFS
```

On utilise fréquemment la boucle for en conbinaison avec les wildcards sur les fichiers:

```bash
prompt$ for file in *.jpg
> do
>   mv $file ~/images/
> done
```

à l'évaluation de la ligne de commande *.jpg sera remplacer par tous les fichiers du dossier courant dont le nom se termine par ".jpg" la boucle sera alors exécuté sur chacun de ces fichiers. Personnelement je ferai plutôt ça comme ça :

```bash
prompt$ mv *.jpg images/
prompt$
```

#### while / until

Vous connaissez le principe, la séquence de commande est re-exécuté tant que le test retourne `vrai` avec `while` ou `faux` avec `until`

Un exemple:

```bash
prompt$ while test "$var" != "quite"
> do echo "hein?"
> read var
> done ; echo "...voilà"
hein?
bah rien
hein?
quite
...voilà
prompt$ until test "$var" == "quite";do echo "hein?"; read var; done ; echo "ben voilà"
hein?
rien
hein?
quite
ben voilà
prompt$
```

## Les fonctions

Une fonction est un ensemble cohérent de commandes pouvant être utilisées plusieurs fois dans un même script.

Une fonction doit être définie avant d'être appelée. Elle fait partie de l'environnement.

Tout comme les scripts, les fonctions sont des commandes, elles ont donc un code retour. Celui-ci est transmis par la commande interne "return"

```bash
prompt$ bar(){
> echo "foo ?"
> return $?
}
```

### Arguments

Tout comme les scripts les fonctions acceptent des arguments, ils sont adressés de la même façon que pour les scripts :

* $1 $2 $3 … : Les argumentsx
* $0 n'est pas modifié, cela reste le nom du script
* $# contient le nombre d'arguments
* $* contient tous les arguments

Il n'est donc pas possible d'adresser les arguements du script dans une focntions

### Variable

Afin d'éviter les écrasements de variables, les variables interne d'une fonction doivent être définie localement aux fonctions avec la commande interne local. Dans le cas contraire c'est une fonction globale.

```bash
prompt$ foo (){
> local var=$1
> echo $var
> return $?
> }
prompt$ foo rototo
rototo
prompt$ echo $var
42
prompt$
```

### Exemples de fonctions

La fonction usage est couramment définie afin de rappeler à l'utilisateur comment le script s'utilise

usage :

```bash
usage(){
  echo "$0 : traite un fichier passé en arguement"
  echo "    syntaxe : $0 -f fichier"
  echo ""
  return 0
}
```

Une fonction end est pratique pour traiter le cas d'un traitement interrompu :

end :

```bash
end(){
  rm ${lockfile:?'lock file absent'}
}
```

Une fonction log permettra de gérer les exceptions et de tracer les actions du script

log :

```bash
log(){
  if $debug
  then
    if test "${1:?'type de log non définie'}" = "error"
    then
      shift && echo `date +%Y%m%d-%H:%M:%S` Error: $* >&2
    elif test "${1:?'type de log non définie'}" = "info"
    then
      shift && echo `date +%Y%m%d-%H:%M:%S` Info: $* >&2
    else
      echo "type de log invalide" >&2
      return 2
    fi
  fi
}
```

## Gestion des signaux

La commande `trap` vas permetre de reprogrammer la gestion des signaux du shell en appelant un fonction

Syntaxe:

```bash
prompt$ trap fonction 1 2 3 15
prompt$ trap -p
trap -- 'fonction' SIGHUP
trap -- 'fonction' SIGINT
trap -- 'fonction' SIGQUIT
trap -- 'fonction' SIGTERM
trap -- '' SIGTSTP
trap -- '' SIGTTIN
trap -- '' SIGTTOU
```

Pour les signaux 1 2 3 et 15 le shell apelera la fonctionn avant de traiter le signal.

## commande getopt

La commande getopt lit le premier argument et shift les suivants.

Syntaxe : getopts: getopts chaine-options opt [arg]

Avec :
chaine-options une chaine commençant par `:`contenant les lettres d'options qui devront être connues (Attention les erreurs sont silencieuses). Si une lettre est suivie par un deux-points, elle devra alors posséder un argument.

`opt` est une variable alimentée par getopt elle contien :  

* L'option récupèré si elle est reconnue par la chaine-options
* sinon :
  * `?` si l'option est inconnue par la chaine-options (la variable `$OPTARG` contiendra alors l'option en cours de traitement)
  * `:` si l'option en cours de traitement nécessite un argument et que celui-ci est absent (la variable $OPTARG contiendra alors l'option en cours de traitement)

voir l'exemple ci après

## Exemple de script

Getopt avec la chaine d'option  `:lf:` pour les options `-f` suivi d'un argument puis `-l`

```bash
#!/bin/sh
# $0: script sevant d'exemple à l'utilisation de getops et des fonctions
#
# author : Alan Simon
# Version : 1.0
#
# Constantes
tmpdir="/tmp"
lock=0
debug="/bin/true"

# Fonction
usage(){
  echo ""
  echo "$0 : traite un fichier passé en arguement"
  echo "    syntaxe : $0 [-l] -f fichier "
  echo ""
  return 0
}

log(){
  if $debug
  then
    if test "${1:?'type de log non définie'}" = "error"
    then
      shift && echo `date +%Y%m%d-%H:%M:%S` Error: $* >&2
    elif test "${1:?'type de log non définie'}" = "info"
    then
      shift && echo `date +%Y%m%d-%H:%M:%S` Info: $* >&2
    else
      echo "type de log invalide" >&2
      return 2
    fi
  fi
}

end(){
  test $lock -eq 1 && rm ${lockfile:?lock file absent}
}

doit(){
  log info `id -un` demande le traitement de $fichier
  # mais je ne fais rien en fait
}

# main
while getopts ":lf:" opt
do
  case $opt in
    f)
      log info "-f ok, avec fichier : $OPTARG"
      fichier=$OPTARG
      ;;
    l)
      log info "-l ok"
      lock=1
      ;;
    \?)
      log error "Unknown option: -$OPTARG"
      usage
      exit 1
      ;;
    :)
      log error "Option -$OPTARG attends un argument."
      usage
      exit 1
      ;;
  esac
done

test -z $fichier && usage && exit 1

if test \! -f $fichier
then
    log error "le fichier $fichier n'existe pas ou n'est pas lisible"
    exit 2
fi

lockfile=$tmpdir/`basename $fichier`.lock

if test -f $lockfile
then
    log error "le fichier $fichier est déja en cours de traitement lock : $lockfile"
    exit 2
fi

if test $lock -eq 1
then
   touch $lockfile || log error "impossible de locker" || exit 2
fi

doit $fichier

end
```
