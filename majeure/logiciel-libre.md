# Le monde libre

[toc]

## Principes fondateurs

Les quatre libertés fondamentales des logiciels libres:

- La liberté d'utiliser le logiciel quelque soit l'usage (gratuité et ouverture)
- La liberté d'étudier et de modifier le logiciel (Accès au code source)
- La liberté de de redistribuer les versions modifiées
- La liberté des versions modifiées et distribuées (qui doivent donc hériter des 3 premières liberté) **Cela est plus une contrainte qu'une liberté.**

Le logiciel issue des logiciels libres doit rester un logiciel libre. Et donc être publié sous une licence compatible avec l'ensemble des logiciels libres inclus dans la solution.

> wikipedia: [Le copyleft](https://fr.wikipedia.org/wiki/Copyleft)

## Les valeurs

Les valeurs du logiciel libre fondent la **culture du libre**.

### Liberté

De principe, la première valeur s'il en est une, est la liberté.

Hérité notament de la culture du monde Unix :
> Unix was not designed to stop you from doing stupid things, because that would also stop you from doing clever things.

La liberté d'usage permet aux solutions libres de se propager. Puis de part la multiplication de l'usage les solutions libres deviennent de fait reconnues comme fiables.

Ce principe de liberté est inclu dans le design fonctionnel d'une solution libre.**Une solution libre bien conçue est un framework** ; le modèle fonctionnel est défini et l'implémentation est modulaire afin d'ouvrir un maximum de possibilités d'utilisations.
Ainsi il est possible de parmetrer et implémenter la solution en fonction des besoins de son organisation, de ses processus métiers ou des classes d'objets fontionnels :

- groupes : d'utilisateur, de ressources, d'accès
- rôles : fonctions, ensemble de droits, Objectif fontionnel
- type : d'objet fonctionnel (sous classe)
- espace de noms : isolation par domaine fonctionnel/organisationel

Cette souplesse d'implémentation est l'un des gros vecteurs d'explosion du libre.

### Transparence

Hérité de la culture de la recherche scientifique (publications scientifiques). Permetre d'étudier le "comment c'est fait" offre un support à la formation, facilite le partage de connaissances et d'autant le renouvèlement des contributeurs.

En retour via les relectures multiples par les paires, la solution ainsi ouverte dispose d'un contrôle et donc d'un gage de qualité important.

Cette transparence est alors un vecteur de collaboration et de standardisation (Exemple : les RFC)

### Collaboration/Partage

Au travers :

- du partage des connaissances, de cas d'usage (décrivant des problemes rencontrées et/ou des solutions apportées) et d'analyses ;
- de propositions d'améliorations et/ou de correctifs ;
- ou simplement par l'entraide dans l'implémentation.

La comunauté du libre partage les bénéfices apportés par les solutions libres et sa communauté tout en participant pleinement à celle-ci et à son succès.

### Culture de l’excellence

A la fois issue et à l'origine des trois valeurs précédentes.

L'excelence est un objectif non disimulé du monde du libre. Et c'est en se donnant **humblement** cet objectif plus qu'un objectif de rentabilité ou de succès, que les valeurs citées précédemment deviennent une nécéssité.

### Démocratie

De part l'application des valeurs précédentes : liberté, collaboration/partage, transparence et une certaine forme d'humilité, l'organisation qui découle de ces valeurs est démocratique.

La plupart des entités du monde du libre sont auto-organisées de façon démocratique (FSF, Fondation Debian).

### Le respect de la vie privée

Une autre valeur importante du monde du logiciel libre : le respect des données privées (personnelles) comme spécification implicite des logiciels libres : "privacy by design"

### L'Emergence du monde du libre

Les contradicteurs du libre opposent à ces valeurs la difficulté d'obtenir des financement privés pour des logiciels libres ce qui serait un frein à l'inovation. (c'est en fait un débat stérile sur l'existance du brevet)

A la vu de la réussite du monde du libre dans le domaine de l'informatique, ces valeurs sont maintenant reprises dans des domaines autre que l'informatique en citant les logiciels libres [Exemple : open source ecology](https://wiki.opensourceecology.org/wiki/Open_Source_Ecology)

## L'opensource

Les concepts de l'opensource sont inclus dans le concept du libre. Ils se veulent être une forme non virale de collaboration car ils n'imposent aucune restriction à la redistribution des produits issus d'évolutions de produits opensource. En clair il est possible de ne pas donner l'accès au code source ajouté aux produits et donc de l'utiliser au sein d'un **logiciel privateur**.

Un logiciel libre est opensource et le restera, un logiciel open source peut ne pas être libre et les logiciels issus de ceux-ci pouvant sous certaines conditions ne pas être opensource.

L'Open Source Initiative est donc largement financé par le secteur privé (IBM/RedHat, HP, Novel, etc...) car nettement moins restreignante et avec, je cite : **"une politique jugée plus adaptée aux réalités économiques et techniques"**

> wikipedia [Open Source Initiative](https://fr.wikipedia.org/wiki/Open_Source_Initiative)

L'opensource n'est pas l'opposé du libre, il vient complèter l'offre du libre plus adapter au monde du privé.

## Les licences

Les licences définissent un cadre légal d'usage et de distribution des logiciels. Un logiciel libre ne fait pas partie du domaine publique, car son usage est réglementé.

### Licence libres

Les licences de logiciels libres :

- Protègent les droits des l'utilisateurs et de leurs données.
  - En permettant l'accès au code source
  - En imposant des formats ouverts et libres
- Protègent les développeurs :
  - Par l'absence de garanties qui permettraient aux utilisateurs de se retourner contre le developpeur
  - Le non engagement de la responsabilité du développeur
  - la protection de la renomée du développeur (précision des modifications, cité l'auteur mais ne pas utiliser son nom à des fins promotionnels etc...)
- Protègent enfin le principe même du logiciel libre
  - par l'héritage de la licence libre pour les produits issus du libre.

Une fois une solution créée utilisants des composants sous licences libre. Quelles licences mettre en place alors sur cette nouvelle solution ?
Soit une seule licence vient couvrir l'ensemble de la solution en étant compatible avec l'ensemble des solutions utilisées ou bien l'organisation du code source devra permettre une publication sous plusieurs licences.

la gpl v3 est trés précise sur ces différents cas, utilisation de bibliothèques plutot que reprendre du code, usage des appels systèmes etc...

> <https://www.gnu.org/licenses/quick-guide-gplv3.fr.html> <https://www.gnu.org/licenses/license-list.fr.html#GPLCompatibleLicenses>

### Les licences opensource

Notament la licence BSD, n'impose pas l'héritage de la licence sur les produits issus des produits Opensource et permet ainsi de ne pas publier les évolutions et améliorations apportées.

licences approvée comme open sources :

GPL, BSD, apache, MIT, modzilla, EUPL, CECILL

> <https://opensource.org/licenses/category>

### compatibilité

La prolifération des licences de logiciels libres et opensource est actuellement un problème dans la communauté car celle-ci ne facilite pas son emergence. La gestion de la compatibilité des licences logiciels est alors plus complexe.

En revanche en imposant moins de restriction les logicels opensource simplifient la gestion de la compatibilité des licences.

[wikipedia : Floss licences](https://en.wikipedia.org/wiki/Free_software_license#/media/File:Floss-license-slide-image.png)
