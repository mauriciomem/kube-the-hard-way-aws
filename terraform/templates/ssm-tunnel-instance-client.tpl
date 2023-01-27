#!/bin/bash
set -ex

apt-get update && apt-get install tmux less curl unzip -y

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli

# Set hostnames
%{ for host, ip in zipmap(client_hosts, client_ips) ~}
if [ "${ip}" == "$(ip addr show | grep -o ${ip})" ] ; then hostnamectl set-hostname ${host}; fi
%{ endfor ~}

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
%{ for host, ip in zipmap(cluster_hosts, cluster_ips) ~}
${ip}     ${host}
%{ endfor ~}
EOF

# setup ssh keys
ssh-keygen -q -t rsa -N '' <<< $'\ny' >/dev/null 2>&1
cp -p ~/.ssh/id_rsa* /home/ubuntu/.ssh/
chown ubuntu.ubuntu /home/ubuntu/.ssh/id_rsa*
export PUBLIC_KEY=$(cat /home/ubuntu/.ssh/id_rsa.pub)
aws ssm send-command --region ${aws_region} --targets "Key=tag:ec2-type,Values=server" --document-name "AWS-RunShellScript" --parameters commands=["echo $PUBLIC_KEY >> /home/ubuntu/.ssh/authorized_keys"]

# install and setup client tools
wget https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# reboot instance
reboot

