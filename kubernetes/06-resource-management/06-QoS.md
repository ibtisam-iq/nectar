# Kubernetes Quality of Service (QoS) Classes

## 🧠 What is QoS in Kubernetes?

**QoS (Quality of Service)** defines how Kubernetes prioritizes **pods** for **CPU/memory allocation and eviction** under resource pressure.

Every pod falls into one of three **QoS classes**:

| Class      | Priority | Use-case          |
| ---------- | -------- | ----------------- |
| Guaranteed | Highest  | Critical apps     |
| Burstable  | Medium   | Normal apps       |
| BestEffort | Lowest   | Test or throwaway |

---

## 🧩 How Kubernetes Assigns QoS Class

QoS is determined **per pod**, based on the **resources (CPU/Memory)** defined in each container.

### 🟢 1. `Guaranteed` (Highest)

**Conditions**:

* Every container in the pod **must define both `requests` and `limits`**
* For each container, the values of `requests` **must equal** `limits`

```yaml
resources:
  requests:
    cpu: "1"
    memory: "256Mi"
  limits:
    cpu: "1"
    memory: "256Mi"
```

📦 Pod QoS Class: `Guaranteed`

### 🟡 2. `Burstable` (Medium)

**Conditions**:

* At least **one container** sets a resource `request` or `limit`
* But **not all match exactly**, or only `requests` are set

```yaml
resources:
  requests:
    cpu: "500m"
```

📦 Pod QoS Class: `Burstable`

### 🔴 3. `BestEffort` (Lowest)

**Conditions**:

* **No `requests` or `limits`** are defined in any container

```yaml
resources: {}
```

📦 Pod QoS Class: `BestEffort`

---

## ⚙️ Why QoS Class Matters

### 🚨 Under Node Memory Pressure (Eviction):

Kubelet evicts pods in this order:

```
BestEffort > Burstable > Guaranteed
```

### 🔧 Scheduler decisions (indirectly):

While scheduling isn't based on QoS, **`requests` impact scheduling**. BestEffort pods don't reserve CPU/memory → easier to schedule but easily evicted.

---

## 💥 Examples and Their QoS Classes

| CPU Request | CPU Limit | Memory Request | Memory Limit | Class      |
| ----------- | --------- | -------------- | ------------ | ---------- |
| 1           | 1         | 256Mi          | 256Mi        | Guaranteed |
| 1           | 2         | 128Mi          | 256Mi        | Burstable  |
| —           | —         | —              | —            | BestEffort |

---

## 🧪 How to Check QoS Class of a Pod

```bash
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'
```

Example:

```bash
kubectl get pod myapp -o jsonpath='{.status.qosClass}'
```

---

## 🔍 LimitRange and QoS Class

If you do **not define `resources:` explicitly**, but a `LimitRange` exists, Kubernetes **auto-applies** default requests/limits → your pod becomes `Burstable`.

#### Example:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: dev
spec:
  limits:
  - default:
      cpu: 1
      memory: 512Mi
    defaultRequest:
      cpu: 500m
      memory: 256Mi
    type: Container
```

> Now even if your Pod YAML has no resources, it’ll be assigned `Burstable` due to these defaults.

---

## 🚧 ResourceQuota + LimitRange + QoS: Interaction

* ResourceQuota **counts requests and limits** toward usage.
* If you don't specify anything, LimitRange might **assign defaults**, consuming your quota.
* This may cause your pod to be **rejected** unexpectedly if quota is exceeded.

---

## ⚠️ Troubleshooting Unexpected QoS

### ❓ Why is my pod not `Guaranteed`?

* Check if **every container** defines both `requests` and `limits`
* Ensure **values are equal**

### ❓ Why was my pod evicted first?

* Check `kubectl describe pod` for:

  * `Evicted`
  * `Status: Failed`
  * `Reason: Evicted`
  * `Message: The node had condition: [MemoryPressure]`

---

## 📌 Summary: When to Use What

| Class      | Use it when...                                  |
| ---------- | ----------------------------------------------- |
| Guaranteed | Mission-critical apps (DBs, control-plane apps) |
| Burstable  | Regular apps needing some level of protection   |
| BestEffort | Dev/test, short-lived tools, batch jobs         |

