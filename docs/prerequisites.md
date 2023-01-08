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
