# Cluster Setup and Configuration

Setting up a Kubernetes cluster involves configuring control plane components (API server, controller manager, scheduler) and ensuring proper node networking. This guide categorizes tools and methods for creating Kubernetes clusters by different use case, providing detailed steps, prerequisites, and verification for each. Whether for local testing, self-managed infrastructure, or managed cloud solutions, understanding these options helps you choose the right approach.

## Table of Contents
1. Local Testing and Development
2. Self-Managed Clusters
3. Managed Control Plane (Hosted Solutions)
4. Hybrid and Edge Options
5. Tool Comparison
6. Troubleshooting Common Issues

---

## 1. Local Testing and Development

These tools are ideal for developers, testers, or learners running Kubernetes locally.

### Minikube
- **Description**: A lightweight tool for running a single-node Kubernetes cluster on a laptop or desktop. Supports hypervisors like VirtualBox, HyperKit, or Docker.
- **Use Case**: Development, testing, or learning Kubernetes basics.
- **Prerequisites**:
  - Hypervisor (e.g., Docker, VirtualBox)
  - 4GB RAM, 2 CPUs, 20GB disk
  - `kubectl`
- **Setup**:
  ```bash
  minikube start
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  minikube status
  ```

### Kind (Kubernetes in Docker)
- **Description**: Runs multi-node Kubernetes clusters inside Docker containers, ideal for CI/CD pipelines, local testing, or simulating production-like setups.
- **Use Case**: Testing multi-node clusters, CI/CD integration, or custom CNI configurations (e.g., Calico).
- **Prerequisites**:
  - Docker (`docker --version`)
  - `kubectl`
  - 8GB RAM, 4 CPUs, 20GB disk
- **Setup**:
  1. Install Kind:
     ```bash
     curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
     chmod +x ./kind
     sudo mv ./kind /usr/local/bin/kind
     ```
  2. Create a configuration file (`kind-cluster-config.yaml`):
     ```yaml
     apiVersion: kind.x-k8s.io/v1alpha4
     kind: Cluster
     name: ibtisam
     nodes:
       - role: control-plane
         image: kindest/node:v1.32.3
         extraPortMappings:
           - containerPort: 6443
             hostPort: 6444
             protocol: TCP
           - containerPort: 30000
             hostPort: 3000
             protocol: TCP
         kubeadmConfigPatches:
           - |
             kind: InitConfiguration
             nodeRegistration:
               name: control-plane-1
       - role: worker
         image: kindest/node:v1.32.3
         kubeadmConfigPatches:
           - |
             kind: JoinConfiguration
             nodeRegistration:
               name: worker-1
     networking:
       disableDefaultCNI: true
       podSubnet: "10.244.0.0/16"
       serviceSubnet: "10.96.0.0/12"
       apiServerAddress: "127.0.0.1"
       apiServerPort: 6443
     kubeadmConfigPatches:
       - |
         kind: ClusterConfiguration
         apiServer:
           extraArgs:
             authorization-mode: Node,RBAC
     containerdConfigPatches:
       - |
         [plugins."io.containerd.grpc.v1.cri".containerd]
           snapshotter = "overlayfs"
     ```
  3. Create the cluster:
     ```bash
     kind create cluster --config kind-cluster-config.yaml
     ```
  4. Install Calico as the CNI:
     ```bash
     curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
     ```
     Edit `calico.yaml` to set `--cluster-cidr` equals to `podSubnet` from the `kind-cluster-config.yaml` file:
     ```yaml
     - name: CALICO_IPV4POOL_CIDR
       value: "10.244.0.0/16"
     - name: CALICO_DISABLE_FILE_LOGGING
       value: "true"
     ```
     Apply:
     ```bash
     kubectl apply -f calico.yaml
     ```
- **Verification**:
  ```bash
  kubectl get nodes
  kubectl get pods -n kube-system -l k8s-app=calico-node
  kubectl run nginx --image=nginx --restart=Never
  kubectl get pods -o wide
  ```
  Ensure pods have IPs in `10.244.0.0/16` (e.g., `10.244.0.5`).

> **See the comprehensive documentation on [Kind and its configuration manifests](kind-cluster-setup-guide.md), and learn how to set up a Kubernetes cluster with Kind using Calico in [this guide](kind-cluster-setup-calico-guide.md).**

### K3s
- **Description**: A lightweight Kubernetes distribution by Rancher, optimized for resource-constrained environments like IoT, edge devices, or low-power servers.
- **Use Case**: Edge computing, development, or minimal-resource setups.
- **Prerequisites**:
  - Linux, macOS, or Windows
  - 2GB RAM, 1 CPU
  - `curl`
- **Setup**:
  ```bash
  curl -sfL https://get.k3s.io | sh -
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  k3s check-config
  ```

---

## 2. Self-Managed Clusters

These tools allow you to manage Kubernetes clusters on your own infrastructure (bare metal, VMs, or cloud instances).

### Kubeadm
- **Description**: A Kubernetes project tool for bootstrapping clusters on user-provided infrastructure. It configures control plane and worker nodes with high flexibility.
- **Use Case**: Custom clusters on bare metal, VMs, or hybrid environments.
- **Prerequisites**:
  - Linux servers (Ubuntu, CentOS, etc.)
  - Docker or containerd runtime
  - 4GB RAM, 2 CPUs per node
  - `kubeadm`, `kubelet`, `kubectl`
- **Setup**:
  Click [here](kubeadm-cluster-setup-guide.md) to know how to set up a Kubeadm cluster step by step.

### Kubespray
- **Description**: Uses Ansible to automate Kubernetes cluster deployment across multiple nodes, supporting various OSes and cloud providers.
- **Use Case**: Large-scale, self-managed clusters with automation.
- **Prerequisites**:
  - Ansible (`pip install ansible`)
  - SSH access to nodes
  - 4GB RAM, 2 CPUs per node
- **Setup**:
  ```bash
  git clone https://github.com/kubernetes-sigs/kubespray.git
  cd kubespray
  ansible-playbook -i inventory/sample/inventory.ini cluster.yml
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

### Kops
- **Description**: Automates Kubernetes cluster creation and management on AWS, with support for other clouds like GCP.
- **Use Case**: Cloud-based, self-managed clusters with infrastructure-as-code.
- **Prerequisites**:
  - AWS CLI, `kops` binary
  - S3 bucket for state storage
  - 4GB RAM, 2 CPUs per node
- **Setup**:
  ```bash
  kops create cluster --name my-cluster.k8s.local --zones us-east-1a
  kops update cluster --name my-cluster.k8s.local --yes
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

### kubicorn
- **Description**: A Go-based tool for provisioning Kubernetes clusters on clouds like AWS, Azure, or GCP using infrastructure-as-code.
- **Use Case**: Custom cloud clusters with programmatic control.
- **Prerequisites**:
  - Go, `kubicorn` binary
  - Cloud provider credentials
  - 4GB RAM, 2 CPUs per node
- **Setup**:
  ```bash
  kubicorn create my-cluster --profile aws
  kubicorn apply my-cluster
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

### RKE (Rancher Kubernetes Engine)
- **Description**: A CNCF-certified Kubernetes installer that simplifies cluster setup on self-managed infrastructure, supporting high availability.
- **Use Case**: Production-grade, self-managed clusters with Rancher integration.
- **Prerequisites**:
  - Docker on all nodes
  - `rke` binary
  - 4GB RAM, 2 CPUs per node
- **Setup**:
  ```bash
  rke up --config cluster.yml
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

---

## 3. Managed Control Plane (Hosted Solutions)

These cloud providers manage the Kubernetes control plane, reducing operational overhead.

### Google Kubernetes Engine (GKE)
- **Description**: Fully managed Kubernetes on Google Cloud, with auto-scaling, auto-upgrades, and integration with GCP services.
- **Use Case**: Production workloads with minimal management.
- **Prerequisites**:
  - Google Cloud account
  - `gcloud` CLI
- **Setup**:
  ```bash
  gcloud container clusters create my-cluster --zone us-central1-a
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

### Amazon Elastic Kubernetes Service (EKS)
- **Description**: Managed Kubernetes on AWS, integrating with IAM, VPC, and other AWS services.
- **Use Case**: Enterprise-grade Kubernetes with AWS ecosystem.
- **Prerequisites**:
  - AWS account
  - `aws` CLI, `eksctl`
- **Setup**:
  ```bash
  eksctl create cluster --name my-cluster --region us-east-1
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

### Azure Kubernetes Service (AKS)
- **Description**: Managed Kubernetes on Azure, with integration into Azure Active Directory and Azure Monitor.
- **Use Case**: Kubernetes with Microsoft ecosystem.
- **Prerequisites**:
  - Azure account
  - `az` CLI
- **Setup**:
  ```bash
  az aks create --resource-group my-group --name my-cluster
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

### DigitalOcean Kubernetes (DOKS)
- **Description**: Managed Kubernetes for simpler workloads, integrated with DigitalOcean’s ecosystem.
- **Use Case**: Small to medium-scale applications.
- **Prerequisites**:
  - DigitalOcean account
  - `doctl` CLI
- **Setup**:
  ```bash
  doctl kubernetes cluster create my-cluster
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

---

## 4. Hybrid and Edge Options

These tools extend Kubernetes to hybrid or edge environments.

### KubeEdge
- **Description**: Extends Kubernetes to edge devices, supporting intermittent connectivity and lightweight nodes.
- **Use Case**: IoT, edge computing, or distributed systems.
- **Prerequisites**:
  - Kubernetes cluster (cloud)
  - Edge nodes with `keadm`
  - 2GB RAM, 1 CPU per edge node
- **Setup**:
  ```bash
  keadm init
  keadm join --cloudcore-ip=<cloud-ip>
  ```
- **Verification**:
  ```bash
  kubectl get nodes
  ```

### OpenShift
- **Description**: Red Hat’s Kubernetes platform with built-in CI/CD, developer tools, and support for self-managed or hosted deployments (e.g., Azure Red Hat OpenShift).
- **Use Case**: Enterprise Kubernetes with developer-friendly features.
- **Prerequisites**:
  - Red Hat account or cloud provider
  - `oc` CLI
  - 8GB RAM, 4 CPUs per node
- **Setup** (Hosted):
  ```bash
  oc adm create-cluster --name my-cluster
  ```
- **Verification**:
  ```bash
  oc get nodes
  ```

---

## 5. Tool Comparison

| Tool         | Use Case                     | Complexity | Resource Needs | Managed Control Plane | CNI Options       |
|--------------|------------------------------|------------|----------------|----------------------|-------------------|
| Minikube     | Local dev/testing            | Low        | 4GB RAM, 2 CPUs | No                   | Various           |
| Kind         | CI/CD, multi-node testing    | Low        | 8GB RAM, 4 CPUs | No                   | Flannel, Calico   |
| K3s          | Edge, lightweight dev        | Low        | 2GB RAM, 1 CPU  | No                   | Flannel, Calico   |
| Kubeadm      | Custom self-managed          | Medium     | 4GB RAM, 2 CPUs | No                   | Any               |
| Kubespray    | Automated self-managed       | High       | 4GB RAM, 2 CPUs | No                   | Any               |
| Kops         | Cloud self-managed           | Medium     | 4GB RAM, 2 CPUs | No                   | Any               |
| kubicorn     | Cloud self-managed           | High       | 4GB RAM, 2 CPUs | No                   | Any               |
| RKE          | Production self-managed      | Medium     | 4GB RAM, 2 CPUs | No                   | Any               |
| GKE          | Managed production           | Low        | Varies          | Yes                  | GKE-native        |
| EKS          | Managed enterprise           | Medium     | Varies          | Yes                  | AWS VPC CNI       |
| AKS          | Managed enterprise           | Medium     | Varies          | Yes                  | Azure CNI         |
| DOKS         | Managed small-scale          | Low        | Varies          | Yes                  | Calico            |
| KubeEdge     | Edge computing               | High       | 2GB RAM, 1 CPU  | No                   | Any               |
| OpenShift    | Enterprise dev/production    | High       | 8GB RAM, 4 CPUs | Optional             | OVN-Kubernetes    |

---

## 6. Troubleshooting Common Issues

### Local Tools (Minikube, Kind, K3s)
- **Issue**: Cluster fails to start.
  **Fix**: Ensure Docker is running (`docker info`) and resources are sufficient.
- **Issue**: Pods stuck in `Pending`.
  **Fix**: Verify CNI is installed (e.g., Calico for Kind):
  ```bash
  kubectl get pods -n kube-system
  ```
- **Issue**: `kubectl` cannot connect.
  **Fix**: Set kubeconfig:
  ```bash
  export KUBECONFIG=$(kind get kubeconfig --name ibtisam)
  ```

### Self-Managed (Kubeadm, Kubespray, etc.)
- **Issue**: Nodes not joining.
  **Fix**: Check `kubeadm join` command and network connectivity.
- **Issue**: CNI errors.
  **Fix**: Ensure `--pod-network-cidr` matches CNI config (e.g., `10.244.0.0/16` for Calico).

### Managed Services (GKE, EKS, AKS, DOKS)
- **Issue**: Cluster inaccessible.
  **Fix**: Verify cloud credentials and CLI configuration (e.g., `gcloud auth login`).

### Edge (KubeEdge, OpenShift)
- **Issue**: Edge nodes disconnected.
  **Fix**: Check network stability and `keadm` logs.

