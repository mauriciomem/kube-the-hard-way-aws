#!/bin/bash -x

for instance in k8s-worker-1 k8s-worker-2; do
  scp kube-proxy.kubeconfig ${instance}:~/
done

for instance in k8s-master-1 k8s-master-2; do
  scp kube-proxy.kubeconfig admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done