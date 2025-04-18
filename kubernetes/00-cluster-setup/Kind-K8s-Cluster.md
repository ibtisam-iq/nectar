# Kind: Kubernetes IN Docker

## Table of Contents

1. Introduction
2. Installation
3. Creating a Cluster
4. Configuring a Cluster
5. Understanding Kind Cluster Components
6. Networking in Kind
7. Port Mapping and Service Exposure
8. Customizing Cluster Configuration
9. Managing Cluster Lifecycle
10. Troubleshooting Common Issues
11. Advanced Use Cases
12. Conclusion

---

## 1. Introduction

Kind (Kubernetes IN Docker) is a tool for running local Kubernetes clusters using Docker containers as nodes. It’s ideal for testing Kubernetes configurations, developing applications, learning Kubernetes, and integrating with CI/CD pipelines. Kind uses `kubeadm` to bootstrap clusters, making it a lightweight alternative to heavier solutions like Minikube.

### Why Use Kind?
- **Lightweight**: Runs Kubernetes nodes as Docker containers, eliminating the need for virtual machines.
- **Fast Setup**: Creates clusters in minutes with minimal configuration.
- **CI/CD Friendly**: Designed for automated testing in CI pipelines.
- **Multi-Node Support**: Supports control-plane and worker nodes for realistic cluster setups.
- **Customizable**: Allows extensive configuration via YAML files and `kubeadm` patches.
- **CNI Flexibility**: Supports custom Container Network Interfaces (CNIs) like Calico.

---

## 2. Installation

### Prerequisites
- **Docker**: Required to run Kind clusters (`docker --version`).
- **kubectl**: Optional but recommended for cluster interaction (`kubectl version --client`).
- **Sufficient Resources**: At least 8GB RAM, 4 CPUs, and 20GB disk for a small cluster.

### Installing Kind
For Linux (AMD64):
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

For other platforms, see the [Kind installation guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

Verify installation:
```bash
kind version
```

---

## 3. Creating a Cluster

Create a basic single-node cluster:
```bash
kind create cluster --name my-cluster
```

For a multi-node cluster, use a configuration file:
```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: my-cluster
nodes:
  - role: control-plane
    image: kindest/node:v1.32.3
  - role: worker
    image: kindest/node:v1.32.3
  - role: worker
    image: kindest/node:v1.32.3
```

Apply the config:
```bash
kind create cluster --config cluster-config.yaml
```

The `--config` flag specifies the YAML file, and `image` ensures all nodes use the same Kubernetes version (v1.32.3 recommended as of April 2025).

> **You want to set up it with ONE click? Run the following command in your terminal:**
```bash
kind create cluster --config https://github.com/ibtisam-iq/SilverKube/blob/main/kind-config-file.yaml
```

---

## 4. Configuring a Cluster

### Cluster Naming
Clusters are named `kind` by default. Specify a custom name:
```bash
kind create cluster --name dev-cluster
```

### Accessing the Cluster
Kind generates a kubeconfig file for `kubectl`. Export it:
```bash
export KUBECONFIG=$(kind get kubeconfig --name dev-cluster)
kubectl cluster-info
```

Alternatively, merge the kubeconfig into your default `~/.kube/config`:
```bash
kind export kubeconfig --name dev-cluster
```

### Switching Contexts
If managing multiple clusters, use `kubectl` contexts:
```bash
kubectl config get-contexts
kubectl config use-context kind-dev-cluster
```

---

## 5. Understanding Kind Cluster Components

### Control-Plane Nodes
- Run the Kubernetes control plane components (API server, scheduler, controller manager, etcd).
- Manage cluster state, handle API requests, and schedule workloads.

### Worker Nodes
- Run application workloads (pods) and kube-proxy for networking.
- Managed by the control-plane nodes.

### Role of kubeadm
- Kind uses `kubeadm` to bootstrap and join nodes into a Kubernetes cluster.
- `kubeadm` initializes the control-plane and configures worker nodes.
- Customizations are applied via `kubeadmConfigPatches` in the Kind config.

### Container Runtime
- Kind uses **containerd** as the container runtime for running pods.
- Configurable via `containerdConfigPatches` for performance optimizations.

---

## 6. Networking in Kind

### Default CNI
- Kind uses **Flannel** as the default CNI for pod-to-pod communication.
- To use a custom CNI (e.g., Calico), disable the default:
  ```yaml
  networking:
    disableDefaultCNI: true
  ```

### Using Calico as CNI
To replace Flannel with Calico for advanced features like network policies, please find [here](Kind-K8s-Cluster-Calico.md) a dedicated guide.


### podSubnet and --cluster-cidr
- `podSubnet` (e.g., `10.244.0.0/16`) sets the IP range for pods, equivalent to the `--cluster-cidr` parameter in Kubernetes.
- The CNI (e.g., Calico) must use a matching CIDR to assign valid pod IPs.
- `10.244.0.0/16` is a safe, standard range to avoid conflicts with local networks.
- Click [here](--cluster-cidr.md) for more details.

### serviceSubnet
- `serviceSubnet` (e.g., `10.96.0.0/12`) defines the IP range for Kubernetes services (used for internal load balancing).
- Must be non-overlapping with `podSubnet`.

### API Server Access
- The API server runs inside the control-plane container, accessible via `127.0.0.1:6443` by default.
- Use `extraPortMappings` to expose it externally:
  ```yaml
  nodes:
    - role: control-plane
      extraPortMappings:
        - containerPort: 6443
          hostPort: 6443
          protocol: TCP
  ```

---

## 7. Port Mapping and Service Exposure

### Why Port Mapping?
- Kind nodes run in Docker containers, isolated from the host network.
- Services exposed via `NodePort` or `LoadBalancer` are not accessible on `localhost` without port mapping.
- `extraPortMappings` forwards host ports to container ports.

### Example
To expose a `NodePort` service on port `30000` to `localhost:8080`:
```yaml
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30000
        hostPort: 8080
        protocol: TCP
```

Access the service at `http://localhost:8080`. Ensure the service’s `NodePort` matches `containerPort`.

### Considerations
- Verify `hostPort` doesn’t conflict with other services on the host.
- For production-like setups, consider `Ingress` or external load balancers (e.g., MetalLB).

> **See detailed guide about `extraPortMappings` [here](extraPortMappings-a.md).**

---

## 8. Customizing Cluster Configuration

### kubeadmConfigPatches
Customize `kubeadm` settings for cluster-wide or node-specific configurations.

#### Cluster-Wide Example
Enable RBAC and Node authorization:
```yaml
kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        authorization-mode: Node,RBAC
```

#### Node-Specific Example
Set custom node names:
```yaml
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          name: control-plane-1
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          name: worker-1
```

### containerdConfigPatches
Optimize the containerd runtime:
```yaml
containerdConfigPatches:
  - |
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
```
This uses `overlayfs` for better performance and storage efficiency.

> **For a detailed explanation, please refer to the documentation on  [`kubeadmConfigPatches`](kubeadmConfigPatches.md) and [`containerdConfigPatches`](containerdConfigPatches.md).**

### Feature Gates
Enable experimental Kubernetes features:
```yaml
featureGates:
  IPv6DualStack: false
```
Set to `true` for dual-stack networking (requires additional Calico configuration).

---

## 9. Managing Cluster Lifecycle

### Creating a Cluster
```bash
kind create cluster --name ibtisam --config kind-cluster-config.yaml
```

### Deleting a Cluster
```bash
kind delete cluster --name ibtisam
```

### Listing Clusters
```bash
kind get clusters
```

### Accessing Nodes
Inspect a node’s container:
```bash
docker ps --filter name=ibtisam
docker exec -it ibtisam-control-plane bash
```

### Stopping/Restarting
Kind doesn’t support stopping/restarting clusters. Delete and recreate instead.

---

## 10. Troubleshooting Common Issues

### Issue: `kubectl` Cannot Connect
**Symptoms**: `kubectl cluster-info` fails with connection errors.
**Fix**:
```bash
export KUBECONFIG=$(kind get kubeconfig --name ibtisam)
kubectl cluster-info
```

### Issue: Pods Stuck in `Pending` or `ContainerCreating`
**Symptoms**: System pods (e.g., `coredns`) don’t start.
**Fix**:
- Ensure Calico is applied (`kubectl apply -f calico.yaml`), if using Calico.
- Check Calico pod logs:
  ```bash
  kubectl logs -n kube-system -l k8s-app=calico-node
  ```
- Verify IP pool:
  ```bash
  kubectl get ippool -o yaml
  ```

### Issue: Service Not Accessible on `localhost`
**Symptoms**: `http://localhost:3000` doesn’t work.
**Fix**:
- Confirm `extraPortMappings` matches the service’s `NodePort` (e.g., `30000`).
- Check service details:
  ```bash
  kubectl get svc
  ```

### Issue: Networking Issues with Calico
**Symptoms**: Pods can’t communicate.
**Fix**:
- Verify `CALICO_IPV4POOL_CIDR` is `10.244.0.0/16` in `calico.yaml`.
- Check for local network conflicts (e.g., with `192.168.0.0/16`).

---

## 11. Advanced Use Cases

### Running Kind in CI/CD
Use Kind in CI pipelines (e.g., GitHub Actions):
```yaml
name: Kubernetes Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Kind
        run: |
          curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
          chmod +x ./kind
          sudo mv ./kind /usr/local/bin/kind
      - name: Create Cluster
        run: kind create cluster --name test-cluster
      - name: Run Tests
        run: |
          kubectl apply -f my-app.yaml
          kubectl get pods
```

### Multi-Cluster Deployments
Create multiple clusters for testing:
```bash
kind create cluster --name cluster1
kind create cluster --name cluster2
kubectl config use-context kind-cluster1
```

### High Availability
Add multiple control-plane nodes:
```yaml
nodes:
  - role: control-plane
  - role: control-plane
  - role: worker
```

### Using Ingress
Deploy an Ingress controller (e.g., NGINX) for external access:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

---

## Conclusion

Kind is a versatile tool for running local Kubernetes clusters, ideal for development, testing, and learning. By customizing configurations (e.g., using Calico, port mappings, `kubeadm` patches), you can tailor clusters to your needs. This guide provides a comprehensive overview, including advanced features like Calico integration and CI/CD workflows.

For more details, visit the [official Kind documentation](https://kind.sigs.k8s.io/) or [Calico documentation](https://docs.tigera.io/calico/latest).

