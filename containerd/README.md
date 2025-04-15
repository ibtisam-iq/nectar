# **Step-by-Step Guide to Install and Configure Containerd for Kubernetes**

## **Introduction**
- Containerd is a lightweight container runtime that manages the lifecycle of containers. It is a core component of Kubernetes and provides features such as image management, execution, and storage.

- Unlike Docker, which includes multiple features beyond container runtime, Containerd is a focused and optimized runtime used by Kubernetes for efficiency and reliability. To know more about the differences between Docker and Containerd in context with Kubernetes, you can refer to the following link: [Docker vs Container]().

This guide will walk you through installing, configuring, and enabling Containerd on a Linux-based system.

## Important Note 

Before proceeding next, it is mandatory to note that you need to install **`runc`** and **CNI (Container Network Interface) plugins** to use Containerd.

## Pre Installation

### **Step 1: Load Required Kernel Modules**
#### 📌 Why?
Kubernetes networking relies on certain kernel modules to work correctly. These modules help in container isolation and networking.

```bash
# Load the overlay module (used for container storage)
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
EOF
```

Now, load the modules manually:
```bash
sudo modprobe overlay
```

Confirm the modules are loaded:
```bash
lsmod | grep overlay
```
✅ overlay – Needed for container storage (not mandatory but recommended).

---

### **Step 2: Configure Kernel Parameters**
#### 📌 Why?
These settings are required for Kubernetes networking and proper packet forwarding. It just configures sysctl for container networking (manually enable IPv4 packet forwarding).

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

Apply the changes:
```bash
sudo sysctl --system
```

Verify the changes:
```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
cat /proc/sys/net/ipv4/ip_forward
```
✅ net.ipv4.ip_forward = 1 – Required for container networking.

---

## Installation

There are two ways to install Containerd, either by using the official Containerd repository or by using a package manager like `apt` or `yum`.

### Choosing the Right Method
| Feature                     | APT Method ✅ (Recommended) | Binary Method ❌ |
|-----------------------------|---------------------------|----------------|
| Ease of setup               | ✅ Easy                    | ❌ Manual & complex |
| CNI plugins auto-installed? | ❌ No (needs YAML apply)  | ❌ No (manual install) |
| runc auto-installed?        | ✅ Yes                     | ❌ No (manual install) |
| containerd.service auto-configured?        | ✅ Yes                     | ❌ No (manual configuration) |
| Best for kubeadm?           | ✅ Yes                     | ❌ No |

**Method 1. Using the official Containerd repository:**

### **🛠 Step 1: Install Dependencies**
Ensure that your system has the necessary tools to download and extract files.

```bash
sudo apt update -y
sudo apt install -y curl tar wget
```

📌 *These dependencies are required for downloading, extracting, and verifying binaries.*

### **📦 Step 2: Download & Install containerd**

```bash
# Get the latest containerd version
export VERSION=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | grep tag_name | cut -d '"' -f 4 | cut -c 2-)

# Download containerd binary
wget https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-amd64.tar.gz

# Verify SHA256 checksum (optional, but recommended)
wget https://github.com/containerd/containerd/releases/download/v${VERSION}/containerd-${VERSION}-linux-amd64.tar.gz.sha256sum
sha256sum -c containerd-${VERSION}-linux-amd64.tar.gz.sha256sum

# Extract containerd into /usr/local
sudo tar -C /usr/local -xzvf containerd-${VERSION}-linux-amd64.tar.gz
```

📌 *This installs containerd binaries in **`/usr/local/bin`**.*

### **Step 3: Configure Systemd Service**

- containerd should be managed via `systemd` to ensure automatic startup on system boot.
- As you've installed containerd manually, you'll need to create a systemd service file.
- Check if the `containerd.service` file exists:

```bash
sudo systemctl status containerd
sudo systemctl show -p FragmentPath containerd
sudo ls /usr/lib/systemd/system/containerd.service # Default path if installed with Package manager
sudo ls /etc/systemd/system/containerd.service # If Manually installed (e.g., from binary or custom scripts).
```
- If it doesn't exist, create it manually:

```bash
# Download the official systemd service file
sudo wget -O /usr/local/lib/systemd/system/containerd.service \
  https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start containerd service
sudo systemctl enable --now containerd
```

📌 *This ensures that containerd starts automatically when the system boots.*

### **🔧 Step 4: Install & Configure runc**

`runc` is a low-level runtime required for container execution.

```bash
# Download latest runc binary
wget https://github.com/opencontainers/runc/releases/latest/download/runc.amd64

# Install runc
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
```

**Method 2. Using a package manager (e.g., apt, yum, etc.):**

```bash
# Add official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install containerd
sudo apt-get install -y containerd.io

# Check if containerd and runc installed:
containerd --version
runc --version

# Check if containerd is running:
sudo systemctl status containerd
sudo systemctl enable --now containerd

```

- Containerd.io contains both `containerd` and `runc`, so you don't need to install `runc` separately.
- As you installed containerd using a package manager (e.g., apt, dnf, or yum), the systemd service file is already included and placed in the correct location.
- Check if `containerd.service` is auto-configured `sudo /usr/lib/systemd/system/containerd.service`. 

---

## Post Installation Steps

### **🌐 Step 1: Install CNI Plugins (For Networking)**

CNI plugins enable networking between containers, which is essential for Kubernetes.

```bash
# Create directory for CNI plugins
sudo mkdir -p /opt/cni/bin

# Download latest CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz

# Extract CNI plugins
# -C /opt/cni/bin	Changes to the /opt/cni/bin directory before extracting.
sudo tar -C /opt/cni/bin -xzvf cni-plugins-linux-amd64-v1.6.2.tgz

# See if CNI plugins are installed correctly
sudo ls /opt/cni/bin/
```

🔹 What is its function?

1. When you extract `cni-plugins-linux-amd64-v1.6.2.tgz`, it places all the CNI plugins into `/opt/cni/bin/`.
2. Now, depending on your configuration, Kubernetes (or any container runtime) picks a specific plugin from this directory based on your config in `/etc/cni/net.d/`. 
 - There can be multiple CNI config files in `/etc/cni/net.d/`.
 - In Kubernetes, the **CNI interface** is typically located at: `/etc/cni/net.d/`
3. When a pod starts, Kubernetes looks at the `CNI configuration file` (e.g., Flannel, Calico) and executes the corresponding plugin binary from `/opt/cni/bin/`.

---

### **Step 2: Configure Containerd**
#### 📌 Why?
Containerd requires a configuration file to define runtime parameters. By default, it does not create one, so we need to generate it manually.

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

Now, edit the configuration file to use **systemd** as the cgroup driver:

```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

📌 **Why change to SystemdCgroup?**
- Kubernetes prefers `systemd` as the cgroup driver because it aligns better with the Linux OS process management.
- Ensures stability and compatibility with modern Kubernetes clusters.

Verify the change:
```bash
grep 'SystemdCgroup' /etc/containerd/config.toml
```

---

## **Step 4: Restart and Enable Containerd**
### 📌 Why?
After modifying the configuration file, we need to restart Containerd to apply the changes and enable it to start at boot.

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd --now
```

Verify Containerd is running:
```bash
sudo systemctl status containerd
```

If it's running, you should see output similar to:
```
● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Tue 2025-03-11 22:15:36 UTC; 262ms ago
```

---

## **Step 5: Verify Containerd is Working**
### 📌 Why?
Before using it with Kubernetes, let's test if Containerd can pull and run a container.

```bash
sudo ctr images pull docker.io/library/alpine:latest
```

Now, run a Redis container using Containerd:
```bash
sudo ctr run --rm -t docker.io/library/alpine:latest test-alpine
```

If the container runs successfully, Containerd is installed and working correctly.

## Next Steps

Now that **Containerd** is installed and configured, proceed with **Kubernetes** setup by installing `kubeadm`, `kubelet`, and `kubectl`.

---

## Containerd Network Accessibility

### Is containerd Directly Accessible on an External Port?
No, by default, containerd is not directly accessible on any external port. 🚫

### 🔍 Why?
containerd is a daemon process that communicates internally using a gRPC socket. It is not exposed directly on any network port but is only accessible through a local UNIX socket (`/run/containerd/containerd.sock`).

### ✅ How to Verify?
If you want to verify whether containerd is running, check its status using systemd:

```bash
sudo systemctl status containerd
```

Alternatively, use the `ss` command to check the socket in use:

```bash
ss -l | grep containerd
```

If the output appears as follows:

```arduino
u_str  LISTEN  0  4096  /run/containerd/containerd.sock
```

It means that containerd is listening on a local UNIX socket and not on any TCP port.

### 🛠️ Can containerd be Exposed on a Port?
Yes, if you need to expose containerd on a TCP port, you will need to modify the configuration.

#### Steps to Enable TCP Port Exposure

1. Open the containerd configuration file:

   ```bash
   sudo nano /etc/containerd/config.toml
   ```

2. Ensure that `cri` is **not** disabled under `disabled_plugins`:

   ```toml
   disabled_plugins = []
   ```

3. Update the gRPC server address to allow TCP communication:

   ```toml
   [grpc]
   address = "tcp://0.0.0.0:5000"
   ```

4. Restart containerd to apply the changes:

   ```bash
   sudo systemctl restart containerd
   ```

5. Verify if the port is open:

   ```bash
   ss -tulnp | grep containerd
   ```

### ⚠️ Security Warning
Exposing containerd on a network port can pose security risks. By default, Kubernetes and containerd communicate locally via UNIX sockets, so exposing a TCP port is usually unnecessary. If you must expose it, ensure that proper security measures like firewalls and authentication mechanisms are in place.

---

## **Conclusion**
Now, your system is set up with Containerd as the container runtime, properly configured to work with Kubernetes.

✅ **You are now ready to proceed with Kubernetes installation!** 🚀



