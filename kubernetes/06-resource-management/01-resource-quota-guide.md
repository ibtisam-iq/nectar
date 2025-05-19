# 🧠 Kubernetes ResourceQuota Deep Dive: `scopeSelector` and Beyond

## 📘 Introduction

`ResourceQuota` is a Kubernetes object that lets you **limit resource consumption and object count** within a namespace. It helps ensure **fair usage** and **prevent abuse** of cluster resources by controlling:

- Compute resources (CPU, memory)
- Storage (PVCs, ephemeral storage)
- Object count (pods, services, secrets, etc.)

This guide explains how quotas work, what `scopeSelector` does, and how to apply quotas on compute, storage, and object counts.

---

## 💡 What Are `requests` and `limits`?

| Field     | Meaning                         | Think of it as...               |
| --------- | ------------------------------- | ------------------------------- |
| `request` | **Minimum guaranteed** resource | Your **reservation**            |
| `limit`   | **Maximum allowed** resource    | Your **ceiling / throttle cap** |


### 🧠 What Happens:

* Kubernetes uses `requests` during **scheduling** (i.e., finding a node).
* Kubernetes uses `limits` during **runtime** (i.e., restricting usage).

> ✅ “Request is the guaranteed minimum amount of resource Kubernetes will reserve for the container at scheduling time.”
>
> ✅ “Limit is the absolute maximum amount of resource the container is allowed to use at runtime. It cannot exceed this.”

### 🏨 Real-World Analogy: Hotel Room

Imagine you're booking a hotel room with flexible budget.

* **Request**: You tell the hotel, “I **need at least 1 room** with 1 bed — guaranteed.”
* **Limit**: You say, “But I **won’t pay for more than 2 beds** — cap it there.”

> Kubernetes does the same:
>
> * It guarantees the container at least the resources specified in `request`.
> * But if the container tries to use more than `limit`, it's throttled or OOMKilled.

### ⚙️ In Terms of a Single Pod:

Let’s say your pod defines:

```yaml
resources:
  requests:
    cpu: "500m"
  limits:
    cpu: "1000m"
```

* Scheduler finds a node with **at least 500m free CPU**.
* Pod is scheduled.
* At runtime, the container can use up to **1000m**, but **no more**.

  * If it tries more, it will be **throttled** (for CPU).
  * If memory exceeds `limit`, it can be **OOMKilled**.

### ✅ Summary

| Concept                  | Request | Limit |
| ------------------------ | ------- | ----- |
| Scheduler uses it?       | ✅ Yes   | ❌ No  |
| Runtime enforces it?     | ❌ No    | ✅ Yes |
| Guarantees availability? | ✅ Yes   | ❌ No  |
| Defines max usage?       | ❌ No    | ✅ Yes |

| Term    | Kubernetes Reserves | Container Can Use | Type                 |
| ------- | ------------------- | ----------------- | -------------------- |
| Request | ✅ Yes               | ✅ At least this   | Minimum (Guaranteed) |
| Limit   | ❌ No                | ✅ At most this    | Maximum (Cap)        |

---

## 🧮 Types of Resources You Can Limit

### 🔹 1. **Compute Resources**
```yaml
hard:
  requests.cpu: "4"      # All pods in this namespace together can request up to 4 CPUs
  limits.cpu: "8"        # All pods can use up to 8 CPUs, but no more
  requests.memory: 8Gi   # All pods can request up to 8Gi memory
  limits.memory: 16Gi    # All pods cannot go over 16Gi usage
```

### Meaning:

| Behavior                      | Effect                                                           |
| ----------------------------- | ---------------------------------------------------------------- |
| Scheduler behavior            | Will only schedule pods if total `requests` of all pods ≤ 4 CPUs |
| Runtime behavior              | All running pods cannot use more than 8 CPUs at once             |
| Same logic applies for memory | Total `requests.memory` ≤ 8Gi and `limits.memory` ≤ 16Gi         |


### 🔹 2. **Storage Resources**
```yaml
hard:
  requests.storage: 100Gi              # Sum of PVC storage requests
  persistentvolumeclaims: "10"        # Max PVCs allowed
```

### 🔹 3. **Object Count** (Case Study: Limiting Number of Objects)
You can also limit **how many objects** can exist in a namespace.
```yaml
hard:
  pods: "20"                 # Max number of pods in the namespace
  services: "5"              # Max services
  configmaps: "10"           # Max configmaps
  secrets: "15"              # Max secrets
  replicationcontrollers: "4"
  services.nodeports: "2"
  count/deployments.apps: "10"
```

📌 This example limits:
- Total number of pods, secrets, configmaps, and PVCs.
- Maximum number of NodePort services.

You can even combine them all in one quota.

---

## ✅ Guide: `spec.hard` in ResourceQuota

### 🔹 Format 1: Basic Resource Consumption Limits (No `requests.` or `limits.` prefixes)

```yaml
spec:
  hard:
    cpu: "2"                   # ❌ INVALID (Deprecated and usually ignored)
    memory: 5Gi                # ❌ INVALID (Deprecated and usually ignored)
    pods: "10"                 # ✅ Valid
    services: "5"              # ✅ Valid
    persistentvolumeclaims: "2" # ✅ Valid
```

* ❌ `cpu` and `memory` without prefix (`requests.` or `limits.`) are **not valid anymore** for `ResourceQuota`.
* ✅ Object count quotas like `pods`, `services`, `configmaps`, etc., are **fully valid**.

🔍 **Why not valid?**

> Since Kubernetes v1.2+, you must specify CPU and Memory with `requests.` or `limits.` prefixes inside `ResourceQuota`. Bare `cpu`/`memory` fields are ignored or trigger validation errors.



### 🔹 Format 2A: ✅ ✅ Flat Key Style (Canonical and Correct)

```yaml
spec:
  hard:
    requests.cpu: "4"
    limits.cpu: "8"
    requests.memory: 8Gi
    limits.memory: 16Gi
```

✅ **This is the only valid way** to enforce compute resource quotas in Kubernetes.

* Uses flat key format like `requests.cpu`, `limits.memory`
* This is how Kubernetes parses and enforces CPU and memory quotas



### 🔹 Format 2B: ❌ INVALID — Nested Style

```yaml
spec:
  hard:
    requests:
      cpu: "4"
      memory: 8Gi
    limits:
      cpu: "8"
      memory: 16Gi
```

❌ **This is invalid YAML for ResourceQuota**, even though it looks readable.

* **Not supported** by Kubernetes API.
* Will cause this error:

  ```
  quantities must match the regular expression '^([+-]?[0-9.]+)([eEinumkKMGTP]*[-+]?[0-9]*)$'
  ```

🔍 **Why not valid?**

> Kubernetes expects all keys inside `.spec.hard` to be flat strings like `requests.cpu`, not nested maps like `requests: { cpu: "4" }`.



### ✅ Valid Object Count Quotas

These are always allowed inside `.spec.hard`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: abc
  namespace: default
spec:
  hard:
    configmaps: "20"
    count/deployments.apps: "10"
    count/jobs.batch: "10"
    count/replicasets.apps: "10"
    count/statefulsets.apps: "10"
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "10"
    pods: "20"
    replicationcontrollers: "4"
    requests.cpu: "4"
    requests.memory: 8Gi
    requests.storage: 100Gi
    secrets: "20"
    services: "20"
    services.nodeports: "2"
```



### ✅ Summary Table (Corrected)

| Format Type         | Example                                    | Valid? | Why                                   |
| ------------------- | ------------------------------------------ | ------ | ------------------------------------- |
| Flat Resources      | `requests.cpu: "4"`, `limits.memory: 16Gi` | ✅      | Required format for compute resources |
| Nested Resources    | `requests: { cpu: "4" }`                   | ❌      | Not valid YAML — not parsed by API    |
| Object Quotas       | `pods: "10"`, `services: "5"`              | ✅      | Fully valid for object-count limits   |
| Deprecated Bare CPU | `cpu: "2"`, `memory: "5Gi"`                | ❌      | Not valid — must use requests/limits  |



### 💡 Recommendation

Always use **flat key syntax** for resource-based quotas:

```yaml
requests.cpu: "4"
limits.memory: 16Gi
```

And avoid nesting under `requests:` or `limits:` in `ResourceQuota` YAMLs.

---

## 🔍 Using `scopes` in ResourceQuota

The `scopes` field restricts the quota to apply only to a **subset** of objects:

| Scope             | Description                                               |
|------------------|-----------------------------------------------------------|
| `BestEffort`     | Applies only to pods without requests/limits              |
| `NotBestEffort`  | Applies to pods with at least one request or limit       |
| `Terminating`    | Applies to pods with active deadlines                     |
| `NotTerminating` | Applies to pods without deadlines                         |
| `PriorityClass`  | Use only with `scopeSelector` (explained below)           |

### Example: Limit BestEffort Pods Only
```yaml
spec:
  hard:
    pods: "5"
  scopes:
    - BestEffort
```

---

## ⚙️ Advanced Filtering with [`scopeSelector`](scopeSelector.md)

`scopeSelector` allows more advanced filtering logic, similar to label selectors. Useful when applying quotas based on `PriorityClass`, etc.

### Example: Apply only to pods in `middle` PriorityClass
Allows advanced filtering with `matchExpressions`:
```yaml
spec:
  hard:
    pods: "10"
  scopeSelector:
    matchExpressions:
      - scopeName: PriorityClass
        operator: In
        values:
          - middle
```

🧠 This is helpful when you want to limit resource consumption **only** for pods that belong to a specific priority class.

> **Not cleared about `scopeSelector`? Click [here](scopeSelector.md) for more info!**

---

## 🛠️ CLI Equivalents: `kubectl create quota`

### 🔹 `--hard` Flag
- Defines the resource limits
- Maps directly to `spec.hard`

```bash
kubectl create quota compute-quota \
  --hard=pods=10,requests.cpu=4,limits.cpu=8,requests.memory=8Gi,limits.memory=16Gi \
  --namespace=dev
```

### 🔹 `--scopes` Flag
- Applies quota only to objects matching all listed scopes
- Maps to `spec.scopes`

```bash
kubectl create quota scope-limited \
  --hard=pods=5 \
  --scopes=BestEffort \
  --namespace=dev
```

🔄 You can later modify them in YAML for complex cases (e.g., `scopeSelector`).

---

## 🧪 Case Study-1: Mixed Quota with Scopes (CLI Command)

```bash
kubectl create quota mixed-quota \
  --hard=services=5,pods=10 \
  --scopes=NotTerminating,BestEffort \
  --namespace=prod
```

📄 YAML:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mixed-quota
  namespace: prod
spec:
  hard:
    services: "5"
    pods: "10"
  scopes:
    - NotTerminating
    - BestEffort
```
---

## 🧪 Case Study-2: Mixed ResourceQuota (YAML)

```yaml
# PriorityClass (must exist):
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: middle
value: 100000
preemptionPolicy: PreemptLowerPriority
globalDefault: false
description: "Middle tier priority"
---
# ResourceQuota with scopes:
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-dev-limit
  namespace: dev
spec:
  hard:
    requests.cpu: "6"
    requests.memory: 12Gi
    limits.cpu: "12"
    limits.memory: 24Gi
    pods: "30"
    persistentvolumeclaims: "5"
    requests.storage: 200Gi
  scopeSelector:
    matchExpressions:
      - scopeName: PriorityClass
        operator: In
        values:
          - middle
```

### 🔍 What This Does:
- Applies **only to pods with priorityClassName: middle**
- Sets total compute usage caps
- Limits pod & PVC count
- Restricts total requested storage

---

## ✳️ Case Study-3; Full Example: Compute, Storage, Object Count, and ScopeSelector
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: complete-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "3"
    pods: "20"
    services: "10"
  scopeSelector:
    matchExpressions:
      - scopeName: PriorityClass
        operator: In
        values:
          - high
```

✔️ This YAML restricts compute, object count, and applies **only to `PriorityClass=high`**

---

## 🚀 Bonus Tip: How Kubernetes Calculates Resources

Official docs: [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

- In Kubernetes, containers can specify:
  - `resources.requests`: Minimum required resources.
  - `resources.limits`: Max usable resources.

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "64Mi"
  limits:
    cpu: "500m"
    memory: "128Mi"
```

ResourceQuota tracks either or both via the `.spec.hard` section.

> **Note:** When a **ResourceQuota** is defined in a namespace, every Pod must **request/limit** the listed resources.

## 🧮 Units in CPU and Memory

Understanding resource units is essential when defining `requests`, `limits`, or `ResourceQuota`.

### 🔸 CPU Units

| Format   | Meaning                       | Example           |
|----------|-------------------------------|-------------------|
| `m`      | *millicores* (1/1000 of 1 CPU) | `500m = 0.5 CPU`  |
| no unit  | *cores*                        | `1 = 1 core`      |

📌 1000m = 1 CPU core

✔️ Valid examples:
```yaml
cpu: "250m"     # quarter of a CPU
cpu: "1"        # 1 full CPU core
cpu: "2.5"      # 2 and a half CPU cores
```

### 🔸 Memory Units

Kubernetes accepts both **binary (power-of-2)** and **decimal (power-of-10)** formats.

| Suffix | Type      | Meaning                           | Example        |
|--------|-----------|-----------------------------------|----------------|
| `Ki`   | Binary     | Kibibyte (1024 bytes)             | `64Ki = 65,536` bytes |
| `Mi`   | Binary     | Mebibyte (1024 Ki)                | `128Mi = 134MB` |
| `Gi`   | Binary     | Gibibyte (1024 Mi)                | `2Gi = 2.14GB`  |
| `M`    | Decimal    | Megabyte (1,000,000 bytes)        | `128M = 128MB`  |
| `G`    | Decimal    | Gigabyte (1,000,000,000 bytes)    | `2G = 2GB`      |

✔️ Valid examples:
```yaml
memory: "128Mi"
memory: "1Gi"
memory: "512M"
```

❗ Avoid mixing formats unless you're confident — binary units (`Mi`, `Gi`) are more common in K8s.

### Key Takeaways

- Use `m` for CPU if using less than 1 core (e.g. `250m`)
- Use `Mi`, `Gi` for memory (e.g. `512Mi`, `2Gi`)
- Always use quotes around values to avoid parsing errors

---

## ✅ Best Practices

- Use `requests.*` and `limits.*` to control fine-grained consumption
- Use `scopes` to target pod behavior (BestEffort, Terminating, etc.)
- Use `scopeSelector` for advanced use cases (e.g. PriorityClass)


| Practice | Why It Matters |
|---------|------------------|
| Always define `PriorityClass` clearly | Required for `scopeSelector` to work |
| Use multiple quotas per tier/team | Fine-grained control |
| Don’t mix `scopes` with `scopeSelector` | Kubernetes doesn’t allow both |
| Name ResourceQuotas descriptively | Easier audit/debugging |
| Use `kubectl describe quota` | For real-time usage stats |

---

## 🚀 Summary Table

| Concept               | Field / Flag          | Description                                        |
|-----------------------|------------------------|----------------------------------------------------|
| Set hard resource caps | `spec.hard` / `--hard` | Limit memory, CPU, and object counts              |
| Target certain pods   | `spec.scopes` / `--scopes` | Restrict quotas to certain pod types              |
| Fine-grained logic    | `spec.scopeSelector`     | Use complex rules (e.g., match PriorityClass)      |
| CLI usage             | `kubectl create quota`   | Create ResourceQuota without writing YAML          |

 Purpose                        | Field              | Example                    |
|--------------------------------|---------------------|-----------------------------|
| Set resource limits            | `spec.hard`         | `cpu`, `memory`, `pods`     |
| Scope filtering (basic)       | `spec.scopes`       | `BestEffort`, `NotBestEffort`|
| Scope filtering (advanced)    | `spec.scopeSelector`| `matchExpressions`          |
| Object tracking (limits)      | `spec.hard.pods`    | Max pod count               |
| Storage quota                 | `requests.storage`  | Total PVC request limit     |


## Next Read

- [Limit Range Guide](02-limit-range-guide.md)
- [Limit Range and Resource Quota Together in Kubernetes](03-limitrange-resourcequota-together.md)
- [Limit Range and Pod Sheduling](04-limitrange-and-pod-scheduling.md)
- [Limit Range and Resource Quota Demo](05-limitrange-resourcequota-demo.md)
