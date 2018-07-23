#!/bin/bash
# dirty 'n quick way to grab the IP of eth1, to avoid k8s standard behaviour of using eth0 as default ip for nodes
IP_NODE=$(ip a | grep eth1 | grep inet | awk '{ print $2 }' | cut -d "/" -f 1)

yum update -y
# disabling SELinux (for testing purposes)
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# configuring repos for Docker and K8s
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Disable swap
swapoff -a
cp /etc/fstab /etc/fstab.old
grep -v swap /etc/fstab.old > /etc/fstab


# Install docker & k8s
yum install -y docker-ce kubelet kubeadm kubectl
systemctl enable docker
systemctl enable kubelet

# Change the cgroup-driver of k8s to "cgroupfs", the same as docker
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# extra args to force kubectl to use the api on the right port
sed -i "s|KUBELET_EXTRA_ARGS=|KUBELET_EXTRA_ARGS=--node-ip=$IP_NODE|g" /etc/sysconfig/kubelet

systemctl daemon-reload
systemctl start docker

# Enabling br_netfilter Kernel module (required by k8s to let pods across the cluster to communicate)
modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables 
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
sysctl -p

systemctl start kubelet
