# Provisioning a CA and Generating TLS Certificates

In this lab you will provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) using the popular openssl tool, then use it to bootstrap a Certificate Authority, and generate TLS certificates for the following components: etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, and kube-proxy.

## Cluster PKI layout summary

**Client certificates**
 - `kube-controller-manager`: Communicates with the `kube-apiserver`. Because of this needs to validate its identity as a client to the `kube-apiserver` service via a TLS certificate.
 - `kube-scheduler`: Communicates with the `kube-apiserver` to schedule pods in the cluster nodes.
 - `kube-proxy`: Communicates with the `kube-apiserver` to manage Kubernetes Services.
 - `administrator`: Authenticates against the `kube-apiserver` via kubectl and/or a rest API client by using certificates.
 - `kubelet`: Access the `kube-apiserver` to retrieve information.
 - `kube-apiserver`: Access to the `kubelet` is required for retrieving metrics, logs, and executing commands in pods from the `kube-apiserver`.

**Server certificates**
 - kube-apiserver: Presents authentication information to `kube-controller-manager`, `kube-scheduler`, `kubelet`, `kube-proxy`, `administrator` and any other user or `ServiceAccount`.
 - `etcd-server`: Only cluster service that doesn't have client certificate. Only client: `kube-apiserver`.
 - `kubelet`: Access to the `kubelet` is required for retrieving metrics, logs, and executing commands in pods from the `kube-apiserver`.

 ## General process

### CA self signed Certificate

It is self signed because the same private key of the key pair is used to generate the CA certificate.

1. Create a private key of a service.
```
openssl genrsa -o ca.key 2048
```
2. Create a [Certificate Signing Request (CSR)](https://en.wikipedia.org/wiki/Certificate_signing_request) by signing it with the private key. The CSR can include attributes that will be embeded into the Certiticate to identify the applicant (such as a Common Name, Organization Name, Organizational Unit, etc.). In Kubernetes its a requirement to add certain attributes to authenticate a service component.
```
openssl req -new -key ca.key -subj “/CN=KUBERNETES-CA”
```
3. Sign the certificate with the key and the CSR
```
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt
```

### Remaining cluster services Certificates

The Certificate generation process is the same, with sligth differences

1. Create the private key of the service
2. Create the CSR with the required attributes for the service.
3. Generate the service Certificate by specifying the CA certificate and CA key to confirm the authenticity of the Certificate.

The CA Certificate will be used to sign all certificates.

# Where to do these?

You can do these on any machine with `openssl` on it. But you should be able to copy the generated files to the provisioned VMs. Or just do these from one of the master nodes.

In our case we do the following steps on the `k8s-master-1` node, as we have set it up to be the administrative client.

## Certificate Authority

In this section you will provision a Certificate Authority that can be used to generate additional TLS certificates.

Query IPs of hosts we will insert as certificate subject alternative names (SANs), which will be read from `/etc/hosts`. Note that doing this allows us to change the VM network range more easily from the default for these labs which are `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`, and `10.0.101.0/24`

Set up environment variables. Run the following:

```bash
MASTER_1=$(dig +short k8s-master-1)
MASTER_2=$(dig +short k8s-master-2)
LOADBALANCER=$(dig +short k8s-ha-lb)
```

Compute cluster internal API server service address, which is always .1 in the service CIDR range. This is also required as a SAN in the API server certificate. Run the following:

```bash
SERVICE_CIDR=10.96.0.0/24
API_SERVICE=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.1", $1, $2, $3) }')
```

Check that the environment variables are set. Run the following:

```bash
echo $MASTER_1
echo $MASTER_2
echo $LOADBALANCER
echo $SERVICE_CIDR
echo $API_SERVICE
```

The output should look like this. If you changed any of the defaults mentioned in the [prerequisites](./01-prerequisites.md) page, then addresses may differ.

```
10.0.1.10
10.0.1.11
10.0.101.10
10.96.0.0/24
10.96.0.1
```

Create a CA certificate, then generate a Certificate Signing Request and use it to create a private key:


```bash
{
  # Create private key for CA
  openssl genrsa -out ca.key 2048

  # Comment line starting with RANDFILE in /etc/ssl/openssl.cnf definition to avoid permission issues
  sudo sed -i '0,/RANDFILE/{s/RANDFILE/\#&/}' /etc/ssl/openssl.cnf

  # Create CSR using the private key
  openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA/O=Kubernetes" -out ca.csr

  # Self sign the csr using its own private key
  openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial  -out ca.crt -days 1000
}
```
Results:

```
ca.crt
ca.key
```

Reference : https://kubernetes.io/docs/tasks/administer-cluster/certificates/#openssl

The `ca.crt` is the Kubernetes Certificate Authority certificate and `ca.key` is the Kubernetes Certificate Authority private key.
You will use the `ca.crt` file in many places, so it will be copied to many places.
The `ca.key` is used by the CA for signing certificates. And it should be securely stored. In this case our master node(s) is our CA server as well, so we will store it on master node(s). There is no need to copy this file elsewhere.

## Client and Server Certificates

In this section you will generate client and server certificates for each Kubernetes component and a client certificate for the Kubernetes `admin` user.

### The Admin Client Certificate

Generate the `admin` client certificate and private key:

```bash
{
  # Generate private key for admin user
  openssl genrsa -out admin.key 2048

  # Generate CSR for admin user. Note the OU.
  openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr

  # Sign certificate for admin user using CA servers private key
  openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out admin.crt -days 1000
}
```

Note that the admin user is part of the **system:masters** group ("O=system:masters") that is mapped into a ClusterRole and ClusterRoleBinding objects. This is how we are able to perform any administrative operations on Kubernetes cluster using kubectl utility.

References: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings

The CN ("CN=admin") attribute it the username that kubernetes uses to authenticate the user when the administrator uses the kubectl tool.

Results:

```
admin.key
admin.crt
```

The `admin.crt` and `admin.key` file gives you administrative access. We will configure these to be used with the kubectl tool to perform administrative functions on kubernetes.

### The Kubelet Client Certificates

We are going to skip certificate configuration for Worker Nodes for now. We will deal with them when we configure the workers.
For now let's just focus on the control plane components.

### The Controller Manager Client Certificate

Generate the `kube-controller-manager` client certificate and private key:

```bash
{
  openssl genrsa -out kube-controller-manager.key 2048

  openssl req -new -key kube-controller-manager.key \
    -subj "/CN=system:kube-controller-manager/O=system:kube-controller-manager" -out kube-controller-manager.csr

  openssl x509 -req -in kube-controller-manager.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000
}
```

The **system:kube-controller-manager** group ("O=system:controller-manager") that is mapped into a ClusterRole and ClusterRoleBinding objects allows access to the resources required by the controller manager component.

References: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#core-component-roles.

The Controller Manager runs various controllers build into the Kubernetes Control Plane by using separated service accounts.

Reference: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#controller-roles

Results:

```
kube-controller-manager.key
kube-controller-manager.crt
```


### The Kube Proxy Client Certificate

Generate the `kube-proxy` client certificate and private key:


```bash
{
  openssl genrsa -out kube-proxy.key 2048

  openssl req -new -key kube-proxy.key \
    -subj "/CN=system:kube-proxy/O=system:node-proxier" -out kube-proxy.csr

  openssl x509 -req -in kube-proxy.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-proxy.crt -days 1000
}
```
There is a core ClusterRole object named **system:node-proxier** and a ClusterRoleBinding with the name **system:kube-proxy** that will allow access to all resources required by the kube-proxy service component.

References: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#core-component-roles

Results:

```
kube-proxy.key
kube-proxy.crt
```

### The Scheduler Client Certificate

Generate the `kube-scheduler` client certificate and private key:

```bash
{
  openssl genrsa -out kube-scheduler.key 2048

  openssl req -new -key kube-scheduler.key \
    -subj "/CN=system:kube-scheduler/O=system:kube-scheduler" -out kube-scheduler.csr

  openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-scheduler.crt -days 1000
}
```
Same as the previous control plane components, the `kube-scheduler` Certificate will include attributes to authenticate the particular service and authorize its access scope.

References: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#core-component-roles

Results:

```
kube-scheduler.key
kube-scheduler.crt
```

### The Kubernetes API Server Certificate

The kube-apiserver certificate requires all names that various components may reach it to be part of the alternate names. These include the different DNS names, and IP addresses such as the master servers IP address, the load balancers IP address, the kube-api service IP address (`kubectl get svc`) etc.

The `openssl` command cannot take alternate names as command line parameter. So we must create a `conf` file for it:

```bash
cat > openssl.cnf <<EOF
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
```
To review an aleady created certificate used in a running cluster, execute: `openssl x509 -noout -text -in /etc/kubernetes/pki/[certificate].crt`

Generate certs for kube-apiserver

```bash
{
  openssl genrsa -out kube-apiserver.key 2048

  openssl req -new -key kube-apiserver.key \
    -subj "/CN=kube-apiserver/O=Kubernetes" -out kube-apiserver.csr -config openssl.cnf

  openssl x509 -req -in kube-apiserver.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial  -out kube-apiserver.crt -extensions v3_req -extfile openssl.cnf -days 1000
}
```

Results:

```
kube-apiserver.crt
kube-apiserver.key
```

# The Kubelet Client Certificate

This certificate is for the api server to authenticate with the kubelets when it requests information from them

```bash
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
```

Generate certs for kubelet authentication

```bash
{
  openssl genrsa -out apiserver-kubelet-client.key 2048

  openssl req -new -key apiserver-kubelet-client.key \
    -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" -out apiserver-kubelet-client.csr -config openssl-kubelet.cnf

  openssl x509 -req -in apiserver-kubelet-client.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial  -out apiserver-kubelet-client.crt -extensions v3_req -extfile openssl-kubelet.cnf -days 1000
}
```

Results:

```
apiserver-kubelet-client.crt
apiserver-kubelet-client.key
```


### The ETCD Server Certificate

Similarly ETCD server certificate must have addresses of all the servers part of the ETCD cluster

The `openssl` command cannot take alternate names as command line parameter. So we must create a `conf` file for it:

```bash
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
```

Generates certs for ETCD

```bash
{
  openssl genrsa -out etcd-server.key 2048

  openssl req -new -key etcd-server.key \
    -subj "/CN=etcd-server/O=Kubernetes" -out etcd-server.csr -config openssl-etcd.cnf

  openssl x509 -req -in etcd-server.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out etcd-server.crt -extensions v3_req -extfile openssl-etcd.cnf -days 1000
}
```

Results:

```
etcd-server.key
etcd-server.crt
```

## The Service Account Key Pair

The Kubernetes Controller Manager leverages a key pair to generate and sign service account tokens as describe in the [managing service accounts](https://kubernetes.io/docs/admin/service-accounts-admin/) documentation.

Generate the `service-account` certificate and private key:

```bash
{
  openssl genrsa -out service-account.key 2048

  openssl req -new -key service-account.key \
    -subj "/CN=service-accounts/O=Kubernetes" -out service-account.csr

  openssl x509 -req -in service-account.csr \
    -CA ca.crt -CAkey ca.key -CAcreateserial  -out service-account.crt -days 1000
}
```

Results:

```
service-account.key
service-account.crt
```

## Verify the PKI

Run the following, and select option 1 to check all required certificates were generated.

```bash
./cert_verify.sh
```

> Expected output

```
PKI generated correctly!
```

If there are any errors, please review above steps and then re-verify

## Distribute the Certificates

Copy the appropriate certificates and private keys to each instance:

```bash
{
for instance in k8s-master-1 k8s-master-2; do
  scp ca.crt ca.key kube-apiserver.key kube-apiserver.crt \
    apiserver-kubelet-client.crt apiserver-kubelet-client.key \
    service-account.key service-account.crt \
    etcd-server.key etcd-server.crt \
    kube-controller-manager.key kube-controller-manager.crt \
    kube-scheduler.key kube-scheduler.crt \
    ${instance}:~/
done

for instance in k8s-worker-1 k8s-worker-2 ; do
  scp ca.crt kube-proxy.crt kube-proxy.key ${instance}:~/
done
}
```

## Optional - Check Certificates

At `k8s-master-1` and `k8s-master-2` nodes, run the following, selecting option 1

```bash
./cert_verify.sh
```

Prev: [Client tools](03-client-tools.md)<br>
Next: [Generating Kubernetes Configuration Files for Authentication](05-kubeconfig-files.md)