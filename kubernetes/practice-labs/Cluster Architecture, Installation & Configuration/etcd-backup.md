# ETCD Backup & Restore

A repo-ready, copy‑paste runbook for backing up and restoring **etcd** on a kubeadm‑managed control plane. Written to match the workflow we practiced (single-node etcd, static pod) and to avoid common crashloops after a restore.

---

## ✅ Scope & Assumptions

* **Single-node etcd** deployed by **kubeadm** as a **static pod** (`/etc/kubernetes/manifests/etcd.yaml`).
* You have root or sudo access on the **control plane node**.
* Certs at default kubeadm paths: `/etc/kubernetes/pki/etcd/`.
* Backup destination (as per task): `/opt/cluster_backup.db`.
* Restore data dir (as per task): `/root/default.etcd`.
* Save restore console output to: `restore.txt`.

> For HA/multi-node etcd, see **When to use extra flags** below.

---

## TL;DR (Cheat Sheet)

```bash
# 0) env
export ETCDCTL_API=3
export EP=https://127.0.0.1:2379
export CERT=/etc/kubernetes/pki/etcd/server.crt
export KEY=/etc/kubernetes/pki/etcd/server.key
export CACERT=/etc/kubernetes/pki/etcd/ca.crt

# 1) backup
etcdctl --endpoints=$EP --cert=$CERT --key=$KEY --cacert=$CACERT \
  snapshot save /opt/cluster_backup.db

# 2) verify snapshot
etcdctl snapshot status /opt/cluster_backup.db -w table

# 3) stop etcd (static pod): pause kubelet from recreating it
mv /etc/kubernetes/manifests/etcd.yaml /etc/kubernetes/

# 4) clean data dir then restore
rm -rf /root/default.etcd
etcdctl snapshot restore /opt/cluster_backup.db \
  --data-dir=/root/default.etcd \
  --name=controlplane \
  --initial-advertise-peer-urls=https://<CONTROLPLANE_IP>:2380 \
  --initial-cluster=controlplane=https://<CONTROLPLANE_IP>:2380 \
  --initial-cluster-token=etcd-cluster-1 \
  --initial-cluster-state=new \

# 5) permissions
chown -R root:root /root/default.etcd
chmod -R 700 /root/default.etcd

# 6) put manifest back and restart kubelet
mv /etc/kubernetes/etcd.yaml /etc/kubernetes/manifests/
systemctl restart kubelet

# 7) health checks
etcdctl --endpoints=$EP --cert=$CERT --key=$KEY --cacert=$CACERT endpoint health
kubectl get pods -A
```

---

## 1) Prepare Environment

```bash
export ETCDCTL_API=3
export EP=https://127.0.0.1:2379
export CERT=/etc/kubernetes/pki/etcd/server.crt
export KEY=/etc/kubernetes/pki/etcd/server.key
export CACERT=/etc/kubernetes/pki/etcd/ca.crt
```

* `ETCDCTL_API=3` ensures v3 API.
* `EP` points to the local secured endpoint used by kubeadm setups.

---

## 2) Take a Backup (Snapshot)

```bash
etcdctl --endpoints=$EP --cert=$CERT --key=$KEY --cacert=$CACERT \
  snapshot save /opt/cluster_backup.db
```

**Verify snapshot file:**

```bash
etcdctl snapshot status /opt/cluster_backup.db -w table
```

> Keep `/opt/cluster_backup.db` safe/off-node for disaster recovery.

---

## 3) Stop etcd (Static Pod) Before Restore

Kubelet recreates static pods automatically from `/etc/kubernetes/manifests`. Temporarily move the etcd manifest:

```bash
mv /etc/kubernetes/manifests/etcd.yaml /etc/kubernetes/
```

> This *stops* the etcd pod cleanly while you restore the data directory.

---

## 4) Restore Snapshot into a Fresh Data Dir

**Always** start from an empty data directory:

```bash
rm -rf /root/default.etcd
```

### Recommended (explicit) restore — robust and matches manifest

```bash
etcdctl snapshot restore /opt/cluster_backup.db \
  --data-dir=/root/default.etcd \
  --name=controlplane \
  --initial-advertise-peer-urls=https://<CONTROLPLANE_IP>:2380 \
  --initial-cluster=controlplane=https://<CONTROLPLANE_IP>:2380 \
  --initial-cluster-token=etcd-cluster-1 \
  --initial-cluster-state=new
```

* Replace `<CONTROLPLANE_IP>` with the node IP your manifest uses (e.g., `172.30.1.2`).
* Output is saved to `/root/restore.txt` as required.

### Minimal restore — fine for same-node single-member

If you’re restoring on the **same** node with **same** IP/name and single-member etcd:

```bash
etcdctl snapshot restore /opt/cluster_backup.db \
  --data-dir=/root/default.etcd
```

> Use minimal only when nothing changed. If you hit member/cluster mismatch errors, rerun the **explicit** restore above.

### Fix permissions (critical)

```bash
chown -R root:root /root/default.etcd
chmod -R 700 /root/default.etcd
```

---

## 5) Update/Confirm the Static Pod Manifest

Open `/etc/kubernetes/etcd.yaml` (the file you moved) and ensure these flags **exist and match the restore**:

```yaml
    - --data-dir=/root/default.etcd
    - --name=controlplane
    - --initial-advertise-peer-urls=https://<CONTROLPLANE_IP>:2380
    - --initial-cluster=controlplane=https://<CONTROLPLANE_IP>:2380
    - --initial-cluster-token=etcd-cluster-1
    - --initial-cluster-state=new
```

Also ensure these volume mounts/hostPaths are set:

```yaml
  volumeMounts:
  - mountPath: /root/default.etcd
    name: etcd-data
  - mountPath: /etc/kubernetes/pki/etcd
    name: etcd-certs

  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /root/default.etcd
      type: DirectoryOrCreate
    name: etcd-data
```

> If your manifest already contains these (common in kubeadm), just confirm they match your restore values/IP and data-dir.

---

## 6) Bring etcd Back

```bash
mv /etc/kubernetes/etcd.yaml /etc/kubernetes/manifests/
systemctl restart kubelet
```

Kubelet will detect the manifest and recreate the pod.

---

## 7) Verify Health

**etcd health**

```bash
etcdctl --endpoints=$EP --cert=$CERT --key=$KEY --cacert=$CACERT endpoint health
```

**Cluster basics**

```bash
kubectl get nodes
kubectl get pods -A
```

**If the pod restarts**, inspect logs:

```bash
kubectl -n kube-system logs etcd-$(hostname) --previous
# or container runtime logs
crictl ps | grep etcd
crictl logs <CONTAINER_ID>
```

---

## When You Need Extra Flags vs. Minimal Restore

**Minimal restore** (only `--data-dir`) works when **all** are true:

* Single-node etcd (no peers).
* Restoring on the **same node** with the **same IP/hostname**.
* Your static pod manifest’s etcd flags match what etcd auto-derives.

Use **explicit flags** (`--name`, `--initial-*`, token, state) when:

* HA/multi-node etcd.
* Node **IP/hostname changed**, or moving to new hardware/VM.
* You see errors like *name mismatch*, *inconsistent cluster ID*, *mismatch member ID*.
* You want deterministic, reproducible restores that match the manifest exactly (recommended).

**Golden Rule:** single-node same-node → minimal is OK; anything else → explicit.

---

## Common Pitfalls & Fixes

* **CrashLoopBackOff after restore**

  * ✅ Fix permissions:

    ```bash
    chown -R root:root /root/default.etcd
    chmod -R 700 /root/default.etcd
    systemctl restart kubelet
    ```
  * Ensure manifest `--data-dir` matches restored dir.
  * Ensure `--initial-cluster=controlplane=https://<IP>:2380` and `--initial-cluster-state=new` exist.

* **`initial-cluster` empty in logs**

  * Restore again with explicit flags (see step 4), and confirm manifest includes them.

* **Name/cluster ID mismatch**

  * Wipe data dir and re-restore with the **same `--name`** used in manifest and correct `--initial-cluster`.

* **Probes killing etcd too early**

  * Temporarily increase `startupProbe`/`livenessProbe` thresholds while troubleshooting, then revert.

* **Old default dir left behind**

  * If you changed data-dir, consider archiving the old one to avoid confusion:

    ```bash
    mv /var/lib/etcd /var/lib/etcd.bak-$(date +%F-%H%M)
    ```
---

## `etcdctl` binary installation

```bash
wget https://github.com/etcd-io/etcd/releases/download/v3.5.15/etcd-v3.5.15-linux-amd64.tar.gz
tar --no-same-owner -xvf etcd-v3.5.15-linux-amd64.tar.gz
sudo mv etcd-v3.5.15-linux-amd64/etcd* /usr/local/bin/
etcdctl version
```

## `etcdctl` and `etcdutl` binaries are installed

```bash
# save the backup as /opt/ibtisam.db
export ETCDCTL_API=3
etcdctl snapshot save /opt/ibtisam.db
    --endpoints 127.0.0.1:2379
    --cert=/etc/kubernetes/pki/etcd/server.crt
    --key=/etc/kubernetes/pki/etcd/server.key
    --cacert=/etc/kubernetes/pki/etcd/ca.crt

# restore
etcdutl snapshot restore /opt/ibtisam.db --data-dir /var/lib/etcd/backup

# Now, edit `--data-dir` location (mandatory) and Volume Mounts (if required) in `/etc/kubernetes/manifests/etcd.yaml`.
systemctl restart kubelet
watch crictl ps
# it can take a few mintues.
```
> **Note:**
> 
> controlplane ~ ✖ etcdutl snapshot restore /opt/ibtisam.db --data-dir=/var/lib/etcd/
> 
> Error: data-dir "/var/lib/etcd/" not empty or could not be read

---

## `etcdctl` and `etcdutl` binaries are not installed

```bash
# save the backup as /opt/ibtisam.db
controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd/backup/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
error: exec: "ETCDCTL_API=3": executable file not found in $PATH: unknown

controlplane ~ ✖ export ETCDCTL_API=3

controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- etcdctl snapshot save /var/lib/etcd/backup/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
Error: could not open /var/lib/etcd/backup/ibtisam.db.part (open /var/lib/etcd/backup/ibtisam.db.part: no such file or directory)
command terminated with exit code 5

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- mkdir -p /var/lib/etcd/backup/
error: exec: "mkdir": executable file not found in $PATH: unknown

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- etcdctl snapshot save /var/lib/etcd/ibtisam.db --endpoints 127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt
{"level":"info","ts":"2025-08-04T08:15:23.920801Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/var/lib/etcd/ibtisam.db.part"}
{"level":"info","ts":"2025-08-04T08:15:23.928325Z","logger":"client","caller":"v3@v3.5.21/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2025-08-04T08:15:23.928373Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"127.0.0.1:2379"}
{"level":"info","ts":"2025-08-04T08:15:24.120010Z","logger":"client","caller":"v3@v3.5.21/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2025-08-04T08:15:24.120097Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"127.0.0.1:2379","size":"4.2 MB","took":"now"}
{"level":"info","ts":"2025-08-04T08:15:24.120165Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/var/lib/etcd/ibtisam.db"}
Snapshot saved at /var/lib/etcd/ibtisam.db

controlplane ~ ➜  ls -l /var/lib/etcd/
total 4128
-rw------- 1 root root 4218912 Aug  4 08:15 ibtisam.db
drwx------ 4 root root    4096 Aug  4 06:17 member

controlplane ~ ➜  cp /var/lib/etcd/ibtisam.db /opt/ibtisam.db

controlplane ~ ➜  ls -l /opt/ibtisam.db 
-rw------- 1 root root 4218912 Aug  4 08:17 /opt/ibtisam.db

# restore
controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- etcdutl snapshot restore /var/lib/etcd/ibtisam.db --data-dir /var/lib/etcd/backup
error: exec: "etcdutl": executable file not found in $PATH: unknown

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -- etcdctl snapshot restore /var/lib/etcd/ibtisam.db --data-dir /var/lib/etcd/backup
Deprecated: Use `etcdutl snapshot restore` instead.

2025-08-04T08:26:37Z    info    snapshot/v3_snapshot.go:265     restoring snapshot      {"path": "/var/lib/etcd/ibtisam.db", "wal-dir": "/var/lib/etcd/backup/member/wal", "data-dir": "/var/lib/etcd/backup", "snap-dir": "/var/lib/etcd/backup/member/snap", "initial-memory-map-size": 0}
2025-08-04T08:26:37Z    info    membership/store.go:138 Trimming membership information from the backend...
2025-08-04T08:26:37Z    info    membership/cluster.go:421       added member    {"cluster-id": "cdf818194e3a8c32", "local-member-id": "0", "added-peer-id": "8e9e05c52164694d", "added-peer-peer-urls": ["http://localhost:2380"], "added-peer-is-learner": false}
2025-08-04T08:26:37Z    info    snapshot/v3_snapshot.go:293     restored snapshot       {"path": "/var/lib/etcd/ibtisam.db", "wal-dir": "/var/lib/etcd/backup/member/wal", "data-dir": "/var/lib/etcd/backup", "snap-dir": "/var/lib/etcd/backup/member/snap", "initial-memory-map-size": 0} 



Every 2.0s: crictl ps                                                                                                                controlplane: Mon Aug  4 08:42:45 2025

CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD
                  NAMESPACE
9dc476ef26bba       499038711c081       42 seconds ago      Running             etcd                      0                   faa2552bcf491       etcd-controlplane
                  kube-system
6518ecab33fa5       8d72586a76469       43 seconds ago      Running             kube-scheduler            2                   f696e6c7eff61       kube-scheduler-controlpla
ne                kube-system
b62ea4b95d1b0       1d579cb6d6967       2 minutes ago       Running             kube-controller-manager   2                   2786dd75a9711       kube-controller-manager-c
ontrolplane       kube-system
2aacb9fa0e4f0       6331715a2ae96       2 hours ago         Running             calico-kube-controllers   0                   857e400da0314       calico-kube-controllers-5
745477d4d-cvh4q   kube-system
11cf37d306af6       ead0a4a53df89       2 hours ago         Running             coredns                   0                   15fc43ad65062       coredns-7484cd47db-dpdtg
                  kube-system
bb1da48d9e35f       ead0a4a53df89       2 hours ago         Running             coredns                   0                   066b0d2818b2c       coredns-7484cd47db-pwjqg
                  kube-system
d8be9b6e3e150       c9fe3bce8a6d8       2 hours ago         Running             kube-flannel              0                   b633c57f49b33       canal-bn9v4
                  kube-system
ebf595f67642d       feb26d4585d68       2 hours ago         Running             calico-node               0                   b633c57f49b33       canal-bn9v4
                  kube-system
cc9ddc27d1910       f1184a0bd7fe5       2 hours ago         Running             kube-proxy                0                   79a58dea2612c       kube-proxy-7wb5z
                  kube-system
9efa8a481d67d       6ba9545b2183e       2 hours ago         Running             kube-apiserver            0                   f9cde1f1f1329       kube-apiserver-controlpla
ne                kube-system

```

---

## `etcd --version`

Run `etcd --version` and store the output at `/opt/course/7/etcd-version`

```bash
controlplane ~ ➜  etcd --version
-bash: etcd: command not found

# Well, etcd is not installed directly on the controlplane but it runs as a Pod instead. So we do:

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -it -- "etcd --version"
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "26cf1ed3170ba3987fd80d8a5bea007750011fa77f5fb678b505e3e8b7feb857": OCI runtime exec failed: exec failed: unable to start container process: exec: "etcd --version": executable file not found in $PATH: unknown

controlplane ~ ✖ k exec -n kube-system etcd-controlplane -it -- etcd --version
etcd Version: 3.6.4
Git SHA: 5400cdc
Go Version: go1.23.11
Go OS/Arch: linux/amd64

controlplane ~ ➜  k exec -n kube-system etcd-controlplane -it -- sh
sh-5.2# etcd --version                                                                                                                                                    
etcd Version: 3.6.4
Git SHA: 5400cdc
Go Version: go1.23.11
Go OS/Arch: linux/amd64
sh-5.2# exit
exit

controlplane ~ ➜  k exec -n kube-system etcd-controlplane -it -- etcd --version > /opt/course/7/etcd-version

controlplane ~ ➜  cat /opt/course/7/etcd-version
etcd Version: 3.6.4
Git SHA: 5400cdc
Go Version: go1.23.11
Go OS/Arch: linux/amd64

controlplane ~ ➜  
```
---

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
