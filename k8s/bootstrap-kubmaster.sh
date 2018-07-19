#!/bin/bash

HOME_VAGRANT="/home/vagrant"

# init of master - in the output file you will find the "kubeadm join" to use
kubeadm init --apiserver-advertise-address=192.168.43.10 --pod-network-cidr=10.244.0.0/16  > $HOME/k8sinit.log
#kubeadm init --apiserver-advertise-address=192.168.43.10 --pod-network-cidr=10.244.0.0/16  --kubernetes-version=v1.11.0 > $HOME/k8sinit.log

su - vagrant -c "mkdir -p $HOME_VAGRANT/.kube"
su - vagrant -c "sudo cp -i /etc/kubernetes/admin.conf $HOME_VAGRANT/.kube/config"
su - vagrant -c "sudo chown $(id -u vagrant):$(id -g vagrant) $HOME_VAGRANT/.kube/config"

su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"


##
echo "EXECUTE THIS TO OTHER NODES"
echo $(grep join $HOME/k8sinit.log)
