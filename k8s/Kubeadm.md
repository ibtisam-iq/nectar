# Set up Kubernetes Cluster using Kubeadm

## Prerequisits:

- A compatible Linux host
- 2 GB or more of RAM per machine
- 2 CPUs or more for control plane machines
- Full network connectivity between all machines in the cluster (public or private network is fine)
- Unique hostname, MAC address, and product_uuid for every node.
- Certain ports are open on your machines.
- [Official Kubeadm Installation Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

---

## 🚀 One Command to Set Up Your Kubernetes Control Plane!

Tired of long, complicated setup processes? **Run your Kubernetes control plane effortlessly** with just **ONE** command! Sit back, grab a coffee ☕, and watch the magic unfold! ✨

### ❓ Do you have an EC2 instance ready with the required security group ports open?

Before running the command, ensure you have a **t2.medium Ubuntu EC2 instance** with the necessary ports open in your security group. See [here](https://kubernetes.io/docs/reference/networking/ports-and-protocols/) for the required ports.

```bash
curl -sL https://raw.githubusercontent.com/ibtisam-iq/SilverInit/main/K8s-Control-Plane-Init.sh | bash
```

💡 No hassle. No manual steps. Just pure automation!
⚡ Get your K8s control plane up and running in minutes!
👉 Run it now and witness Kubernetes initialization like never before! 🚀

🌸 *A flower never competes with its neighbor. It just blooms. So, be like a flower that gives its fragrance even to the hand that crushes it*. 🌸

---

## Get Started

### 🔹 Step 1: AWS EC2 Machines Setup

1️⃣ **Create EC2 Instances**

- **Instance Type:** t2.medium (2 vCPU, 4GB RAM)
- **OS:** Ubuntu 22.04 LTS (recommended)
- **Storage:** 20GB disk (minimum)
- **Networking:** Attach same VPC & Security Group to all instances

**Example:**

| Instance Name | Private IP   | Role          |
|---------------|--------------|---------------|
| k8s-master-1  | 192.168.1.10 | Control Plane |
| k8s-master-2  | 192.168.1.11 | Control Plane |
| k8s-worker-1  | 192.168.1.20 | Worker Node   |
| k8s-worker-2  | 192.168.1.21 | Worker Node   |
| k8s-worker-3  | 192.168.1.22 | Worker Node   |

2️⃣ **Configure Security Group (SG)**

Follow the official guide [here](https://kubernetes.io/docs/reference/networking/ports-and-protocols/) to open the specific ports for Kubernetes components.

---

### 🔹 Step 2: Setup Base OS Configurations on All Nodes

1️⃣ **Update OS & Disable Swap**

The default behavior of a kubelet is to fail to start if swap memory is detected on a node. This means that swap should either be disabled or tolerated by kubelet.

```bash
# Update OS
sudo apt update && sudo apt install -y net-tools

# Disable Swap immediately (Without Rebooting)
sudo swapoff -a

# Check if Swap is Disabled, run any of the following commands: 
sudo swapon --summary   # Should be empty
free -h                 # If swap is 0B, it is disabled
lsblk | grep swap       # Should not show any swap partitions
```

**Edit fstab to persist swap disable even after reboot**

```bash
sudo sed -i '/\s\+swap\s\+/d' /etc/fstab
```
OR

Open fstab in a text editor and either delete swap line or comment it out like:
```bash
# UUID=6759eaaa-01cf-4c33-a802-6e7d1bb5bd83 none swap sw 0 0
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

2️⃣ **Set Unique Hostnames**

There are two ways to set a unique hostname on each node:

- **Method 1: Using hostnamectl command**
```bash
sudo hostnamectl set-hostname k8s-master-1   # Control Plane 1
sudo hostnamectl set-hostname k8s-master-2   # Control Plane 2
sudo hostnamectl set-hostname k8s-worker-1   # Worker Node 1
sudo hostnamectl set-hostname k8s-worker-2   # Worker Node 2
sudo hostnamectl set-hostname k8s-worker-3   # Worker Node 3
```

- **Method 2: Using hostname command**

You can set it by editing the hostname file and then run `sudo init 6` to apply the changes. However, this method is not recommended as it can cause issues with the system's ability to automatically configure the hostname.

3️⃣ **Set Hostnames in /etc/hosts for DNS resolution (Optional step)**

If you want to be able to resolve the hostnames of your nodes without a DNS server, you can add the following lines to the hosts file on each node:

```bash
127.0.0.1   localhost

# Control Plane Nodes
192.168.1.100 k8s-master-1
192.168.1.101 k8s-master-2

# Worker Nodes
192.168.1.102 k8s-worker-1
192.168.1.103 k8s-worker-2
192.168.1.104 k8s-worker-3
```
> Replace the IP addresses with the actual IP addresses (private) of your nodes.

Now, check `ping k8s-master-1` for example to see if the hostname is correctly resolved on any node.

4️⃣ **Verify the MAC address and product_uuid are unique for every node**

You can verify the MAC address and product_uuid of each node by running the following commands:

```bash
ip link show
ifconfig -a
sudo cat /sys/class/dmi/id/product_uuid
```

---

### 🔹 Step 3: Install Kubernetes Dependencies on All Nodes
You will install these packages on all of your machines:

- `kubeadm`: the command to bootstrap the cluster.

- `kubelet`: the component that runs on all of the machines in your cluster and does things like starting pods and containers.

- `kubectl`: the command line util to talk to your cluster.

> `kubeadm` will not install or manage `kubelet` or `kubectl` for you, so you will need to ensure they match the version of the Kubernetes control plane you want kubeadm to install for you.
> `kubeadm` will install all of the necessary kubernetes components, except `kubelet`. That's why you need to install `kubelet` separately.

```bash
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubelet --version
kubectl version --client
```
#### Step 3 Result

```text
ubuntu@ip-172-31-17-2:~$ sudo ls /etc/kubernetes/
manifests

ubuntu@ip-172-31-17-2:~$ sudo ls /etc/kubernetes/manifests/

ubuntu@ip-172-31-17-2:~$ ls -lah /etc/kubernetes/
ls -lah /var/lib/etcd

total 12K
drwxrwxr-x   3 root root 4.0K Mar 18 18:41 .
drwxr-xr-x 114 root root 4.0K Mar 18 18:41 ..
drwxrwxr-x   2 root root 4.0K Mar 18 18:41 manifests
ls: cannot access '/var/lib/etcd': No such file or directory

ubuntu@ip-172-31-17-2:~$ sudo systemctl status kubelet
○ kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: inactive (dead)
       Docs: https://kubernetes.io/docs/

ubuntu@ip-172-31-17-2:~$ sudo systemctl status containerd
● containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: active (running) since Tue 2025-03-18 18:41:53 UTC; 27min ago
       Docs: https://containerd.io
    Process: 5787 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
   Main PID: 5788 (containerd)
      Tasks: 8
     Memory: 27.2M (peak: 36.7M)
        CPU: 2.039s
     CGroup: /system.slice/containerd.service
             └─5788 /usr/bin/containerd
```
---

### 🔹 Step 4: Install Container Runtime (containerd) on All Nodes
- To run containers in Pods, Kubernetes uses a container runtime.

- By default, Kubernetes uses the Container Runtime Interface (CRI) to interface with your chosen container runtime.

- There are several container runtimes available, but a few of them are supported only by Kubernetes. We will use `containerd` here.

- Please follow the steps to install `containerd` [here]().
- [Official Documentation](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

---

### 🔹 Step 5: Setting up Kubernetes (after containerd is installed) on All Nodes
Once `containerd` is running, Kubernetes requires additional networking configurations.

```bash
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
```

📌 **Explanation**
- ✅ overlay – Needed for container storage 
- ✅ br_netfilter – Required for Kubernetes networking (so iptables sees bridged traffic).
- ✅ net.bridge.bridge-nf-call-iptables = 1 – Ensures Kubernetes networking works properly.
- ✅ net.bridge.bridge-nf-call-ip6tables = 1 – Same, but for IPv6.
- ✅ net.ipv4.ip_forward = 1 – Enables packet forwarding, mandatory for Kubernetes networking.

---

### 🔹 Step 6: Initialize Control Plane
`kubeadm init` is the command used to initialize a Kubernetes control plane.

#### 📌 What Happens When You Run `kubeadm init`?

**1️⃣ Pre-checks**
- Ensures the system is ready by checking firewall, swap, network settings, etc.
- Verifies if the required ports are open.
- Confirms that necessary system components (like `containerd`) are running.

**2️⃣ Generates Certificates**
- Creates TLS certificates for API Server authentication.
- Stores them in `/etc/kubernetes/pki/`.
- Ensures secure communication within the cluster.

**3️⃣ Configures the Control Plane**
- Deploys the API Server, Controller Manager, and Scheduler as static pods.
- These static pod manifests are located in `/etc/kubernetes/manifests/`.
- Runs these pods under `kubelet`.

**4️⃣ Sets up Networking**
- Enables `iptables` rules for networking.
- Configures network policies for the cluster.

**5️⃣ Creates the `admin.conf` File**
- Allows `kubectl` to communicate with the cluster.
- Located at `/etc/kubernetes/admin.conf`.
- Must be copied to the user’s home directory for easy access.

**6️⃣ Outputs `kubeadm join` Command**
- This command is used to add worker nodes to the cluster.
- The output resembles the following:

  ```bash
  kubeadm join <master-ip>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
  ```

#### Just before `kubeadm init`

```bash
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
kubeadm config images pull
```

Let’s run the `kubeadm init` command to initialize the control plane:

```bash
sudo kubeadm init \
  --control-plane-endpoint "10.0.138.123:6443" \ # Replace with your master node's Private IP address
  --upload-certs \ 
  --pod-network-cidr=10.244.0.0/16 \ # Replace with your desired pod network CIDR
  --apiserver-advertise-address=10.0.138.123 \ # Replace with your master node's Private IP address
  --node-name=master-node \ # Replace with your desired node name
  --cri-socket=unix:///var/run/containerd/containerd.sock 
```
📌 **Explanation**

`--control-plane-endpoint`:
- This is the endpoint that the control plane will listen on.
- Defines a stable IP/DNS for the control plane. Use this when setting up HA (High Availability) with multiple control plane nodes.

`--upload-certs`:
- Automatically uploads control plane certificates, allowing other control plane nodes to join easily. 
- Even though if you have one control plane, this ensures you can add more control planes in the future without manually handling certificates.

`--pod-network-cidr`:
- Necessary for setting up the pod network (like Flannel or Calico).
- Defines the IP (network) range for pods within the cluster.
- Flannel network range: `10.244.0.0/16`
- Calico network range: `192.168.0.0/16`
- You can change this to whatever you want, but it must be a valid IP range.

`--cir-socket`:
- This is the path to the cri socket.
- It is auto-detected by kubeadm, but you can specify it if you have a custom setup.
- Its value varies depending on the container runtime you are using (e.g., containerd).
- For containerd, it is `unix:///var/run/containerd/containerd.sock`.

> **Note:** Please find the official documentation for the `kubeadm commands` [here](https://kubernetes.io/docs/reference/setup-tools/kubeadm/).

```
[init] Using Kubernetes version: v1.32.2
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
W0311 22:52:37.409918   17086 checks.go:846] detected that the sandbox image "registry.k8s.io/pause:3.8" of the container runtime is inconsistent with that used by kubeadm.It is recommended to use "registry.k8s.io/pause:3.10" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-master kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.0.138.123]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s-master localhost] and IPs [10.0.138.123 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s-master localhost] and IPs [10.0.138.123 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "super-admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests"
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 1.000880348s
[api-check] Waiting for a healthy API server. This can take up to 4m0s
[api-check] The API server is healthy after 5.001750334s
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
636ec4f5119f8938b5807aa6158b40699ba8e3f156cb6fbfac9cbc20a4d75a19
[mark-control-plane] Marking the node k8s-master as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8s-master as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: 3dd81p.dsq98vpo4vnwi9gk
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes running the following command on each as root:

  kubeadm join 10.0.138.123:6443 --token 3dd81p.dsq98vpo4vnwi9gk \
	--discovery-token-ca-cert-hash sha256:3a0e53edb48f871e04ca34c5abebcf258b74bce63b1f130d7a79690a5bbd45b4 \
	--control-plane --certificate-key 636ec4f5119f8938b5807aa6158b40699ba8e3f156cb6fbfac9cbc20a4d75a19

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.138.123:6443 --token 3dd81p.dsq98vpo4vnwi9gk \
	--discovery-token-ca-cert-hash sha256:3a0e53edb48f871e04ca34c5abebcf258b74bce63b1f130d7a79690a5bbd45b4 
```

---

## Post Control Plane Initialization Steps

### 📌 Step 1: Setting Up `kubectl` Access

### What this means?
After initialization, your Kubernetes cluster is running, but you need to configure your `kubectl` command to interact with the cluster.

### Why is this needed?
- The Kubernetes control plane stores its credentials in `/etc/kubernetes/admin.conf`.
- By default, only root can access it.
- You need to copy and set the permissions properly so that your non-root user can use `kubectl` without issues. So, follow this step on your control plane node or any other node where you want to use `kubectl`.

### Commands & Explanation:
```bash
# Create the kubeconfig directory in your home folder
mkdir -p $HOME/.kube

# Copy the cluster config to your user directory  
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Change the file ownership to your user  
sudo chown $(id -u):$(id -g) $HOME/.kube/config  
```

✅ After running these, you will be able to use `kubectl` to manage your cluster.
✅ You need to run this step on each machine that will use `kubectl` to interact with your cluster.

### Alternative: If you are logged in as root, you can just set the environment variable instead:
```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```
(This avoids copying and changing permissions, but it's temporary and needs to be re-run on every new shell session.)

---

### 📌 Step 2: Installing a CNI (Pod Network)

CNI (Container Network Interface) is just a standard (a set of specifications) that defines how networking should be implemented in containerized environments. It doesn't provide networking itself.

#### CNI Plugin:
A CNI plugin is an actual implementation of the CNI standard. Calico, Flannel, Cilium, Weave, etc., are CNI plugins that follow the CNI specification to provide networking for Kubernetes clusters.

#### Example of CNI Plugins

| CNI Plugin | Networking Model | Key Features |
|------------|-------------------|--------------|
| Calico     | Layer 3 (Routing) | Network policies, BGP support, security-focused |
| Flannel    | Layer 2 (Overlay) | Simple, lightweight, uses VXLAN or host-gw |
| Cilium     | eBPF-based        | Highly scalable, security-focused, service mesh integration |
| Weave      | Layer 2 (Overlay) | Simpler than Calico, automatic peer discovery |

#### CNI Interface:
- The CNI (Container Network Interface) interface is a standardized API that allows Kubernetes (or any container runtime) to communicate with networking plugins. 
- nIt acts as a bridge between the container runtime (like containerd or CRI-O) and networking solutions (like Calico, Flannel, etc.). 
- In Kubernetes, the **CNI interface** is typically located at: `/etc/cni/net.d/`.

#### How It Works

1️⃣ **Kubernetes (Kubelet) needs to create a pod**

- It calls the container runtime (e.g., containerd).

2️⃣ **Container runtime requests network setup**

- The runtime calls the CNI interface, passing details like pod name, namespace, and container ID.

3️⃣ **CNI Interface triggers the configured CNI plugin**

- This could be Calico, Flannel, Cilium, etc.

4️⃣ **CNI Plugin configures networking**

- It sets up interfaces, IPs, routes, and any necessary firewall rules for the pod.

5️⃣ **Networking is ready**

- The pod gets connected to the cluster network.

### Summary

- Kubernetes does not automatically set up networking for pods.
- You need to deploy a CNI (Container Network Interface) plugin like Calico or Flannel.
- Without a CNI, your pods won't be able to communicate with each other.
- You should choose that CNI of which CIDR range you set in the `--pod-network-cidr` flag while initializing the control plane above.
- Please find the [official documentation](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy) for which CNI plugin you choose to use.

#### Flannel CNI:
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

#### Calico CNI:
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```
✅ Only run this **ONCE** on the first control plane.
✅ Now pods can start communicating across the cluster.

---

## 📌 Step 3: Joining Additional Control Planes (HA Cluster)

### What this means?
- You currently have one control plane (master node).
- If you want High Availability (HA), you can add more control planes.
- The command shown in the output will add more control plane nodes to the cluster.

### Command & Explanation:
```bash
sudo kubeadm join 10.0.138.123:6443 --token 3dd81p.dsq98vpo4vnwi9gk \
    --discovery-token-ca-cert-hash sha256:3a0e53edb48f871e04ca34c5abebcf258b74bce63b1f130d7a79690a5bbd45b4 \
    --control-plane --certificate-key 636ec4f5119f8938b5807aa6158b40699ba8e3f156cb6fbfac9cbc20a4d75a19
```

### Explanation of Each Flag:
- `10.0.138.123:6443` → This is the API server endpoint of the current control plane.
- `--token 3dd81p.dsq98vpo4vnwi9gk` → This token is required for new nodes to join the cluster.
- `--discovery-token-ca-cert-hash sha256:...` → Ensures the new node is joining the correct cluster.
- `--control-plane` → This tells Kubernetes that this node is also a control plane (not just a worker).
- `--certificate-key ...` → Used to securely share certificates between control planes.

✅ Run this command on any new control plane nodes to make them part of the cluster.
⚠ This is only needed if you're adding more control planes!

---

## 📌 Step 4: Joining Worker Nodes

### What this means?
- To actually run workloads (pods, services), you need worker nodes.
- Worker nodes don't manage the cluster; they just run containers.
- You use a simpler join command for them.

### Command & Explanation:
```bash
sudo kubeadm join 10.0.138.123:6443 --token 3dd81p.dsq98vpo4vnwi9gk \
    --discovery-token-ca-cert-hash sha256:3a0e53edb48f871e04ca34c5abebcf258b74bce63b1f130d7a79690a5bbd45b4
```

### Explanation of Each Flag:
- `10.0.138.123:6443` → API server of the control plane.
- `--token 3dd81p.dsq98vpo4vnwi9gk` → Required authentication token.
- `--discovery-token-ca-cert-hash sha256:...` → Ensures the node is joining the correct cluster.

✅ Run this command on each worker node to join them to the cluster.
✅ No `--control-plane` flag is needed since these are just worker nodes.

---

## 📌 Step 5: Keeping Certificates Secure

### What this means?
- Kubernetes uses TLS certificates to secure cluster communication.
- The `--certificate-key` used earlier is very sensitive and should be kept secret.
- Certificates expire after 2 hours for security reasons.

### How to regenerate certificates if needed?
```bash
kubeadm init phase upload-certs --upload-certs
```
This will generate a new certificate key so you can add new control plane nodes later.

---

## 📌 Final Checklist (After `kubeadm init`)
✅ Run the `kubectl` setup commands to start using the cluster.
✅ Apply a CNI plugin (Flannel or Calico) to enable networking.
✅ Join additional control planes (if needed) using the provided command.
✅ Join worker nodes using the provided `kubeadm join` command.
✅ Verify the cluster status using:

```bash
kubectl get nodes
kubectl get pods -n kube-system
```
🚀 Your Kubernetes cluster is now set up! 🎯

---

🔍 **Analysis of Cluster Status**

📌 **1. kubectl get all Output**

```
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   19m
```

✅ **What This Means:**
- Only one service (**kubernetes**) is running.
- This is the **API Server service** that allows `kubectl` to communicate with the cluster.
- It is assigned a **ClusterIP (10.96.0.1)**, meaning it is accessible only within the cluster.
- No other services or workloads are running yet.

---

📌 **2. kubectl get pods -n kube-system Output**

You have multiple pods running in the **kube-system** namespace.

| **Pod Name**                               | **Status** | **Role**                      |
|--------------------------------------------|-----------|--------------------------------|
| calico-kube-controllers-7498b9bb4c-swhbg   | ✅ Running | Manages Calico CNI            |
| coredns-668d6bf9bc-dsqc4                   | ✅ Running | DNS resolution                |
| coredns-668d6bf9bc-k8m7m                   | ✅ Running | DNS resolution                |
| etcd-k8s-master                            | ✅ Running | Stores cluster state          |
| kube-apiserver-k8s-master                  | ✅ Running | Handles API requests          |
| kube-controller-manager-k8s-master         | ✅ Running | Manages controllers           |
| kube-scheduler-k8s-master                  | ✅ Running | Schedules pods                |
| kube-proxy-2mpvh                           | ✅ Running | Network routing               |
| kube-proxy-mvqdp                           | ✅ Running | Network routing               |
| kube-proxy-p888w                           | ✅ Running | Network routing               |

✅ **These are critical system components that are working properly.**

