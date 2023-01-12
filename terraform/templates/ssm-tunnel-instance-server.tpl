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
if [ "${k8s-master-1-ip}" == "$(ip addr show | grep -o ${k8s-master-1-ip})" ] ; then hostnamectl set-hostname k8s-master-1; fi
if [ "${k8s-master-2-ip}" == "$(ip addr show | grep -o ${k8s-master-2-ip})" ] ; then hostnamectl set-hostname k8s-master-2; fi
if [ "${k8s-worker-1-ip}" == "$(ip addr show | grep -o ${k8s-worker-1-ip})" ] ; then hostnamectl set-hostname k8s-worker-1; fi
if [ "${k8s-master-2-ip}" == "$(ip addr show | grep -o ${k8s-master-2-ip})" ] ; then hostnamectl set-hostname k8s-worker-2; fi
if [ "${k8s-ha-lb-ip}" == "$(ip addr show | grep -o ${k8s-ha-lb-ip})" ] ; then hostnamectl set-hostname k8s-ha-lb; fi

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
${k8s-master-1-ip}  k8s-master-1
${k8s-master-2-ip}  k8s-master-2
${k8s-worker-1-ip}  k8s-worker-1
${k8s-master-2-ip}  k8s-worker-2
${k8s-ha-lb-ip}     k8s-ha-lb
${k8s-ha-lb-ip}     kubernetes
EOF

# install client tools

apt install awscli -y

wget https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# reboot instance
reboot

