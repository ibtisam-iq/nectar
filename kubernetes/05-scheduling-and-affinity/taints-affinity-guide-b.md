# Taints, Tolerations, Node Selector & Node Affinity in Kubernetes

## 🧠 Problem-Driven Storyline: Smarter Scheduling with Rules

In a multi-node Kubernetes cluster, controlling which Pods run on which nodes is crucial for optimal resource usage, security, and performance. But out-of-the-box, Kubernetes treats all nodes equally unless we give it some hints.

Let’s journey through how we intelligently guide Kubernetes to make smarter scheduling decisions — from rejecting unwanted Pods to steering preferred ones with pinpoint control.

---

## 1️⃣ **Taints & Tolerations: Making Nodes Say "No!"**

### 🤔 The Problem
What if a node is reserved for special workloads? How can we ensure that *only specific* pods land there and others stay away?

### 🛠️ The Solution: **Taints & Tolerations**

- A **taint** is applied to a **node**. It says: *“Don’t schedule any pod here unless it tolerates me!”*
- A **toleration** is added to a **pod**. It says: *“It’s okay, I can live with that taint.”*

### 📌 Taint Syntax:
```bash
kubectl taint node ibtisam-worker flower=rose:NoSchedule
```

### 🔍 To remove the taint:
```bash
kubectl taint node ibtisam-worker flower=rose:NoSchedule-
```

### 🔍 Inspect taints on a node:
```bash
kubectl describe node ibtisam-control-plane | grep -i taint -5
```

### ⚙️ Taint Effects:
- **NoSchedule**: Pods that don’t tolerate this taint will not be scheduled.
- **PreferNoSchedule**: Scheduler will *try* to avoid tainted node, but not guaranteed.
- **NoExecute**: Existing pods without toleration will be *evicted* from the node.

### 🧪 YAML Example: Tolerated vs Non-Tolerated

```yaml
# Plain pod (no toleration)
apiVersion: v1
kind: Pod
metadata:
  name: plain-po
spec:
  containers:
  - name: abcd
    image: busybox
    command: ["sleep", "3600"]
```

```yaml
# Pod that tolerates the taint flower=rose:NoSchedule
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

### 🤯 Problem Solved?
Yes: Unwanted pods are repelled from tainted nodes.

### ❗ Still a Problem:
The wanted pod (with toleration) could be scheduled *anywhere else* too — not necessarily on the desired node.

---

## 2️⃣ **Labels, NodeSelector, and Directed Scheduling**

### ⚠️ The Next Problem
We want not only to tolerate a node’s taint — but also to *target* that specific node.

### ✅ The Solution: **Labels + nodeSelector**

- **Labels** are key-value pairs that we can apply to various Kubernetes resources (nodes, pods, services, etc.).
- **nodeSelector** allows us to schedule pods on nodes that have specific labels.

### 🏷️ Label the Node
```bash
kubectl label node ibtisam-worker2 cpu=large
```

### 🧪 YAML: nodeSelector

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

### ⚠️ Limitations of nodeSelector:
- Only uses **equality-based** matching (`key = value`).
- No advanced expressions like "In", "Exists", etc.
- Cannot match multiple complex conditions.

---

## 3️⃣ **Node Affinity: Advanced Scheduling Logic**

### 🚀 The Upgrade from nodeSelector
**Node Affinity** lets you define more expressive rules using *match expressions* with multiple operators.

### 💡 Two Types (as of now):
- `requiredDuringSchedulingIgnoredDuringExecution`: **Hard rule** — pod must match, or it won't be scheduled.
- `preferredDuringSchedulingIgnoredDuringExecution`: **Soft rule** — try to match, but can skip.

### 🧪 Hard Node Affinity (Required)

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

### 🧪 Soft Node Affinity (Preferred)

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
```

### 🧪 Combo: Toleration + Node Affinity

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
```

---

## 4️⃣ **Multi-Taint & Multi-Label Logic**

### 🧪 Multiple Taints on a Node
```bash
kubectl taint nodes node1 env=prod:NoSchedule
kubectl taint nodes node1 gpu=nvidia:NoExecute
```
- All taints must be tolerated by the Pod to be scheduled.

### 🧪 Multiple Labels on a Node
```bash
kubectl label nodes node1 env=prod disktype=ssd tier=frontend
```

You can combine expressions with logical `AND` by using multiple `matchExpressions`. All must be satisfied.

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: env
          operator: In
          values:
          - prod
        - key: disktype
          operator: In
          values:
          - ssd
```

---

## 5️⃣ **Labels vs. Taints — Key Distinction**

| Feature        | Labels            | Taints & Tolerations     |
|----------------|--------------------|---------------------------|
| Applied To     | Any resource       | Only nodes                |
| Purpose        | Selection / Match  | Restriction / Repelling   |
| Pod Role       | selector/affinity  | toleration                |
| Enforcement    | Soft (opt-in)      | Hard (opt-out)            |

Labels are universal selectors. Taints are strict gatekeepers on nodes.

---

## 🧪 YAML Lab: Multi-Taint + Multi-Affinity Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-constraint-po
spec:
  containers:
  - name: abcd
    image: busybox
    command: ["sleep", "3600"]
  tolerations:
  - key: "env"
    operator: "Equal"
    value: "prod"
    effect: "NoSchedule"
  - key: "gpu"
    operator: "Exists"
    effect: "NoExecute"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
          - key: tier
            operator: In
            values:
            - frontend
```

---

## ✅ Summary: Dot-Connecting Review

- **Taints repel pods**, **tolerations let pods tolerate** taints.
- **Labels attract pods** via **nodeSelector** or **nodeAffinity**.
- **nodeSelector** is basic; **nodeAffinity** is expressive.
- You can combine **toleration + affinity** to precisely target nodes.
- **Multi-taints or labels** work by satisfying *all* conditions.

This layering gives you **surgical scheduling control** for real-world production environments. 

---

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
spec:
  selector:
    matchLabels:                                  # matchLabels are key-value pairs.
      app: store
  replicas: 3
  template:
    metadata:
      labels:
        app: store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:    # matchExpressions: key field is "key", the operator is "In", and the values array contains only "value". 
              - key: app
                operator: In
                values:
                - store
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: redis-server
        image: redis:3.2-alpine
```
