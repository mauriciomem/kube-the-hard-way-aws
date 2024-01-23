#!/bin/bash
set -ex

# Setup package manager
apt-get update
apt-get install -y apt-transport-https ca-certificates curl less unzip gpg

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

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

# Set reverse proxy configuration
if [ "k8s-ha-lb" == "$(hostname)" ]; then 
  apt-get install -y haproxy
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind k8s-ha-lb:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-1 k8s-master-1:6443 check fall 3 rise 2
    server k8s-master-2 k8s-master-2:6443 check fall 3 rise 2
EOF

  systemctl restart haproxy
fi

# container runtime config

# versions supported for kubernetes v1.24+
CONTAINERD_VERSION=1.6.5
CNI_VERSION=1.0.0
RUNC_VERSION=1.1.1

# download containerd, cni plugins, runc
wget -q --show-progress --https-only --timestamping \
  https://github.com/containerd/containerd/releases/download/v1.6.5/containerd-1.6.5-linux-amd64.tar.gz \
  https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-amd64-v1.0.0.tgz \
  https://github.com/opencontainers/runc/releases/download/v1.1.1/runc.amd64

# place downloaded binaries in its corresponding folders
mkdir -p /opt/cni/bin
mkdir -p /etc/cni/net.d
chmod +x runc.amd64
mv runc.amd64 /usr/local/bin/runc
tar -xzvf containerd-1.6.5-linux-amd64.tar.gz -C /usr/local
tar -xzvf cni-plugins-linux-amd64-v1.0.0.tgz -C /opt/cni/bin

# create containerd systemd service running configuration
cat <<EOF | tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl enable containerd
systemctl start containerd

# setup kubernetes binaries

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# setup ssh keys
ssh-keygen -q -t rsa -N '' <<< $'\ny' >/dev/null 2>&1
cp -p ~/.ssh/id_rsa* /home/ubuntu/.ssh/
chown ubuntu.ubuntu /home/ubuntu/.ssh/id_rsa*
export PUBLIC_KEY=$(cat /home/ubuntu/.ssh/id_rsa.pub)
aws ssm send-command --region ${aws_region} --targets "Key=tag:ec2-type,Values=server" --document-name "AWS-RunShellScript" --parameters commands=["echo $PUBLIC_KEY >> /home/ubuntu/.ssh/authorized_keys"]

# reboot instance
reboot

