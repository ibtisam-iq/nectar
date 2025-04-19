# Setting up Kind Cluster Using Calico as CNI

This guide provides a complete workflow to replace Flannel (the default CNI in Kind) with Calico in a Kind cluster, based on the provided [`kind-cluster-config.yaml`](https://raw.githubusercontent.com/ibtisam-iq/SilverKube/main/kind-config-file.yaml). It covers configuration updates, Calico installation, and verification, with explanations of key concepts like `--cluster-cidr`. The setup assumes an IPv4-only cluster (`IPv6DualStack: false`) but includes notes for dual-stack if needed.

---

## 1. Why Use Calico Instead of Flannel?

Calico offers advanced features compared to Flannel, making it suitable for specific use cases:

- **Network Policies**: Calico supports Kubernetes [`NetworkPolicy`](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/03-networking/network-policy-guide.md) resources for fine-grained control over pod-to-pod communication, enhancing security.
- **BGP Support**: Calico supports Border Gateway Protocol (BGP) for advanced routing, useful in hybrid or multi-cluster setups.
- **Dual-Stack Networking**: Calico fully supports IPv4/IPv6 dual-stack networking, though this guide focuses on IPv4-only.
- **Flexibility**: Calico is highly configurable, supporting various environments and networking requirements.

**Flannel vs. Calico Comparison**:

| Feature                  | Flannel                          | Calico                          |
|--------------------------|----------------------------------|---------------------------------|
| Ease of Use              | Simple, lightweight, default     | Requires manual installation    |
| Network Policies         | Not supported                   | Fully supported                 |
| Performance              | Minimal overhead                | Slightly higher due to features |
| IPv6 Support             | Limited                         | Full dual-stack support         |
| BGP Support              | Not supported                   | Supported                       |
| Use Case                 | Simple clusters, testing        | Security-focused, complex setups |

**Rationale for Calico**:
- The [`kind-cluster-config.yaml`](https://raw.githubusercontent.com/ibtisam-iq/SilverKube/main/kind-config-file.yaml) is designed for a local development or testing cluster named `ibtisam` with a single control-plane and worker node. Switching to Calico allows you to leverage network policies and prepare for potential future needs (e.g., security, advanced networking), while maintaining compatibility with your existing setup.

---

## 2. Understanding Key Concepts

Before proceeding, let’s clarify critical terms:

- **CNI (Container Network Interface)**:
  - The CNI is responsible for setting up pod networking in Kubernetes, assigning IP addresses to pods and enabling communication between them. Flannel is Kind’s default CNI, but you’re replacing it with Calico.

- **podSubnet**:
  - The `podSubnet` in `kind-cluster-config.yaml` (e.g., `10.244.0.0/16`) defines the IP range for pod IPs. It’s equivalent to the `--cluster-cidr` parameter in Kubernetes, used by the CNI and Kubernetes components to manage pod networking.

- **--cluster-cidr**:
  - This is the Kubernetes configuration parameter that specifies the CIDR range for pod IPs. In Kind, it’s set via the `podSubnet` field (e.g., `10.244.0.0/16`). The CNI (Calico) must use a CIDR that matches or falls within this range to assign valid pod IPs.
  - Example: Your `podSubnet: "10.244.0.0/16"` sets `--cluster-cidr` to `10.244.0.0/16`.

- **serviceSubnet**:
  - The `serviceSubnet` (e.g., `10.96.0.0/12`) defines the IP range for Kubernetes service IPs, used for cluster-internal load balancing. It’s separate from `podSubnet` and doesn’t directly affect Calico configuration.

- **IPv6DualStack**:
  - When enabled (`IPv6DualStack: true`), the cluster supports both IPv4 and IPv6 for pods and services. Since you’ve chosen `IPv6DualStack: false`, the cluster will be IPv4-only, simplifying Calico’s configuration.

- **CALICO_IPV4POOL_CIDR**:
  - This setting in the Calico manifest specifies the IPv4 CIDR from which Calico assigns pod IPs. It must match the `podSubnet` (e.g., `10.244.0.0/16`) to ensure proper networking.

---

## 3. Prerequisites

- **Kind Installed**: Ensure Kind is installed on your system (`kind --version`).
- **kubectl Installed**: Verify `kubectl` is installed and configured (`kubectl version --client`).
- **Docker Running**: Kind uses Docker to run cluster nodes, so Docker must be active (`docker info`).
- **Sufficient Resources**: Ensure your host has adequate resources (e.g., 8GB RAM, 4 CPUs, 20GB disk) for a small cluster with one control-plane and one worker node.

---

## 4. Update `kind-cluster-config.yaml`

Your original `kind-cluster-config.yaml` needs minor changes to disable Flannel, set IPv4-only mode, and ensure compatibility with Calico. Below is the updated configuration with only the necessary changes highlighted.

### Updated `kind-cluster-config.yaml`
```yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: ibtisam
nodes:
  - role: control-plane
    image: kindest/node:v1.32.3
    extraPortMappings:
      - containerPort: 6443
        hostPort: 6443
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
  disableDefaultCNI: true          # Changed: Disable Flannel to use Calico
  podSubnet: "10.244.0.0/16"      # Unchanged: IPv4 pod subnet
  serviceSubnet: "10.96.0.0/12"   # Unchanged
  apiServerAddress: "127.0.0.1"   # Unchanged
  apiServerPort: 6443             # Unchanged
kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        authorization-mode: Node,RBAC
featureGates:
  IPv6DualStack: false           # Changed: Disable dual-stack for IPv4-only
containerdConfigPatches:
  - |
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
```

### Key Changes
1. **disableDefaultCNI: true**:
   - Disables Flannel, preventing Kind from installing the default CNI. This allows you to manually install Calico after cluster creation.
   - Without a CNI, pods (e.g., `coredns`) will be in a `Pending` state until Calico is applied.

2. **IPv6DualStack: false**:
   - Disables dual-stack networking, configuring the cluster for IPv4-only. This simplifies Calico’s configuration, as you won’t need an IPv6 pool.

3. **podSubnet: "10.244.0.0/16"**:
   - Retained as is, as it’s a standard, conflict-free range for pod IPs. This matches the `--cluster-cidr` and will be used by Calico.

4. **Other Settings**:
   - The `serviceSubnet`, node configurations, port mappings, RBAC, and `overlayfs` settings remain unchanged, as they don’t directly affect the CNI switch.

### Why Keep `podSubnet: "10.244.0.0/16"`?
- **Avoid Conflicts**: The `10.244.0.0/16` range is unlikely to overlap with local networks (unlike Calico’s default `192.168.0.0/16`, which may conflict with home routers or Docker).
- **Standard Practice**: It’s a common default for Kubernetes clusters (used by Flannel, k3s, etc.), ensuring compatibility with tools and tutorials.
- **No Cluster Recreation**: Keeping the existing `podSubnet` avoids the need to recreate the cluster or update workloads that rely on this range.

---

## 5. Configure the Calico Manifest

Calico’s manifest (`calico.yaml`) must be updated to align with your cluster’s `podSubnet` (`10.244.0.0/16`). Since `IPv6DualStack` is disabled, only the IPv4 pool needs configuration.

### Steps to Update `calico.yaml`
1. **Download the Manifest**:
   - Get the latest Calico manifest compatible with Kubernetes v1.32.3 (use Calico v3.28 or newer as of April 2025):
     ```bash
     curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
     ```
   - Check the [Calico documentation](https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind) for the latest version.

2. **Modify `CALICO_IPV4POOL_CIDR`**:
   - Open `calico.yaml` and locate the `calico-node` DaemonSet configuration (search for `CALICO_IPV4POOL_CIDR`). Update it to:
     ```yaml
     - name: CALICO_IPV4POOL_CIDR
       value: "10.244.0.0/16"
     - name: CALICO_DISABLE_FILE_LOGGING
       value: "true"
     ```
   - **Changes**:
     - Replace the default `192.168.0.0/16` (or uncomment the line if commented) with `10.244.0.0/16` to match your `podSubnet`.
     - Keep `CALICO_DISABLE_FILE_LOGGING: "true"` to ensure logs are accessible via `kubectl logs`.
   - **No IPv6 Configuration**:
     - Since `IPv6DualStack: false`, do not add `CALICO_IPV6POOL_CIDR` or any IPv6 settings. Calico will operate in IPv4-only mode.

3. **Optional: Explicitly Disable IPv6**:
   - To ensure Calico doesn’t attempt IPv6, you can add:
     ```yaml
     - name: IP
       value: "autodetect"
     - name: IP6
       value: "none"
     ```
     This is usually unnecessary, as `IPv6DualStack: false` already configures the cluster for IPv4-only.

### Why Modify `calico.yaml` Instead of `podSubnet`?
- **Alignment with Cluster**: The `CALICO_IPV4POOL_CIDR` must match the `podSubnet` (`10.244.0.0/16`), which is the `--cluster-cidr`. A mismatch causes pods to receive invalid IPs, breaking networking.
- **Avoid Conflicts**: Calico’s default `192.168.0.0/16` may conflict with local networks (e.g., home routers, Docker). Using `10.244.0.0/16` is safer.
- **Simpler Change**: Editing `calico.yaml` is a localized change that doesn’t require recreating the cluster, unlike changing `podSubnet`.
- **Best Practice**: Kubernetes clusters commonly use `10.244.0.0/16`, and Calico’s manifest is designed to be customized to match the cluster’s `--cluster-cidr`.

---

## 6. Deploy the Cluster and Install Calico

Follow these steps to create the cluster and set up Calico:

1. **Save the Updated `kind-cluster-config.yaml`**:
   - Ensure the config includes `disableDefaultCNI: true`, `podSubnet: "10.244.0.0/16"`, and `IPv6DualStack: false` as shown above.

2. **Create the Kind Cluster**:
   - Run:
     ```bash
     kind create cluster --config kind-cluster-config.yaml
     ```
   - This creates the cluster named `ibtisam` without a CNI. Pods like `coredns` will be in a `Pending` state until Calico is installed.

3. **Apply the Calico Manifest**:
   - Apply the modified `calico.yaml`:
     ```bash
     kubectl apply -f calico.yaml
     ```
   - This deploys Calico’s components, including:
     - `calico-node` DaemonSet (runs on each node for networking).
     - `calico-kube-controllers` (manages network policies and IP pools).

---

## 7. Verify the Setup

After applying Calico, verify that the cluster and networking are functioning correctly:

1. **Check Calico Pods**:
   - Ensure `calico-node` pods are running on all nodes:
     ```bash
     kubectl get pods -n kube-system -l k8s-app=calico-node
     ```
     Expected output:
     ```
     NAME                READY   STATUS    RESTARTS   AGE
     calico-node-xyz     1/1     Running   0          2m
     ```
   - Verify `calico-kube-controllers`:
     ```bash
     kubectl get pods -n kube-system -l k8s-app=calico-kube-controllers
     ```

2. **Verify System Pods**:
   - Check that `coredns` and other system pods are no longer `Pending`:
     ```bash
     kubectl get pods -n kube-system
     ```
     Expected output: All pods in `Running` state.

3. **Test Pod Networking**:
   - Deploy a sample pod to verify IP assignment:
     ```bash
     kubectl run nginx --image=nginx --restart=Never
     kubectl get pods -o wide
     ```
     Expected output:
     ```
     NAME    READY   STATUS    RESTARTS   AGE   IP             NODE
     nginx   1/1     Running   0          1m    10.244.0.5     worker-1
     ```
     Confirm the IP is in the `10.244.0.0/16` range (e.g., `10.244.0.5`).

4. **Test Connectivity**:
   - Create a second pod to test pod-to-pod communication:
     ```bash
     kubectl run test --image=busybox --restart=Never --rm -it -- /bin/sh
     ```
     Inside the pod, ping the `nginx` pod’s IP (e.g., `10.244.0.5`):
     ```bash
     ping 10.244.0.5
     ```
     Expected output: Successful pings.

5. **Optional: Test Network Policies**:
   - Calico’s key feature is support for `NetworkPolicy`. Create a sample policy to allow traffic to the `nginx` pod:
     ```yaml
     apiVersion: networking.k8s.io/v1
     kind: NetworkPolicy
     metadata:
       name: allow-nginx
       namespace: default
     spec:
       podSelector:
         matchLabels:
           run: nginx
       policyTypes:
       - Ingress
       ingress:
       - from:
         - podSelector: {}
     ```
     Apply it:
     ```bash
     kubectl apply -f nginx-policy.yaml
     ```
     Test connectivity again to ensure the policy allows traffic.

---

## 8. Troubleshooting

If issues arise, use these steps to diagnose:

1. **Pods Stuck in `Pending`**:
   - Check Calico pod logs:
     ```bash
     kubectl logs -n kube-system -l k8s-app=calico-node
     ```
   - Verify the `calico-node` DaemonSet:
     ```bash
     kubectl get ds -n kube-system
     ```

2. **Networking Issues**:
   - Confirm the IP pool matches `podSubnet`:
     ```bash
     kubectl get ippool -o yaml
     ```
     Expected `cidr`: `10.244.0.0/16`.
   - Check for CIDR mismatches or conflicts with local networks.

3. **Resource Constraints**:
   - Ensure your host has sufficient CPU/memory (e.g., 8GB RAM, 4 CPUs). Calico is slightly more resource-intensive than Flannel.

4. **Common Errors**:
   - **IP assignment failure**: Ensure `CALICO_IPV4POOL_CIDR` is `10.244.0.0/16` in `calico.yaml`.
   - **Calico pods not starting**: Check for image pull issues or resource limits (`kubectl describe pod -n kube-system`).

---

## 9. Considerations for IPv6DualStack

If you later decide to enable `IPv6DualStack: true`, you’ll need additional Calico configuration:

1. **Update Kind Config**:
   - Set `featureGates: IPv6DualStack: true` in `kind-cluster-config.yaml`.

2. **Update Calico Manifest**:
   - Add an IPv6 pool:
     ```yaml
     - name: CALICO_IPV6POOL_CIDR
       value: "fd00:10:244::/48"
     ```
   - Ensure `CALICO_IPV4POOL_CIDR` remains `10.244.0.0/16`.

3. **Enable IPv6 in Docker**:
   - Update `/etc/docker/daemon.json`:
     ```json
     {
       "ipv6": true,
       "fixed-cidr-v6": "fd00::/80"
     }
     ```
   - Restart Docker:
     ```bash
     sudo systemctl restart docker
     ```

4. **Verify Dual-Stack**:
   - Pods should receive both IPv4 (e.g., `10.244.0.5`) and IPv6 (e.g., `fd00:10:244::5`) addresses.

Since you’ve chosen `IPv6DualStack: false`, these steps are unnecessary for now.

---

## 10. Why Modify Calico Manifest Instead of `podSubnet`?

You might wonder why we update `CALICO_IPV4POOL_CIDR` in `calico.yaml` to match `podSubnet: "10.244.0.0/16"` instead of changing `podSubnet` to Calico’s default `192.168.0.0/16`. Here’s why:

- **Avoid Network Conflicts**:
  - `192.168.0.0/16` is a common private IP range used by home routers, VPNs, or Docker’s bridge network. Using it risks IP conflicts, causing pods to be unreachable or misrouted.
  - `10.244.0.0/16` is a safer, Kubernetes-standard range unlikely to overlap with local networks.

- **No Cluster Recreation**:
  - Changing `podSubnet` requires deleting and recreating the cluster:
    ```bash
    kind delete cluster --name ibtisam
    kind create cluster --config kind-cluster-config.yaml
    ```
  - Editing `calico.yaml` is less disruptive, as it doesn’t affect the cluster’s core configuration.

- **Workload Compatibility**:
  - Existing workloads or configurations (e.g., `NetworkPolicy`, service IPs) may rely on `10.244.0.0/16`. Changing to `192.168.0.0/16` would break these.

- **Best Practice**:
  - Kubernetes clusters commonly use `10.244.0.0/16` (e.g., Flannel’s default). Aligning Calico with this standard ensures compatibility with tools and tutorials.
  - Calico’s manifest is designed to be customized, with `CALICO_IPV4POOL_CIDR` explicitly meant to match the cluster’s `--cluster-cidr`.

- **Future Flexibility**:
  - Keeping `10.244.0.0/16` allows easy switching to other CNIs (e.g., Flannel, Cilium) without changing `podSubnet`.

---

## 11. Additional Notes

- **Resource Usage**:
  - Calico is slightly more resource-intensive than Flannel due to features like network policies and the Felix agent. Monitor your host’s resource usage, especially with multiple nodes.

- **Documentation**:
  - Document changes to `calico.yaml` (e.g., in a `README`) to clarify why `CALICO_IPV4POOL_CIDR` is set to `10.244.0.0/16`. This helps team members or your future self.

- **Version Compatibility**:
  - Ensure Calico v3.28 (or newer) is compatible with Kubernetes v1.32.3. Check [Calico release notes](https://github.com/projectcalico/calico/releases) for details.

- **Scalability**:
  - Your config includes commented-out nodes for additional control-plane and worker nodes. To enable them for high availability or increased capacity, uncomment the relevant sections and reapply the cluster configuration.

- **Network Policies**:
  - Leverage Calico’s `NetworkPolicy` support to enhance security. Start with simple policies (like the `allow-nginx` example) and expand as needed.

---

## 12. Summary

To use Calico as the CNI in your Kind cluster:
1. Update `kind-cluster-config.yaml`:
   - Set `disableDefaultCNI: true` to disable Flannel.
   - Set `IPv6DualStack: false` for IPv4-only.
   - Keep `podSubnet: "10.244.0.0/16"` as the `--cluster-cidr`.
2. Modify `calico.yaml`:
   - Set `CALICO_IPV4POOL_CIDR` to `10.244.0.0/16`.
   - Keep `CALICO_DISABLE_FILE_LOGGING: "true"`.
   - No IPv6 settings needed.
3. Create the cluster: `kind create cluster --config kind-cluster-config.yaml`.
4. Apply Calico: `kubectl apply -f calico.yaml`.
5. Verify Calico pods, system pods, and pod networking.
6. Optionally, test network policies to leverage Calico’s features.

### ONE Command Solution

Just copy and paste the following commands into your terminal in order:

```bash
curl -s https://raw.githubusercontent.com/ibtisam-iq/SilverKube/main/kind-calico-config-file.yaml | kind create cluster --config -
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
sed -i 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/' calico.yaml
sed -i 's/#   value: "192.168.0.0\/16"/  value: "10.244.0.0\/16"/' calico.yaml
kubectl apply -f calico.yaml
```

This setup ensures a robust, IPv4-only Kind cluster with Calico, supporting advanced networking features while maintaining compatibility with your existing configuration. The `10.244.0.0/16` range avoids conflicts, and modifying `calico.yaml` is less invasive than changing `podSubnet`.
