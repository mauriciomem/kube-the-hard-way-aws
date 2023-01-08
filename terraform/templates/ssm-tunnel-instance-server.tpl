#!/bin/bash -x 
set -ex

apt update

# Disable cgroups v2 (kernel command line parameter)
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=0 ipv6.disable=1 /' /etc/default/grub
update-grub

# Add br_netfilter kernel module
echo "br_netfilter" >> /etc/modules

# Set network tunables
cat <<EOF >> /etc/sysctl.d/10-kubernetes.conf
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF

# Set hostnames
if [ 10.0.1.10 == $(ip addr show | grep -o 10.0.1.10) ] ; then hostnamectl set-hostname k8s-master-1; fi
if [ 10.0.1.11 == $(ip addr show | grep -o 10.0.1.11) ] ; then hostnamectl set-hostname k8s-master-2; fi
if [ 10.0.2.12 == $(ip addr show | grep -o 10.0.2.12) ] ; then hostnamectl set-hostname k8s-worker-1; fi
if [ 10.0.2.13 == $(ip addr show | grep -o 10.0.2.13) ] ; then hostnamectl set-hostname k8s-worker-2; fi
if [ 10.0.101.10 == $(ip addr show | grep -o 10.0.101.10) ] ; then hostnamectl set-hostname k8s-ha-lb; fi

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
10.0.1.10       k8s-master-1
10.0.1.11       k8s-master-2
10.0.2.12       k8s-worker-1
10.0.2.13       k8s-worker-2
10.0.101.10   k8s-ha-lb
EOF

# install client tools

apt install awscli -y

wget https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# reboot instance
reboot

