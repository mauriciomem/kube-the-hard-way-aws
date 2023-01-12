#!/bin/bash -x

### Provision a Network Load Balancer

sudo apt-get update && sudo apt-get install -y haproxy

MASTER_1=$(dig +short k8s-master-1)
MASTER_2=$(dig +short k8s-master-2)
LOADBALANCER=$(dig +short k8s-ha-lb)

## Create HAProxy configuration to listen on API server port on this host and distribute requests evently to the two master nodes.

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind ${LOADBALANCER}:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-1 ${MASTER_1}:6443 check fall 3 rise 2
    server k8s-master-2 ${MASTER_2}:6443 check fall 3 rise 2
EOF

sudo systemctl restart haproxy


### Verification

curl  https://${LOADBALANCER}:6443/version -k