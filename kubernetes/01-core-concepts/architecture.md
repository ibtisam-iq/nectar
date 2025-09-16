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
| `kube-proxy`         | All Nodes        | DaemonSet   | Handles network routing |
| `CNI Plugin`         | All Nodes        | DaemonSet   | Manages pod-to-pod networking |
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
- Typically runs on **control plane** but scheduled like a normal pod
- Requirements:
  - Cluster must have functional networking
  - kubelet + container runtime + scheduler must work

---

## 7. Static Pods vs Deployments

### Static Pods
- Created by placing manifest files in `/etc/kubernetes/manifests`
- Managed by **kubelet**, not by API server directly
- Used for core control plane components (apiserver, etcd, etc.)

```bash
controlplane ~ ➜  cat /var/lib/kubelet/config.yaml | grep -i staticPodPath:
staticPodPath: /etc/kubernetes/manifests
```

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

> Correct! That's because 2379 is the port of ETCD to which all control plane components connect to. 2380 is only for etcd peer-to-peer connectivity. When you have multiple controlplane nodes. In this case we don't.

---

## 🧠 OVERVIEW TABLE – 4 Static Pods

| Component                   | What It Does                                                           | Listens On | Local Only | Talks to API Server?       | AuthN/AuthZ | Health Port             |
| --------------------------- | ---------------------------------------------------------------------- | ---------- | ---------- | -------------------------- | ----------- | ----------------------- |
| **kube-apiserver**          | Front door to the cluster; receives and validates all requests         | 6443       | ❌ No       | ✅ It's the API server      | ✅ Yes       | 6443 (/healthz)        |
| **kube-scheduler**          | Assigns Pods to nodes based on resource needs and policies             | 10259      | ✅ Yes      | ✅ Yes                      | ✅ Yes       | 10259 (/livez, /readyz) |
| **kube-controller-manager** | Ensures desired state by running controllers (replicas, nodes, tokens) | 10257      | ✅ Yes      | ✅ Yes                      | ✅ Yes       | 10257 (/healthz)        |
| **etcd**                    | Key-value store for all cluster data                                   | 2379       | ✅ Yes      | ❌ (API server talks to it) | ❌ No        | 2381 (/health)          |

---

## 🔍 DEEP COMPARISON

| Aspect               | kube-apiserver                                     | kube-scheduler                              | kube-controller-manager                     | etcd                                             |
| -------------------- | -------------------------------------------------- | ------------------------------------------- | ------------------------------------------- | ------------------------------------------------ |
| **Main Role**        | API gateway, validation, REST interface            | Pod placement decision-making               | State automation & controller management    | Persistent storage for all cluster state         |
| **Image Used**       | `kube-apiserver:v1.33.0`                           | `kube-scheduler:v1.33.0`                    | `kube-controller-manager:v1.33.0`           | `etcd:3.5.x`                                     |
| **Authentication**   | Uses many TLS certs and client auth                | Uses `scheduler.conf` for kubeconfig & auth | Uses `controller-manager.conf` & many certs | Uses TLS (peer, client certs, etc.)              |
| **Leader Election**  | ❌ (Only one API server in single-node cluster)     | ✅ Ensures only one scheduler is active      | ✅ Ensures only one manager is active        | ❌ (No HA setup here)                             |
| **Volume Mounts**    | Certs, audit logs, encryption keys, etcd certs     | Just `scheduler.conf`                       | Lots: certs, kubeconfig, SA keys, CA dirs   | Peer certs, server certs, data dir, etcd configs |
| **Security Ports**   | Port 6443 → Exposed for all clients                | Port 10259 → Internal only                  | Port 10257 → Internal only                  | 2379 client / 2380 peer                          |
| **Service Exposure** | Exposed via kubeconfig to `kubectl`                | Not exposed externally                      | Not exposed externally                      | Exposed only to API server (on localhost)        |
| **Health Checks**    | `/healthz`, `/livez`, `/readyz` (all on 127.0.0.1) | `/livez`, `/readyz` on 10259                | `/healthz` on 10257                         | `/health` on 2381                                |

---

## 🧬 SIMPLIFIED REAL-WORLD ANALOGY

| Component              | Like a...              | Role in a Team                                      |
| ---------------------- | ---------------------- | --------------------------------------------------- |
| **API Server**         | Receptionist & Manager | Accepts all tasks, verifies, and routes them        |
| **Scheduler**          | Project Manager        | Decides who (node) gets the next task (pod)         |
| **Controller Manager** | Operations Supervisor  | Checks if everyone is doing their job, fixes if not |
| **etcd**               | Company Database       | Stores everything — HR, attendance, logs, files     |

---

## 🧪 What Should You Remember for CKA?

* These four components **must be healthy** for the control plane to work.
* They're all defined as **static pods**, so kubelet loads them directly from manifest files.
* `kube-scheduler` and `controller-manager` use **leader election** — only one is active at a time.
* `etcd` is **the single source of truth** — if it fails, you lose your entire cluster state.
* Most internal endpoints (`10257`, `10259`, etc.) are **only accessible via localhost**.
* Certificates and kubeconfigs are located in `/etc/kubernetes/` and `/etc/kubernetes/pki`.

---

## 📦 Directory Summary

| Path                         | What’s Inside                                |
| ---------------------------- | -------------------------------------------- |
| `/etc/kubernetes/manifests/` | Static pod YAMLs for control plane           |
| `/etc/kubernetes/pki/`       | TLS certs, keys for auth (CA, etcd, SA keys) |
| `/etc/kubernetes/*.conf`     | Kubeconfigs for control-plane components     |
| `/var/lib/etcd`              | The actual key-value data store for etcd     |

---

```bash
controlplane ~ ➜  ps -aux | grep kube-apiserver
bad data in /proc/uptime
root        3465  0.0  0.4 1529060 280128 ?      Ssl  13:22   2:09 kube-apiserver --advertise-address=192.168.121.223 --allow-privileged=true --authorization-mode=Node,RBAC --client-ca-file=/etc/kubernetes/pki/ca.crt --enable-admission-plugins=NodeRestriction --enable-bootstrap-token-auth=true --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key --etcd-servers=https://127.0.0.1:2379 --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key --requestheader-allowed-names=front-proxy-client --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --requestheader-extra-headers-prefix=X-Remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --secure-port=6443 --service-account-issuer=https://kubernetes.default.svc.cluster.local --service-account-key-file=/etc/kubernetes/pki/sa.pub --service-account-signing-key-file=/etc/kubernetes/pki/sa.key --service-cluster-ip-range=172.20.0.0/16 --tls-cert-file=/etc/kubernetes/pki/apiserver.crt --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
root       53524  0.0  0.0   6932  2384 pts/5    S+   14:25   0:00 grep --color=auto kube-apiserver

controlplane ~ ➜  ps -aux | grep etcd
bad data in /proc/uptime
root        3551  0.0  0.0 11740560 57776 ?      Ssl  13:22   1:09 etcd --advertise-client-urls=https://192.168.121.223:2379 --cert-file=/etc/kubernetes/pki/etcd/server.crt --client-cert-auth=true --data-dir=/var/lib/etcd --experimental-initial-corrupt-check=true --experimental-watch-progress-notify-interval=5s --initial-advertise-peer-urls=https://192.168.121.223:2380 --initial-cluster=controlplane=https://192.168.121.223:2380 --key-file=/etc/kubernetes/pki/etcd/server.key --listen-client-urls=https://127.0.0.1:2379,https://192.168.121.223:2379 --listen-metrics-urls=http://127.0.0.1:2381 --listen-peer-urls=https://192.168.121.223:2380 --name=controlplane --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt --peer-client-cert-auth=true --peer-key-file=/etc/kubernetes/pki/etcd/peer.key --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt --snapshot-count=10000 --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
root       54353  0.0  0.0   6932  2304 pts/5    S+   14:26   0:00 grep --color=auto etcd

controlplane ~ ➜  ps -aux | grep kube-scheduler
bad data in /proc/uptime
root        3523  0.0  0.0 1298564 30804 ?       Ssl  13:22   0:26 kube-scheduler --authentication-kubeconfig=/etc/kubernetes/scheduler.conf --authorization-kubeconfig=/etc/kubernetes/scheduler.conf --bind-address=127.0.0.1 --kubeconfig=/etc/kubernetes/scheduler.conf --leader-elect=true
root       55679  0.0  0.0   6932  2292 pts/5    S+   14:28   0:00 grep --color=auto kube-scheduler

controlplane ~ ➜  ps -aux | grep kube-control-manager
bad data in /proc/uptime
root       56292  0.0  0.0   6936  2296 pts/5    S+   14:29   0:00 grep --color=auto kube-control-manager

controlplane ~ ➜  ps -aux | grep kube-controller-manager
bad data in /proc/uptime
root        3516  0.0  0.0 1319952 63472 ?       Ssl  13:22   0:43 kube-controller-manager --allocate-node-cidrs=true --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf --bind-address=127.0.0.1 --client-ca-file=/etc/kubernetes/pki/ca.crt --cluster-cidr=172.17.0.0/16 --cluster-name=kubernetes --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt --cluster-signing-key-file=/etc/kubernetes/pki/ca.key --controllers=*,bootstrapsigner,tokencleaner --kubeconfig=/etc/kubernetes/controller-manager.conf --leader-elect=true --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --root-ca-file=/etc/kubernetes/pki/ca.crt --service-account-private-key-file=/etc/kubernetes/pki/sa.key --service-cluster-ip-range=172.20.0.0/16 --use-service-account-credentials=true
root       57132  0.0  0.0   6940  2360 pts/5    S+   14:30   0:00 grep --color=auto kube-controller-manager


controlplane ~ ➜  ps -aux | grep kubelet
bad data in /proc/uptime
root        3465  0.0  0.4 1529316 278060 ?      Ssl  13:22   2:37 kube-apiserver --advertise-address=192.168.121.223 --allow-privileged=true --authorization-mode=Node,RBAC --client-ca-file=/etc/kubernetes/pki/ca.crt --enable-admission-plugins=NodeRestriction --enable-bootstrap-token-auth=true --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key --etcd-servers=https://127.0.0.1:2379 --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key --requestheader-allowed-names=front-proxy-client --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt --requestheader-extra-headers-prefix=X-Remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --secure-port=6443 --service-account-issuer=https://kubernetes.default.svc.cluster.local --service-account-key-file=/etc/kubernetes/pki/sa.pub --service-account-signing-key-file=/etc/kubernetes/pki/sa.key --service-cluster-ip-range=172.20.0.0/16 --tls-cert-file=/etc/kubernetes/pki/apiserver.crt --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
root        3993  0.0  0.1 3010708 93140 ?       Ssl  13:22   1:29 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock --pod-infra-container-image=registry.k8s.io/pause:3.10
root       64091  0.0  0.0   6932  2328 pts/5    S+   14:40   0:00 grep --color=auto kubelet

controlplane ~ ➜  cat /var/lib/kubelet/config.yaml 
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: cgroupfs
clusterDNS:
- 172.20.0.10
clusterDomain: cluster.local
containerRuntimeEndpoint: ""
cpuManagerReconcilePeriod: 0s
crashLoopBackOff: {}
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMaximumGCAge: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
    text:
      infoBufferSize: "0"
  verbosity: 0
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
resolvConf: /run/systemd/resolve/resolv.conf
rotateCertificates: true
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s

controlplane ~ ➜  cat /etc/kubernetes/kubelet.conf 
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJVENOYjlPMHNmTHN3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRBM01UY3hNekUzTURKYUZ3MHpOVEEzTVRVeE16SXlNREphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUREMmptTFVqYkg4UTZmVnRDOGtlelQxYjk1R2J6VXZKM0E5MFppczdkQzQwdkdiTzZlMW42cHVVQ0sKRDVWWE51Y2lWbXQySWlhZFduV0pDS2x0U2RlbUNtVVV6eDd4a1lHdE1ReGxSU2N6V2hwekxCNXVBNWR3Rm9CMApGdWRqQldrcFg0NCtiTmVQVmVYRWRndjFMQTBPOTBqandkOVVDL0pPOTY2UFlxSkp3U2RsT3BRSFA4T0VGa2tTCmZZRnBYK1B4T241cHB6NEZlakY0MlZaZUlxZHNyOG1XMUlFL3UwRmxQVmtxUmJaMnhqTnlnWnNhaUpIMC9qV2YKMnZBZW5qVENkSkxvdEZodlV1WGk2MlRhMWJYL3JCdzBMb1ZST252Vzgyam9uTTJPY0ZpQ2pibC80Y0lSb2FMUwpWS3B0Z3FOMUEwc29FQXJxWlBmcUIwK3c5eUZqQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJRdURyUDZvU25sWXNCcWZ5QS9MbDhsTjRlYXlqQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQkhTaUhGdDdTWgpiTm10T0JnOTFRck5SUElDV1ZJdFljQlpBblRqWEVVSTU5UUx3a2NOZjNWVlB4THd2YUpqV1ZOS3VRZnFDeW9pClRvWnQxaFduQTFqVUp3b0t6cUdGeWV3NkRTa3drSy9wUHByL2prLzVhNXBDZHRkSzllOURTYlh2SXJKNHlSZ0UKYWoyUzllOGRSMkpQZEZENEkrd2Q2U3kvTW1KQUxIYVEybzJ4N1ZSMXFIV0t2V2dKelpRWktZTG1vV0d1RzMwRQpCWGpvT1lHRDM2dzR1dGFGaUFwZmtJVWpQUG1DR3VnQjBJdG9aSkRpYzU2aHdNZU12UVlaQ1o0M2FCRE1JNExMCkV6Qkw1Um5ReEVBN2dzRER2SGdoa1NDaXQrMzI3Q2t5MWFiZXQrM3RoaUdLTzRDTUs5Mjd2RHFFdGlrcEtmbHAKbDl0SzE0elY3U0ZMCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://192.168.121.223:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: system:node:controlplane
  name: system:node:controlplane@kubernetes
current-context: system:node:controlplane@kubernetes
kind: Config
preferences: {}
users:
- name: system:node:controlplane
  user:
    client-certificate: /var/lib/kubelet/pki/kubelet-client-current.pem
    client-key: /var/lib/kubelet/pki/kubelet-client-current.pem


controlplane ~ ➜  ps -aux | grep -i kube-proxy
bad data in /proc/uptime
root        4382  0.0  0.0 1298512 16032 ?       Ssl  13:22   0:01 /usr/local/bin/kube-proxy --config=/var/lib/kube-proxy/config.conf --hostname-override=controlplane
```

---

**Q. Identify the pod CIDR network of the full kubernetes cluster. This information is crucial for configuring the CNI plugin during installation. 
Output the pod CIDR network to a file at `/root/pod-cidr.txt`.**

```bash
controlplane ~ ✖ k get cm -n kube-system 
NAME                                                   DATA   AGE
canal-config                                           6      89m
coredns                                                1      89m
extension-apiserver-authentication                     6      89m
kube-apiserver-legacy-service-account-token-tracking   1      89m
kube-proxy                                             2      89m
kube-root-ca.crt                                       1      88m
kubeadm-config                                         1      89m
kubelet-config                                         1      89m

controlplane ~ ➜  k describe cm -n kube-system kubeadm-config 
Name:         kubeadm-config
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Data
====
ClusterConfiguration:
----
apiServer:
  certSANs:
  - controlplane
apiVersion: kubeadm.k8s.io/v1beta4
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: controlplane:6443
controllerManager: {}
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: v1.33.0
networking:
  dnsDomain: cluster.local
  podSubnet: 172.17.0.0/16
  serviceSubnet: 172.20.0.0/16
proxy: {}
scheduler: {}



BinaryData
====

Events:  <none>

controlplane ~ ➜  kubectl get configmap kubeadm-config -n kube-system  -o jsonpath="{.data.ClusterConfiguration}" | grep podSubnet  | awk '{print $2}' > /root/pod-cidr.txt

controlplane ~ ➜  cat pod-cidr.txt 
172.17.0.0/16
```
---
