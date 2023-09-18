#!/bin/bash

cat >>/etc/hosts<<EOF
192.168.33.100 master.lab.local master
192.168.33.101 worker1.lab.local worker1
192.168.33.102 worker2.lab.local worker2
EOF

cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1

sed -i '/swap/d' /etc/fstab
swapoff -a


apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install docker-ce -y
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker >/dev/null 2>&1
systemctl start docker
# Kube
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet >/dev/null 2>&1
systemctl start kubelet >/dev/null 2>&1

usermod -aG docker vagrant
echo "export TERM=xterm" >> /home/vagrant/.bashrc

line=`cat /vagrant/id_rsa.pub`
grep -q "$line" /home/vagrant/.ssh/authorized_keys || echo "$line" >> /home/vagrant/.ssh/authorized_keys
cp /vagrant/id_rsa /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa /home/vagrant/.ssh/authorized_keys
chown vagrant.vagrant /home/vagrant/.ssh/id_rsa /home/vagrant/.ssh/authorized_keys /home/vagrant/.bashrc

