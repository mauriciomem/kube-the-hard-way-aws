#!/bin/bash
set -ex

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
%{ for host, ip in zipmap(cluster_hosts, cluster_ips) ~}
if [ "${ip}" == "$(ip addr show | grep -o ${ip})" ] ; then hostnamectl set-hostname ${host}; fi
%{ endfor ~}

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
%{ for host, ip in zipmap(cluster_hosts, cluster_ips) ~}
${ip}     ${host}
%{ endfor ~}
EOF

# install and setup client tools
wget https://storage.googleapis.com/kubernetes-release/release/v1.28.5/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# reboot instance
reboot

