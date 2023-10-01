# Les schedulers d'i/o

[toc]

## Présentation

Les scheduleur I/O sont des modules du kernel dont l'objet est l'optimisation de la bande passante des I/O  sur les disques.
il peut par exemple regrouper les i/o de block contigue afin d'obtimiser leurs temps d'accès (très long sur disque physique).

### Scheduleur multi-threads

* bfq (Budget Fair Queuing) Spécialisé pour organiser les I/O sur les device lents afin d'obtenir un temps de réponse plus rapides. ce scheduleur coûte cher en temps cpu.
* kyber un scheduleur simple et rapide specialiser pour le périphérique de stockage disposant aussi de plusieurs files des traitement.
* none aucune réorganisation des requêtes afin de réduire la charge, il est parfait pour des périphérique avec des temps d'accès rapide sur tout les blocs (nvme)
* mq-deadline le compromis, faible consomation et réorganisation minimal assurant un temps de réponse trés correct. C'est la réimplémentation du scheduleur deadline en multithreadé.

### Scheduleur non multi-thread (deprecié) depuis le kernel 5.3)

* deadline : 3 files d'attente I/O
  * Sorted
  * Read FIFO
  * Write FIFO
  les i/o sont trié (issue le la file sorted) jusqu'a ce qu'une i/o des files read/write FIFO soient expirée. 500Ms pour read 5s pour write
* cfq (Completely Fair Queueing)
  * une file par process pour les i/o synchrones (R)
  * quelques files pour les accès asynchrone (W)
  * priorisation avev les ionice
  les files d'I/O ne sont pas priorisée entre elle.
* noop (No-operation)
  regroupe les i/o dans les réorganiser la réorganisation est alors délégué au controleur de strockage.

## modification du scheduleur d'i/o

le scheduleur est défini par disque :

```bash
root@target:~# cat /sys/block/sda/queue/scheduler 
[mq-deadline] none
```

Pour utiliser un autre schéduleur il faut charger le module associé dans le noyau:

```bash
root@target:~# modprobe kyber-iosched
root@target:~# cat /sys/block/sda/queue/scheduler 
[mq-deadline] kyber none
root@target:~# modprobe bfq
root@target:~# cat /sys/block/sda/queue/scheduler 
[mq-deadline] kyber bfq none
```

puis juste le sélectioner en écrivant sur le fichier la valeur souhaité :

```bash
root@target:~# echo bfq > /sys/block/sdc/queue/scheduler
root@target:~# cat /sys/block/sdc/queue/scheduler
mq-deadline kyber [bfq] none
root@target:~# 
```
