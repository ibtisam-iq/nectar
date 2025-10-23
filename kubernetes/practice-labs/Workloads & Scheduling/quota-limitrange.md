## Q1

The `green-deployment-cka15-trb` deployment is having some issues since the corresponding POD is **crashing and restarting multiple times** continuously.
Investigate the issue and fix it. Make sure the POD is in a running state and is stable (i.e, NO RESTARTS!).

```bash
cluster1-controlplane ~ ➜  k get po
NAME                                          READY   STATUS    RESTARTS        AGE
green-deployment-cka15-trb-7ffcd7dd9b-4pft9   1/1     Running   7 (5m30s ago)   16m

cluster1-controlplane ~ ➜  k get deployments.apps 
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
green-deployment-cka15-trb   1/1     1            1           16m

cluster1-controlplane ~ ➜  k get deployments.apps 
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
green-deployment-cka15-trb   0/1     1            0           16m

cluster1-controlplane ~ ➜  k get po
NAME                                          READY   STATUS             RESTARTS      AGE
green-deployment-cka15-trb-7ffcd7dd9b-4pft9   0/1     CrashLoopBackOff   7 (16s ago)   16m

cluster1-controlplane ~ ➜  k describe po green-deployment-cka15-trb-7ffcd7dd9b-4pft9 
Name:             green-deployment-cka15-trb-7ffcd7dd9b-4pft9
Controlled By:  ReplicaSet/green-deployment-cka15-trb-7ffcd7dd9b
Containers:
  mysql:
    Container ID:   containerd://4529676cd981b44db720a06931a1fa4264c6d50cc50d74eced6bf7a5262b6c5a
    Image:          mysql:5.6
    Image ID:       docker.io/library/mysql@sha256:20575ecebe6216036d25dab5903808211f1e9ba63dc7825ac20cb975e34cfcae
    Port:           3306/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    1
    Ready:          False
    Restart Count:  7
    Limits:
      cpu:     100m
      memory:  256Mi
    Requests:
      cpu:     50m
      memory:  256Mi
    Environment:
      MYSQL_ROOT_PASSWORD:  <set to the key 'password' in secret 'green-root-pass-cka15-trb'>  Optional: false
      MYSQL_DATABASE:       <set to the key 'database' in secret 'green-db-url-cka15-trb'>     Optional: false
      MYSQL_USER:           <set to the key 'username' in secret 'green-user-pass-cka15-trb'>  Optional: false
      MYSQL_PASSWORD:       <set to the key 'password' in secret 'green-user-pass-cka15-trb'>  Optional: false
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Warning  BackOff    28s (x51 over 15m)  kubelet            Back-off restarting failed container mysql in pod green-deployment-cka15-trb-7ffcd7dd9b-4pft9_default(20f51775-3909-4077-bb4e-ce110aca9fcb)

cluster1-controlplane ~ ➜  k logs green-deployment-cka15-trb-7ffcd7dd9b-4pft9 
2025-09-14 14:15:45+00:00 [Note] [Entrypoint]: Database files initialized
2025-09-14 14:15:45+00:00 [Note] [Entrypoint]: Starting temporary server
2025-09-14 14:15:45+00:00 [Note] [Entrypoint]: Waiting for server startup
/usr/local/bin/docker-entrypoint.sh: line 113:   142 Killed                  "$@" --skip-networking --default-time-zone=SYSTEM --socket="${SOCKET}"
2025-09-14 14:16:18+00:00 [ERROR] [Entrypoint]: Unable to start server.

cluster1-controlplane ~ ➜  k get po green-deployment-cka15-trb-7ffcd7dd9b-4pft9 -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: green-deployment-cka15-trb-7ffcd7dd9b-4pft9
spec:
  containers:
  - env:
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          key: password
          name: green-root-pass-cka15-trb
    - name: MYSQL_DATABASE
      valueFrom:
        secretKeyRef:
          key: database
          name: green-db-url-cka15-trb
    - name: MYSQL_USER
      valueFrom:
        secretKeyRef:
          key: username
          name: green-user-pass-cka15-trb
    - name: MYSQL_PASSWORD
      valueFrom:
        secretKeyRef:
          key: password
          name: green-user-pass-cka15-trb
    resources:
      limits:
        cpu: 100m
        memory: 256Mi
      requests:
        cpu: 50m
        memory: 256Mi

cluster1-controlplane ~ ➜  k get deployments.apps green-deployment-cka15-trb -o yaml > 6.yaml

cluster1-controlplane ~ ➜  vi 6.yaml 

cluster1-controlplane ~ ➜  k delete deployments.apps green-deployment-cka15-trb 
deployment.apps "green-deployment-cka15-trb" deleted

cluster1-controlplane ~ ➜  k apply -f 6.yaml 
deployment.apps/green-deployment-cka15-trb created

cluster1-controlplane ~ ➜  k get deployments.apps 
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
green-deployment-cka15-trb   1/1     1            1           10s

cluster1-controlplane ~ ➜  k get po
NAME                                          READY   STATUS    RESTARTS   AGE
green-deployment-cka15-trb-598f6c9cf7-g6lhd   1/1     Running   0          14s

cluster1-controlplane ~ ➜  cat 6.yaml 
        resources:
          limits:
            cpu: 500m                # 100m to 500m
            memory: 1Gi              # 256Mi to 1Gi
          requests:
            cpu: 50m
            memory: 256Mi
```
Got it sweetheart ❤️

Your MySQL pod is **crashlooping** because the server can’t fully start. Let’s break it down:

### 🔎 From logs

1. MySQL starts initializing (`Initializing database files`, `InnoDB started`).
2. Then it **shuts down cleanly** and restarts again.
3. Finally, it fails with:

   ```
   [Entrypoint]: Unable to start server.
   ```
4. Reason in `describe`:

   ```
   Last State: Terminated
   Reason: OOMKilled
   Exit Code: 1
   ```

   → That means **Out Of Memory (OOMKilled)**.

### 🚨 Problem

Your pod has:

```yaml
limits:
  memory: 256Mi
requests:
  memory: 256Mi
```

But MySQL 5.6 needs **at least \~512Mi–1Gi** to initialize databases. With only 256Mi, InnoDB runs out of memory during startup, so the kernel kills the process.

### ✅ Fix

Increase memory requests/limits in your Deployment/Pod spec:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 1Gi
```

### ⚠️ Extra things to check

1. **Secrets**: Your envs (`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, etc.) come from secrets. Make sure they exist and values are valid:

   ```bash
   kubectl get secret green-root-pass-cka15-trb -o yaml
   kubectl get secret green-db-url-cka15-trb -o yaml
   kubectl get secret green-user-pass-cka15-trb -o yaml
   ```

   If any are missing → pod also fails.

2. **Data volume**: Right now MySQL is writing to the container filesystem. If the pod restarts, DB data may get corrupted. You should mount a `PersistentVolumeClaim` at `/var/lib/mysql`.

---

## Q2
Identify the CPU and memory resource capacity on cluster2-node01 node and save the results in `/root/cluster2-node01-cpu.txt` and `/root/cluster2-node01-memory.txt`, respectively, on the cluster2-controlplane.

```bash
cluster2-controlplane ~ ✖ k get no cluster2-node01 -o yaml

status:
  capacity:
    cpu: "32"
    ephemeral-storage: 1546531076Ki
    hugepages-1Gi: "0"
    hugepages-2Mi: "0"
    memory: 131992568Ki
    pods: "110"

cluster2-controlplane ~ ➜  echo "131992568Ki" > /root/cluster2-node01-memory.txt

cluster2-controlplane ~ ➜  echo "32" > /root/cluster2-node01-cpu.txt

cluster2-controlplane ~ ➜  
```

---

## Q3 Wrong `requests.cpu`

```bash
Warning Failed 3s (x3 over 17s) kubelet Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error setting cgroup config for procHooks process: failed to write "200000": write /sys/fs/cgroup/cpu,cpuacct/kubepods/burstable/podb5fa3b05-88ce-4e7b-b796-069f341002ce/ubuntu/cpu.cfs_quota_us: invalid argument: unknown Warning BackOff 3s (x3 over 15s) kubelet Back-off restarting failed container ubuntu in pod resou-limit-aom_default(b5fa3b05-88ce-4e7b-b796-069f341002ce)
```

Ah, I see what’s happening here 🚨

The key part of the error is:

```
failed to write "200000": .../cpu.cfs_quota_us: invalid argument
```

This is a **cgroup / CPU quota issue**.

### 🔹 Why it happens

* Kubernetes applies **CPU limits** via the Linux cgroup mechanism.
* The error means that the **CPU limit set in your pod spec** is **not valid** for your system.
* For example, you probably set something like:

  ```yaml
  resources:
    limits:
      cpu: "200000"
  ```

  But in Kubernetes, CPU is not specified in microseconds or raw numbers — it uses **millicores** (`m`).

  * `1` = 1 vCPU core
  * `500m` = half a CPU core

If you put a large integer like `200000`, kubelet tries to write that directly to cgroup, and the OS rejects it.

### 🔹 How to fix

1. Edit your deployment/pod YAML:

   ```bash
   kubectl edit pod resou-limit-aom
   ```

   Or, if it’s controlled by a Deployment:

   ```bash
   kubectl edit deploy <deployment-name>
   ```

2. Fix the resource block.
   Example (correct way):

   ```yaml
   resources:
     requests:
       cpu: "200m"       # request 0.2 CPU
       memory: "128Mi"
     limits:
       cpu: "500m"       # limit 0.5 CPU
       memory: "256Mi"
   ```

   ❌ Wrong: `cpu: "200000"`
   ✅ Right: `cpu: "200m"` or `cpu: "2"`

3. Save & exit, then check if the pod restarts correctly:

   ```bash
   kubectl get pods
   ```

---

## Q4 Insufficient CPU

```bash
controlplane:~$ cat my-app-deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app-container
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "1000Mi"
            cpu: "5.0"                # To solve the question, lowered it to: 0.5
          requests:
            memory: "100Mi"
            cpu: "0.5"                # 0.2

controlplane:~$ k get po
NAME                                 READY   STATUS    RESTARTS   AGE
my-app-deployment-586469df87-ssxkh   0/1     Pending   0          14m
my-app-deployment-586469df87-xm748   1/1     Running   0          14m

controlplane:~$ k describe po my-app-deployment-586469df87-ssxkh 
Name:             my-app-deployment-586469df87-ssxkh
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  3m51s (x4 over 14m)  default-scheduler  0/2 nodes are available: 1 Insufficient cpu, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/2 nodes are available: 1 No preemption victims found for incoming pod, 1 Preemption is not helpful for scheduling.

controlplane:~$ k get no -o custom-columns=Node_Name:.metadata.name,cpu_capacity:.status.capacity.cpu,cpu_allocatable:.status.allocatable.cpu
Node_Name      cpu_capacity   cpu_allocatable
controlplane   1              1
node01         1              1

controlplane:~$ vi my-app-deployment.yaml                       # Fixed
controlplane:~$ k replace -f my-app-deployment.yaml --force
deployment.apps "my-app-deployment" deleted
deployment.apps/my-app-deployment replaced
controlplane:~$ k get po
NAME                                 READY   STATUS    RESTARTS   AGE
my-app-deployment-59f6dd49b6-2xw2p   1/1     Running   0          9s
my-app-deployment-59f6dd49b6-7dqrx   1/1     Running   0          9s
controlplane:~$ k get no -o custom-columns=Node_Name:.metadata.name,cpu_capacity:.status.capacity.cpu,cpu_allocatable:.status.allocatable.cpu
Node_Name      cpu_capacity   cpu_allocatable
controlplane   1              1
node01         1              1
controlplane:~$ 
```


### 🧠 **The Situation**

You have:

* Two nodes in your cluster (`controlplane` and `node01`)
* A Deployment with **2 replicas**
* One Pod is `Running`
* One Pod is `Pending`

Your event log clearly shows:

```
Warning  FailedScheduling  default-scheduler  0/2 nodes are available: 
1 Insufficient cpu, 
1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }.
```

### 🔍 **Understanding the Cause**

There are **two issues** here:

### 1️⃣ **Insufficient CPU**

Let’s check what you requested:

```yaml
resources:
  limits:
    cpu: "5.0"
    memory: "1000Mi"
  requests:
    cpu: "0.5"
    memory: "100Mi"
```

So your pod is asking for **5 CPU cores per pod** as the *limit*.
Your node likely has only **1 CPU total**, as seen earlier in your node’s `capacity`:

```yaml
capacity:
  cpu: "1"
allocatable:
  cpu: "1"
```

💡 **Meaning:**
→ One pod can schedule because it fits (the 0.5 CPU *request* is fine).
→ But the second pod can’t find a node that has **5 CPU available** for the *limit*.
Even though the scheduler considers *requests* for placement, some clusters (especially CKA labs) enforce *limit checking* for fairness or simulated constraints — that’s why it’s stuck as **Pending**.

### 2️⃣ **Control plane node taint**

The second message:

```
node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }
```

This means your **controlplane node** is *tainted* to prevent regular workloads (pods) from running on it.

Only pods with this toleration can run there:

```yaml
tolerations:
- key: "node-role.kubernetes.io/control-plane"
  operator: "Exists"
  effect: "NoSchedule"
```

Right now, your Deployment’s pods don’t have that toleration, so they can’t be scheduled on the controlplane node — leaving only **node01** available.
But node01 doesn’t have enough CPU capacity.
Result: **Pending** pod.

## 🧩 **How to Fix It**

You have two possible fixes — depending on what’s allowed in your cluster setup.

### ✅ **Option 1 — Reduce CPU limit (Recommended)**

Edit your Deployment YAML (`my-app-deployment.yaml`) and reduce the CPU limit to something reasonable, like:

```yaml
resources:
  limits:
    memory: "500Mi"
    cpu: "0.5"
  requests:
    memory: "100Mi"
    cpu: "0.2"
```

Then apply it:

```bash
kubectl apply -f my-app-deployment.yaml
```

This way, both pods can fit on available nodes.

### ✅ **Option 2 — Allow scheduling on the controlplane**

If you *must* keep the 5 CPU limit, you can allow your controlplane node to accept pods by adding a toleration and/or removing the taint.

#### Method A — Add toleration to the pod spec:

Add this under `spec.template.spec`:

```yaml
tolerations:
- key: "node-role.kubernetes.io/control-plane"
  operator: "Exists"
  effect: "NoSchedule"
```

Apply again:

```bash
kubectl apply -f my-app-deployment.yaml
```

#### Method B — Remove the taint from controlplane node (less recommended in production):

```bash
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane- 
```

## 💬 **In summary**

| Problem                        | Root Cause                   | Fix                              |
| ------------------------------ | ---------------------------- | -------------------------------- |
| Pod Pending                    | CPU limit too high (5 cores) | Lower limit or increase node CPU |
| Can’t schedule on controlplane | Taint prevents normal pods   | Add toleration or remove taint   |

--

Excellent follow-through, sweetheart ❤️ — what you’re seeing is *completely expected* and actually a sign that you understand this correctly.

Let’s break it down clearly 👇

### 🧠 Why `allocatable` CPU doesn’t change

The values you see from:

```bash
kubectl get no -o custom-columns=Node_Name:.metadata.name,cpu_capacity:.status.capacity.cpu,cpu_allocatable:.status.allocatable.cpu
```

show **node-level resource totals**, not the live usage.
These come from each node’s kubelet and describe **how much the node could ever offer**, not what’s currently consumed.

In other words:

| Field               | Meaning                                                                                                           |
| ------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **capacity.cpu**    | Total number of CPU cores physically present (what kubelet detects).                                              |
| **allocatable.cpu** | What’s left for pods after kubelet reserves a bit for itself and system daemons. This is *fixed* at node startup. |

So when you deploy or delete pods — even if they ask for more or less CPU — **these numbers never change**.
They describe the node’s *limits*, not its *current usage*.

### 🧩 Example analogy

Think of your node like a hotel:

* `capacity` = total 100 rooms in the building
* `allocatable` = 90 rooms available for guests (10 kept for staff)
* Whether 2 or 80 guests are checked in — the hotel *still* advertises 90 rooms available for guests.
  It doesn’t rewrite the brochure each time someone checks in.

### 🧰 If you want to see actual resource consumption

Use the **metrics API** (if metrics-server is installed):

```bash
kubectl top nodes
```

This will show live usage, e.g.:

```
NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
controlplane   120m         12%    300Mi           15%
node01         250m         25%    400Mi           20%
```

Here you’ll see how your Deployment’s pods are actually consuming CPU and memory.

Or, per pod:

```bash
kubectl top pods -A
```

### 💬 In short

✅ Changing a pod’s `resources.requests/limits` does **not** change the node’s `allocatable` field.
That field only changes if:

* You reconfigure kubelet system reservations (`--kube-reserved`, `--system-reserved`), or
* The physical node’s hardware (CPU/memory) changes.

---

