# Loadbalancing

* [MetalLB](#metallb)
  * [Déploiement de metalLB](#déploiement-de-metallb)
  * [Déploiement d'un ReplicatSet derrière le loadbalanceur](#déploiement-dun-replicatset-derrière-le-loadbalanceur)
* [Conclusion](#conclusion)

## MetalLB

MetalLB est la solution de loadbalancing qui s'intégre dans un cluster Kubernetes.

Il permet de publier sur une adresse ip hors du "cluster network" un Service les accès sur cette ip seront routés vers le service ainsi publié.

### Déploiement de metalLB

le manifeste de déploiement viendra provisioner:

* un namespace : metallb-system
* des "CustomResource" en extension à l'api kubernetes : *.metallb.io dont:
  * ipaddresspools.metallb.io
  * l2advertisements.metallb.io
* deux ServiceAccount et leur accès RBAC: Role, ClusterRole, RoleBinding et ClusterRoleBinding
* enfin un secret, un service, un daemonset et un Déploiement
* puis des webhook de validation de config qui sortent clairement du cadre de ce cours.

```bash
$ curl -sL https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml | grep -e "^apiVersion: " -e "^kind: " -e "^  name: "
apiVersion: v1
kind: Namespace
  name: metallb-system
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
  name: addresspools.metallb.io
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
  name: bfdprofiles.metallb.io
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
  name: bgpadvertisements.metallb.io
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
  name: bgppeers.metallb.io
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
  name: communities.metallb.io
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
  name: ipaddresspools.metallb.io
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
  name: l2advertisements.metallb.io
apiVersion: v1
kind: ServiceAccount
  name: controller
apiVersion: v1
kind: ServiceAccount
  name: speaker
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
  name: controller
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
  name: pod-lister
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
  name: metallb-system:controller
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
  name: metallb-system:speaker
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
  name: controller
  name: controller
  name: controller
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
  name: pod-lister
  name: pod-lister
  name: speaker
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
  name: metallb-system:controller
  name: metallb-system:controller
  name: controller
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
  name: metallb-system:speaker
  name: metallb-system:speaker
  name: speaker
apiVersion: v1
kind: Secret
  name: webhook-server-cert
apiVersion: v1
kind: Service
  name: webhook-service
apiVersion: apps/v1
kind: Deployment
  name: controller
apiVersion: apps/v1
kind: DaemonSet
  name: speaker
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
  name: metallb-webhook-configuration
  name: bgppeersvalidationwebhook.metallb.io
  name: addresspoolvalidationwebhook.metallb.io
  name: bfdprofilevalidationwebhook.metallb.io
  name: bgpadvertisementvalidationwebhook.metallb.io
  name: communityvalidationwebhook.metallb.io
  name: ipaddresspoolvalidationwebhook.metallb.io
  name: l2advertisementvalidationwebhook.metallb.io
```

On l'applique sur le cluster

```bash
$ kubectl apply -f curl -sL https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
...
```

### Configuration

On applique la configuration suivante définissant deux IPAddressPool et L2Advertisement , tout deux objets de l'extension à l'api kubernetes pour metallb défini plus haut.

```bash
manifests$ cat metallb-config.yml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  creationTimestamp: null
  name: default
  namespace: metallb-system
spec:
  addresses:
  - 192.168.33.10-192.168.33.10
status: {}
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  creationTimestamp: null
  name: realpool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.33.20-192.168.33.30
status: {}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  creationTimestamp: null
  name: l2advertisement1
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
status: {}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  creationTimestamp: null
  name: l2advertisement2
  namespace: metallb-system
spec:
  ipAddressPools:
  - realpool
status: {}
---
```

#### Résultat

```bash
manifests$ kubectl get all -n metallb-system
NAME                              READY   STATUS    RESTARTS   AGE
pod/controller-577b5bdfcc-w75d5   1/1     Running   0          3h25m
pod/speaker-ptt54                 1/1     Running   0          3h25m
pod/speaker-v68p8                 1/1     Running   0          3h25m

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/webhook-service   ClusterIP   10.110.53.218   <none>        443/TCP   3h25m

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/speaker   2         2         2       2            2           kubernetes.io/os=linux   3h25m

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/controller   1/1     1            1           3h25m

NAME                                    DESIRED   CURRENT   READY   AGE
replicaset.apps/controller-577b5bdfcc   1         1         1       3h25m
```

### Déploiement d'un ReplicatSet derrière le loadbalanceur

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
      containers:
      - image: nginx
        name: tst-ct-nginx
        ports:
          - containerPort: 80
            protocol: TCP
        volumeMounts:
          - name: nginx-configs
            mountPath: /etc/nginx/conf.d
      volumes:
        - name: nginx-configs
          configMap:
            name: tst-pod-nginx-config
---
apiVersion: v1
kind: Service
metadata:
  labels:
    name: tst-svc-label-nginx
  annotations:
    metallb.universe.tf/address-pool: realpool          # definition du pool
    metallb.universe.tf/loadBalancerIPs: 192.168.33.30  # et de l'ip
  name: tst-svc-nginx
spec:
  type: LoadBalancer                                    # appel au loadbalanceur du cluster
  ports:
    - port: 1080
      targetPort: 80
  selector:                                       # selection des templates de pods
    applicat: tst-pod-label-nginx
```

```bash
$ kubectl apply -f tst-replicatset-nginx-lb.yml
configmap/tst-pod-nginx-config created
replicaset.apps/tst-replicaset created
service/tst-svc-nginx created
$ kubectl get all
NAME                       READY   STATUS    RESTARTS   AGE
pod/tst-replicaset-868ql   1/1     Running   0          104s
pod/tst-replicaset-rv9l4   1/1     Running   0          104s

NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)          AGE
service/kubernetes      ClusterIP      10.96.0.1     <none>          443/TCP          13d
service/tst-svc-nginx   LoadBalancer   10.99.39.25   192.168.33.30   1080:32594/TCP   104s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/tst-replicaset   2         2         2       104s
```

On notera l'external IP et que le site est maintenant accessible via l'url
<http://192.168.33.30:1080/>

## Conclusion

Nous pouvons maintenant déployer des services réellement accessible sur une ip publique (extérieur au cluster).

Pour ce faire nous definissons le service de type load balanceur:

```yaml
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    metallb.universe.tf/address-pool: <POOL>
    metallb.universe.tf/loadBalancerIPs: <IPFROMPOOL>
  name: <SERVICENAME>
spec:
  type: LoadBalancer
  ports:
    - port: <PUBLICPORT>
      targetPort: <CONTAINERPORT>   # le port sur le pod
```

Dans notre exemple nous retrouvons bien le port public 1080, le port de kubeproxy sur le node : 32594 et enfin le port sur le container : 80

```bash
$ kubectl get services tst-svc-nginx
NAME            TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)          AGE
tst-svc-nginx   LoadBalancer   10.99.39.25   192.168.33.30   1080:32594/TCP   34m
$ kubectl get endpoints tst-svc-nginx
NAME            ENDPOINTS                   AGE
tst-svc-nginx   10.44.0.5:80,10.44.0.6:80   34m
```
