# Helm

Helm est le gestionaire de package Pour kubernetes
<https://helm.sh/fr/> Il permet de gerer des répository de packages et donc d'installer des application pré-packagé par un editeur.

## Installation et tests

Suivez la doc: <https://helm.sh/fr/docs/intro/install/>

Sinon, sous linux depuis le host master

```bash
root@master:~# wget -q https://get.helm.sh/helm-v3.11.1-linux-amd64.tar.gz
root@master:~# tar -zxvf helm-v3.11.1-linux-amd64.tar.gz
linux-amd64/
linux-amd64/helm
linux-amd64/LICENSE
linux-amd64/README.md
root@master:~# ls -al linux-amd64/
total 44036
drwxr-xr-x 2 3434 3434     4096 Jan 24 16:29 .
drwx------ 5 root root     4096 Mar  6 15:31 ..
-rwxr-xr-x 1 3434 3434 45068288 Jan 24 16:18 helm
-rw-r--r-- 1 3434 3434    11373 Jan 24 16:29 LICENSE
-rw-r--r-- 1 3434 3434     3367 Jan 24 16:29 README.md
root@master:~# mv linux-amd64/helm /usr/local/bin/helm
```

recherche de package sur le hub

```bash
root@master:~# helm search hub minecraft
URL                                                CHART VERSION APP VERSION DESCRIPTION                                       
https://artifacthub.io/packages/helm/minecraft-... 3.8.1         SeeValues   Minecraft server                                  
https://artifacthub.io/packages/helm/cocainefar... 1.4.0         1.18        A Helm chart for a minecraft server               
https://artifacthub.io/packages/helm/cloudnativ... 1.0.0         1.13.1      Minecraft server                                  
.../...
```

ajout d'un repos et recherche sur le repo :

```bash
root@master:~# helm repo add stable https://charts.helm.sh/stable
"stable" has been added to your repositories
root@master:~# helm search repo stable
NAME                                  CHART VERSION APP VERSION             DESCRIPTION                                       
stable/acs-engine-autoscaler          2.2.2         2.1.1                   DEPRECATED Scales worker nodes within agent pools 
stable/aerospike                      0.3.5         v4.5.0.5                DEPRECATED A Helm chart for Aerospike in Kubern...
stable/airflow                        7.13.3        1.10.12                 DEPRECATED - please use: https://github.com/air...
stable/ambassador                     5.3.2         0.86.1                  DEPRECATED A Helm chart for Datawire Ambassador   
stable/anchore-engine                 1.7.0         0.7.3                   Anchore container analysis and policy evaluatio...
```

## Exemple d'utilisation

### ajout des repo helm de prometheus-community, kube-state-metrics et grafana

```bash
root@master:~# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories
root@master:~# helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
"kube-state-metrics" has been added to your repositories
root@master:~# helm repo add grafana https://grafana.github.io/helm-charts
"grafana" has been added to your repositories
root@master:~# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "kube-state-metrics" chart repository
...Successfully got an update from the "grafana" chart repository
...Successfully got an update from the "prometheus-community" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
```

### Configuration prometheus

Dans ce cas précis on désactive l'alerte manager et la push gateway. Chaque package offre tout un choix d'options et paramètres qui dépendent naturelement de la solution packagée et de ce que l'on souhaites en faire.
Le pramétrage se fait via un fichier yaml définissant les variables utilisées par les chats helm.

```bash
root@master:~# helm show values prometheus-community/prometheus > prom-values.yaml
root@master:~# cp prom-values.yaml prom-values.yaml.orig
root@master:~# vi prom-values.yaml
root@master:~# diff prom-values.yaml prom-values.yaml.orig 
1081c1081
<   enabled: False
---
>   enabled: true
1120c1120
<   enabled: False
---
>   enabled: true
```

Nous le déploirons un peu plus loin.

il est aussi possible de simplement downloader le package :

```bash
root@master:~# helm pull prometheus-community/prometheus
root@master:~# ls -al prometheus-19.6.1.tgz
-rw-r--r-- 1 root root 56962 Feb 22 18:08 prometheus-19.6.1.tgz
root@master:~# tar xzf prometheus-19.6.1.tgz
root@master:~# tree -L 2 prometheus/
prometheus/
├── Chart.lock
├── Chart.yaml
├── README.md
├── charts
│   ├── alertmanager
│   ├── kube-state-metrics
│   ├── prometheus-node-exporter
│   └── prometheus-pushgateway
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── clusterrole.yaml
│   ├── clusterrolebinding.yaml
│   ├── cm.yaml
│   ├── deploy.yaml
│   ├── extra-manifests.yaml
│   ├── headless-svc.yaml
│   ├── ingress.yaml
│   ├── network-policy.yaml
│   ├── pdb.yaml
│   ├── psp.yaml
│   ├── pvc.yaml
│   ├── rolebinding.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   ├── sts.yaml
│   └── vpa.yaml
├── values.schema.json
└── values.yaml
```

On retrouve le fichier values.yml récupèrer plus tôt et tout un tas de template de manifest.

si on regarde par exemple le template du service associé au server prometheus. (J'en ai filtré une partie afin de mieu la présenter)

```bash
root@master:~# grep -v "^\s*{{" prometheus/templates/service.yaml | grep -v -e nodePort: -e loadBalancer -e annotations: -e labels:
apiVersion: v1
kind: Service
metadata:
  name: {{ template "prometheus.server.fullname" . }}
spec:
  clusterIP: {{ .Values.server.service.clusterIP }}
  externalIPs:
    - {{ $cidr }}
  ports:
    - name: http
      port: {{ .Values.server.service.servicePort }}
      protocol: TCP
      targetPort: 9090
    - name: grpc
      port: {{ .Values.server.service.gRPC.servicePort }}
      protocol: TCP
      targetPort: 10901
  selector:
    statefulset.kubernetes.io/pod-name: {{ template "prometheus.server.fullname" . }}-{{ .Values.server.service.statefulsetReplica.replica }}
  sessionAffinity: {{ .Values.server.service.sessionAffinity }}
  type: "{{ .Values.server.service.type }}"
```

On retrouve bien un manifest avec des valeurs soit issue du fichier value.yml, exemple : `.Values.server.service.type` soit issue du fichier de templating _helper.tpl : `prometheus.server.fullname` que l'on va retrouver dans plusieurs template et qui est défini qu'une seul fois sous forme de valeur ou de ligne

Exemple :

```text
root@master:~# nl prometheus/templates/_helpers.tpl | tail -10
   251 {{/*
   252 Define the prometheus.namespace template if set with forceNamespace or .Release.Namespace is set
   253 */}}
   254 {{- define "prometheus.namespace" -}}
   255 {{- if .Values.forceNamespace -}}
   256 {{ printf "namespace: %s" .Values.forceNamespace }}
   257 {{- else -}}
   258 {{ printf "namespace: %s" .Release.Namespace }}
   259 {{- end -}}
   260 {{- end -}}
root@master:~# grep -r prometheus.namespace prometheus/ | wc -l
15
```

> On suivra la documentation de helm pour y voir un peu plus claire sur ce format : <https://helm.sh/docs/chart_template_guide/getting_started/>

### Deploiement prometheus

On utilise simple helm pour déployer le package avec notre personalisation de variable

```bash
root@master:~# helm install prometheus prometheus-community/prometheus --values prom-values.yaml --namespace admin
NAME: prometheus
LAST DEPLOYED: Wed Feb 22 18:14:18 2023
NAMESPACE: admin
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.admin.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace admin -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace admin port-forward $POD_NAME 9090


#################################################################################
######   WARNING: Pod Security Policy has been disabled by default since    #####
######            it deprecated after k8s 1.25+. use                        #####
######            (index .Values "prometheus-node-exporter" "rbac"          #####
###### .          "pspEnabled") with (index .Values                         #####
######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
######            in case you still need it.                                #####
#################################################################################


For more information on running Prometheus, visit:
https://prometheus.io/
```

> **Commande à retenir:**
>
> * helm repo add $\$RepoName$ $\$RepoUrl$
> * helm show values $\$RepoName$/$\$Package$ > file.yml
> * helm install $\$RepoName$/$\$Package$ --values $\$File.yaml$ --namespace $\$NameSpace$

### Configuration grafana

On fait de même avec l'application Grafana.

* On change le type de service en mode LoadBalncer
* On active la persistence des données sur 4GB

```bash
root@master:~# helm show values grafana/grafana > graf-values.yaml
root@master:~# cp graf-values.yaml graf-values.yaml.orig
root@master:~# vi graf-values.yaml
root@master:~# diff graf-values.yaml graf-values.yaml.orig 
173c173
<   type: LoadBalancer
---
>   type: ClusterIP
313c313
<   enabled: True
---
>   enabled: false
317c317
<   size: 4Gi
---
>   size: 10Gi
```

### Deploiement grafana

```bash
root@master:~# helm install grafana grafana/grafana --values ./graf-values.yaml --namespace admin
NAME: grafana
LAST DEPLOYED: Wed Feb 22 18:25:02 2023
NAMESPACE: admin
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:

   kubectl get secret --namespace admin grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.admin.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:
   NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace admin -w grafana'
     export SERVICE_IP=$(kubectl get svc --namespace admin grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
     http://$SERVICE_IP:80

3. Login with the password from step 1 and the username: admin
```

On récupère l'ip loadbalanceur :

```bash
root@master:~# kubectl get svc --namespace admin grafana
NAME      TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
grafana   LoadBalancer   10.111.82.33   192.168.33.10   80:30959/TCP   71s

root@master:~# kubectl get secret --namespace admin grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
POIJ3z5uFGM2ycECjfnn9MuYev858hrnU3lagBDM
```

Sur l'interface grafana on crééra le datasource de type prometheus : <http://prometheus-server.admin.svc.cluster.local>

Ce noms dns est maintenu par le service coredns de kubernetes il est donc connu de tout les pods.

On pourra alors installer les dashboard grafana suivants :

* <https://grafana.com/grafana/dashboards/8685>
* <https://grafana.com/grafana/dashboards/13421>
* <https://grafana.com/grafana/dashboards/11454>

## Conclusion

Voilà voilà, nous avons une plateforme kubernetes sur laquel nous pouvons déployer des applications avec du stockage, un peu de monitoring, reste a deployer nos services.
