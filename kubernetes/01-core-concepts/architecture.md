# Kubernetes Architecture (Complete Guide)

This documentation provides an in-depth understanding of Kubernetes architecture, covering concepts, components, and processes from basics to advanced operations.

![Kubernetes Cluster Components](https://kubernetes.io/images/docs/kubernetes-cluster-architecture.svg)

---

## 📘 Table of Contents

1. [What happens when you run a `kubectl` command?](#1-what-happens-when-you-run-a-kubectl-command)
2. [Kubeconfig File and Contexts](#2-kubeconfig-file-and-contexts)
3. [Control Plane vs Worker Node Components](#3-control-plane-vs-worker-node-components)
4. [Kubelet in the Architecture](#4-kubelet-in-the-architecture)
5. [CNI Plugins and Networking](#5-cni-plugins-and-networking)
6. [CoreDNS](#6-coredns)
7. [Static Pods vs Deployments](#7-static-pods-vs-deployments)
8. [Kube Proxy - Where It Runs](#8-kube-proxy---where-it-runs)
9. [EKS/Managed Services and kubeconfig](#9-eksmanaged-services-and-kubeconfig)
10. [Cluster Topology and Multiple Clusters](#10-cluster-topology-and-multiple-clusters)
11. [📊 Visual Diagrams](#11-visual-diagrams)

---

## 1. What happens when you run a `kubectl` command?

When a user runs a `kubectl` command:

1. `kubectl` looks for the **kubeconfig** file.
2. It extracts the **context**, which contains:
   - `cluster`: API server endpoint
   - `user`: credentials (token, cert, etc.)
   - `namespace`: default namespace for operation
3. It establishes a secure connection to the **API server**.
4. API server authenticates and authorizes the request.
5. The requested object is created/fetched/updated in **etcd**.
6. API server notifies relevant components (like scheduler or controller manager).
7. If it's a new Pod, **scheduler** schedules it to a Node.
8. That Node’s **kubelet** notices the pod assignment and pulls the container.

---

## 2. Kubeconfig File and Contexts

- **What is kubeconfig?**
  - A file that stores info on how to connect with Kubernetes clusters.
  - Located at: `~/.kube/config` by default.

- **Contents**
```yaml
apiVersion: v1
clusters:
- name: cluster-name
  cluster:
    server: https://api-server-url
    certificate-authority-data: ...
contexts:
- name: context-name
  context:
    cluster: cluster-name
    user: user-name
current-context: context-name
users:
- name: user-name
  user:
    token: or client-cert+key
```

- **Where should it exist?**
  - On **any machine** from where you want to access the cluster using `kubectl`. It’s not tied to control plane or node.

- **Minikube / Kind / Kubeadm**
  - They automatically generate or prompt to export kubeconfig.

- **EKS / Managed Kubernetes**
  - Uses: `aws eks update-kubeconfig --region <region> --name <cluster>`
  - This command contacts AWS API, fetches cluster details, and updates your local kubeconfig.
  - EKS cluster names are **not globally unique** like S3 buckets.

- **Multiple Clusters**
  - You can manage multiple clusters by switching contexts.
  - The kubeconfig is not automatically updated for new clusters—you append manually or use CLI tools.

---

## 3. Control Plane vs Worker Node Components

| Component             | Runs On         | Type        | Description |
|----------------------|------------------|-------------|-------------|
| `kube-apiserver`     | Control Plane    | Static Pod  | Frontend to cluster, all communication goes through it |
| `etcd`               | Control Plane    | Static Pod  | Stores all cluster data in key-value format |
| `kube-scheduler`     | Control Plane    | Static Pod  | Assigns pods to nodes |
| `controller-manager` | Control Plane    | Static Pod  | Manages background tasks (e.g., replicaset) |
| `kubelet`            | All Nodes        | Process     | Manages containers on node, not a pod |
| `kube-proxy`         | All Nodes        | Pod         | Handles network routing |
| `CNI Plugin`         | All Nodes        | Pod/DaemonSet | Manages pod-to-pod networking |
| `CoreDNS`            | Control Plane    | Deployment  | Resolves internal DNS names |


✅ **Static Pods** = Always defined on node via manifests
✅ **Deployments** = Created via API server and managed dynamically

---

## 4. Kubelet in the Architecture

- A **process**, not a pod
- Installed on every node (control + workers)
- Communicates with API server
- Responsibilities:
  - Ensures defined containers are running
  - Reports pod health/status
  - Pulls images, mounts volumes

### With respect to kubectl:
- When you run `kubectl apply`, the scheduler assigns the pod to a node.
- Then kubelet on that node executes the pod creation.

---

## 5. CNI Plugins and Networking

- CNI (Container Network Interface) provides networking for pods.
- Plugins like **Calico**, **Flannel**, **Weave**, etc. manage pod IPs and routing.
- Calico Modes:
  - **ipipMode: Always** = Uses IP-in-IP tunneling
  - **vxlanMode** = Alternative overlay mode

### Pods:
CNI plugins usually deploy as **DaemonSets** so each node has a pod.

---

## 6. CoreDNS

- Deployed by kubeadm or managed services
- It’s a **Deployment**, not static pod
- Typically runs on control plane but scheduled like a normal pod
- Requirements:
  - Cluster must have functional networking
  - kubelet + container runtime + scheduler must work

---

## 7. Static Pods vs Deployments

### Static Pods
- Created by placing manifest files in `/etc/kubernetes/manifests`
- Managed by **kubelet**, not by API server directly
- Used for core control plane components (apiserver, etcd, etc.)

### Deployments
- Managed by API server
- Created dynamically
- Controlled via `ReplicaSet`

---

## 8. Kube Proxy - Where It Runs?

- **Runs on all nodes** (control + worker)
- Responsible for maintaining **iptables/ipvs** rules
- Routes external/internal traffic to pods

🔸 Sometimes people think it runs only on workers due to workload association, but control plane also hosts services, so proxy is required there too.

---

## 9. EKS/Managed Services and kubeconfig

- EKS doesn’t expose control plane for user management
- You use AWS CLI to update kubeconfig
- EKS uses IAM for authentication via tokens
- EKS creates CoreDNS, kube-proxy, CNI plugin pods automatically

---

## 10. Cluster Topology and Multiple Clusters

- Kubernetes supports:
  - Multiple control plane nodes (for HA)
  - Multiple worker nodes
  - Multiple clusters (multi-context kubeconfig)

- Kubelet, kube-proxy, and CNI run on **all nodes**
- Control plane pods = multiple copies if HA is configured

---

## 11. 📊 Visual Diagrams

### 11.1 Basic Kubernetes Architecture
```
+----------------------------+
|        kubectl CLI        |
+------------+--------------+
             |
             v
     +-------+--------+
     |   kube-apiserver |
     +-------+--------+
             |
   +---------+------------+
   |    Kubernetes Control  |
   | Plane Components       |
   |                        |
   | +-------------------+ |
   | | etcd               | |
   | | scheduler          | |
   | | controller-manager | |
   | +-------------------+ |
   +---------+------------+
             |
      +------+-------+
      |              |
+-----v----+    +----v-----+
| Worker 1 |    | Worker 2 |
|          |    |          |
| +------+ |    | +------+ |
| |kubelet| |    | |kubelet| |
| +------+ |    | +------+ |
| |k-proxy| |    | |k-proxy| |
| +------+ |    | +------+ |
| |  CNI  | |    | |  CNI  | |
+---------+     +---------+
```

### 11.2 Control Plane Communication
```
[kubectl] -> [kube-apiserver] -> [scheduler/controller] -> [kubelet on node]
                     |
                  [etcd]
```

---

## ✅ Summary

- kubeconfig is needed only where you want to use `kubectl`
- Control Plane runs only a few static pods (scheduler, etcd, apiserver)
- kubelet is a background process on every node
- kube-proxy and CNI are pods (usually DaemonSets) running on all nodes
- CoreDNS is a deployment created post-cluster-init
- EKS and other managed services simplify the cluster but still use kubeconfig


