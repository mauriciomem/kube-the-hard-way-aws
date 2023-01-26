# Prerequisites

## AWS 

General requisites

 - An AWS account available to deploy AWS resources.
 - An SSH key pair.
 - An SSH Configuration to be able to login through SSM session manager.
 - awscli installed.
 - A small budget to deploy 6 EC2 instances with a NAT Gateway. 

## Terraform

The `terraform` folder includes all required resources to provision all the underlying infrastructure. To deploy all the AWS resources, you should:

1. Copy the file variables.default.tfvars to variables.tfvars and set the variable values accordingly.
2. Review if everything is in place and check the resources to be deployed with: `terraform plan --var-file variables.tfvars`.
3. Apply changes to deploy the infra with: `terraform apply --var-file variables.tfvars`

## SSH configuration

This lab leverages SSM session manager to access the EC2 instances, replacing the deployment of a bastion  in a public subnet. This setup is managed by terraform. Nevertheless, from the client side, you should add to the ssh configuration file the following references,

```
# K8S client over Session Manager
host k8s-client
    HostName [EC2 instances ID]
    User ubuntu
    PreferredAuthentications publickey
    IdentitiesOnly yes
    IdentityFile ~/.ssh/[SSH Private key]
    ProxyCommand sh -c "~/.ssh/ssm-private-ec2-proxy.sh %h %p"

# SSH over Session Manager
host i-* mi-*
    User ubuntu
    PreferredAuthentications publickey
    IdentitiesOnly yes
    IdentityFile ~/.ssh/[SSH Private key]
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

The first SSH config clause will allow you access the client EC2 instance that it will be used in all steps during the cluster setup.
In certain situations or for troubleshooting purposes, the second SSH config clause permits access to every EC2 instance via a `aws ssm start-session` command

## Lab Defaults

Three subnets
One NAT gateway
10.0.0.0/16 CIDR

### EC2 Instances Network

The network deployed in AWS consists in:

 - Three private subnets.
 - Three public subnets.
 - An only NAT Gateway.
 - An Internet Gateway.

All instances except the load balancer will be placed in private subnets. The load balancer will have attached a public IP.

It is *recommended* that you leave the pod and service networks with the following defaults. If you change them then you will also need to edit one or both of the CoreDNS and Weave networking manifests to accommodate your change.

### Pod Network

The network used to assign IP addresses to pods is `10.244.0.0/16`.

To change this, open all the `.md` files in the [docs](../docs/) directory in your favourite IDE and do a global replace on<br>
`POD_CIDR=10.244.0.0/16`<br>
with the new CDIR range.  This should not overlap any of the other network settings.

### Service Network

The network used to assign IP addresses to Cluster IP services is `10.96.0.0/16`.

To change this, open all the `.md` files in the [docs](../docs/) directory in your favourite IDE and do a global replace on<br>
`SERVICE_CIDR=10.96.0.0/16`<br>
with the new CDIR range.  This should not overlap any of the other network settings.

Additionally edit line 164 of [coredns.yaml](../deployments/coredns.yaml) to set the new DNS service address (should still end with `.10`)

## Running Commands in Parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances, in those cases consider using tmux and splitting a window into multiple panes with synchronize-panes enabled to speed up the provisioning process.

> The use of tmux is optional and not required to complete this tutorial.

![tmux screenshot](images/tmux-screenshot.png)

> Enable synchronize-panes by pressing `CTRL+B` followed by `"` to split the window into two panes. In each pane (selectable with mouse), ssh to the host(s) you will be working with.</br>Next type `CTRL+X` at the prompt to begin sync. In sync mode, the dividing line between panes will be red. Everything you type or paste in one pane will be echoed in the other.<br>To disable synchronization type `CTRL+X` again.</br></br>Note that the `CTRL-X` key binding is provided by a `.tmux.conf` loaded onto the VM by the vagrant provisioner.

Next: [Compute Resources](02-compute-resources.md)
