# Set Up a Kubernetes Cluster with Kubeadm

This guide provides a step-by-step process to deploy a production-ready Kubernetes cluster using **kubeadm** on Ubuntu 24.04 LTS, tailored for high availability (HA) and integrated with the Calico [CNI](cni-plugin-installation.md). Designed for clarity and precision, it ensures you can initialize a control plane, join worker nodes, and verify a fully functional cluster with confidence. Follow each step to build a robust Kubernetes environment for development, testing, or production.

## Prerequisites

Before starting, ensure your environment meets these requirements:

- **Operating System**: Ubuntu 24.04 LTS on all nodes.
- **Hardware**:
  - **Control Plane Nodes**: Minimum 2 CPUs, 4 GB RAM (e.g., AWS EC2 `t2.medium`).
  - **Worker Nodes**: Minimum 1 CPU, 2 GB RAM.
  - **Storage**: 20 GB disk per node.
- **Networking**:
  - Full connectivity between nodes (private or public network).
  - Unique hostname, MAC address, and `product_uuid` for each node.
  - Open ports as per the [Kubernetes ports and protocols](https://kubernetes.io/docs/reference/networking/ports-and-protocols/).
- **Software**: `kubeadm`, `kubelet`, `kubectl`, and `containerd` (installed in later steps).
- **Access**: SSH access to all nodes with `sudo` privileges.

**Example Cluster Setup** (AWS EC2):
| Instance Name | Private IP   | Role          |
|---------------|--------------|---------------|
| k8s-master-1  | 10.0.138.123 | Control Plane |
| k8s-master-2  | 10.0.138.124 | Control Plane |
| k8s-worker-1  | 10.0.138.125 | Worker Node   |
| k8s-worker-2  | 10.0.138.126 | Worker Node   |

---

## 🚀 Quick & Effortless Kubernetes Cluster Setup — One Click Away!

Setting up a Kubernetes control plane manually?

**No need!**

Head over to **[infra-bootstrap](https://github.com/ibtisam-iq/infra-bootstrap)** — my dedicated automation repo offering **one-click Kubernetes control plane installation**.

🎯 **What you'll find there:**
- ⚡ Fully automated control plane setup scripts for EC2
- 💾 Clean, reliable Kubernetes installation workflows
- 🚀 No step-by-step guides, no copy-pasting — just one command to rule them all

👉 [Explore infra-bootstrap now and experience effortless Kubernetes cluster initialization!](https://github.com/ibtisam-iq/infra-bootstrap)

🌸 *Let automation bloom, while you focus on building the future on Kubernetes.* 🌸

---

## Get Started

## Step 1: Set Up AWS EC2 Instances

Configure EC2 instances to host your Kubernetes cluster, ensuring proper networking and security settings.

1. **Create EC2 Instances**:
   - **Instance Type**: `t2.medium` (2 vCPUs, 4 GB RAM) for control plane; `t2.micro` or higher for workers.
   - **OS**: Ubuntu 24.04 LTS.
   - **Storage**: 20 GB SSD (gp3 recommended).
   - **Networking**: Place all instances in the same VPC and subnet for simplicity. Assign private IPs (e.g., `10.0.138.123` for `k8s-master-1`).
   - **Security Group**: Create a security group allowing:
     - **Control Plane**: TCP 6443 (API server), 2379-2380 (etcd), 10250-10259 (kubelet, scheduler, controller).
     - **Worker Nodes**: TCP 10250 (kubelet), 30000-32767 (NodePort).
     - **Inter-Node**: All traffic within the VPC (e.g., `10.0.0.0/16`) for pod communication.
     - **SSH**: TCP 22 from your IP for access.
     - Reference: [Kubernetes Ports](https://kubernetes.io/docs/reference/networking/ports-and-protocols/).

2. **Verify Setup**:
   - SSH into each instance: `ssh -i <key.pem> ubuntu@<public-ip>`.
   - Confirm private IPs: `ip addr show`.
   - Ensure unique MAC and UUID:
     ```bash
     ip link show | grep ether
     sudo cat /sys/class/dmi/id/product_uuid
     ```

---

## Step 2: Configure the Base OS on All Nodes

Prepare each node’s operating system to meet Kubernetes requirements, including disabling swap, setting hostnames, and enabling networking.

1. **Update OS and Install Tools**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y net-tools
   ```

2. **Disable Swap**:
   Kubernetes requires swap to be disabled to ensure predictable performance.
   ```bash
   # Disable swap immediately
   sudo swapoff -a
   # Remove swap entries from fstab
   sudo sed -i '/\s\+swap\s\+/d' /etc/fstab
   # Verify swap is disabled
   free -h | grep Swap
   ```
   **Expected Output**:
   ```
   Swap:          0B          0B          0B
   ```

#### Explanation:
- `\s\+` → Matches **one or more whitespace characters**.
- `swap` → Looks for the word **"swap"**.
- `\s\+` → Ensures **"swap" is surrounded by whitespace**.
- `/d` → **Deletes matching lines**.

#### Effect:
- It **removes only lines where "swap" appears with spaces around it**, ensuring it targets properly formatted swap entries.
- This leaves other lines in fstab unaffected.
- This is a safe operation as it only removes lines that match the specified pattern.
#### Purpose:
- This removes any swap entries from `/etc/fstab`, which prevents the system from mounting swap partitions or swap files on boot.

3. **Set Unique Hostnames**:
   Assign descriptive hostnames to each node for clarity.
   ```bash
   # On k8s-master-1
   sudo hostnamectl set-hostname k8s-master-1
   # On k8s-master-2
   sudo hostnamectl set-hostname k8s-master-2
   # On k8s-worker-1, etc.
   sudo hostnamectl set-hostname k8s-worker-1
   ```

4. **Configure /etc/hosts (Optional)**:
   Add entries for node resolution without a DNS server.
   ```bash
   sudo nano /etc/hosts
   ```
   Add:
   ```
   127.0.0.1 localhost
   10.0.138.123 k8s-master-1
   10.0.138.124 k8s-master-2
   10.0.138.125 k8s-worker-1
   10.0.138.126 k8s-worker-2
   ```
   Verify: `ping k8s-master-1`.

---

## Step 3: Install Kubernetes Dependencies on All Nodes

Install `kubeadm`, `kubelet`, and `kubectl` to bootstrap and manage the cluster. Ensure version consistency (v1.32.2) across components.

- `kubeadm`: the command to bootstrap the cluster.

- `kubelet`: the component that runs on all of the machines in your cluster and does things like starting pods and containers.

- `kubectl`: the command line utility to talk to your cluster.

> `kubeadm` will not install or manage `kubelet` or `kubectl` for you, so you will need to ensure they match the version of the Kubernetes control plane you want kubeadm to install for you.
> `kubeadm` will install all of the necessary kubernetes components, except `kubelet`. That's why you need to install `kubelet` separately.

1. **Add Kubernetes Repository**:
   ```bash
   sudo apt update
   sudo apt install -y apt-transport-https ca-certificates curl gpg
   sudo mkdir -p -m 755 /etc/apt/keyrings
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
   ```

2. **Install Kubernetes Components**:
   ```bash
   sudo apt update
   # sudo apt install -y kubelet=1.32.2-1.1 kubeadm=1.32.2-1.1 kubectl=1.32.2-1.1
   sudo apt-get install -y kubelet kubeadm kubectl
   sudo apt-mark hold kubelet kubeadm kubectl
   ```

3. **Verify Installation**:
   ```bash
   kubeadm version
   kubectl version --client
   kubelet --version
   ```
   **Expected Output** (partial):
   ```
   kubeadm version: &version.Info{Major:"1", Minor:"32", GitVersion:"v1.32.2", ...}
   ```
   **Verify** `sudo ls /etc/kubernetes/manifests/` to ensure the `kubelet` configuration files are not yet present.

   **Verify** `sudo systemctl status kubelet` to ensure the `kubelet` service is not yet running.

---

## Step 4: Install and Configure Containerd on All Nodes

Kubernetes uses **containerd** as the container runtime via the Container Runtime Interface (CRI).

1. **Install Containerd**:
   ```bash
   sudo apt update
   sudo apt install -y containerd
   ```

2. **Configure Containerd**:
   Ensure containerd uses `systemd` as the cgroup driver and OverlayFS for storage.
   ```bash
   sudo mkdir -p /etc/containerd
   containerd config default | sudo tee /etc/containerd/config.toml
   sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
   sudo sed -i 's/snapshotter = ".*"/snapshotter = "overlayfs"/' /etc/containerd/config.toml
   ```

3. **Enable and Start Containerd**:
   ```bash
   sudo systemctl restart containerd
   sudo systemctl enable containerd
   sudo systemctl status containerd
   ```
   **Expected Output**: `Active: active (running)`.

> **ONE Command Solution**: Head over again to **[infra-bootstrap](https://github.com/ibtisam-iq/infra-bootstrap)** to install and configure containerd on all nodes with a single command.

---

## Step 5: Configure Kubernetes Networking on All Nodes

Enable kernel modules and sysctl settings for Kubernetes networking.

1. **Load Kernel Modules**:
   ```bash
   cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
   overlay
   br_netfilter
   EOF
   sudo modprobe overlay
   sudo modprobe br_netfilter
   ```

2. **Configure Sysctl Parameters**:
   ```bash
   cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
   net.bridge.bridge-nf-call-iptables  = 1
   net.bridge.bridge-nf-call-ip6tables = 1
   net.ipv4.ip_forward                 = 1
   EOF
   sudo sysctl --system
   ```

3. **Verify Settings**:
   ```bash
   sysctl net.bridge.bridge-nf-call-iptables
   sysctl net.bridge.bridge-nf-call-ip6tables
   sysctl net.ipv4.ip_forward
   ```
   **Expected Output**:
   ```
   net.bridge.bridge-nf-call-iptables = 1
   net.ipv4.ip_forward = 1
   ```

📌 **Explanation**
- ✅ overlay – Needed for container storage 
- ✅ br_netfilter – Required for Kubernetes networking (so iptables sees bridged traffic).
- ✅ net.bridge.bridge-nf-call-iptables = 1 – Ensures Kubernetes networking works properly.
- ✅ net.bridge.bridge-nf-call-ip6tables = 1 – Same, but for IPv6.
- ✅ net.ipv4.ip_forward = 1 – Enables packet forwarding, mandatory for Kubernetes networking.

---

## Step 6: Initialize the Control Plane

Initialize the first control plane node using `kubeadm init`, setting up the cluster with Calico networking.

1. **Pre-Checks**:
   ```bash
   sudo swapoff -a
   sudo systemctl start containerd kubelet
   sudo netstat -tulnp | grep 6443  # Ensure port 6443 is free
   systemctl is-active "kubelet"    # kubelet is activating, becuase it requires configuration, which is done by kubeadm init
   kubeadm config images pull
   ```
   
2. **Run kubeadm init**:
   Use your control plane’s private IP and Calico’s pod CIDR.
   ```bash
   sudo kubeadm init \
     --control-plane-endpoint "10.0.138.123:6443" \ # Replace with your control plane's private IP
     --upload-certs \
     --pod-network-cidr=10.244.0.0/16 \
     --apiserver-advertise-address=10.0.138.123 \   # Replace with your control plane's private IP
     --node-name=k8s-master-1 \
     --cri-socket=unix:///var/run/containerd/containerd.sock
   ```

3. **Understand the Flags**:
   - `--control-plane-endpoint`: Stable API server endpoint for HA (supports DNS or load balancer).
   - `--upload-certs`: Shares certificates for additional control planes.
   - `--pod-network-cidr`: Sets Calico’s pod IP range (`10.244.0.0/16`).
   - `--apiserver-advertise-address`: Control plane’s private IP.
   - `--node-name`: Unique node name.
   - `--cri-socket`: Specifies containerd’s CRI socket.
   - Click [here](kubeadm-init-flags-and-kind-config.md) for more information on `kubeadm init` flags.

4. **Save Join Commands**:
   The output includes `kubeadm join` commands for control planes and workers. Save them:
   ```
   kubeadm join 10.0.138.123:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --control-plane --certificate-key <key>
   kubeadm join 10.0.138.123:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
   ```

⚙️ **Ever wondered what black magic unfolds behind the curtain when you run `kubeadm init`?**  

It’s not just a command — it’s a symphony of components, certificates, manifests, and networking dances happening in perfect sync.

👉 [Peek behind the scenes](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/00-cluster-setup/kubeadm-init-working.md#-what-happens-when-you-run-kubeadm-init) and witness how your Kubernetes control plane is born, one daemon and one API handshake at a time.

---

## Step 7: Configure kubectl Access

Enable `kubectl` to interact with the cluster from the control plane node.

### What this means?
After initialization, your Kubernetes cluster is running, but you need to configure your `kubectl` command to interact with the cluster.

### Why is this needed?
- The Kubernetes control plane stores its credentials in `/etc/kubernetes/admin.conf`.
- By default, only root can access it.
- You need to copy and set the permissions properly so that your non-root user can use `kubectl` without issues. So, follow this step on your control plane node or any other node where you want to use `kubectl`.

1. **Set Up [kubeconfig](kubeconfig-setup.md)**:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

2. **Verify Access**:
   ```bash
   kubectl get nodes
   ```
   **Expected Output**:
   ```
   NAME           STATUS   ROLES           AGE   VERSION
   k8s-master-1   Ready    control-plane   5m    v1.32.2
   ```

---

## Step 8: Install Calico CNI

Deploy Calico to enable pod networking, matching the `--pod-network-cidr`.

1. **Download and Configure Calico**:
   ```bash
   curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
   ```
   Edit `calico.yaml` to set the CIDR:
   ```yaml
   - name: CALICO_IPV4POOL_CIDR
     value: "10.244.0.0/16"
   ```

2. **Apply Calico**:
   ```bash
   kubectl apply -f calico.yaml
   ```

3. **Verify Calico**:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=calico-node
   ```
   **Expected Output**: All pods in `Running` state.

> Click [here](cni-plugin-installation.md) to learn more about CNI plugins.

---

## Step 9: Join Additional Control Planes (Optional)

For high availability, add more control plane nodes.

1. **Run kubeadm join** (on `k8s-master-2`):
   ```bash
   sudo kubeadm join 10.0.138.123:6443 \
     --token <token> \
     --discovery-token-ca-cert-hash sha256:<hash> \
     --control-plane \
     --certificate-key <key> \
     --node-name=k8s-master-2 \
     --cri-socket=unix:///var/run/containerd/containerd.sock
   ```

2. **Verify**:
   ```bash
   kubectl get nodes
   ```

---

## Step 10: Join Worker Nodes

Add worker nodes to run workloads. Worker nodes don't manage the cluster; they just run workloads.

1. **Run kubeadm join** (on `k8s-worker-1`, `k8s-worker-2`):
   ```bash
   sudo kubeadm join 10.0.138.123:6443 \
     --token <token> \
     --discovery-token-ca-cert-hash sha256:<hash> \
     --node-name=k8s-worker-<1 or 2> \
     --cri-socket=unix:///var/run/containerd/containerd.sock
     # No `--control-plane` flag is needed since these are just worker nodes.
   ```

2. **Verify**:
   ```bash
   kubectl get nodes
   ```
   **Expected Output**:
   ```
   NAME           STATUS   ROLES           AGE   VERSION
   k8s-master-1   Ready    control-plane   10m   v1.32.2
   k8s-worker-1   Ready    <none>          2m    v1.32.2
   k8s-worker-2   Ready    <none>          1m    v1.32.2
   ```

---

## Step 11: Secure Certificates

Certificates are sensitive and expire after 2 hours. Regenerate if needed:
```bash
sudo kubeadm init phase upload-certs --upload-certs
```
Store the new `--certificate-key` securely.

---

## Step 12: Verify Cluster Health

Confirm the cluster is operational.

1. **Check Nodes**:
   ```bash
   kubectl get nodes -o wide
   ```

2. **Check Pods**:
   ```bash
   kubectl get pods -n kube-system -o wide
   ```
   **Expected Output**: All pods (e.g., `calico-node`, `coredns`, `kube-apiserver`) in `Running` state.

3. **Test Networking**:
   Deploy a sample pod:
   ```bash
   kubectl run nginx --image=nginx --port=80
   kubectl expose pod nginx --type=NodePort
   ```
   Find the NodePort:
   ```bash
   kubectl get svc nginx
   ```
   Access: `http://<worker-ip>:<nodeport>`.

---

## Troubleshooting

1. **Cluster Initialization Fails**:
   - **Fix**: Check logs:
     ```bash
     sudo journalctl -u kubelet
     ```
     Ensure swap is disabled, containerd is running, and ports are open.

2. **Nodes Not Joining**:
   - **Fix**: Verify token and hash. Regenerate token if expired:
     ```bash
     kubeadm token create --print-join-command
     ```

3. **Calico Pods Not Running**:
   - **Fix**: Confirm `CALICO_IPV4POOL_CIDR` matches `--pod-network-cidr`:
     ```bash
     kubectl get ippool -o yaml
     ```
     Check logs:
     ```bash
     kubectl logs -n kube-system -l k8s-app=calico-node
     ```

4. **kubectl Access Issues**:
   - **Fix**: Verify kubeconfig:
     ```bash
     cat $HOME/.kube/config
     ```

---

## Best Practices

- **Backup Certificates**: Store `/etc/kubernetes/pki/` securely.
- **Use Version Control**: Pin `kubeadm`, `kubelet`, `kubectl` to the same version (e.g., `1.32.2-1.1`).
- **Monitor Security Groups**: Restrict ports to trusted IPs where possible.
- **Automate Setup**: Use tools like Ansible for multi-node deployments.
- **Regular Updates**: Keep Ubuntu and Kubernetes components updated.

---

## Conclusion

You’ve successfully deployed a Kubernetes cluster using kubeadm, complete with a Calico CNI and optional HA control planes. This guide, tailored to your setup with `pod-network-cidr=10.244.0.0/16` and Ubuntu 24.04, ensures a robust and scalable cluster. Explore advanced features like network policies with Calico or deploy workloads to test your cluster’s capabilities.