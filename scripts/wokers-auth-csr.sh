#!/bin/bash

# ClusterRoleBinding to allow kubelets to create CSR through the system:node-bootstrapper ClusterRole
# https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#authorize-kubelet-to-create-csr
cat > csrs-for-bootstrapping.yaml <<EOF
# enable bootstrapping nodes to create CSR
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: create-csrs-for-bootstrapping
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:node-bootstrapper
  apiGroup: rbac.authorization.k8s.io
EOF

# n order to approve CSRs, you need to tell the controller-manager that it is acceptable to approve them. 
# This is done by granting RBAC permissions to the correct group.
# https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#approval
cat > auto-approve-csrs-for-group.yaml <<EOF
# Approve all CSRs for the group "system:bootstrappers"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-csrs-for-group
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
  apiGroup: rbac.authorization.k8s.io
EOF

# We now create the Cluster Role Binding required for the nodes to automatically renew the certificates on expiry. 
# Note that we are NOT using the system:bootstrappers group here any more. Since by the renewal period, 
# we believe the node would be bootstrapped and part of the cluster already. All nodes are part of the system:nodes group.
# https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#approval
cat > auto-approve-renewals-for-nodes.yaml <<EOF
# Approve renewal CSRs for the group "system:nodes"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: auto-approve-renewals-for-nodes
subjects:
- kind: Group
  name: system:nodes
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl create -f csrs-for-bootstrapping.yaml --kubeconfig admin.kubeconfig
kubectl create -f auto-approve-csrs-for-group.yaml --kubeconfig admin.kubeconfig
kubectl create -f auto-approve-renewals-for-nodes.yaml --kubeconfig admin.kubeconfig