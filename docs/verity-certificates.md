# Verify Certificates in Master-1/2 & Worker-1

> Note: This script is only intended to work with a kubernetes cluster setup following instructions from this repository. It is not a generic script that works for all kubernetes clusters. Feel free to send in PRs with improvements.

This script was developed to assist the verification of certificates for each Kubernetes component as part of building the cluster. This script may be executed as soon as you have completed the Lab steps up to [Bootstrapping the Kubernetes Worker Nodes](./10-worker-nodes-setup.md). 

It is important that the script execution needs to be done by following commands after logging into the respective virtual machines [ whether it is k8s-master-1 / k8s-master-2 / k8s-worker-1 ] via SSH.

```bash
cd /home/vagrant
bash cert_verify.sh
```

Any misconfiguration in certificates will be reported in red.
