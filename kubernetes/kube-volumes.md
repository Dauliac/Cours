# Gestion du stockage

* [gestion des volumes persistants](#gestion-des-volumes-persistants)
  * [Mise en oeuvre de la gestion de stockage](#mise-en-oeuvre-de-la-gestion-de-stockage)
  * [Test unitaire de la gestion de stockage](#test-unitaire-de-la-gestion-de-stockage)
  * [Utilisation des PersistentVolumes](#utilisation-des-persistentvolumes)
* [Conclusion](#conclusion)

Le principe est que nos applications qui tournent dans les container ne stocke aucune donnée, celle-ci est systématriquement placé dans un volume dédié à cela assurant sa persistance

Dans un environement cloud, le provider propose des solution de stockage corespondant à des StorageClass.

Sur notre lab, nous avons déployé un serveur NFS et monté un partage sur tout le noeud sur /opt/data ceci nous permet de proposer un classe de stockage à nos utilisateurs.

## Gestion des volumes persistants

Modèle :

Pour avoir du stockage nous devons definir une demande de stockage via l'objet : `PersistentStorageClaim` sur la classe de stockage `StorageClass` que nous avons définie.

Les pod ou templat de pod (dans les déploiements ou replicatset ,daemonset, jobs etc... ) necessitant du stockage persisitant vont définir un volume associé au PersistentVolumeClaim

![pod related objects](../images/pod-related-objects.drawio.png)

Un `PersistentStorage` est créé répondant à ce besoin a disponible sur tout les noeud susceptible de porter l'un des pods utilisants ce volume.

Ce PersistentVolume est alors rattaché au PersistentStorageClaim lui même rataché au pod ou template de pods puis monté dans les container.

Ce Perssistent volume sera persistant jusqu'a supression explicite de cet objet.

Les containeurs qui auront monté ce volume sera utilisé via le point de montage.

> Dans le point suivant, nous déployons une application dont la fonction est de répondre automatiquement au PersistantStorageClaim en fournissant un PersistentStorage.
> Cette application doit avoir certain accès sur les namespace autres que le sien et necesssite donc une gestion de droits partifulière sur le cluster kube qui sera juste survolée dans ce tp

### Mise en oeuvre de la gestion de stockage

Création de la classe de stockage :

```bash
$ cat storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: nfs-provisioner
reclaimPolicy: Retain
parameters:
  pathPattern: "${.PVC.namespace}/${.PVC.name}/${.PVC.volume}"
  onDelete: "Retain"
  archiveOnDelete: "false"
```

Déploiement

```bash
$ kubectl create -f storage-class.yaml -n admin
storageclass.storage.k8s.io/managed-nfs-storage created
```

Pour les droits d'accès, on créer sur le lab:

* Un ServiceAccount : un compte d'accès
* Un ClusterRole : offrant les droits d'accès necessaires aux objets du cluster :
  * PersistantVolume
  * PersistentVolumeClaims
  * StorageClasses
  * Events
* Un ClusterRoleBinding qui lie le ServiceAcount au ClusterRole
* Un Role Offrant les accès aux objets des namespaces
* Un role binding associant ce role au ServiceAcount

```bash
$ cat rbac-admin.yaml
kind: ServiceAccount
apiVersion: v1
metadata:
  name: nfs-client-provisioner
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: admin
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # namespace 
    namespace: admin
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```

Déploiement

```bash
$ kubectl create -f rbac-admin.yaml -n admin
serviceaccount/nfs-client-provisioner created
clusterrole.rbac.authorization.k8s.io/nfs-client-provisioner-runner created
clusterrolebinding.rbac.authorization.k8s.io/run-nfs-client-provisioner created
role.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
rolebinding.rbac.authorization.k8s.io/leader-locking-nfs-client-provisioner created
```

Déploiement de l'application `nfs-client-provisioner` (image: groundhog2k/nfs-subdir-external-provisioner:v3.2.0<https://hub.docker.com/r/groundhog2k/nfs-subdir-external-provisioner>) qui créer les PersistantVolumes répondant aux PersistentVolumeClaims

```bash
$ cat provis-nfs-deploy.yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
spec:
  selector:
    matchLabels:
      app: nfs-client-provisioner
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: groundhog2k/nfs-subdir-external-provisioner:v3.2.0
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: nfs-provisioner
            - name: NFS_SERVER
              value: 192.168.33.100
            - name: NFS_PATH
              value: /opt/data/
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.33.100
            path: /opt/data/
```

Déploiement

```bash
$ kubectl create -f provis-nfs-deploy.yaml -n admin
deployment.apps/nfs-client-provisioner created
```

### Test unitaire de la gestion de stockage

Nous créons persistent storage claim sur le namespace default :

```bash
manifests$ cat tst-persistent-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc1
spec:
  storageClassName: managed-nfs-storage
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Mi
```

Déploiement et résultat :

```bash
$ kubectl apply -f tst-persistent-volume-claim.yaml
persistentvolumeclaim/pvc1 created
$ kubectl get pv,pvc
NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM          STORAGECLASS          REASON   AGE
persistentvolume/pvc-17a20a87-2c28-4ea0-8003-49d8eafb6941   50Mi       RWX            Retain           Bound      default/pvc1   managed-nfs-storage            8s

NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          AGE
persistentvolumeclaim/pvc1   Bound    pvc-17a20a87-2c28-4ea0-8003-49d8eafb6941   50Mi       RWX            managed-nfs-storage   8s
```

Un PersistentVolume à bien été créé et il est visible sur le partage NFS :

```bash
vagrant@worker2:~$ tree /opt/data/
/opt/data/
└── default
    └── pvc1
```

On netoie notre test unitaire :

```bash
$ kubectl delete -f tst-persistent-volume-claim.yaml
persistentvolumeclaim/pvc1 deleted
$ kubectl delete persistentvolume/pvc-17a20a87-2c28-4ea0-8003-49d8eafb6941
persistentvolume/pvc-17a20a87-2c28-4ea0-8003-49d8eafb6941 deleted
```

Du fait de la storage class, et du paramete onDelete : `onDelete: "Retain"` le volume n'est pas détruit on le supprime donc manuelement :

```bash
vagrant@worker2:~$ rmdir /opt/data/default/pvc1
```

> **a retenir:**
>
> * kubectl get pv,pvc
> * Les volumes doivent être managés

### Utilisation des PersistentVolumes

Dans le manifest tst-deploiement-volume-nginx.yml :

On créé une config map pour la config nginx
un PersistentVolumeClaim pour les données statiques/public de notre server nginx, notre déploiement en enfin un service pour y accèder

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
        location /public/ {
            alias /usr/share/nginx/html/;   # routage sur le point de montage
        }
    }
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: tst-deployment-pvc                 # Les pvc
spec:
  storageClassName: managed-nfs-storage    # la storage classe managé
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Mi
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
      maxSurge: 1
      maxUnavailable: 0
  minReadySeconds: 5
  revisionHistoryLimit: 4
  template:                              # les template de pods
    metadata:
      labels:
        applicat: tst-pod-label-nginx
    spec:
      volumes:                              # Les volumes
        - name: nginx-configs
          configMap:                        # Une ConfigMap
            name: tst-pod-nginx-config
        - name: webpubdata                  
          persistentVolumeClaim:            # Un PVC
            claimName: tst-deployment-pvc
      containers:                           # les containers du pod
      - image: nginx:1.15
        name: tst-ct-nginx
        ports:
          - containerPort: 80
            protocol: TCP
        volumeMounts:
          - name: nginx-configs
            mountPath: /etc/nginx/conf.d
          - name: webpubdata
            mountPath: /usr/share/nginx/html
---
apiVersion: v1
kind: Service                           # le service
metadata:
  labels: 
    name: tst-svc-label-nginx
  name: tst-svc-nginx
spec: 
  ports:
    - port: 1080
      targetPort: 80
  selector:
    applicat: tst-pod-label-nginx

```

Déploiement :

```bash
$ kubectl apply -f tst-deploiement-volume-nginx.yml
configmap/tst-pod-nginx-config configured
persistentvolumeclaim/tst-deployment-pvc created
deployment.apps/tst-deployment configured
service/tst-svc-nginx unchanged
```

Le pv est bien créé :

```bash
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS          REASON   AGE
pvc-fe13886d-e1b9-428a-a142-b6cde0fbca1c   50Mi       RWX            Retain           Bound    default/tst-deployment-pvc   managed-nfs-storage            58m
```

Sur le serveur NFS on créé du contenu statique sur le pvc créé:

```bash
root@master:~# echo yes > /opt/data/default/tst-deployment-pvc/tst.txt
```

Enfin après avoir redémarrer le proxy kubectl on test l'accès au contenu statique depuis le service :

<http://127.0.0.1:8001/api/v1/namespaces/default/services/http:tst-svc-nginx:1080/proxy/public/tst.txt>

Netoyage :

```bash
$ kubectl delete -f tst-deploiement-volume-nginx.yml
configmap "tst-pod-nginx-config" deleted
persistentvolumeclaim "tst-deployment-pvc" deleted
deployment.apps "tst-deployment" deleted
service "tst-svc-nginx" deleted
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                        STORAGECLASS          REASON   AGE
pvc-fe13886d-e1b9-428a-a142-b6cde0fbca1c   50Mi       RWX            Retain           Released   default/tst-deployment-pvc   managed-nfs-storage            76m
$ kubectl delete pv pvc-fe13886d-e1b9-428a-a142-b6cde0fbca1c
persistentvolume "pvc-fe13886d-e1b9-428a-a142-b6cde0fbca1c" deleted
```

Netoyage de la donnée :

```bash
root@master:~# ls /opt/data/default/
tst-deployment-pvc
root@master:~# ls /opt/data/default/tst-deployment-pvc/
tst.txt
root@master:~# rm /opt/data/default/tst-deployment-pvc/tst.txt 
root@master:~# rmdir /opt/data/default/tst-deployment-pvc/
root@master:~# 
```

## Conclusion

Nous avons maintenant une solution de stokage disponible pour tout les noeud du cluster, nous pouvons maintenant déployer des applications necessitant des volumes
