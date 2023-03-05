# Generating Kubernetes Configuration Files for Authentication

In this lab you will generate [Kubernetes configuration files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/), also known as "kubeconfigs", which enable Kubernetes clients to locate and authenticate to the Kubernetes API Servers.

Note: It is good practice to use file paths to certificates in kubeconfigs that will be used by the services. When certificates are updated, it is not necessary to regenerate the config files, as you would have to if the certificate data was embedded. Note also that the cert files don't exist in these paths yet - we will place them in later labs.

User configs, like admin.kubeconfig will have the certificate info embedded within them.

A kubeconfig file consists in three main sections that allows a user or a service to authenticate to a Kubernetes API enpoint of a cluster. It allows the organization and management of information about clusters, users, namespaces and authentication mechanisms.

 - The *user* section: Specifies the user or service name and the required credentials parameters to authenticate to a cluster endpoint. The authentication mechanism can vary according to the requirements of the cluster. 
 - The *cluster* section: Sets information about the cluster such as the name, authentication information (CA Certificate) and the API cluster endpoint.
 - The *context* section: Connect the user section with the cluster section and it can include namespace information.

## Kubeconfig facts

- By default the `kubectl` binary will look for a kubeconfig file inside the `$HOME/.kube` directory.
- Custom kubeconfig file can be set via declaring the `KUBECONFIG` env variable or invoking the `--kubeconfig` parameter via `kubectl`.
- A kubeconfig file can include multiple contexts to allow users switching accross clusters and namespaces.
- TLS certificates are the most extended alternative for authentication in clusters. But it can be used tokens, thrid party solutions and other means of authentication.

## kubectl commands

  - Insert user and authentication mechanisms inside a kubeconfig file:

 `kubectl config set-credentials [name] [parameters] --kubeconfig=[name.kubeconfig]`

  Most common parameters are `--client-certificate` and `--client-key` to authenticate the user or service via TLS certificates.

 - Insert cluster data and authentication information:

`kubectl config set-cluster [name] [parameters] --kubeconfig=[name.kubeconfig]`

 - Insert context data by connecting user and cluster information:

`kubectl config set-context [name] --cluster=[cluster name] --user=[user name] --kubeconfig=[name.kubeconfig]`

 - Set context as current and active context

`kubectl config use-context [name] --kubeconfig=[name.kubeconfig]`

 - Review current context or configuration stored in a kubeconfig file.

`kubectl config view`

## Client Authentication Configs

In this section you will generate kubeconfig files for the `controller manager`, `kube-proxy`, `scheduler` clients and the `admin` user.

### Kubernetes Public IP Address

Each kubeconfig requires a Kubernetes API Server to connect to. To support high availability the IP address assigned to the load balancer will be used, so let's first get the address of the loadbalancer into a shell variable such that we can use it in the kubeconfigs for services that run on worker nodes. The controller manager and scheduler need to talk to the local API server, hence they use the localhost address.

```bash
LOADBALANCER=$(dig +short k8s-ha-lb)
```

### The kube-proxy Kubernetes Configuration File

Generate a kubeconfig file for the `kube-proxy` service:

```bash
{
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
}
```

Results:

```
kube-proxy.kubeconfig
```

Reference docs for kube-proxy [here](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/)

### The kube-controller-manager Kubernetes Configuration File

Generate a kubeconfig file for the `kube-controller-manager` service:

```bash
{
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
}
```

Results:

```
kube-controller-manager.kubeconfig
```

Reference docs for kube-controller-manager [here](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)

### The kube-scheduler Kubernetes Configuration File

Generate a kubeconfig file for the `kube-scheduler` service:

```bash
{
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
}
```

Results:

```
kube-scheduler.kubeconfig
```

Reference docs for kube-scheduler [here](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/)

### The admin Kubernetes Configuration File

Generate a kubeconfig file for the `admin` user:

```bash
{
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
}
```

Results:

```
admin.kubeconfig
```

Reference docs for kubeconfig [here](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)

##

## Distribute the Kubernetes Configuration Files

Copy the appropriate `kube-proxy` kubeconfig files to each worker instance:

```bash
for instance in worker-1 worker-2; do
  scp kube-proxy.kubeconfig ${instance}:~/
done
```

Copy the appropriate `admin.kubeconfig`, `kube-controller-manager` and `kube-scheduler` kubeconfig files to each controller instance:

```bash
for instance in k8s-master-1 k8s-master-2; do
  scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
```

## Optional - Check kubeconfigs

At `k8s-master-1` and `k8s-master-2` nodes, run the following, selecting option 2

```bash
./cert_verify.sh
```

## Example kubeconfig workflow with the kube-proxy service cluster access

 - Set cluster configuration

```bash
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
  --server=https://${LOADBALANCER}:6443 \
  --kubeconfig=kube-proxy.kubeconfig
```
 - Output in kubeconfig file

```yaml
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
```

 - Set user credentials

```bash
kubectl config set-credentials system:kube-proxy \
  --client-certificate=/var/lib/kubernetes/pki/kube-proxy.crt \
  --client-key=/var/lib/kubernetes/pki/kube-proxy.key \
  --kubeconfig=kube-proxy.kubeconfig
```

 - Output in kubeconfig file

```yaml
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
```

 - Set context information

```bash
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
```

 - Output in kubeconfig file

```yaml
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
```

 - Use context crated previously by setting it as current context.

```bash
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

 - Output in kubeconfig file

```yaml
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
```


Prev: [Certificate Authority](04-ca-certificates-cluster.md)<br>
Next: [Generating the Data Encryption Config and Key](06-data-rest-encryption-keys.md)