#!/bin/bash

containerdversion="1.6.16"
kubestuffversion="1.23.17-00"
#kubestuffversion="1.23.3-00"
kubecniversion="1.1.1-00"
#kubecniversion="0.8.7-00"


# source local environement
test -r /vagrant/.env || echo you should have defined .env file !!!
test -r /vagrant/.env || exit 1
test -r /vagrant/.env && . /vagrant/.env

cat >>/etc/hosts<<EOF
192.168.33.100 master.lab.local master
192.168.33.101 worker1.lab.local worker1
192.168.33.102 worker2.lab.local worker2
EOF

cat >>/etc/sysctl.d/99-kubernetes-cri.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1

sed -i '/swap/d' /etc/fstab
swapoff -a

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# container runtime:
apt-get update
apt-get -y install podman containerd
systemctl stop containerd

# upgrade containerd to $containerdversion
mkdir /opt/src
cd /opt/src
wget https://github.com/containerd/containerd/releases/download/v${containerdversion}/containerd-${containerdversion}-linux-amd64.tar.gz > /dev/null 2>&1
tar xf containerd-${containerdversion}-linux-amd64.tar.gz 
cp bin/* /usr/bin/
cd -

cat <<EOF | sudo tee /etc/containers/registries.conf
[registries.search]
registries = ['docker.io']
EOF

sudo mkdir -p /etc/containerd
cp /etc/containerd/config.toml /etc/containerd/config.toml.saved && echo /etc/containerd/config.toml saved to /etc/containerd/config.toml.saved || echo /etc/containerd/config.toml not existing creating it
cat > /etc/containerd/config.toml <<EOF
disabled_plugins = []
imports = []
oom_score = 0
plugin_dir = ""
required_plugins = []
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[plugins]

  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
      base_runtime_spec = ""
      container_annotations = []
      pod_annotations = []
      privileged_without_host_devices = false
      runtime_engine = ""
      runtime_root = ""
      runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
        BinaryName = ""
        CriuImagePath = ""
        CriuPath = ""
        CriuWorkPath = ""
        IoGid = 0
        IoUid = 0
        NoNewKeyring = false
        NoPivotRoot = false
        Root = ""
        ShimCgroup = ""
        SystemdCgroup = true
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry-1.docker.io".auth]
    username = '$DockerUser'
    password = '$DockerPassword'
EOF

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

systemctl enable containerd
systemctl start containerd


# kube
apt-get install -qq -y gnupg gnupg2 curl software-properties-common
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/cgoogle.gpg
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update
apt-get install -qq -y kubelet=$kubestuffversion kubeadm=$kubestuffversion kubectl=$kubestuffversion kubernetes-cni=$kubecniversion

cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS="--container-runtime remote --container-runtime-endpoint unix:///run/containerd/containerd.sock"
EOF
systemctl daemon-reload
systemctl enable kubelet

echo "export TERM=xterm" >> /home/vagrant/.bashrc

line=`cat /vagrant/id_rsa.pub`
grep -q "$line" /home/vagrant/.ssh/authorized_keys || echo "$line" >> /home/vagrant/.ssh/authorized_keys
cp /vagrant/id_rsa /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa /home/vagrant/.ssh/authorized_keys
chown vagrant.vagrant /home/vagrant/.ssh/id_rsa /home/vagrant/.ssh/authorized_keys /home/vagrant/.bashrc

