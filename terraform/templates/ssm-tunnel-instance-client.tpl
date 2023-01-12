#!/bin/bash -x 
set -ex

apt update

# Set hostnames
if [ "${k8s-client-ip}" == "$(ip addr show | grep -o ${k8s-client-ip})" ] ; then hostnamectl set-hostname k8s-client; fi

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

apt install tmux awscli -y

ssh-keygen -q -t rsa -N '' <<< $'\ny' >/dev/null 2>&1

cp -p ~/.ssh/id_rsa* /home/ubuntu/.ssh/
chown ubuntu.ubuntu /home/ubuntu/.ssh/id_rsa*

export PUBLIC_KEY=$(cat /home/ubuntu/.ssh/id_rsa.pub)

aws ssm send-command --region us-east-1 --targets "Key=tag:ec2-type,Values=server" --document-name "AWS-RunShellScript" --parameters commands=["echo $PUBLIC_KEY >> /home/ubuntu/.ssh/authorized_keys"]

wget https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# reboot instance
reboot

