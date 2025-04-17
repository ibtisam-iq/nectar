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

---

## 1. Introduction

Kind (Kubernetes IN Docker) is a tool designed to run local Kubernetes clusters using Docker container nodes. It is primarily used for testing Kubernetes setups, CI/CD pipelines, and learning Kubernetes fundamentals in an isolated environment.

### Why Use Kind?
- **Lightweight:** Runs Kubernetes inside Docker containers without needing a VM.
- **Fast Setup:** No need for manual cluster provisioning.
- **CI/CD Friendly:** Ideal for automated testing in CI pipelines.
- **Multi-node Clusters:** Supports control-plane and worker node configurations.
- **Kubeadm Support:** Uses kubeadm internally to bootstrap clusters.

---

## 2. Installation

### Prerequisites
- Docker (required)
- kubectl (optional but recommended)

### Installing Kind
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind
```

To verify installation:
```bash
kind version
```

---

## 3. Creating a Cluster

To create a basic single-node cluster:
```bash
kind create cluster --name my-cluster
```

For a multi-node cluster, use a custom config file:
```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
  - role: control-plane
  - role: worker
  - role: worker
```

Apply the config:
```bash
kind create cluster --config cluster-config.yaml
```

---

## 4. Configuring a Cluster

### Cluster Naming
By default, clusters are named `kind`. You can specify a name with:
```bash
kind create cluster --name dev-cluster
```

### Exporting Kubeconfig
To access the cluster using `kubectl`:
```bash
export KUBECONFIG=$(kind get kubeconfig-path --name="dev-cluster")
kubectl cluster-info
```

---

## 5. Understanding Kind Cluster Components

### Control Plane and Worker Nodes
- **Control Plane:** Manages the Kubernetes cluster, handling API requests, scheduling workloads, and managing cluster state.
- **Worker Nodes:** Run containerized applications (Pods).

### Role of Kubeadm in Kind
- Kind relies on **kubeadm** to initialize and join nodes into a Kubernetes cluster.
- Without kubeadm, Kind wouldn’t be able to form a proper cluster.
- It allows customization through `kubeadmConfigPatches`.

---

## 6. Networking in Kind

### Default CNI (Container Network Interface)
- Kind ships with a default CNI for pod-to-pod communication.
- You can disable it and install another CNI like Calico or Flannel.

```yaml
networking:
  disableDefaultCNI: false  # Set to true if using a custom CNI
```

### API Server Access
- Kind runs the API server inside a container.
- By default, it is only accessible from within the Docker network.
- Use `extraPortMappings` to expose it externally.

```yaml
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 6443
        hostPort: 6443
```

---

## 7. Port Mapping and Service Exposure

### Why is Port Mapping Needed?
- Containers in Kind are isolated within the Docker network.
- Services exposed via **NodePort** or **LoadBalancer** are not accessible on `localhost` by default.
- **Solution:** Use `extraPortMappings` to forward traffic from host to the cluster.

```yaml
extraPortMappings:
  - containerPort: 30000
    hostPort: 8080
    protocol: TCP
```

Now, a service on NodePort `30000` will be accessible at `http://localhost:8080`.

> **See detailed guide about `extraPortMappings` [here](extraPortMappings-a.md).**

---

## 8. Customizing Cluster Configuration

### Kubeadm Configuration Patches
- `kubeadmConfigPatches` customizes the kubeadm settings inside Kind.
- It allows modifying cluster configurations at both **cluster level** and **node level**.


#### Cluster-Wide Configuration:
```yaml
kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        authorization-mode: Node,RBAC
```

#### Node-Specific Configuration:
```yaml
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          name: control-plane-1
```

### Containerd Configuration Patches
- Kind uses **containerd** as the container runtime.
- You can modify its settings using `containerdConfigPatches`.

```yaml
containerdConfigPatches:
  - |
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
```

This improves container performance and storage efficiency.

> **For a detailed explanation, please refer to the documentation on  [`kubeadmConfigPatches`](kubeadmConfigPatches.md) and [`containerdConfigPatches`](containerdConfigPatches.md).**

---

## 9. Managing Cluster Lifecycle

### Deleting a Cluster
```bash
kind delete cluster --name dev-cluster
```

### Listing Clusters
```bash
kind get clusters
```

### Stopping and Restarting
Kind does not support stopping and restarting clusters. You must delete and recreate them.

---

## 10. Troubleshooting Common Issues

### Issue: `kubectl` Cannot Connect
**Fix:** Export the correct Kubeconfig path:
```bash
export KUBECONFIG=$(kind get kubeconfig-path --name=my-cluster)
kubectl cluster-info
```

### Issue: Service Not Accessible on `localhost`
**Fix:** Ensure `extraPortMappings` is set correctly.

### Issue: Pods Stuck in `ContainerCreating`
**Fix:** Check containerd logs for errors:
```bash
docker logs kind-control-plane
```

---

## 11. Advanced Use Cases

### Running Kind in CI/CD Pipelines
- Kind can be used in **GitHub Actions, GitLab CI, and Jenkins** for Kubernetes testing.
- Example GitHub Actions Workflow:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Install Kind
        run: |
          curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
          chmod +x ./kind
          mv ./kind /usr/local/bin/kind
      - name: Create Cluster
        run: kind create cluster
      - name: Run Tests
        run: kubectl get nodes
```

### Multi-Cluster Deployments
- Kind can create **multiple clusters** for testing hybrid-cloud scenarios.

```bash
kind create cluster --name cluster1
kind create cluster --name cluster2
```

---

## Conclusion
Kind is a powerful tool for local Kubernetes cluster management. Whether you're learning Kubernetes, developing microservices, or setting up CI/CD workflows, Kind provides a lightweight and flexible solution for running Kubernetes in Docker.

For more details, visit the [official Kind documentation](https://kind.sigs.k8s.io/).

