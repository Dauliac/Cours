---
header: 'Cours des systèmes'
footer: 'Julien Dauliac -- ynov.casualty925@passfwd.com'
---

<!-- headingDivider: 3 -->
<!-- paginate: true -->
<!-- colorPreset: sunset -->

# Cours des systèmes

[TOC]

# Introduction

## Objectifs
- Comprendre le processus de démarrage d'un système, de l'initialisation du BIOS à l'exécution du noyau.
- Avoir des bases sur les architectures des système d'exploitation.
- Explorer les différentes formes d'isolation, notamment les machines virtuelles, les conteneurs et les lambdas, et comprendre leurs avantages et inconvénients.


## C’est quoi un OS ?

[Wooclap](https://app.wooclap.com/events/FKFKTZ/questions/64fe433fa84d0f1d6fea38b2)

[Question 1](https://app.wooclap.com/events/FKFKTZ/questions/64fe435da84d0f1d6fea39e5)


### Quelle est la proposition d’un OS:

- J’en ait besoin:
    - non mais si c’est un ordinateur personnel (PC), c’est mieux
- Pourquoi faire:
    - Abstraire le matériel

## Un système simple pour commencer

- BIOS
- Démarrage du kernel par le bios
- Création du processus 0 par le kernel
- IDLE = processus qui ne fait rien:
    
    ```c
    while(true) {}
    ```
---

![](assets/system-2.svg)

# BIOS

- **Fun fact:** 🍎 Le bruit de démarrage des Mac vient d’un sample illégal l’album sergent pepper des beatles.

## BIOS de barbu


![width:200px](assets/Untitled.png)
![width:200px](assets/Untitled%201.png)

## BIOS de corpo kid


![width:200px](assets/Untitled%202.png)
![width:200px](assets/Untitled%203.png)

## BIOS de beauf

![width:200px](assets/Untitled%204.png)
![width:200px](assets/Untitled%205.png)

## Qu’est ce qu’un `BIOS`

- La première instruction exécutée par le processeur
- Découverte et initialisation du matériel
    - Processeurs, mémoire, contrôleurs d'E/S, périphériques, etc.
- Configuration matérielle
- Démarrage du système d'exploitation
- Nom ancien

### Un abus de language

- *Extensible Firmware Interface → INTEL*
- **Unified Extensible Firmware Interface →** [AMD](https://fr.wikipedia.org/wiki/Advanced_Micro_Devices), [American Megatrends](https://fr.wikipedia.org/wiki/American_Megatrends), [Apple](https://fr.wikipedia.org/wiki/Apple), [ARM](https://fr.wikipedia.org/wiki/ARM_(entreprise)), [Dell](https://fr.wikipedia.org/wiki/Dell), [HP](https://fr.wikipedia.org/wiki/Hewlett-Packard), [Intel](https://fr.wikipedia.org/wiki/Intel), [IBM](https://fr.wikipedia.org/wiki/International_Business_Machines_Corporation), Insyde Software, [Microsoft](https://fr.wikipedia.org/wiki/Microsoft) et [Phoenix Technologies](https://fr.wikipedia.org/wiki/Phoenix_Technologies)

### Architecture de l’UEFI

[UEFI](https://fr.wikipedia.org/wiki/UEFI)

---

- SEC (*Security*) pour l'exécution des processus d'authentification et de contrôle d'intégrité (SecureBoot, mot de passe, token USB)

---

- PEI (*Pre EFI Initialization*) pour l'initialisation de la carte mère et du *chipset*. Passage du processeur en mode protégé

---

- DXE (*Driver Execution Environment*) pour l'enregistrement de tous les pilotes. Le routage par un dispatcher des demandes issues des applications EFI comme un chargeur de
démarrage

---

- BDS (*Boot Dev Select*) pour un gestionnaire de démarrage comme [grub](https://fr.wikipedia.org/wiki/GRand_Unified_Bootloader)

---

- TSL (*Transient System Load*) pour la phase transitoire où le système d'exploitation est chargé. Les
services EFI seront clos via la fonction ExitBootServices(), pour passer la main au système d'exploitation

---

- RT (*RunTime*) quand le
système d'exploitation a pris la main. Le seul moyen d'interagir avec le firmware est alors de passer par les variables EFI stockées dans la
NVRAM.


---

![](assets/system-mermaid-bios.svg)


## Sécurité

> Le BIOS n’est pas notre royaume, mais faisons attentions aux fondations.
> 
- Définir un mot de passe UEFI
- Activez le secure boot:
    - signe le bootloader, le kernel, et vérifie les signatures au démarrage.

## Un bios open source 🎊

**Open Firmware**

[Firmware Switching (Proprietary Firmware or System76 Open Firmware)](https://support.system76.com/articles/transition-firmware/)

# Kernel

- Code mort
- chargé au démarrage
- qui vient isoler les programme de la machine
- Interface avec le user space: `SYSCALL`

## Résumé des composants du Noyau

| Éléments | Description | Temps de l’étudier |
| --- | --- | --- |
| Scheduler | Le noyau décide quels processus doivent s'exécuter et pendant combien de temps, en utilisant des politiques d'ordonnancement. | ✅ |
| Gestion des Processus | Le noyau gère les processus et les threads, décidant de leur allocation de temps CPU et de leurs priorités. | ✅ |
| appel système | Gestion des demandes au système d’exploitation | ✅ |
| Gestion des Entrées/Sorties | Le noyau facilite les opérations d'entrée/sortie entre les périphériques matériels et les processus logiciels, en utilisant des mécanismes tels que les pilotes de périphériques. | ❌ |
| Drivers | Gestion des  externes. | ❌ |
| Communication Inter-Processus | Le noyau fournit des mécanismes pour la communication entre les processus, tels que les signaux, les tubes et les sémaphores. | ❌ |
| Partage de la RAM entre processus | Le système utilise un système de mémoire virtuelle et de page pour isoler et partager la RAM entre les processus. | ❌ |

## Scheduler
*Un quoi ?*

### Comment fait-on pour lancer plusieurs processus ?

![](assets/system-2.svg)


### Ordonnanceur et temporisateur

![](assets/system-3.svg)

---

- Ordonnanceur: algorithme basé qui utilise un circuit temporisateur pour partagé l’accès aux cœurs.
- Le kernel interrompt le processus.
- Le temps de laisser la parole à tout les processus on appelle cela une **epoch**.
- Pour fonctionner l’ordonnanceur utilise des **interruptions système**

### Algorithmes d’ordonnancements

- Round Robin chacun son tour
- Par priorité
- Multi level-feedback round robin Queues

---

Comme dans la vie, on peut créer des inégalités

```bash
# renice - alter priority of running processes
renice
```

---

**example:**

Sur des systèmes critiques comme les fusées 🚀 on peut définit la priorité de chaque processus.
C’est d’autant plus simple quand on connaît la liste de tout les processus à l’avance.

## Les syscalls

![](assets/system-1.svg)

---

- Protocole de communication avec le kernel
- Une liste de numéros
- Dans les sources du kernel:
    
    ```c
    SYSCALL_DEFINE3(ioctl, unsigned int, fd, unsigned int, cmd, unsigned long, arg)
    {
    /* do freaky ioctl stuff */
    }
    ```

---    

| System Call | rax | rdi | rsi | rdx | r10 | r8 | r9 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| sys_chroot | 161 | const char* filename |  |  |  |  |  |
| sys_chmod | 90 | const char* filename | uid_t user | gid_t group |  |  |  |
| sys_mkdir | 83 | const char* pathname | int mode |  |  |  |  |

[documentation des syscalls](https://github.com/torvalds/linux/blob/28f20a19294da7df158dfca259d0e2b5866baaf9/arch/x86/entry/syscalls/syscall_64.tbl)

# Processus

## Premier processus

Quiz: Quel est le premier processus qui est généralement lancé sur linux ?

---

```bash
ps -aux | grep init
root           1  0.0  0.0 166896 11700 ?        Ss   10:19   0:01 /sbin/init splash
dauliac    44107  0.0  0.0  19016  2560 pts/0    S+   19:53   0:00 grep --color=auto init

~
➜ ls -la /sbin/init
lrwxrwxrwx 20 root 10 août  18:37 /sbin/init -> /lib/systemd/systemd
```

## Histoire de l’architecture de la RAM

### 2 modèles

- Architecture Harvard
    - D'abord mis en œuvre dans le Mark I (1944).
    - Gardez les programmes et les données séparés.
    - Permet de récupérer des données et des instructions en même temps.
    - Simple à manipuler pour les programmeurs mais moins puissant pour les ordinateurs.
- Architecture Princeton
    - D'abord mis en œuvre dans l'ENIAC (1946).
    - Permet de coder en auto-modifiant et l'entrelacement de programme et de données.
    - Difficile à manipuler pour les programmeurs mais plus puissant pour les ordinateurs.

### Et maintenant

Quiz: Quelle architecture utilise-on ?

---

Les 2.

---

- Les programmeurs codent en architecture Harvard.
- Les machines exécutent le code en architecture Princeton.
- Les compilateurs traduisent le code de l'architecture Harvard à l'architecture Princeton.

---

- Mais, quelques pertes se produisent dans la traduction... et certains bugs peuvent permettre à des utilisateurs malveillants d'accéder à des fonctionnalités non autorisées grâce à des comportements inattendus.
La plupart des problèmes de sécurité dans la sécurité des logiciels viennent d'une mauvaise compréhension du couplage de ces deux architectures.
- L'exploitation consiste essentiellement à utiliser cette "machine" en dehors de ses spécifications.

## Le layout de la ram

[Wooclap](https://app.wooclap.com/events/FKFKTZ/questions/64fe435da84d0f1d6fea39e5)

---

![](assets/system-4.svg)

---

| Position | Contenu |
| --- | --- |
| Stack | Utilisé pour stocker les variables locales, les adresses de retour des fonctions et les données temporaires. |
| Heap | Utilisé pour la gestion dynamique de la mémoire, telles que l'allocation et la libération de mémoire. |
| Bss | Contient les données non initialisées ou initialisées à zéro, telles que les variables statiques globales. |
| Data | Stocke les données initialisées, telles que les variables statiques globales avec une valeur spécifiée. |
| R/O Data | constantes, chaînes de caractère littérales  |
| Text | Contient le code exécutable du programme. |

## Sécurité de la ram

---

- **Address space layout randomization:**
    
    s’agit en général de la position du [tas](https://fr.wikipedia.org/wiki/Tas_(informatique)), de la [pile](https://fr.wikipedia.org/wiki/Pile_(informatique)) et des [bibliothèques](https://fr.wikipedia.org/wiki/Biblioth%C3%A8que_logicielle). Ce procédé permet de limiter les effets des attaques de type [dépassement de tampon](https://fr.wikipedia.org/wiki/D%C3%A9passement_de_tampon) par exemple.
    
    - L’implémentation sous Linux est supportée dans le noyau depuis la version 2.6.20 (June 1, 2005)
    
    [Address space layout randomization](https://fr.wikipedia.org/wiki/Address_space_layout_randomization)
---

- **Non-executable stack**

---

- **Control-related data in read-only regions**

---

- **Canary:**
    - Prévient du débordement de tampon basé sur la pile
    - Vérifié avant l'instruction assembleur `ret`
    - Idéalement aléatoire (et par thread)

## Processus states

![](assets/system-5.svg)

## Pagination virtuelle

On a pas le temps désolé 😕

Mais en gros la mémoire dans le kernel est gérée avec un système de page qui permet d’isoler les processus et de distribuer la mémoire de manière extrêmement performante (cf partie processus).

# Les nouvelles isolations 🔒

Le kernel est une première forme d’isolation

## Les machines virtuelles

![](assets/system-10.svg)

---

| Outil | Description | Example |
| --- | --- | --- |
| L’émulateur | Simule le matériel | QEMU |
| Hyperviseur | Outil de contrôle des systèmes d’exploitation | KVM |
- Dans certains cas, KVM n’utilise pas d’émulation pour les processeurs, mais utilise directement le kernel haute pour y accéder.

## Les containers 🐋

![](assets/system-8.svg)

---

| Éléments | Description  |
| --- | --- |
| Dockefile | Fichier texte déclarant comment construire une image |
| Image | Archive contenant le filesystem et les méta données permettant d’exécuter le container. |
| Registry | Depo permettant de versionner, partager, récupérer et télécharger les images. |
| Runtime | Permet d’exécuter les containers (containerd) |
| Frontend | Client permettant d’interagir avec ces éléments: docker, podman, kaniko. |

### Dockerfile
```Dockerfile
FROM alpine

COPY \
    package.json package-lock.json \
    /var/lib/app/
RUN \
    npm install \
    npm run build
COPY ./src /var/lib/app

CMD npm run prod
```

---

**Conseils:**
- Utiliser [hadolint](https://github.com/hadolint/hadolint)
- Utiliser [trivy](https://github.com/aquasecurity/trivy)
- Faire des images avec un seul processus

---

| Avantages des `Dockerfiles`          | Inconvénients des `Dockerfiles`                  |
|-----------------------------------|-----------------------------------------------|
| 1. **Reproductibilité** : Les Dockerfiles permettent de définir de manière précise l'environnement d'une application, garantissant ainsi que l'application se comportera de la même manière partout où le conteneur Docker est exécuté. | 1. **Nature Impérative** : Les Dockerfiles sont impératifs, ce qui signifie que vous spécifiez les étapes de construction plutôt que de décrire l'état souhaité. Cela peut rendre difficile la compréhension de l'environnement cible. |
| 2. **Isolation** : Les Dockerfiles permettent d'isoler une application et ses dépendances, ce qui évite les conflits entre les différentes applications s'exécutant sur la même machine hôte. | 2. **Maintenance** : Les Dockerfiles nécessitent une maintenance continue pour rester à jour avec les nouvelles versions des dépendances, ce qui peut devenir fastidieux. |
| 3. **Gestion des Versions** : Les Dockerfiles peuvent être versionnés et gérés avec des systèmes de contrôle de version, ce qui facilite la gestion des modifications de configuration au fil du temps. | 3. **Taille du Conteneur** : Les Dockerfiles peuvent générer des images de conteneur volumineuses, car chaque instruction ajoute des couches au système de fichiers de l'image. Cela peut augmenter les temps de transfert et d'exécution. |
| 4. **Reconstruction Rapide** : En utilisant un Dockerfile, vous pouvez rapidement reconstruire une image de conteneur en cas de besoin, ce qui facilite le déploiement continu. | 4. **Complexité Potentielle** : Les Dockerfiles peuvent devenir complexes, en particulier pour les applications multi-étapes ou avec de nombreuses dépendances. La gestion de cette complexité peut être difficile. |
| 5. **Automatisation** : Les Dockerfiles peuvent être utilisés dans des pipelines CI/CD pour automatiser la construction et le déploiement de conteneurs, ce qui accélère les processus de développement et de déploiement. | 5. **Difficile à Déboguer** : Les erreurs dans un Dockerfile peuvent être difficiles à déboguer, car il peut être compliqué de déterminer où l'erreur s'est produite. |

---

### Les containers et les syscalls

> Les containers font reposer leurs fonctionnement sur une suite de `syscall`.
> 

| Appel Système | Description |
| --- | --- |
| Clone (sys_clone) | Crée des processus légers et partage certaines parties de l'espace d'adressage avec le parent. |
| Namespace (sys_unshare, sys_setns, etc.) | Isolation des ressources système telles que les processus, les réseaux, les points de montage, etc. |
| Cgroups (Control Groups) | Gestion des limites et contraintes sur les ressources système (CPU, mémoire, réseau, etc.). |
| Chroot (sys_chroot) | Modification de la racine du système de fichiers pour créer un environnement de fichiers isolé. |
| Seccomp (Secure Computing Mode) | Restreint les appels système disponibles pour un processus, renforçant ainsi la sécurité. |
| Capacités (capabilities) | Accorde des droits spécifiques aux processus pour effectuer certaines actions normalement réservées à l'utilisateur root. |
| Sysfs, procfs, etc. | Utilisation de systèmes de fichiers virtuels pour obtenir des informations sur l'état du système et ajuster les paramètres du noyau. |
| Socketpair (sys_socketpair) | Crée des paires de sockets pour la communication inter-processus (IPC) entre les processus dans le même conteneur. |
| Privilèges d'espace utilisateur | Crée des comptes d'utilisateurs isolés dans l'espace utilisateur, renforçant ainsi l'isolation des utilisateurs entre les conteneurs. |
| Appels Systèmes Réseau (sys_socket, etc.) | Utilisés pour établir des connexions réseau, souvent avec des restrictions spécifiques au conteneur pour garantir l'isolation. |

[Digging into Linux namespaces - part 1](https://blog.quarkslab.com/digging-into-linux-namespaces-part-1.html)

### Les lambdas 📏

- Se débarrasser d’un maximum de composants: Il ne reste que la RAM, le réseau, les cœurs
    - Pas de gestion des fichiers
    - Plus d’accès a l’hyperviseur

---

![](assets/system-9.svg)

---

| Éléments | Description  |
| --- | --- |
| Code | Code à exécuter en tant que lambda |
| Scheduler | Backend permettant de distribuer le calculs des lambdas |
| Bibliothèque | Packet permettant de rendre compatible le code avec les apis des lamdbas. |

---

Les lambdas c’est juste

- des processus
- Exécuté dans des containers, ou des vms, ou une machine 😱

---

| Avantages 🌈 | Inconvenants 😢 |
| --- | --- |
| Peu de couplage | Peut coûter cher |
| Isolation de tout les processus | Difficile à mettre en place avec des logiciels libre |
| Permet d’architecturer des applications évolutives | Peut facilement vendor lock. |
| Uniquement déclaratif |  |

---

### Web assembly 🤖

- Compilation du code dans un language agnostique
- Se débarrasser d’un maximum de composants: Plus d’interpréteur.
- peut tourner en back ou en front

https://webassembly.org/
https://developer.mozilla.org/fr/docs/WebAssembly

## Comparaison 🆚

![](assets/system-7.svg)

## Résumé 🧠

---

![](assets/system-0.svg)

---

![](assets/system-6.svg)

## Conclusion

![Untitled](assets/Untitled%206.png)
---

![](assets/system-11.svg)

---
- Coût alternance perf, sécurité:
    - On fait de la performance en faisant des design permissifs et ouvert
    - Puis on regrette
    - ~~Puis on rappel son ex~~
    - Puis on ajoute une couche de sécurité au dessus
    - Puis on smash nos erreurs et on fait un nouveau standard
    - Puis, MARKETING 🏁
    - Et on boucle
