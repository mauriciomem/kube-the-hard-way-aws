# Bootstrapping clusters with kubeadm

This repository also includes the [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/) alternative of bootstrapping kubernetes clusters.
By setting to `true` the `kubeadm_on` variable in terraform, a new user data template will be installed in all kubernetes servers, including all the necessary packages to play with kubeadm.
This can be considered a helpful alternative to test creating and/or upgrading kuberentes.

## Initial configuration 

Because of the different Kubernetes node roles, you can set up a multi-master cluster. As a reference, you can review the steps left below.

1. **Initialize a master node**

`kubeadm init [arguments]`

Common options:

 - `--control-plane-endpoint`: Entrypoint of API server if multiple masters are available.

- `--apiserver-advertise-address`: where the control plane node will listen to.

- `--pod-network-cidr`: pod network.

- `--upload-certs`: to distribute the certificates accross all control plane node without manual distribution. Let kubeadm manage the certifcate creation and distribution processes.

- `--apiserver-cert-extra-sans`: extra Subject Alternative Name for the API endpoint server certificate. Could come handy if access to the cluster should be done via the public DNS hostname of the public facing instance.

2. **kubeadm init without automatic certificate distribution**

```
sudo kubeadm init --control-plane-endpoint=k8s-ha-lb --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address=10.0.1.10
```

3. **Join node to the cluster with a master role. Remember to save the one time tokens generated in the previous step.**

```
kubeadm join k8s-ha-lb:6443 --token [token] --discovery-token-ca-cert-hash [hash] --control-plane --apiserver-advertise-address=10.0.1.11
```

4. **Join node to the cluster with a worker role**

```
kubeadm join k8s-ha-lb:6443 --token [token] --discovery-token-ca-cert-hash [hash]
```

5. **Remember that the kubeconfig file for the admin user is placed inside the `/etc/kubernetes/` folder.**