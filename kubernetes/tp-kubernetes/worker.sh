#!/bin/bash
test -f /root/kubeinstallworkerdone && echo "already installed"
test -f /root/kubeinstallworkerdone && exit 0

su - vagrant -c "scp -o StrictHostKeyChecking=no master.lab.local:/home/vagrant/joinkubecluster.sh /home/vagrant/joinkubecluster.sh"

bash /home/vagrant/joinkubecluster.sh

# Nfs mount
mkdir /opt/data
apt-get install -qq -y nfs-common

cat >>/etc/fstab <<EOF
192.168.33.100:/opt/data /opt/data nfs defaults 0 2
EOF
mount /opt/data

touch /root/kubeinstallworkerdone

#ufw allow 10250/tcp
#ufw allow 30000:32767/tcp
#ufw reload
