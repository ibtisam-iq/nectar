`kubeadm init` is the command used to initialize a Kubernetes control plane.

---

### **Will the Kubelet Service Run Before `kubeadm init`?**

Let’s break down the behavior of the **kubelet** and **containerd** services when started prior to `kubeadm init`, focusing on your setup (Ubuntu 24.04, containerd, Kubernetes v1.32).

#### **1. Containerd Service**
- **Behavior**:
  - **Containerd** is the container runtime you’ve chosen (aligned with `--cri-socket=/var/run/containerd/containerd.sock` in your `kubeadm init`).
  - Running `sudo systemctl start containerd` starts the containerd daemon, which manages container lifecycles (e.g., pulling images, creating containers).
  - Containerd operates independently of `kubeadm init` and does not require Kubernetes-specific configurations to run.
  - **Status**: When you execute:
    ```bash
    sudo systemctl start containerd
    ```
    Containerd starts successfully and remains running, listening on its socket (e.g., `/var/run/containerd/containerd.sock`).
  - **Verification**:
    ```bash
    systemctl is-active containerd
    ```
    **Output**: `active`
    ```bash
    ss -x | grep containerd
    ```
    **Output**: Shows the socket `/var/run/containerd/containerd.sock`.
- **Correctness**: Starting containerd before `kubeadm init` is **correct** and necessary, as `kubeadm init` relies on containerd to pull and run Kubernetes component images (e.g., `kube-apiserver`).
- **In Your Setup**: Your confidence that containerd is running is well-founded, and this step aligns with your guide’s pre-checks.

#### **2. Kubelet Service**
- **Behavior**:
  - The **kubelet** is Kubernetes’ node agent, responsible for managing pods on a node, communicating with the API server, and interacting with the container runtime (containerd in your case).
  - Kubelet requires a configuration to function properly, including:
    - A kubeconfig file (e.g., `/etc/kubernetes/kubelet.conf`) to authenticate with the API server.
    - A bootstrap kubeconfig (e.g., `/etc/kubernetes/bootstrap-kubelet.conf`) or a node configuration from `kubeadm init`.
  - **Before `kubeadm init`**:
    - `kubeadm init` has not yet run, so no Kubernetes cluster exists, and critical files like `/etc/kubernetes/kubelet.conf` or `/etc/kubernetes/bootstrap-kubelet.conf` are **not present**.
    - When you run:
      ```bash
      sudo systemctl start kubelet
      ```
      Kubelet starts but immediately enters a **crash-loop** because it cannot:
        - Connect to the API server (no cluster, no kubeconfig).
        - Find a valid node configuration.
    - **Logs**: Checking kubelet logs confirms this:
      ```bash
      journalctl -u kubelet
      ```
      **Sample Output**:
      ```
      kubelet[1234]: E0418 12:00:00.123456   1234 kubelet.go:123] "Failed to run kubelet" err="failed to load Kubelet config file /var/lib/kubelet/config.yaml, error: open /var/lib/kubelet/config.yaml: no such file or directory"
      kubelet[1234]: E0418 12:00:00.123789   1234 server.go:456] "Failed to run kubelet" err="failed to initialize kubelet: node not found"
      ```
      Kubelet restarts repeatedly (due to systemd’s `Restart=always`) until `kubeadm init` provides the necessary configuration.
  - **Status**: Kubelet **will not run successfully** before `kubeadm init`. It starts but crashes, as your original note correctly observed:
    ```markdown
    > Since `kubeadm init` is not run, and kubelet needs a valid configuration to work, it keeps crashing and restarting.
    ```
---

## 📌 What Happens When You Run `kubeadm init`?

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

---

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

---

```text
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

