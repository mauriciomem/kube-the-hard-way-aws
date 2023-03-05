# Installing the Client Tools

I chose the `k8s-client` node to perform administrative tasks. Whichever system you chose make sure that system is able to access all the provisioned EC2 instances through SSH to copy files over. Terraform will be in charge of distributing the neccesary public SSH keys within the cluster members, and the EC2 instance officing as the client node will have the key pair already installed to avoid manual setup. At the client node you can perform `ssh ubuntu@k8s-master-1` without thinking about instance IDs or SSH keys.

## Access all EC2 instances from the client node

Here we create an SSH key pair for the `ubuntu` user who we are logged in as. We will copy the public key of this pair into the `ssh_public_key` variable inside the `variables.tfvars` file.

Generate Key Pair for the `k8s-client` node

```bash
ssh-keygen
```

## Install kubectl

The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl). command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Linux

```bash
wget https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.24.3 or higher is installed:

```
kubectl version -o yaml
```

> output

```
kubectl version -o yaml
clientVersion:
  buildDate: "2022-07-13T14:30:46Z"
  compiler: gc
  gitCommit: aef86a93758dc3cb2c658dd9657ab4ad4afc21cb
  gitTreeState: clean
  gitVersion: v1.24.3
  goVersion: go1.18.3
  major: "1"
  minor: "24"
  platform: linux/amd64
kustomizeVersion: v4.5.4

The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

Don't worry about the error at the end as it is expected. We have not set anything up yet!

Prev: [Compute Resources](02-compute-resources.md)<br>
Next: [Certificate Authority](04-ca-certificates-cluster.md)