# Déploiements sur un cluster

* [Préambules](#pr-ambules)
  * [kubectl](#kubectl)
  * [Les namespaces](#les-namespaces)
  * [Les objets connexes](#les-objets-connexes)
    * [Completion du pod](#completion-du-pod)
    * [Controleurs de pod](#controleurs-de-pod)
* [Les déploiements](#les-d-ploiements)
  * [Un pod](#un-pod)
  * [Un Service](#un-service)
  * [Une config map](#une-config-map)
  * [Un replica set](#un-replica-set)
    * [Deploiement d'un replicaset](#deploiement-d-un-replicaset)
    * [Manipulation du replica set](#manipulation-du-replica-set)
  * [Un deploiement](#un-deploiement)
* [Conclusion](#conclusion)

## Préambules

### kubectl

L'accès à l'api kubernetes via la ligne de commande kubectl.

Comme vue dans le TP précédent une fois configué notre contexte

```bash
kubectl Actions Objets
```

Les Principales commandes à connaitre pour la suite :

* `kubectl get ObjectType` : retourne tout les objet du type ObjectType (du Namespace courant)
* `kubectl describe ObjectType/Name` : retourne toute la description de l'objet "Name" du type ObjectType
* `kubectl create .....` : permet de créé un objet on utilise plutot un manifeste
* `kubectl apply -f manifest.yml` : permet de créer tout les objets défini en yaml dans le fichier manifest
* `kubectl delete -f manifest.yml` : permet de supprimer tout les objets défini en yaml dans le fichier manifest.
* `kubectl proxy` : permet de lancer le proxy
* `kubectl [action] help` : retour l'aide kubectl (pour l'action action).

Ces commandes s'exécute dans votre contexte actuel on ajoute `-n namespace` à la commande afin qu'elle s'exécute dans le namespace spécifié.

### Les namespaces

Un namespace est un sous ensemble du cluster. De façon a rester organiser un ensemble cohérent d'objets est défini dans un namespace.

le dasboard déployé précédement à été déployé au seins d'un namespace

```bash
$ kubectl get namespace
NAME                   STATUS   AGE
default                Active   22h
kube-node-lease        Active   22h
kube-public            Active   22h
kube-system            Active   22h
kubernetes-dashboard   Active   22h
```

Il peut être créé dans une manifest :

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard
```

ou par une simple commande :

```bash
$ kubectl create namespace testing
namespace/testing created
$ kubectl get namespace
NAME                   STATUS   AGE
default                Active   22h
kube-node-lease        Active   22h
kube-public            Active   22h
kube-system            Active   22h
kubernetes-dashboard   Active   22h
testing                Active   5s
```

Il est possible de definir le namespace à utiliser par défaut :

```bash
$ kubectl config set-context --current --namespace=testing
Context "kubernetes-admin@kubernetes" modified.
alan@al-e6230:~/prep-form/repo/libre-infra$ kubectl get pods
No resources found in testing namespace.
```

cela modifie en fait votre configuration kubectl qu'il est possible de remettre au namespace default

```bash
$ grep -A2 "\- context" ~/.kube/config 
- context:
    cluster: kubernetes
    namespace: testing
$ kubectl config set-context --current --namespace=default
Context "kubernetes-admin@kubernetes" modified.
$ grep -A2 "\- context" ~/.kube/config
- context:
    cluster: kubernetes
    namespace: default
```

Nous pouvons bien sur supprimer ce namespace :

```bash
$ kubectl delete namespace testing
namespace "testing" deleted
```

> Afin de rester organiser nous crérons un namespace par ensemble cohérent d'application déployée. On se créé d'ailleurs un namespace pour de l'admin.
>
> ```bash
> kubectl create namespace admin
> ```

### Les objets connexes

![pod related objects](../images/pod-related-objects.drawio.png)

#### Completion du pod

* Service : exposition réseaux des pod
* config map : Eléments de configuration stocké dans etcd
* Persistent volume et persistent volume claim : stockage rémanet utilisable par les pod

#### Controleurs de pod

Rappel des objet kubernetes de controle de pod

* Le `ReplicaSet` : Cet objet définie le fait qu'un pod doit être répliqué un certain nombre de fois.
* Le `Deployment` : Cet objet définie Comment le **ReplicatSet** doit être re-déployé
* Le `StatefulSet` : Cet objet lie un **pod**, un **ReplicatSet** ou un **Deployment** a un `volume` (conservant l'état des pods : stateful)
* Le `DaemonSet` : Cet objet définie le fait qu'un pod doit exister sur chacuns (certains)des noeud du cluster c'est en général un pod lié a la gestion du cluster ou ses fonctionalité
* Le `Job` : le job est un pod qui effectue une tache puis s'arrête, Kubernetes ne s'assure pas que celui-ci fonctionne en permanence mais qu'il s'est exécuté avec succes
* Le `cronjob` : C'est une ligne de crontab mais dans kubernetes

## Les déploiements

### Un pod

> Un pod est un ensemble de containers

Les parametre de definition d'un pod :

* Ses meta data :
  * son nom
  * des labels
* les specifications :
  * les containeurs qui le compose
    * image
      nom
      ports exposé

On défini un pod contenant un deux containers qui écoute sur le port 80 en TCP via le manifeste suivant dans le fichier tst-pod-nginx.yml

```yaml
---
apiVersion: v1             # version de l'api
kind: Pod                  # le type d'objet
metadata:
  name: tst-pod-nginx      # le nom du pod
  labels:                  # des labels : clefs valeures
    applicat: tst-pod-label-nginx  # clef "applicat"
spec:                      # spécifications de l'objet
  containers:              # les containers du pod
  - image: nginx           # premier nginx 
    name: tst-ct-nginx
    ports:
      - containerPort: 80  # port d'écoute du container
        protocol: TCP
  - image: busybox         # Un second busybox
    name: busb
    args:
    - sleep
    - "36000"
```

Nous le lançons sur le cluster :

```bash
$ kubectl apply -f tst-pod-nginx.yml 
pod/tst-pod-nginx created
```

Nous pouvons alors consulter le pod

```bash
$ kubectl describe pod/tst-pod-nginx
Name:         tst-pod-nginx
Namespace:    default
Priority:     0
Node:         worker2/192.168.33.102
Start Time:   Sat, 26 Feb 2022 12:10:50 +0000
Labels:       applicat=tst-pod-label-nginx
Annotations:  <none>
Status:       Running
IP:           10.44.0.3
IPs:
  IP:  10.44.0.3
Containers:
  tst-ct-nginx:
    Container ID:   containerd://10a9564492066696413581c32add9430d95c6fe1df68f03f6fa134b0d3304ca2
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:2834dc507516af02784808c5f48b7cbe38b8ed5d0f4837f16e78d00deb7e7767
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sat, 26 Feb 2022 12:10:53 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-ct42d (ro)
  busb:
    Container ID:  containerd://6bcf4b0fbd4279ed35c01d15cb34380aa250dbbc465c14155a6ba27632d2dcee
    Image:         busybox
    Image ID:      docker.io/library/busybox@sha256:afcc7f1ac1b49db317a7196c902e61c6c3c4607d63599ee1a82d702d249a0ccb
    Port:          <none>
    Host Port:     <none>
    Args:
      sleep
      36000
    State:          Running
      Started:      Sat, 26 Feb 2022 12:10:54 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-ct42d (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-ct42d:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  28s   default-scheduler  Successfully assigned default/tst-pod-nginx to worker2
  Normal  Pulling    27s   kubelet            Pulling image "nginx"
  Normal  Pulled     26s   kubelet            Successfully pulled image "nginx" in 1.065513535s
  Normal  Created    25s   kubelet            Created container tst-ct-nginx
  Normal  Started    25s   kubelet            Started container tst-ct-nginx
  Normal  Pulling    25s   kubelet            Pulling image "busybox"
  Normal  Pulled     24s   kubelet            Successfully pulled image "busybox" in 1.078638565s
  Normal  Created    24s   kubelet            Created container busb
  Normal  Started    23s   kubelet            Started container busb
```

et ses logs :

```bash
$ kubectl logs pod/tst-pod-nginx -c tst-ct-nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2022/02/20 14:56:50 [notice] 1#1: using the "epoll" event method
2022/02/20 14:56:50 [notice] 1#1: nginx/1.21.6
2022/02/20 14:56:50 [notice] 1#1: built by gcc 10.2.1 20210110 (Debian 10.2.1-6) 
2022/02/20 14:56:50 [notice] 1#1: OS: Linux 4.15.0-163-generic
2022/02/20 14:56:50 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2022/02/20 14:56:50 [notice] 1#1: start worker processes
2022/02/20 14:56:50 [notice] 1#1: start worker process 31
2022/02/20 14:56:50 [notice] 1#1: start worker process 32
```

On peu aussi executer un processus attaché à un des container du pod :

```bash
$ kubectl exec -it pod/tst-pod-nginx -c busb -- sh
/ # ls
bin   dev   etc   home  proc  root  sys   tmp   usr   var
/ # ^D
$ kubectl exec -it pod/tst-pod-nginx -c tst-ct-nginx -- /bin/bash
root@tst-pod-nginx:/# ls /etc/nginx/conf.d/
default.conf
root@tst-pod-nginx:/# exit
exit
$ 
```

> **Commandes à retenir:**
>
> * kubectl **apply -f** Manifest.yml [-n NameSpace]
> * kubectl **delete -f** Manifest.yml
> * kubectl **get pods** [**--all-namespaces**]
> * kubectl **describe** Class/ObjectName
> * kubectl **logs** pod/PodName [-c ContainerName]
> * kubectl **exec** -it pod/PodName -c ContainerName -- Command

### Un Service

Afin d'accèder à l'application contenue dans le pod, nous créons un service dans le fichier tst-svc-nginx.yml

```yaml
---
apiVersion: v1
kind: Service                   # type d'objet
metadata:
  labels:                       # labels du service
    name: tst-svc-label-nginx   #    clef = name
  name: tst-svc-nginx           # le nom du service
spec:                           # spécifications de l'objet
  ports:                        # publication
    - port: 1080                # sur le port 1080
      targetPort: 80            # le port du container est 80
  selector:                     # ICI on selectione le ou les pods
    applicat: tst-pod-label-nginx   # à partir du label "applicat" que nous avons défini
```

Nous lançon ce service sur le cluster :

```bash
$ kubectl apply -f tst-svc-nginx.yml 
service/tst-svc-nginx created
```

Et nous pouvons alors consulter le services

```bash
$ kubectl describe services/tst-svc-nginx
Name:              tst-svc-nginx
Namespace:         default
Labels:            name=tst-svc-label-nginx
Annotations:       <none>
Selector:          applicat=tst-pod-label-nginx
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.99.39.230
IPs:               10.99.39.230
Port:              <unset>  1080/TCP
TargetPort:        80/TCP
Endpoints:         10.44.0.3:80
Session Affinity:  None
Events:            <none>
```

et le tester au travers de `kubectl proxy`:

```bash
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
```

via l'url : <http://127.0.0.1:8001/api/v1/namespaces/default/services/tst-svc-nginx:1080/proxy/>

```bash
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
.../...
```

Supression du pod (on garde en revanche le service):

```bash
$ kubectl delete -f tst-pod-nginx.yml
pod "tst-pod-nginx" deleted
```

> **A retenir:**
>
> * kubectl **proxy**
> * l'url **/api/v1/namespaces/**$\$NameSpace$/**services/**$\$Service$:$\$Port$/**proxy/**

### Une config map

On créé le fichier `tst-pod-configmap-nginx.yml` dans lequel on definie une config map et on redefinie le pod afin qu'il l'utilise via le montage d'un volume contenant la config map

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tst-pod-nginx-config      # juste un nom
data:                             # les données : un fichier et son contenu :
  default.conf: |
    server {
        listen 80;

        location / {
            default_type text/plain;
            expires -1;
            return 200 'Server address: $server_addr:$server_port\nServer name: $hostname\nDate: $time_local\nURI: $request_uri\nRequest ID: $request_id\n';
        }
    }
---
apiVersion: v1             # version de l'api
kind: Pod                  # le type d'objet
metadata:
  name: tst-pod-nginx      # le nom du pod
  labels:                  # des labels : clefs valeures
    applicat: tst-pod-label-nginx  # clef "applicat"
spec:                      # spécifications de l'objet
  containers:              # les containers du pod
  - image: nginx           # un seul : nbinx
    name: tst-ct-nginx
    ports:
      - containerPort: 80  # port d'écoute du container
        protocol: TCP
    volumeMounts:          # On monte un volume
      - name: nginx-configs
        mountPath: /etc/nginx/conf.d
  volumes:
    - name: nginx-configs  # le volume contien la config map
      configMap:
        name: tst-pod-nginx-config
```

Déploiement

```bash
$ kubectl apply -f tst-pod-configmap-nginx.yml
configmap/tst-pod-nginx-config created
pod/tst-pod-nginx created
```

Affichage du web : <http://127.0.0.1:8001/api/v1/namespaces/default/services/tst-svc-nginx:1080/proxy/>

```html
Server address: 10.44.0.3:80
Server name: tst-pod-nginx
Date: 20/Feb/2022:17:45:41 +0000
URI: /
Request ID: e2dffd35688a87a100f5f683efd36445
```

On observera les éléments du `kubectl describe` avec attention afin d'identifier les points de montage et les volumes :

```bash
$ kubectl describe pod/tst-pod-nginx
Name:         tst-pod-nginx
Namespace:    default
Priority:     0
Node:         worker2/192.168.33.102
Start Time:   Sun, 20 Feb 2022 18:44:57 +0100
Labels:       applicat=tst-pod-label-nginx
Annotations:  <none>
Status:       Running
IP:           10.44.0.3
IPs:
  IP:  10.44.0.3
Containers:
  tst-ct-nginx:
    Container ID:   containerd://857557b819396f34fe4eb4cbbc2a40ed9de348ee455ab97f4a5ee20b7913f22a
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:2834dc507516af02784808c5f48b7cbe38b8ed5d0f4837f16e78d00deb7e7767
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 20 Feb 2022 18:45:00 +0100
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /etc/nginx/conf.d from nginx-configs (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-zbtt4 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  nginx-configs:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      tst-pod-nginx-config
    Optional:  false
  kube-api-access-zbtt4:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
.../...
```

Supression du pod, de la config map et du service:

```bash
$ kubectl delete -f tst-pod-configmap-nginx.yml
configmap "tst-pod-nginx-config" deleted
pod "tst-pod-nginx" deleted
$ kubectl delete -f tst-svc-nginx.yml 
service "tst-svc-nginx" deleted
```

> **a retenir:**
>
> Le format d'un fichier d'une config map :
>
> ```yaml
> data:
>   default.conf: |
>     xxxxx
>     xxxxx
> ```

### Un replica set

Un ReplicaSet permet de definir qu'un pod est exécuté plusieurs fois, plusieur instance de l'applivation est exécuté en même temps.

On utilise le fichier : tst-replicaset-nginx.yml

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tst-pod-nginx-config
data:
  default.conf: |
    server {
        listen 80;

        location / {
            default_type text/plain;
            expires -1;
            return 200 'Server address: $server_addr:$server_port\nServer name: $hostname\nDate: $time_local\nURI: $request_uri\nRequest ID: $request_id\n';
        }
    }
---
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  labels:
    run: tst-ct-nginx
  name: tst-replicaset
spec:
  replicas: 2
  selector:
    matchLabels:
      applicat: tst-pod-label-nginx
  template:
    metadata:
      labels:
        applicat: tst-pod-label-nginx
    spec:
      containers:              # les containers du pod
      - image: nginx
        name: tst-ct-nginx
        ports:
          - containerPort: 80  # port d'écoute du container
            protocol: TCP
        volumeMounts:
          - name: nginx-configs
            mountPath: /etc/nginx/conf.d
      volumes:
        - name: nginx-configs
          configMap:
            name: tst-pod-nginx-config
```

#### Deploiement d'un replicaset

Le ReplicaSet

```bash
$ kubectl apply -f tst-replicaset-nginx.yml
configmap/tst-pod-nginx-config created
replicaset.apps/tst-replicaset created
$ kubectl get all
NAME                       READY   STATUS    RESTARTS   AGE
pod/tst-replicaset-677sp   1/1     Running   0          10s
pod/tst-replicaset-pvb2f   1/1     Running   0          10s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5d4h

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/tst-replicaset   2         2         2       10s
```

Affichage du service web : <http://127.0.0.1:8001/api/v1/namespaces/default/services/tst-svc-nginx:1080/proxy/>

```html
Server address: 10.44.0.3:80
Server name: tst-replicaset-pvb2f
Date: 24/Feb/2022:21:46:54 +0000
URI: /tst
Request ID: 8af10e709ca82837b2d4f51df883eee8
```

> Si on rafraichi on tombe alternativement sur l'un ou l'autre des deux pods.

#### Manipulation du ReplicaSet

il est possible de changer les nombre de réplicats en live pour le réduire ou l'augmenter

```bash
$ kubectl scale --replicas=1 rs tst-replicaset
$ kubectl get all
NAME                       READY   STATUS    RESTARTS   AGE
pod/tst-replicaset-677sp   1/1     Running   0          10s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   5d4h

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/tst-replicaset   1         1         
```

Netoyage (pour le tp suivant) :

Supression du pod, de la config map et du service:

```bash
$ kubectl delete -f tst-replicaset-nginx.yml
configmap "tst-pod-nginx-config" deleted
replicaset.apps "tst-replicaset" deleted
$ 
```

> **a retenir:**
>
> * kubectl **scale --replicas=**$\$X$ $\$ReplicatSetName$
>
> afin de modifier en live le nombre de replicas pour s'adapter à une monté en charge par exemple, cela peu être utilise aussi pour relancer les pods avec une valeur à 0 puis à la valeur souhaité.

### Un deploiement

Un déploiement est un réplicat intégrant une stratégye de re-déploiement

* Recreate : on recréer complétement le ReplicatSet/Deployment
* RollingUpdate : On met à jour successivement les pod du ReplicatSet/Deployment en fonctions des paramettres suivants :
  * maxUnavailable : nombre ou % de pod maximum arreté en même temps (25% par défaut) pendant le mise à jour.
  * maxSurge : nombe ou % maximal de pods pouvant être créés en plus pendant la mise à jour.

Nous pouvons tester un déploiement avec la stratégie rolling update :

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tst-pod-nginx-config
data:
  default.conf: |
    server {
        listen 80;

        location / {
            default_type text/plain;
            expires -1;
            return 200 'Server address: $server_addr:$server_port\nServer name: $hostname\nDate: $time_local\nURI: $request_uri\nRequest ID: $request_id\n';
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: tst-ct-nginx
  name: tst-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      applicat: tst-pod-label-nginx
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
  minReadySeconds: 5
  revisionHistoryLimit: 10
  template:
    metadata:
      labels:
        applicat: tst-pod-label-nginx
    spec:
      containers:              # les containers du pod
      - image: nginx:1.12
        name: tst-ct-nginx
        ports:
          - containerPort: 80  # port d'écoute du container
            protocol: TCP
        volumeMounts:
          - name: nginx-configs
            mountPath: /etc/nginx/conf.d
      volumes:
        - name: nginx-configs
          configMap:
            name: tst-pod-nginx-config
```

Déploiement :

```bash
$ kubectl apply -f tst-deploiement-nginx.yml
configmap/tst-pod-nginx-config created
deployment.apps/tst-deployment created
$ kubectl get deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
tst-deployment   2/2     2            2           10m
```

Nous avons bien les sous objets ReplicatSet et Pod de definis:

```bash
$ kubectl get replicaset
NAME                        DESIRED   CURRENT   READY   AGE
tst-deployment-7dd5c66695   2         2         2       10m
$ kubectl get pod --selector=applicat=tst-pod-label-nginx
NAME                              READY   STATUS    RESTARTS   AGE
tst-deployment-7dd5c66695-c5zc9   1/1     Running   0          10m
tst-deployment-7dd5c66695-dgdcj   1/1     Running   0          10m
```

Pour gèrer l'objet Deployment :

Le déploiement est terminé avec succès et une seule version de ce déploiement à déjà été déployée dans ce namespace :

```bash
$ kubectl rollout status deployment tst-deployment
deployment "tst-deployment" successfully rolled out
$ kubectl rollout history deployment tst-deployment
deployment.apps/tst-deployment 
REVISION  CHANGE-CAUSE
1         <none>
```

Si on change la version de l'image:

```bash
$ kubectl set image deployment tst-deployment tst-ct-nginx=nginx:1.14 --record
$ kubectl rollout status deployment tst-deployment
Waiting for deployment "tst-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "tst-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "tst-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "tst-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "tst-deployment" rollout to finish: 1 of 2 updated replicas are available...
Waiting for deployment "tst-deployment" rollout to finish: 1 of 2 updated replicas are available...
deployment "tst-deployment" successfully rolled out
$ kubectl rollout history deployment tst-deployment
deployment.apps/tst-deployment 
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl set image deployment tst-deployment tst-ct-nginx=nginx:1.14 --record=true
$ kubectl get pod --selector=applicat=tst-pod-label-nginx -o=custom-columns='NAME:metadata.name,DATA:spec.containers[*].image'
NAME                              DATA
tst-deployment-7dd5c66695-ghmvv   nginx:1.14
tst-deployment-7dd5c66695-tkswx   nginx:1.14
```

> Dans la pratrique on modifira le manifeste et on appliquera l'upgrade avec la commande suivante
>
> ```bash
> $ kubectl apply --filename=tst-deploiement-nginx.yml --record=true
> configmap/tst-pod-nginx-config unchanged
> deployment.apps/tst-deployment configured
> ```

Avec `kubectl rollout undo tst-deployment` il est possible d'annuler (Rollback) le re-déploiement et de revenir à sa version précédente :

```bash
$ kubectl rollout undo deploy tst-deployment
deployment.apps/tst-deployment rolled back
$ kubectl rollout history deployment tst-deployment
deployment.apps/tst-deployment 
REVISION  CHANGE-CAUSE
2         kubectl set image deployment tst-deployment tst-ct-nginx=nginx:1.14 --record=true
3         <none>
$ kubectl get pod --selector=applicat=tst-pod-label-nginx -o=custom-columns='NAME:metadata.name,DATA:spec.containers[*].image'
NAME                              DATA
tst-deployment-7dd5c66695-ghmvv   nginx:1.12
tst-deployment-7dd5c66695-tkswx   nginx:1.12
```

Après plusieurs déploiements de revision distinctes de notre déploimement, nous avons un seul déploiement mais plusieurs versions différentes du réplicat set nous permettant de revenir plusieurs version en arrière:

```bash
$ kubectl get deployments
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
tst-deployment   2/2     2            2           12m
$ kubectl get rs
NAME                        DESIRED   CURRENT   READY   AGE
tst-deployment-76f4649cb9   2         2         2       2d1h
tst-deployment-7dd5c66695   0         0         0       2d1h
tst-deployment-9b449759b    1         1         0       13s
```

> **Commandes à retenir:**
>
> * kubectl get pod --selector=$\$key$=$\$value$ **-o=custom-columns='NAME:metadata.name,DATA:spec.containers[*].image'**
> * kubectl get deployments -n $\$NameSpace$
> * kubectl **get rs** -n $\$NameSpace$
> * kubectl **set image** deployment $\$Deployment$ $\$Container$=$\$image$:$\$version$
> * kubectl **rollout restart** deployment $\$DeploymentName$
> * kubectl **rollout undo** deployment $\$DeploymentName$
> * kubectl **scale** deployment.v1.apps/$\$Deployment$ **--replicas=**$\$NbReplica$
>

## Conclusion

Nous savons maintenant déployer et mettre à jour des applications intégrant une scalabilité horizontale (des réplicats)

> **On retiendra** en plus des commandes kubectl cété plus haut:
>
> * les principales clefs et format de manifest des objets : Pods, Deploiement(replicaSet,DaemonSet), Service, ConfigMap
> * L'usage des `selector` et des metadata afin de "connecter" les objets entre eux
