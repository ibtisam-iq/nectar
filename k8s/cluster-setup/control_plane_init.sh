# Update OS
sudo apt update && sudo apt install -y net-tools

# Disable Swap immediately (Without Rebooting)
sudo swapoff -a

# Check if Swap is Disabled, run any of the following commands: 
sudo swapon --summary   # Should be empty
free -h                 # If swap is 0B, it is disabled
lsblk | grep swap       # Should not show any swap partitions

sudo sed -i '/swap/d' /etc/fstab
sudo hostnamectl set-hostname k8s-master-1
ip link show
ifconfig -a
# Verify UUID of the machine
sudo cat /sys/class/dmi/id/product_uuid

sudo apt update > /dev/null 2>&1

# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update > /dev/null 2>&1
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubelet --version
kubectl version --client

# Add official GPG key:
sudo apt update > /dev/null 2>&1
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update > /dev/null 2>&1

# Install containerd
sudo apt-get install -y containerd.io

# Check if containerd and runc installed:
containerd --version
runc --version

# Check containerd.service
sudo /usr/lib/systemd/system/containerd.service
echo "Verify the path of the containerd service file"
sudo systemctl show -p FragmentPath containerd

# Check if containerd is running:
sudo systemctl status containerd
sudo systemctl enable --now containerd

# Create directory for CNI plugins
sudo mkdir -p /opt/cni/bin

# Download latest CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz

# Extract CNI plugins
# -C /opt/cni/bin	Changes to the /opt/cni/bin directory before extracting.
sudo tar -C /opt/cni/bin -xzvf cni-plugins-linux-amd64-v1.6.2.tgz

# See if CNI plugins are installed correctly
sudo ls /opt/cni/bin/

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

grep 'SystemdCgroup' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd --now
sudo ss -l | grep containerd

sudo ctr images pull docker.io/library/alpine:latest

###

echo "Loading required kernel modules for Kubernetes..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load immediately without rebooting
sudo modprobe overlay
sudo modprobe br_netfilter

# Verify module is loaded
sudo lsmod | grep overlay
sudo lsmod | grep br_netfilter

echo "Configuring sysctl parameters for Kubernetes..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply changes without rebooting
sudo sysctl --system

# Verify applied settings
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
cat /proc/sys/net/ipv4/ip_forward

# Make sure you have disabled swap on the machine. 
sudo swapoff -a

# Make sure you have initiated the containerd service. 
sudo systemctl start containerd
sudo systemctl enable containerd

# Make sure you have initiated the Kubernetes service. 
sudo systemctl start kubelet
sudo systemctl enable kubelet
sudo netstat -tulnp | grep 6443

# Make sure you have pulled the required images.
sudo kubeadm config images pull

CONTROL_PLANE_IP=$(hostname -I | awk '{print $1}')
NODE_NAME=$(hostnamectl --static)

sudo kubeadm init \
  --control-plane-endpoint "${CONTROL_PLANE_IP}:6443" \
  --upload-certs \
  --pod-network-cidr 192.168.0.0/16 \
  --apiserver-advertise-address="${CONTROL_PLANE_IP}" \
  --node-name "${NODE_NAME}" \
  --cri-socket=unix:///var/run/containerd/containerd.sock

# Create the kubeconfig directory in your home folder
mkdir -p $HOME/.kube

# Copy the cluster config to your user directory  
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Change the file ownership to your user  
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl get nodes
kubectl get pods -n kube-system

