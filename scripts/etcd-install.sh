#!/bin/bash -x

# download, install and configures etcd in control-plane nodes

INTERNAL_IP=$(ip addr show ens5 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
MASTER_1=$(dig +short k8s-master-1)
MASTER_2=$(dig +short k8s-master-2)
ETCD_NAME=$(hostname -s)

wget -q --show-progress --https-only --timestamping "https://github.com/coreos/etcd/releases/download/v3.5.3/etcd-v3.5.3-linux-amd64.tar.gz"

tar -xvf etcd-v3.5.3-linux-amd64.tar.gz
sudo mv etcd-v3.5.3-linux-amd64/etcd* /usr/local/bin/

sudo mkdir -p /etc/etcd /var/lib/etcd /var/lib/kubernetes/pki
sudo cp etcd-server.key etcd-server.crt /etc/etcd/
sudo cp ca.crt /var/lib/kubernetes/pki/
sudo chown root:root /etc/etcd/*
sudo chmod 600 /etc/etcd/*
sudo chown root:root /var/lib/kubernetes/pki/*
sudo chmod 600 /var/lib/kubernetes/pki/*
sudo ln -s /var/lib/kubernetes/pki/ca.crt /etc/etcd/ca.crt

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster k8s-master-1=https://${MASTER_1}:2380,k8s-master-2=https://${MASTER_2}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd