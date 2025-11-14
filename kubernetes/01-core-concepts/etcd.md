```bash
# On Controlplane Host
controlplane ~ ➜  curl -k https://127.0.0.1:2379
curl: (56) OpenSSL SSL_read: error:0A00045C:SSL routines::tlsv13 alert certificate required, errno 0

controlplane ~ ✖ curl --cacert /etc/kubernetes/pki/etcd/ca.crt \
     --cert   /etc/kubernetes/pki/etcd/server.crt \
     --key    /etc/kubernetes/pki/etcd/server.key \
     https://127.0.0.1:2379/health
{"health":"true","reason":""}
controlplane ~ ➜

# Inside etcd Pod, when etcdctl binary is not installed on controlplane host

controlplane ~ ✖ k exec -it -n kube-system etcd-controlplane -- sh
sh-5.2# ETCDCTL_API=3 etcdctl --endpoints 127.0.0.1:2379 \    
>   --cert=/etc/kubernetes/pki/etcd/server.crt \
>   --key=/etc/kubernetes/pki/etcd/server.key \
>   --cacert=/etc/kubernetes/pki/etcd/ca.crt \
>   member list
{"level":"warn","ts":"2025-11-14T05:37:17.544835Z","caller":"flags/flag.go:94","msg":"unrecognized environment variable","environment-variable":"ETCDCTL_API=3"}
99487c420363552e, started, controlplane, https://192.168.102.162:2380, https://192.168.102.162:2379, false

sh-5.2# ETCDCTL_API=3 etcdctl \
>   --endpoints=https://127.0.0.1:2379 \
>   --cert=/etc/kubernetes/pki/etcd/server.crt \
>   --key=/etc/kubernetes/pki/etcd/server.key \
>   --cacert=/etc/kubernetes/pki/etcd/ca.crt \
>   endpoint health
{"level":"warn","ts":"2025-11-14T05:42:30.621473Z","caller":"flags/flag.go:94","msg":"unrecognized environment variable","environment-variable":"ETCDCTL_API=3"}
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 9.507896ms
sh-5.2#  
```


### 📦 ETCD Static Pod (`/etc/kubernetes/manifests/etcd.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://192.168.102.134:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.102.134:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --experimental-initial-corrupt-check=true
    - --experimental-watch-progress-notify-interval=5s
    - --initial-advertise-peer-urls=https://192.168.102.134:2380
    - --initial-cluster=controlplane=https://192.168.102.134:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.102.134:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.102.134:2380
    - --name=controlplane
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    image: registry.k8s.io/etcd:3.5.21-0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /livez
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    name: etcd
    readinessProbe:
      failureThreshold: 3
      httpGet:
        host: 127.0.0.1
        path: /readyz
        port: 2381
        scheme: HTTP
      periodSeconds: 1
      timeoutSeconds: 15
    resources:
      requests:
        cpu: 100m
        memory: 100Mi
    startupProbe:
      failureThreshold: 24
      httpGet:
        host: 127.0.0.1
        path: /readyz
        port: 2381
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd-data
    - mountPath: /etc/kubernetes/pki/etcd
      name: etcd-certs
  hostNetwork: true
  priority: 2000001000
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
  - hostPath:
      path: /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd-data
status: {}
```

---

```bash
COMMANDS:
        auth disable            Disables authentication
        auth enable             Enables authentication
        auth status             Returns authentication status
        del                     Removes the specified key or range of keys [key, range_end)
        endpoint health         Checks the healthiness of endpoints specified in `--endpoints` flag
        endpoint status         Prints out the status of endpoints specified in `--endpoints` flag
        get                     Gets the key or a range of keys
        help                    Help about any command
        put                     Puts the given key into the store
        snapshot restore        Restores an etcd member snapshot to an etcd directory
        snapshot save           Stores an etcd node backend snapshot to a given file
        snapshot status         [deprecated] Gets backend snapshot status of a given file
        txn                     Txn processes all the requests in one transaction
        version                 Prints the version of etcdctl

OPTIONS:
      --cacert=""                               verify certificates of TLS-enabled secure servers using this CA bundle
      --cert=""                                 identify secure client using this TLS certificate file
      --data-dir=""                             path to the data directory
      --endpoints=[127.0.0.1:2379]              gRPC endpoints
  -h, --help[=false]                            help for etcdctl
      --insecure-skip-tls-verify[=false]        skip server certificate verification (CAUTION: this option should be enabled only for testing purposes)
      --key=""                                  identify secure client using this TLS key file
      --password=""                             password for authentication (if this option is used, --user option shouldn't include password)
      --user=""                                 username[:password] for authentication (prompt if password is not supplied)
  -w, --write-out="simple"                      set the output format (fields, json, protobuf, simple, table)
```

---

| **Group**                   | **Flag(s)**                                            | **Purpose**                                                 | **Multi-Node Setup**                                | **Reference with `kube-apiserver`**        |
| --------------------------- | ------------------------------------------------------ | ----------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------ |
| 🚀 **Core Startup**         | `etcd`                                                 | Starts etcd binary.                                         | Same on all nodes.                                  | N/A                                        |
| 📢 **Client Advertise URL** | `--advertise-client-urls=https://192.168.102.134:2379` | etcd tells clients (like kube-apiserver) where to reach it. | Must be the **local node IP**.                      | Used by `--etcd-servers` in kube-apiserver |
| 🗃 **Data Directory**       | `--data-dir=/var/lib/etcd`                             | Where etcd stores all its data.                             | Each node stores data locally. Needs syncing in HA. | N/A                                        |

---

### 🔐 **Authentication & Security**

| **Flag(s)**                                                     | **Purpose**                                                     | **Multi-Node Setup**                          | **kube-apiserver Reference**                                       |
| --------------------------------------------------------------- | --------------------------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------ |
| `--cert-file`, `--key-file`                                     | Server cert/key for HTTPS clients (e.g., API server).           | Unique per node but signed by shared etcd CA. | kube-apiserver uses these to auth with etcd.                       |
| `--client-cert-auth=true`                                       | Only allow TLS client auth.                                     | Should be enabled on all nodes.               | Matches with `--etcd-certfile`, `--etcd-keyfile` in kube-apiserver |
| `--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt`             | CA used to verify connecting clients (API server, peers).       | Shared across all nodes.                      | Matches with `--etcd-cafile` in kube-apiserver                     |
| `--peer-client-cert-auth=true`                                  | Require peer TLS certs in cluster.                              | Must be enabled in HA setup.                  | Peer cert config follows this.                                     |
| `--peer-cert-file`, `--peer-key-file`, `--peer-trusted-ca-file` | Used for TLS **peer-to-peer communication** between etcd nodes. | Unique per node certs, shared CA.             | N/A                                                                |

---

### 🌍 **Network & URLs**

| **Flag(s)**                                                                | **Purpose**                                    | **Multi-Node Setup**                                                                                     | **kube-apiserver Reference**                                          |
| -------------------------------------------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `--listen-client-urls=https://127.0.0.1:2379,https://192.168.102.134:2379` | etcd listens for incoming client traffic here. | Must include `127.0.0.1` (for kube-apiserver) and node IP.                                               | kube-apiserver connects to `127.0.0.1:2379` in single-node; LB in HA. |
| `--listen-peer-urls=https://192.168.102.134:2380`                          | Where this etcd instance listens for peers.    | Each node listens on its own IP:2380.                                                                    | N/A                                                                   |
| `--initial-advertise-peer-urls=https://192.168.102.134:2380`               | Tells other peers: "You can reach me here."    | Unique per node.                                                                                         | N/A                                                                   |
| `--initial-cluster=controlplane=https://192.168.102.134:2380`              | Tells etcd what nodes form the cluster.        | In HA: comma-separated list of all peers (e.g., `node1=https://1.1.1.1:2380,node2=https://1.1.1.2:2380`) | N/A                                                                   |
| `--listen-metrics-urls=http://127.0.0.1:2381`                              | For liveness/readiness probes & metrics.       | Localhost only. Safe.                                                                                    | Used by the probes.                                                   |

---

## 🔹 1. `--listen-client-urls=https://127.0.0.1:2379,https://192.168.102.134:2379`

### ✅ What it does:

This flag tells the etcd process on **which addresses and ports to listen** for **client connections**.

* Clients = Kubernetes components like `kube-apiserver` that want to talk to etcd.
* etcd will "bind" to both:

  * `127.0.0.1:2379` → for **internal clients** running on the same node (e.g., `kube-apiserver`)
  * `192.168.102.134:2379` → for **external clients** (used in multi-node setups or for debugging).

---

### 🧠 Why do we need both?

| Listener          | Why It's Needed                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------- |
| `127.0.0.1`       | Local-only access — used by the **kube-apiserver** running as a static pod on the same node |
| `192.168.102.134` | Node IP — needed if other nodes or external tools want to reach etcd                        |

---

### 🌐 In Multi-Node HA:

In a multi-control-plane setup:

* Each etcd node also **serves client traffic** to other nodes’ kube-apiservers or external monitoring tools.
* So we must expose the node IP (`192.168.x.x`) here.
* **Bonus**: This also helps in debugging. You can run:

  ```bash
  ETCDCTL_API=3 etcdctl --endpoints=https://192.168.102.134:2379 ...
  ```

---

## 🔹 2. `--listen-peer-urls=https://192.168.102.134:2380`

### ✅ What it does:

This tells etcd where to **listen for connections from other etcd peers**.

* This is **peer-to-peer communication** used for syncing data and cluster state.
* etcd members gossip, replicate logs, and elect leaders via this channel.

---

### 📌 In Single Node:

* Only one etcd = No actual peer connections.
* Still needed so etcd behaves like a complete cluster member.

---

### 🌐 In Multi-Node:

* Every etcd node must open this listener to **accept peer requests** from other control-plane nodes.
* If this isn’t reachable → etcd cluster will break → Kubernetes becomes **read-only** (no new pods, services, etc.).

---

## 🔹 3. `--initial-advertise-peer-urls=https://192.168.102.134:2380`

### ✅ What it does:

Tells **other etcd nodes**:
👉 “This is my IP and port for **peer communication**.”

* This is the **outgoing address** — how etcd introduces itself to the cluster.
* Think of it like: “If you want to sync logs with me, call me at 192.168.102.134:2380.”

---

### 🧠 Real-world analogy:

If `--listen-peer-urls` is **opening the front door**, then `--initial-advertise-peer-urls` is like **giving others your address**.

---

### 🌐 In Multi-Node:

Must be **unique per node**, e.g.:

```yaml
--initial-advertise-peer-urls=https://node1:2380
--initial-advertise-peer-urls=https://node2:2380
```

If you put the wrong IP or port → other peers can’t talk to you.

---

## 🔹 4. `--initial-cluster=controlplane=https://192.168.102.134:2380`

### ✅ What it does:

This is the **initial etcd cluster membership**.

It tells the etcd instance:

> “Here’s the list of nodes that will be in this cluster, and their peer addresses.”

Format:

```
<name>=<peer-URL>
```

---

### 📌 In Single Node:

```bash
--initial-cluster=controlplane=https://192.168.102.134:2380
```

* Only 1 member.
* Name must match the value of `--name=controlplane`.

---

### 🌐 In HA (Multi-Node):

You give a comma-separated list of all nodes:

```bash
--initial-cluster=cp1=https://10.0.0.1:2380,cp2=https://10.0.0.2:2380,cp3=https://10.0.0.3:2380
```

If any entry is missing or wrong, cluster bootstrapping will fail.

---

### ⚠️ Note:

This is **only used at cluster creation time**. If the cluster already exists, modifying this flag won’t help.

---

## 🔹 5. `--listen-metrics-urls=http://127.0.0.1:2381`

### ✅ What it does:

This is where etcd **exposes internal metrics and health endpoints**.

Used by:

* Liveness probes
* Readiness probes
* Prometheus (if configured)

---

### 📌 Why Localhost Only?

* For security: we don’t want these endpoints public.
* They’re only useful to **local processes**, like the kubelet doing health checks.

---

### 🧪 Example Endpoints:

* `http://127.0.0.1:2381/metrics`
* `http://127.0.0.1:2381/readyz`
* `http://127.0.0.1:2381/livez`

---

## 🧠 Summary in Real-World Terms:

| Flag                            | Think of it like...                                                  |
| ------------------------------- | -------------------------------------------------------------------- |
| `--listen-client-urls`          | Opening your **shop** doors to customers (API servers)               |
| `--listen-peer-urls`            | Leaving the **backdoor** open for fellow shopkeepers (etcd peers)    |
| `--initial-advertise-peer-urls` | Putting your address on a **shared shopkeeper directory**            |
| `--initial-cluster`             | The **group chat** of all shopkeepers — names + locations            |
| `--listen-metrics-urls`         | A **dashboard screen** behind the counter showing your shop’s health |

---

### 🔁 **Health, Watch, and Snapshot**

| **Flag(s)**                                        | **Purpose**                                             | **Multi-Node Setup**             | **Notes**                                    |
| -------------------------------------------------- | ------------------------------------------------------- | -------------------------------- | -------------------------------------------- |
| `--experimental-initial-corrupt-check=true`        | Checks for DB corruption on start.                      | Should be enabled.               | Safety mechanism.                            |
| `--experimental-watch-progress-notify-interval=5s` | How often etcd sends progress update even if no events. | Tuning knob.                     | Optional tweak.                              |
| `--snapshot-count=10000`                           | Triggers a snapshot after N writes.                     | Must be consistent across nodes. | Controls frequency of internal DB snapshots. |

---

### 📛 **Identification**

| **Flag(s)**           | **Purpose**                    | **Multi-Node Setup**                       | **Notes**                         |
| --------------------- | ------------------------------ | ------------------------------------------ | --------------------------------- |
| `--name=controlplane` | Logical name of the etcd node. | Must be **unique** per control-plane node. | Also used in `--initial-cluster`. |

---

### 🧱 **Mounts, Volumes, Probes**

| **Item**                          | **Purpose**           | **Multi-Node Setup**                | **Relation to kube-apiserver**                       |
| --------------------------------- | --------------------- | ----------------------------------- | ---------------------------------------------------- |
| `/var/lib/etcd`                   | Local data directory. | Must persist between restarts.      | N/A                                                  |
| `/etc/kubernetes/pki/etcd`        | etcd TLS certs dir.   | Mounted with proper certs per node. | kube-apiserver reads from this too for client access |
| Startup/Readiness/Liveness Probes | Ensure etcd health.   | Same across all nodes.              | Probes use port 2381.                                |

---

## ✅ Summary Table: Single Node vs Multi-Control Plane

| **Component**                  | **Single Node**          | **Multi-Control Plane**                 |
| ------------------------------ | ------------------------ | --------------------------------------- |
| `--advertise-client-urls`      | Local node IP            | Each node’s IP                          |
| `--initial-cluster`            | One node only            | All peer nodes listed                   |
| Certs (peer/server/client)     | Self-contained           | Shared CA, unique certs                 |
| `--name`                       | `controlplane`           | Must be unique: `cp1`, `cp2`, etc.      |
| `--etcd-servers` in API Server | `https://127.0.0.1:2379` | List of all peer IPs                    |
| Peer URLs                      | Unused                   | Critical for cluster comms              |
| Load balancer for etcd?        | ❌ Not needed             | ❌ Generally not used (direct peer list) |

---

