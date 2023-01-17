# Prerequisites

## AWS

 An AWS account or AWS user
  SSH key pair
  SSH Configuration
  Instance types

## Terraform

## Lab Defaults

Three subnets
One NAT gateway
10.0.0.0/16 CIDR

### EC2 Instances Network

The network used by the Virtual Box virtual machines is `192.168.56.0/24`.

To change this, edit the [Vagrantfile](../vagrant/Vagrantfile) in your cloned copy (do not edit directly in github), and set the new value for the network prefix at line 9. This should not overlap any of the other network settings.

Note that you do not need to edit any of the other scripts to make the above change. It is all managed by shell variable computations based on the assigned VM  IP  addresses and the values in the hosts file (also computed).

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



## SSH configuration

.ssh/config

```
# K8S client over Session Manager
host k8s-client
    HostName i-ffffffffffff
    User ubuntu
    PreferredAuthentications publickey
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_rsa_cloud
    ProxyCommand sh -c "~/.ssh/ssm-private-ec2-proxy.sh %h %p"

# SSH over Session Manager
host i-* mi-*
    User ubuntu
    PreferredAuthentications publickey
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_rsa_cloud
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

ssh/ssm-private-ec2-proxy.sh

```bash
#!/bin/bash

AWS_PROFILE=GreatProfile
AWS_REGION=us-east-1
MAX_ITERATION=5
SLEEP_DURATION=5

# Arguments passed from SSH client
HOST=$1
PORT=$2

echo $HOST

# Start ssm session
aws ssm start-session --target $HOST \
  --document-name AWS-StartSSHSession \
  --parameters portNumber=${PORT} \
  --profile ${AWS_PROFILE} \
  --region ${AWS_REGION}
```
