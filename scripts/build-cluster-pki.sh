#!/bin/bash

MASTER_1=$(dig +short k8s-master-1)
MASTER_2=$(dig +short k8s-master-2)
LOADBALANCER=$(dig +short k8s-ha-lb)
SERVICE_CIDR=10.96.0.0/24
API_SERVICE=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')
CERT_FILES=$HOME/openssl-cluster-files

echo $MASTER_1
echo $MASTER_2
echo $LOADBALANCER
echo $SERVICE_CIDR
echo $API_SERVICE
mkdir $CERT_FILES
cd $CERT_FILES

## Create CA certificate by:
# 1. create a private key, the CA private key
# 2. create the CSR and sign it with the CA private key created earlier. 
# It's important to add information about its use and what is meant for. The information added will be added to the future public key to form the CA certificate.
# 3. create the CA certificate with the CSR and the private key.
#  Why CAcreateserial parameter? https://stackoverflow.com/questions/66357451/why-does-signing-a-certificate-require-cacreateserial-argument
echo -e "Create CA Certificate\n"
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA/O=Kubernetes" -out ca.csr
openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial  -out ca.crt -days 730

## Create the Admin client certificate
# IMPORTANT: the common name (CN) will be used by the kubernetes API server to authenticate the user name
# IMPORTANT: the admin user can be recognized as an administrator by including the Organization (O) attribute value system:masters
echo -e "Create the Admin client certificate\n"
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr
openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out admin.crt -days 730

## Controller Manager client Certificate

echo -e "Controller Manager certificate\n"
openssl genrsa -out kube-controller-manager.key 2048
openssl req -new -key kube-controller-manager.key \
    -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager" -out kube-controller-manager.csr
openssl x509 -req -in kube-controller-manager.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 730

## kube-proxy client Certificate

echo -e "kube-proxy client Certificate\n"
openssl genrsa -out kube-proxy.key 2048
openssl req -new -key kube-proxy.key \
    -subj "/CN=system:kube-proxy/O=system:node-proxier" -out kube-proxy.csr
openssl x509 -req -in kube-proxy.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-proxy.crt -days 730

## kube-scheduler client Certificate

echo -e "kube-scheduler client Certificate\n"
openssl genrsa -out kube-scheduler.key 2048
openssl req -new -key kube-scheduler.key \
    -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" -out kube-scheduler.csr
openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-scheduler.crt -days 730

###### Server Certificates

## Kube API server server Certificate

echo -e "Kube API server server Certificate\n"
cat > openssl-api-server.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = ${API_SERVICE}
IP.2 = ${MASTER_1}
IP.3 = ${MASTER_2}
IP.4 = ${LOADBALANCER}
IP.5 = 127.0.0.1
EOF

openssl genrsa -out kube-apiserver.key 2048
openssl req -new -key kube-apiserver.key \
    -subj "/CN=kube-apiserver/O=Kubernetes" -out kube-apiserver.csr -config openssl-api-server.cnf
openssl x509 -req -in kube-apiserver.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-apiserver.crt \
    -extensions v3_req -extfile openssl-api-server.cnf -days 730


## kubelet client certificate
# Certificate for the API server to authenticate with the kubelets
echo -e "kubelet client certificate for kube-apiserver\n"
cat > openssl-kubelet.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = critical, CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl genrsa -out apiserver-kubelet-client.key 2048
openssl req -new -key apiserver-kubelet-client.key \
    -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" \
    -out apiserver-kubelet-client.csr -config openssl-kubelet.cnf
openssl x509 -req -in apiserver-kubelet-client.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out apiserver-kubelet-client.crt \
    -extensions v3_req -extfile openssl-kubelet.cnf -days 730

## ETCD server certificate

echo -e "ETCD server certificate\n"
cat > openssl-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = ${MASTER_1}
IP.2 = ${MASTER_2}
IP.3 = 127.0.0.1
EOF

openssl genrsa -out etcd-server.key 2048
openssl req -new -key etcd-server.key \
    -subj "/CN=etcd-server/O=Kubernetes" -out etcd-server.csr -config openssl-etcd.cnf
openssl x509 -req -in etcd-server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out etcd-server.crt -extensions v3_req -extfile openssl-etcd.cnf -days 730

## Service Account Key Pair
# The Kubernetes Controller Manager leverages a key pair to generate and sign service account tokens 
# https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/

echo -e "Service Account Key Pair\n"
openssl genrsa -out service-account.key 2048
openssl req -new -key service-account.key \
    -subj "/CN=service-accounts/O=Kubernetes" -out service-account.csr
openssl x509 -req -in service-account.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out service-account.crt -days 730

## Distribute the certificates

echo -e "Distribute the certificates\n"
for instance in k8s-master-1 k8s-master-2; do
  scp ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
    apiserver-kubelet-client.crt apiserver-kubelet-client.key \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    kube-controller-manager.key kube-controller-manager.crt \
    kube-scheduler.key kube-scheduler.crt \
    kube-proxy.crt kube-proxy.key \
    ${instance}:~/
done

for instance in k8s-worker-1 k8s-worker-2 ; do
  scp ca.crt kube-proxy.crt kube-proxy.key ${instance}:~/
done