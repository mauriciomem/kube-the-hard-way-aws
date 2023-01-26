
## Install container runtime interface (cri) with depenencies

# - container network inteface (cni) plugin to allow containerd manage networks
# - runc as the user space cli tool to run container according to the OCI spec.

# versions supported for kubernetes v1.24
CONTAINERD_VERSION=1.5.9
CNI_VERSION=0.8.6
RUNC_VERSION=1.1.1

# download containerd, cni plugins, runc
wget -q --show-progress --https-only --timestamping \
  https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz \
  https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz \
  https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64

# place downloaded binaries in its corresponding folders
sudo mkdir -p /opt/cni/bin
sudo chmod +x runc.amd64
sudo mv runc.amd64 /usr/local/bin/runc
sudo tar -xzvf containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -C /usr/local
sudo tar -xzvf cni-plugins-linux-amd64-v${CNI_VERSION}.tgz -C /opt/cni/bin


# create containerd systemd service running configuration
# https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl enable containerd
sudo systemctl start containerd