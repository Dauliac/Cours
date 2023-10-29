#!/bin/bash
test -f /root/kubeinstallmasterdone && echo "already installed"
test -f /root/kubeinstallmasterdone && exit 0

# init cluster
kubeadm init --apiserver-advertise-address=192.168.33.100 --pod-network-cidr=10.42.0.0/16 >> /root/kubeinit.log 2>&1

# give vagrant access
mkdir /home/vagrant/.kube /root/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
cp /etc/kubernetes/admin.conf /root/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# weavenet CNI
curl -s -L "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml" -o weavenet.yml
kubectl apply -f weavenet.yml

# create join token availiable for few hours
kubeadm token create --print-join-command > /home/vagrant/joinkubecluster.sh
chown vagrant:vagrant /home/vagrant/joinkubecluster.sh

# serveur NFS
mkdir /opt/data
apt-get install -qq -y nfs-kernel-server
cat >> /etc/exports <<EOF
/opt/data 192.168.33.0/24(rw,no_root_squash)
EOF
service nfs-kernel-server reload

touch /root/kubeinstallmasterdone

#ufw allow 6443/tcp
#ufw allow 2379/tcp
#ufw allow 2380/tcp
#ufw allow 10250/tcp
#ufw allow 10251/tcp
#ufw allow 10252/tcp
#ufw allow 10255/tcp
#ufw reload 
