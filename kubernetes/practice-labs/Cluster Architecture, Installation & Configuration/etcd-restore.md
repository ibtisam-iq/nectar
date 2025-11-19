Perfect sweetheart — you’ve already proven the cause: the snapshot was restored **with peer URL `http://localhost:2380`**, while your static-pod manifest expects **`https://192.168.102.161:2380`** (and uses TLS for peers). That mismatch makes etcd try to reconcile member metadata and panic with `failed to update; member unknown`.

Fix: re-do the restore **with the exact cluster/peer values from the manifest**, remove the current (wrong) data, and copy the restored tree in *preserving mode*. Follow these commands **exactly** (I include brief explanations).

---

# 1) Stop kubelet (prevent static pod from starting while we prepare)

```bash
sudo systemctl stop kubelet
```

# 2) Remove the broken data dir

```bash
sudo rm -rf /var/lib/etcd/*
```

(You already did this before — repeat to be safe.)

# 3) Delete a restore temporary directory

```bash
sudo rm -rf /tmp/ibtisam/*
```

# 4) Restore the snapshot with the exact peer URLs and name into a temporary directory

Use these options so the restored metadata matches `/etc/kubernetes/manifests/etcd.yaml`:

```bash
sudo ETCDCTL_API=3 etcdctl snapshot restore /opt/backup.db \
  --name controlplane \
  --initial-cluster controlplane=https://192.168.102.161:2380 \
  --initial-advertise-peer-urls https://192.168.102.161:2380 \
  --data-dir /tmp/ibtisam
```

Why this matters: `--initial-advertise-peer-urls` and `--initial-cluster` set the member’s peer URL recorded in the snapshot metadata. They must match the static pod args (`https://192.168.102.161:2380`) including protocol (`https`) and IP.

# 5) Copy the restored files correctly (preserve structure & attributes)

```bash
sudo cp -a /tmp/ibtisam/* /var/lib/etcd/
```

# 6) Ensure correct ownership and perms

```bash
sudo chown -R root:root /var/lib/etcd
sudo chmod -R 700 /var/lib/etcd
```

# 7) Start kubelet (static pod will create etcd container)

```bash
sudo systemctl start kubelet
```

# 8) Verify status and logs

Wait a few seconds, then:

```bash
crictl ps -a | grep etcd
crictl logs <etcd-container-id>
```

Or check journal for kubelet/static pod if needed:

```bash
sudo journalctl -u kubelet -f --no-hostname --output=short
```

---

```bash
controlplane /var/lib/etcd ➜  grep peer-urls /etc/kubernetes/manifests/etcd.yaml
    - --initial-advertise-peer-urls=https://192.168.102.161:2380
    - --listen-peer-urls=https://192.168.102.161:2380

controlplane /var/lib/etcd ➜  sudo systemctl stop kubelet

controlplane /var/lib/etcd ➜  sudo rm -rf /var/lib/etcd/*

controlplane /var/lib/etcd ➜  sudo rm -rf /tmp/ibtisam

controlplane /var/lib/etcd ➜  sudo ETCDCTL_API=3 etcdctl snapshot restore /opt/backup.db \
  --name controlplane \
  --initial-cluster controlplane=https://192.168.102.161:2380 \
  --initial-advertise-peer-urls https://192.168.102.161:2380 \
  --data-dir /tmp/ibtisam
Error: data-dir "/tmp/ibtisam" exists

controlplane /var/lib/etcd ✖ sudo rm -rf /tmp/ibtisam/*

controlplane /var/lib/etcd ➜  sudo ETCDCTL_API=3 etcdctl snapshot restore /opt/backup.db   --name controlplane   --initial-cluster controlplane=https://192.168.102.161:2380   --initial-advertise-peer-urls https://192.168.102.161:2380   --data-dir /tmp/ibtisam
Error: data-dir "/tmp/ibtisam" exists

controlplane /var/lib/etcd ✖ ls /tmp/ibtisam/

controlplane /var/lib/etcd ➜  rm -rf /tmp/ibtisam/

controlplane /var/lib/etcd ➜  ls /tmp/ibtisam/
ls: cannot access '/tmp/ibtisam/': No such file or directory

controlplane /var/lib/etcd ✖ sudo ETCDCTL_API=3 etcdctl snapshot restore /opt/backup.db   --name controlplane   --initial-cluster controlplane=https://192.168.102.161:2380   --initial-advertise-peer-urls https://192.168.102.161:2380   --data-dir /tmp/ibtisam
2025-11-19 12:48:26.237073 I | mvcc: restore compact to 5408
2025-11-19 12:48:26.256710 I | etcdserver/membership: added member 666eab07ec088f66 [https://192.168.102.161:2380] to cluster bd87b675dbfafcae

controlplane /var/lib/etcd ➜  sudo cp -a /tmp/ibtisam/* /var/lib/etcd/

controlplane /var/lib/etcd ➜  ls
member

controlplane /var/lib/etcd ➜  sudo chown -R root:root /var/lib/etcd

controlplane /var/lib/etcd ➜  sudo chmod -R 700 /var/lib/etcd

controlplane /var/lib/etcd ➜  sudo systemctl start kubelet

controlplane /var/lib/etcd ➜  k describe ns production 
Name:         production
Labels:       kubernetes.io/metadata.name=production
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:            production
  Resource         Used   Hard
  --------         ---    ---
  requests.cpu     300m   300m
  requests.memory  300Mi  300Mi

No LimitRange resource.

controlplane /var/lib/etcd ➜  k get po -n production 
NAME                   READY   STATUS    RESTARTS   AGE
abc-588f7f5777-6kl75   1/1     Running   0          59m
abc-588f7f5777-nj9qc   1/1     Running   0          59m
abc-588f7f5777-tbdw6   1/1     Running   0          59m

controlplane /var/lib/etcd ➜  k get no -o wide
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP       
controlplane   Ready    control-plane   96m   v1.34.0   192.168.102.161   
node01         Ready    <none>          95m   v1.34.0   192.168.102.156   
node02         Ready    <none>          95m   v1.34.0   192.168.102.166   

controlplane /var/lib/etcd ➜  cat /etc/kubernetes/manifests/etcd.yaml 
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://192.168.102.161:2379
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.102.161:2379
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://192.168.102.161:2380                                  # 3) use this
    - --initial-cluster=controlplane=https://192.168.102.161:2380                                 # 2) use this
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.102.161:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.102.161:2380
    - --name=controlplane                                                                         # 1) use this

controlplane /var/lib/etcd ➜  
```

---

## ⭐ 1) Why your restore failed originally

Because when you restored the etcd snapshot, you **did NOT use:**

* `--name`
* `--initial-cluster`
* `--initial-advertise-peer-urls`

So etcd restored with **default values**:

```
name = default
peer-url = http://localhost:2380
initial-cluster = default=http://localhost:2380
```

But your kubeadm etcd static pod uses:

```
name = controlplane
peer-url = https://192.168.102.161:2380
initial-cluster = controlplane=https://192.168.102.161:2380
```

This mismatch causes etcd to panic:

### **“failed to update; member unknown”**

Because the restored metadata does NOT match the running cluster metadata.

---

## ⭐ 2) What these three flags actually mean

### 🚩 `--name`

This is the etcd member’s identity.
Your kubeadm cluster uses:

```
--name=controlplane
```

If you restore without this, etcd will assign a random new name → mismatch → panic.

---

### 🚩 `--initial-cluster`

This defines the cluster topology (members + peer URLs).

Your kubeadm uses:

```
--initial-cluster=controlplane=https://192.168.102.161:2380
```

If the restore uses anything else (like localhost), etcd thinks:

> “This isn’t the same cluster.”

and panics.

---

### 🚩 `--initial-advertise-peer-urls`

This tells etcd **where it announces itself to other members**.

Your kubeadm uses:

```
--initial-advertise-peer-urls=https://192.168.102.161:2380
```

When you restored without this flag, etcd assumed:

```
http://localhost:2380
```

Huge mismatch → TLS mismatch → cluster metadata mismatch → panic.

---

## ⭐ Summary

| Flag                            | Why it matters                                |
| ------------------------------- | --------------------------------------------- |
| `--name`                        | Must match the etcd member name in static pod |
| `--initial-cluster`             | Must match cluster topology from static pod   |
| `--initial-advertise-peer-urls` | Must match peer URLs in static pod            |

**NEVER** trust the official etcd docs for kubeadm clusters.
**ALWAYS** extract values from `/etc/kubernetes/manifests/etcd.yaml`.
