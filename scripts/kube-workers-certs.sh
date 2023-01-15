#!/bin/bash -x

CERT_FILES=$HOME/openssl-cluster-files
mkdir $CERT_FILES
cd $CERT_FILES

if [ ! -f $HOME/openssl-cluster-files/ca.crt ] ; then 
  echo "not k8s self signed CA" 
  exit 1

## Setup worker certificates and kubeconfigs
WORKER_1=$(dig +short k8s-worker-1)
WORKER_1_NAME=$(dig -x $WORKER_1 +short | sed 's/\.$//')
WORKER_2=$(dig +short k8s-worker-2)
WORKER_1_NAME=$(dig -x $WORKER_2 +short | sed 's/\.$//')
LOADBALANCER=$(dig +short k8s-ha-lb)

### Provisioning Kubelet Client Certificates - k8s-worker-1
cat > openssl-k8s-worker-1.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${WORKER_1_NAME}
IP.1 = ${WORKER_1}
EOF

openssl genrsa -out k8s-worker-1.key 2048
openssl req -new -key k8s-worker-1.key -subj "/CN=system:node:${WORKER_1_NAME}/O=system:nodes" -out k8s-worker-1.csr -config openssl-k8s-worker-1.cnf
openssl x509 -req -in k8s-worker-1.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out k8s-worker-1.crt -extensions v3_req -extfile openssl-k8s-worker-1.cnf -days 1000

### Provisioning Kubelet Client Certificates - k8s-worker-2
cat > openssl-k8s-worker-2.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${WORKER_2_NAME}
IP.1 = ${WORKER_2}
EOF

openssl genrsa -out k8s-worker-2.key 2048
openssl req -new -key k8s-worker-2.key -subj "/CN=system:node:${WORKER_2_NAME}/O=system:nodes" -out k8s-worker-2.csr -config openssl-k8s-worker-2.cnf
openssl x509 -req -in k8s-worker-2.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out k8s-worker-2.crt -extensions v3_req -extfile openssl-k8s-worker-2.cnf -days 1000


### The kubelet Kubernetes Configuration File - k8s-worker-1
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://${LOADBALANCER}:6443 \
  --kubeconfig=k8s-worker-1.kubeconfig

kubectl config set-credentials system:node:${WORKER_1_NAME} \
  --client-certificate=/var/lib/kubernetes/pki/k8s-worker-1.crt \
  --client-key=/var/lib/kubernetes/pki/k8s-worker-1.key \
  --kubeconfig=k8s-worker-1.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:node:k8s-worker-1 \
  --kubeconfig=k8s-worker-1.kubeconfig

kubectl config use-context default --kubeconfig=k8s-worker-1.kubeconfig

scp ca.crt k8s-worker-1.crt k8s-worker-1.key k8s-worker-1.kubeconfig ${WORKER_1_NAME}:~/

### The kubelet Kubernetes Configuration File - k8s-worker-1
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://${LOADBALANCER}:6443 \
  --kubeconfig=k8s-worker-2.kubeconfig

kubectl config set-credentials system:node:${WORKER_2_NAME} \
  --client-certificate=/var/lib/kubernetes/pki/k8s-worker-2.crt \
  --client-key=/var/lib/kubernetes/pki/k8s-worker-2.key \
  --kubeconfig=k8s-worker-2.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:node:k8s-worker-2 \
  --kubeconfig=k8s-worker-2.kubeconfig

kubectl config use-context default --kubeconfig=k8s-worker-2.kubeconfig

scp ca.crt k8s-worker-2.crt k8s-worker-2.key k8s-worker-2.kubeconfig ${WORKER_2_NAME}:~/