# Provisioning Compute Resources

Note: You must have installed and configure all the requisites discussed in the [prerequisites](docs/prerequisites.md) section

Download this github repository

```bash
git clone https://github.com/mauriciomem/kube-the-hard-way-aws.git
```

CD into terraform directory

```bash
cd kube-the-hard-way-aws/terraform
```

Copy and adjust the `variables.default.tfvars`

terraform plan && terraform deploy

```bash
terraform plan --vars-file variables.tfvars
terraform deploy --vars-file variables.tfvars
```


This does the below:

- Deploys 6 VMs - 2 Master, 2 Worker, 1 Loadbalancer, 1 client with the names listed below.

- Set's IP addresses and updates the `/etc/hosts` file.

    | EC2 Instance name | Purpose        | IP          | Instance type  |
    | ------------      |:--------------:| -----------:| --------------:|
    | k8s-master-1      | Master         | 10.0.1.10   | t3.small       |
    | k8s-master-2      | Master         | 10.0.1.11   | t3.small       |
    | k8s-worker-1      | Worker         | 10.0.2.12   | t3.tiny        |
    | k8s-worker-2      | Worker         | 10.0.2.13   | t3.tiny        |
    | k8s-ha-lb         | LoadBalancer   | 10.0.101.10 | t3.tiny        |
    | k8s-client        | Client         | 10.0.1.9    | t3.tiny        |


    > These are the default settings. These can be changed in terraform VPC resources definition.

- Installs client tools.

- Distributes a SSH public key generated during the deployment in the client instance to all the service instances.

- Sets required kernel settings for kubernetes networking to function correctly.

## SSH to the nodes

There are two ways to SSH into the nodes:

### 1. SSH directly to each instance from the host.

### 2. SSH to the k8s-client instance.

This has the advantaje of a friendly user interface and interaction with the rest of the instances.


Prev: [Prerequisites](01-prerequisites.md)<br>
Next: [Client tools](03-client-tools.md)