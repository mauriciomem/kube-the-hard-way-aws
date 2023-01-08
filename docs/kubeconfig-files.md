## Example kube-proxy
## kube-proxy binary and service configuration https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://${LOADBALANCER}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

cat kube-proxy.kubeconfig 
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://10.0.101.10:6443
  name: kubernetes-the-hard-way
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null

######

kubectl config set-credentials system:kube-proxy \
  --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
  --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
  --kubeconfig=kube-proxy.kubeconfig

cat kube-proxy.kubeconfig 
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://10.0.101.10:6443
  name: kubernetes-the-hard-way
contexts: null
current-context: ""
kind: Config
preferences: {}
users:
- name: system:kube-proxy
  user:
    client-certificate: /var/lib/kubernetes/pki/kube-proxy.crt
    client-key: /var/lib/kubernetes/pki/kube-proxy.key

kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://10.0.101.10:6443
  name: kubernetes-the-hard-way
contexts:
- context:
    cluster: kubernetes-the-hard-way
    user: system:kube-proxy
  name: default
current-context: ""
kind: Config
preferences: {}
users:
- name: system:kube-proxy
  user:
    client-certificate: /var/lib/kubernetes/pki/kube-proxy.crt
    client-key: /var/lib/kubernetes/pki/kube-proxy.key

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://10.0.101.10:6443
  name: kubernetes-the-hard-way
contexts:
- context:
    cluster: kubernetes-the-hard-way
    user: system:kube-proxy
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: system:kube-proxy
  user:
    client-certificate: /var/lib/kubernetes/pki/kube-proxy.crt
    client-key: /var/lib/kubernetes/pki/kube-proxy.key

## Example kube-controller-manager

# server localhost
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://127.0.0.1:6443
  name: kubernetes-the-hard-way
contexts: null
current-context: ""
kind: Config
preferences: {}
users: null

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=/var/lib/kubernetes/pki/kube-controller-manager.crt \
  --client-key=/var/lib/kubernetes/pki/kube-controller-manager.key \
  --kubeconfig=kube-controller-manager.kubeconfig

apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://127.0.0.1:6443
  name: kubernetes-the-hard-way
contexts: null
current-context: ""
kind: Config
preferences: {}
users:
- name: system:kube-controller-manager
  user:
    client-certificate: /var/lib/kubernetes/pki/kube-controller-manager.crt
    client-key: /var/lib/kubernetes/pki/kube-controller-manager.key


kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://127.0.0.1:6443
  name: kubernetes-the-hard-way
contexts:
- context:
    cluster: kubernetes-the-hard-way
    user: system:kube-controller-manager
  name: default
current-context: ""
kind: Config
preferences: {}
users:
- name: system:kube-controller-manager
  user:
    client-certificate: /var/lib/kubernetes/pki/kube-controller-manager.crt
    client-key: /var/lib/kubernetes/pki/kube-controller-manager.key

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

cat kube-controller-manager.kubeconfig 
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://127.0.0.1:6443
  name: kubernetes-the-hard-way
contexts:
- context:
    cluster: kubernetes-the-hard-way
    user: system:kube-controller-manager
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: system:kube-controller-manager
  user:
    client-certificate: /var/lib/kubernetes/pki/kube-controller-manager.crt
    client-key: /var/lib/kubernetes/pki/kube-controller-manager.key