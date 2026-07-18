# 🧠 Kubernetes Scheduling Control: Taints, Tolerations, Node Selectors, and Node Affinity

> A complete intellectual journey from *why* to *how*, exploring how Kubernetes gives you control over **where** Pods run, using taints, tolerations, selectors, and affinities.

---

## 🧩 PROBLEM STATEMENT #1 — Unwanted Pods Are Scheduled on Certain Nodes

Imagine you have a **special node** meant only for specific workloads — high CPU, sensitive data, or GPU jobs. But Kubernetes, by default, sees every node as equal and might schedule general-purpose Pods there too.

### 🔧 SOLUTION — Taint the Node & Add Tolerate in Pod

A **taint** repels all Pods unless those Pods have a matching **toleration**.

> **Taint** = Applied to the node (it repels Pods)
> 
> **Toleration** = Applied to the Pod (it tolerates the taint)

### 🧪 Real-Life Analogy
A tainted node is like a VIP lounge — only those with a matching wristband (toleration) can enter. Others are not allowed in.

### 🔨 Imperative Command
```bash
kubectl taint node ibtisam-worker flower=rose:NoSchedule
kubectl describe node ibtisam-worker | grep -i taint -A 5
kubectl taint node ibtisam-worker flower=rose:NoSchedule-
```

> The `-` at the end removes the taint.

### 🌱 Example Manifest (Tolerating a Taint)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tol-po
spec:
  containers:
  - name: abcd
    image: busybox
    command: ["sleep", "3600"]
  tolerations:
  - key: "flower"
    operator: "Equal"
    value: "rose"
    effect: "NoSchedule"
```

### 🎯 Effects of Taint
| Effect             | Behavior |
|--------------------|----------|
| `NoSchedule`       | Pod will not schedule on the node unless it has a toleration.
| `PreferNoSchedule` | Scheduler will avoid placing Pod here, but it's not guaranteed.
| `NoExecute`        | Pod will be evicted if it doesn't tolerate the taint.

---

## ⚠️ PROBLEM #2 — Even Tolerated Pods May Go to the Wrong Node

Even after a Pod tolerates a taint, Kubernetes might still schedule it **on any other untainted node**.

> You want a Pod to go to a specific node — but toleration alone doesn't guarantee *where* it goes, just that it *can* go.

### 🧠 SOLUTION — Add a Node Label & Use `nodeName`, `nodeSelector` or `affinity`

```bash
kubectl label node ibtisam-worker cpu=large
kubectl label node ibtisam-worker cpu- # remove the label
```

### Example: Node Name
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
  nodeName: kube-01
```

The above Pod will only run on the node `kube-01`.

### 🌱 Example: Node Selector
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nodeselector-po
spec:
  containers:
  - name: abcd
    image: busybox
    command: ["sleep", "3600"]
  nodeSelector:
    cpu: large
```

### ⚠️ Limitation of Node Selector
- Only supports `=` operator
- No fallback or flexible logic
- Can only match **one label**

> This is where **Node Affinity** enters the picture

---

## 🔁 Node Affinity — Flexible and Declarative

> `nodeAffinity` gives you expressive control over scheduling using multiple operators and terms.

### 🧩 Syntax Inside Pod Spec
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:  # Hard rule
      preferredDuringSchedulingIgnoredDuringExecution: # Soft rule
```

### 🧪 Real-Life Analogy
It’s like saying: "I *require* a hotel with Wi-Fi (hard rule), but *prefer* one with a pool too (soft rule)."

---

## 💎 Node Affinity Types Explained

### 1. `requiredDuringSchedulingIgnoredDuringExecution` (Hard)
> Pod **must** be scheduled on a matching node or stay pending.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ha-po
spec:
  containers:
  - name: abcd
    image: busybox
    command: ["sleep", "3600"]
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - hdd
```

### 2. `preferredDuringSchedulingIgnoredDuringExecution` (Soft)
> Kubernetes will **try** to match, but falls back if needed.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sa-po
spec:
  containers:
  - name: abcd
    image: busybox
    command: ["sleep", "3600"]
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - hdd
```

### 3. `requiredDuringSchedulingRequiredDuringExecution`
> **(Proposed feature)** Enforces node match *even after* scheduling.

---

## ⚙️ Operators in Node Affinity

| Operator     | Description                                                                 |
|--------------|-----------------------------------------------------------------------------|
| `In`         | Node must have label value in list                                           |
| `NotIn`      | Node must **not** have label value in list                                  |
| `Exists`     | Node must have the label, any value                                          |
| `DoesNotExist`| Node must **not** have the label at all                                     |
| `Gt`         | Label value must be greater than the given number (lexical comparison)       |
| `Lt`         | Label value must be less than the given number (lexical comparison)          |

---

## 🔁 Combined Example — Toleration + Node Affinity
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tol-ha-po
spec:
  containers:
  - name: abcd
    image: busybox
    command: ["sleep", "3600"]
  tolerations:
  - key: "flower"
    operator: "Equal"
    value: "rose"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - hdd
```

---

## By-default Taint on Control Plane Nodes

```bash
Taints:             node-role.kubernetes.io/control-plane:NoSchedule

kubectl get nodes --show-labels
NAME           STATUS   ROLES           AGE   VERSION   LABELS
controlplane   Ready    control-plane   10m   v1.32.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=controlplane,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=

node01         Ready    <none>          10m   v1.32.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=node01,kubernetes.io/os=linux
```
---

## 📌 Final Thoughts — When to Use What?

| Use Case                                      | Use This Feature                  |
|----------------------------------------------|------------------------------------|
| Block pods from nodes unless explicitly allowed | Taints + Tolerations              |
| Ensure pods go to nodes with specific labels  | Node Affinity or Node Selector    |
| Simple matching on single label               | Node Selector                     |
| Advanced label logic                          | Node Affinity                     |
| Prevent running pods from staying on node     | `NoExecute` effect in Taint       |



## 🧵 Conclusion: How Everything Connects

| Concept          | Applied On | Enforces | Purpose |
|------------------|------------|----------|---------|
| Taint            | Node       | Repulsion | Prevent unwanted pods |
| Toleration       | Pod        | Toleration | Allow pod to ignore a taint |
| nodeSelector     | Pod        | Constraint | Target specific node label |
| Node Affinity    | Pod        | Constraint | Advanced matching with rules |

Together, **taints + tolerations** repel and allow selectively, while **labels + nodeSelector/affinity** attract and guide where pods land.

> ✅ Use taints when you want to **protect a node** from unwanted workloads.
> ✅ Use tolerations when you want **specific pods to enter protected nodes**.
> ✅ Use nodeSelector/affinity when you want **specific pods to land on specific nodes**.

That's how you gain full control over pod placement in your cluster — like an air traffic controller for your workloads. ✈️

## Want to learn more? 🤔

Please click [here](taints-affinity-guide-b.md) for understanding this topic in more depth.

