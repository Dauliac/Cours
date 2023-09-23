# LVM

<!-- vim-markdown-toc GitLab -->

* [Présentation](#présentation)
* [Commandes LVM](#commandes-lvm)

<!-- vim-markdown-toc -->

## Présentation

LVM pour *Logical Volume Manager* permet de définir des volumes logiques indépendants des volumes physiques. Il offre un grand nombre de fonctionalités sur la gestion des volumes (*mirroring*, *snapshot*, redimensionnement, etc.).

Les **volumes physiques (PV)** sont regroupés dans un **Volume Group (VG)**, puis découpés en blocs de données appelés **Physical Extent (PE)**.

A la création d'un volume physique, un label unique est écrit en début de disque. Un espace est réservé juste après, en fin de disque, afin d'écrire l'ensemble des données relatives à LVM.

Un **PV** :

![lvmpv](../images/lvm-pv.png)

Un **volume logique (LV)** est défini comme un ensemble de ces blocs de données. Ansi un volume logique (LV) peut être stocké sur plusieurs volumes physiques PV).
En cas de *mirroring* chaque bloc est stocké en plusieurs copies ; chacune sur un volume physique (PV) différent.

![lvm](../images/lvm.png)

## Intérêt

Pour toute configuration matériel de production en datacenter ou vrituel **il faut mettre en place du LVM**.

* Pour la gestion des changement et des évolution
  * cas du changement de SAN
* Afin d'optimiser l'espace disque en de répliquant que ce qui est necessaire d'être répliqué
* Afin de gerer une surcossomation de stockage et un besoin d'agrandissement de volume.

## Commandes LVM

Les volumes physiques (PV), les Volume Groups (VG) et les volumes logiques (LV) sont gérés par les commandes LVM :

* `[pv|vg|lv]display` : affiche les caractéristiques d'un PV, VG ou LV
* `[pv|vg|lv]create` : crée un des objets LVM
* `[pv|vg|lv]remove` : supprime un des objets LVM
* `vgextend` : ajoute un volume physique (PV) à un Volume Group (VG)
* `vgreduce` : enlève un disque d'un Volume Group (VG)
* `pvmove` : déplace les blocs de données d'un volume physique (PV) vers un autre
* `lvconvert` : modifie la répartition des blocs
* `lvchange` : modifie les attributs d'un volume logique (LV)
* `lvresize` : redimensionne un volume logique (LV)

La pratique est encore le meilleur moyen de comprendre alors voici un [td](./tp-lvm.md).
