#!/bin/bash -x

LOADBALANCER=$(dig +short k8s-ha-lb)

## Kubernetes configuration files

## General process

# kubectl config - how to authenticate and access an API server endpoint
# Three parts:
## kubectl config set-cluster: create a kubeconfig yaml manifest (kind: Config) with the CA certificate info and the server API endpoint
## kubectl config set-credentials: update the kubeconfig yaml manifest with user information inside the users: yaml clause
## kubectl config set-context: update the kubecofnig yaml manifest with context information that connects cluster and user information
## kubectl config use-context: update the kubeconfig yaml manifest to set the previous created context as the context that will be used

# kube-proxy kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
--certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://${LOADBALANCER}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
  --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

# kube-controller-manager kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=/var/lib/kubernetes/pki/kube-controller-manager.crt \
  --client-key=/var/lib/kubernetes/pki/kube-controller-manager.key \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

# kube-scheduler kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=/var/lib/kubernetes/pki/kube-scheduler.crt \
  --client-key=/var/lib/kubernetes/pki/kube-scheduler.key \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

# administrator kubeconfig

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.crt \
  --client-key=admin.key \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

# distribution of kubeconfig files through the cluster nodes

for instance in k8s-worker-1 k8s-worker-2; do
  scp kube-proxy.kubeconfig ${instance}:~/
done

for instance in k8s-master-1 k8s-master-2; do
  scp kube-proxy.kubeconfig admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done