**# Kubernetes Container Runtime Installation Guide (Binary vs APT Method)**

## **Introduction**
When setting up Kubernetes, the choice of installation method for the container runtime (containerd) impacts how additional components like runc and CNI plugins are managed. This guide clarifies the differences between installing containerd via **binary method** versus **APT package manager**, particularly in how CNI plugins are handled.

---
## **1️⃣ Installing Container Runtime using APT (Recommended for kubeadm)**
When you install containerd via `apt`, the following behavior occurs:

- **runc**: Automatically installed as a dependency.
- **CNI Plugins**: *Not included by default* in `/opt/cni/bin/`.
- **containerd**: Installed and configured via systemd.

### **Steps for APT Method:**
1. Install dependencies:
   ```bash
   sudo apt update
   sudo apt install -y containerd
   ```
2. Verify installation:
   ```bash
   containerd --version
   ```
3. Since CNI plugins are **not installed**, Kubernetes will require a CNI plugin (like Flannel, Calico, etc.) to be deployed separately. After `kubeadm init`, you must install a CNI plugin:
   ```bash
   kubectl apply -f <CNI-YAML>
   ```
   Example for Calico:
   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

### **Key Considerations for APT Method:**
- ✅ **Easier & recommended for kubeadm setups**
- ❌ **CNI plugins must be installed separately after kubeadm init**
- ✅ **Automatic runc installation**

---
## **2️⃣ Installing Container Runtime using Binary (More Manual Steps)**
When installing via binaries, everything is managed manually, including `containerd`, `runc`, and CNI plugins.

### **Steps for Binary Method:**
1. Download and install containerd, runc, and CNI plugins manually:
   ```bash
   wget https://github.com/containerd/containerd/releases/download/v1.x.x/containerd-1.x.x-linux-amd64.tar.gz
   sudo tar Cxzvf /usr/local containerd-1.x.x-linux-amd64.tar.gz
   ```
2. Install `runc` manually:
   ```bash
   wget https://github.com/opencontainers/runc/releases/download/v1.x.x/runc.amd64
   sudo install -m 755 runc.amd64 /usr/local/sbin/runc
   ```
3. Install CNI plugins manually:
   ```bash
   wget https://github.com/containernetworking/plugins/releases/download/v1.x.x/cni-plugins-linux-amd64-v1.x.x.tgz
   sudo mkdir -p /opt/cni/bin
   sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.x.x.tgz
   ```

### **Key Considerations for Binary Method:**
- ✅ **More control over versions & configurations**
- ❌ **Manual installation of runc & CNI plugins is required**
- ❌ **More complex setup, requiring extra verification**

---
## **Conclusion: Choosing the Right Method**
| Feature                     | APT Method ✅ (Recommended) | Binary Method ❌ |
|-----------------------------|---------------------------|----------------|
| Ease of setup               | ✅ Easy                    | ❌ Manual & complex |
| CNI plugins auto-installed? | ❌ No (needs YAML apply)  | ❌ No (manual install) |
| runc auto-installed?        | ✅ Yes                     | ❌ No (manual install) |
| Best for kubeadm?           | ✅ Yes                     | ❌ No |
| Custom version control      | ❌ No (uses default repo) | ✅ Yes |

If using **kubeadm**, the **APT method** is strongly recommended. The **binary method** is useful for advanced users needing strict control over versions but requires extra manual steps.

---
### **Final Reminder: What Changes Between These Methods?**
- `apt install containerd` **automatically installs runc**, but **does not install CNI plugins**.
- The **binary method requires manual installation of both runc and CNI plugins**.
- In **both methods, a CNI plugin must be applied in Kubernetes** for networking to function.
- For Kubernetes cluster setup using `kubeadm`, **just installing a CNI plugin via YAML is enough** (you don’t need to manually place CNI binaries in `/opt/cni/bin/`).

This guide ensures you know exactly **what each method does and what additional steps are required.** 🚀

