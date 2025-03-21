# Installing containerd (Official Binary Method)

## **Introduction**

containerd is an industry-standard container runtime that is widely used with Kubernetes. This guide provides a step-by-step installation method using the **official binary** approach, ensuring you get the latest version with full control over configurations. This method is preferred for Kubernetes cluster setups.

## **Why Use Official Binaries Instead of **``**?**

There are multiple ways to install containerd, but the official binary method is recommended because: ✅ Provides the **latest version** ✅ Ensures **Kubernetes compatibility** ✅ Offers **manual configuration control** ✅ Avoids outdated versions from OS package repositories

## **Step-by-Step Installation Guide**

### **🛠 Step 1: Install Dependencies**

Ensure that your system has the necessary tools to download and extract files.

```bash
sudo apt update -y
sudo apt install -y curl tar wget
```

📌 *These dependencies are required for downloading, extracting, and verifying binaries.*

---

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
sudo tar Cxzvf /usr/local containerd-${VERSION}-linux-amd64.tar.gz
```

📌 *This installs containerd binaries in **`/usr/local/bin`**.*

---

### **📝 Step 3: Configure Systemd Service**

containerd should be managed via `systemd` to ensure automatic startup on system boot.

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

---

### **🔧 Step 4: Install & Configure runc**

`runc` is a low-level runtime required for container execution.

```bash
# Download latest runc binary
wget https://github.com/opencontainers/runc/releases/latest/download/runc.amd64

# Install runc
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
```

📌 *runc is required for managing container execution at a lower level.*

---

### **🌐 Step 5: Install CNI Plugins (For Networking)**

CNI plugins enable networking between containers, which is essential for Kubernetes.

```bash
# Create directory for CNI plugins
sudo mkdir -p /opt/cni/bin

# Download latest CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz

# Extract CNI plugins
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz
```

📌 *These plugins are required for container networking, especially in Kubernetes clusters.*

---

### **🚀 Step 6: Verify Installation**

Ensure everything is correctly installed and running.

```bash
# Check containerd version
containerd --version

# Check runc version
runc --version

# Check if containerd service is running
systemctl status containerd
```

📌 *If everything is installed correctly, **`containerd`** should be active and running.*

---

## **🎯 Summary**

✅ Installed containerd using the **official binary method** ✅ Configured **systemd service** ✅ Installed **runc runtime** ✅ Installed **CNI plugins** for networking.



