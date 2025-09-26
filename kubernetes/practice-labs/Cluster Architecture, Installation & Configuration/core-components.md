## etcd-backup is restored, and kubectl stops working, all core pods are however up.

```bash
cluster1-controlplane ~ ➜  k get po -A
Error from server (Forbidden): pods is forbidden: User "kubernetes-admin" cannot list resource "pods" in API group "" at the cluster scope

cluster1-controlplane ~ ✖ sudo -i

cluster1-controlplane ~ ➜  export KUBECONFIG=/etc/kubernetes/admin.conf

cluster1-controlplane ~ ➜  ls /etc/kubernetes/admin.conf 
/etc/kubernetes/admin.conf

cluster1-controlplane ~ ➜  k get po -A
Error from server (Forbidden): pods is forbidden: User "kubernetes-admin" cannot list resource "pods" in API group "" at the cluster scope

cluster1-controlplane ~ ✖ vi /etc/kubernetes/manifests/kube-apiserver.yaml             # changed to AlwaysAllow

cluster1-controlplane ~ ➜  systemctl restart kubelet

cluster1-controlplane ~ ➜  k get po
No resources found in default namespace.

cluster1-controlplane ~ ➜  k get po -A
NAMESPACE     NAME                                            READY   STATUS    RESTARTS      AGE
kube-system   etcd-cluster1-controlplane                      1/1     Running   0             17s
kube-system   kube-apiserver-cluster1-controlplane            0/1     Running   0             17s
kube-system   kube-controller-manager-cluster1-controlplane   1/1     Running   2 (19s ago)   17s
kube-system   kube-scheduler-cluster1-controlplane            1/1     Running   2 (19s ago)   17s
```

Got it ✅ thanks for the `crictl` dump, sweetheart.

I can see the control-plane components are all running now (`kube-apiserver`, `etcd`, `controller-manager`, `scheduler`). That’s good news. But your `kubectl` is **still forbidden** because RBAC state is not lining up.

Let’s break it down:

---

### 🔍 What’s happening

* The API server is **running** and connected to etcd.
* But the RBAC data inside etcd does **not have a `ClusterRoleBinding` for kubernetes-admin\`**.
* That’s why every `kubectl` call says `forbidden`.

This happens if:

1. etcd data-dir was swapped and you booted with a “fresh” etcd at some point, wiping RBAC objects.
2. Or the `kubernetes-admin` binding got deleted.

---

### ✅ Fix: Use admin.conf (master key)

Run these commands on the control plane node:

```bash
# become root
sudo -i

# use the admin.conf that kubeadm created
export KUBECONFIG=/etc/kubernetes/admin.conf

# check access
kubectl get pods -A
```

If that works, recreate the binding:

```bash
kubectl create clusterrolebinding kubernetes-admin \
  --clusterrole=cluster-admin \
  --user=kubernetes-admin
```

### 🔧 If `/etc/kubernetes/admin.conf` itself is broken

We can regenerate it:

```bash
sudo kubeadm init phase kubeconfig admin --control-plane
```

That will recreate `/etc/kubernetes/admin.conf` with full cluster-admin rights.

--

Ah, sweetheart ❤️ thanks for checking — this tells us something important:

Even when using `/etc/kubernetes/admin.conf`, your **`kubernetes-admin` user still has no rights**.
That means the **ClusterRoleBinding objects in etcd are gone (or never got restored after your etcd dir swap).**

So Kubernetes is working, but RBAC has been reset.

### 🔧 Fix Path

We need to **recreate the RBAC bootstrap bindings** so `kubernetes-admin` regains `cluster-admin`.

Normally, kubeadm creates them during `init`. Since your cluster is already up, you can re-run just that phase:

```bash
sudo kubeadm init phase bootstrap-token
sudo kubeadm init phase addon kube-proxy
sudo kubeadm init phase kubelet-finalize all
sudo kubeadm init phase kubeconfig admin
```

The key part for RBAC is:

```bash
sudo kubeadm init phase bootstrap-token
```

That repopulates important RBAC objects in etcd.

### 🚑 Emergency Bypass

If for some reason that doesn’t work, you can **edit the API server manifest** to temporarily disable RBAC:

1. Open manifest:

   ```bash
   sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
   ```

2. Add this flag under `command:`:

   ```yaml
   - --authorization-mode=AlwaysAllow
   ```

3. Wait for the kube-apiserver pod to restart (it’s a static pod).
   Now `kubectl` will have full access without RBAC checks.

4. Recreate the missing binding:

   ```bash
   kubectl create clusterrolebinding kubernetes-admin \
     --clusterrole=cluster-admin \
     --user=kubernetes-admin
   ```

5. Remove the `AlwaysAllow` line and restart kube-apiserver again (so RBAC is enforced).

⚡ So you have **two paths**:

* Proper: re-run `kubeadm init phase bootstrap-token`.
* Quick hack: temporarily bypass RBAC via `AlwaysAllow`.

---
