> This tutorial is a modified version of the original developed by [Kelsey Hightower](https://github.com/kelseyhightower/kubernetes-the-hard-way) and [Mumshad Mannambeth](https://github.com/mmumshad/kubernetes-the-hard-way).

# Kubernetes The Hard Way On EC2

This tutorial walks you through setting up Kubernetes the hard way on AWS using EC2 instances. This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster. 
If that's you, check out [Amazon Elastic Kubernetes Service](https://aws.amazon.com/eks/), or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

This tutorial is a modified version of the original developed by [Kelsey Hightower](https://github.com/kelseyhightower/kubernetes-the-hard-way) and and [Mumshad Mannambeth](https://github.com/mmumshad/kubernetes-the-hard-way).
While the original one uses GCP as the platform to deploy Kubernetes, I use EC2 instances and Terraform to deploy a cluster on AWS to recreate a deployment of a Kubernetes cluster as if it were an on-premise infra with VMs or a local machine with VirtualBox installed.

> The results of this tutorial should not be viewed as production ready and may receive limited support from the community, but don't let that stop you from learning!

Please note that this particular challenge is all about the minute detail. If you miss one tiny step anywhere along the way, it will break!

Always run the `cert_verify` script at the places it suggests, and always ensure you are on the correct node when you do stuff. If `cert_verify` shows anything in red, then you have made an error in a previous step. For the master node checks, run the check on `k8s-master-1` and on `k8s-master-2`

## Target Audience

The target audience for this tutorial is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together.

## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

* [Kubernetes](https://github.com/kubernetes/kubernetes) 1.24.3
* [Container Runtime](https://github.com/containerd/containerd) 1.5.9
* [CNI Container Networking](https://github.com/containernetworking/cni) 0.8.6
* [Weave Networking](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/)
* [etcd](https://github.com/coreos/etcd) v3.5.3
* [CoreDNS](https://github.com/coredns/coredns) v1.9.4

## Cluster Deployment

The underlying infrastructure consists of EC2 instances deployed spread across three availability zones with a custom network layout. See [diagram]()

 * [Terraform](https://developer.hashicorp.com/terraform/downloads) 1.3.6
 * [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/4.40.0/docs) 4.40.0

### Node configuration

We will be building the following:

* Two control plane nodes (`k8s-master-1` and `k8s-master-2`) running the control plane components as operating system services.
* Two worker nodes (`k8s-worker-1` and `k8s-worker-2`).
* One loadbalancer EC2 instance running HAProxy to balance requests between the two API servers.
* One client EC2 instance to manage all the nodes.

### Extras

In some steps documents, this particular KTHW alternative approach includes additional information to give extra context about why we are performing each task, helping to understand and learn the whole process.

Also, because we are working in a cloud environment, with costs charged by the hour, inside the [scripts](scripts/) folder, you will find basic bash scripts that perform all the tasks required on each step. This alternative could help you reach faster where you left off.
Finally, if you don't want to focus on the KTHW approach, you have the alternative to enable the [kubeadm way](docs/kubeadm-cluster.md). 

## Labs

* [Prerequisites](docs/01-prerequisites.md)
* [Provisioning Compute Resources](docs/02-compute-resources.md)
* [Installing the Client Tools](docs/03-client-tools.md)
* [Provisioning the CA and Generating TLS Certificates](docs/04-ca-certificates-cluster.md)
* [Generating Kubernetes Configuration Files for Authentication](docs/05-kubeconfig-files.md)
* [Generating the Data Encryption Config and Key](docs/06-data-rest-encyption-keys.md)
* [Bootstrapping the etcd Cluster](docs/07-setup-etcd-cluster.md)
* [Bootstrapping the Kubernetes Control Plane](docs/08-bootstrapping-kubernetes-controllers.md)
* [Installing CRI on Worker Nodes](docs/09-install-cri-workers.md)
* [Bootstrapping the Kubernetes Worker Nodes](docs/10-worker-nodes-setup.md)
* [TLS Bootstrapping the Kubernetes Worker Nodes](docs/11-tls-bootstrapping.md)
* [Configuring kubectl for Remote Access](docs/12-client-final-kubeconfig.md)
* [Deploy Weave - Pod Networking Solution](docs/13-pod-networking.md)
* [Kube API Server to Kubelet Configuration](docs/14-rbac-apiserver-to-kubelet.md)
* [Deploying the DNS Cluster Add-on](docs/15-coredns-install.md)
* [Smoke Test](docs/16-smoke-test.md)
* [Extra - Certificate Verification](docs/verify-certificates.md)
* [Extra - Kubernetes the kubeadm way](docs/kubeadm-cluster.md)
