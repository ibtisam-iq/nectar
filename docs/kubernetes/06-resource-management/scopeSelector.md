## 🔍 What Is `scopeSelector`?

A `scopeSelector` allows a ResourceQuota to apply **only to specific subsets of resources**, filtered by a **logical condition**.

### Example:
```yaml
scopeSelector:
  matchExpressions:
    - scopeName: PriorityClass
      operator: In
      values:
        - middle
```

### ✅ Meaning:
- Apply this quota only to pods with `priorityClassName: middle`
- Other pods are ignored by this quota

> Note: You cannot use `scopes` and `scopeSelector` together in the same ResourceQuota.

---

## 🔧 Full YAML Tutorial with `scopeSelector`

### 🎯 Scenario:
You want to:
- Set CPU/memory limits
- Only for `middle` priority pods
- In the `dev` namespace

### 🧱 PriorityClass (must exist):

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: middle
value: 100000
preemptionPolicy: PreemptLowerPriority
globalDefault: false
description: "Middle tier priority"
```

### 📄 ResourceQuota YAML:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: mid-tier-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "2"               # Total CPU request across matching pods
    requests.memory: 4Gi            # Total memory requested
    limits.cpu: "4"                 # Total CPU limit allowed
    limits.memory: 8Gi              # Total memory limit allowed
  scopeSelector:
    matchExpressions:
      - scopeName: PriorityClass
        operator: In
        values:
          - middle
```

---

## 🧩 Supported Scopes for `scopeSelector`

| Scope Name             | Description                                       |
|------------------------|---------------------------------------------------|
| `BestEffort`           | Applies only to BestEffort pods                   |
| `NotBestEffort`        | Applies to all but BestEffort pods               |
| `Terminating`          | Applies to terminating pods                      |
| `NotTerminating`       | Applies to non-terminating pods                  |
| `PriorityClass`        | Targets pods using specific priority classes     |
| `CrossNamespacePodAffinity` | Applies to pods using inter-namespace affinity |

---

## 🎯 Using scopeSelector

Use `scopeSelector` to apply quotas only to specific resource types. One example is restricting resource quotas based on the `PriorityClass` of pods.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: scoped-quota
  namespace: dev
spec:
  hard:
    pods: "5"
  scopeSelector:
    matchExpressions:
      - scopeName: PriorityClass
        operator: In
        values:
          - middle
```

🔍 Explanation:
- `scopeSelector` restricts the quota to only apply to pods with `PriorityClass=middle`.

---

## 📦 Real-World Use Case: Team-Based Resource Limits

### Scenario:
Two teams (`team-a`, `team-b`) share a cluster. You want to:
- Limit Team A to 4 CPU, 8Gi memory
- Limit Team B to 2 CPU, 4Gi memory
- Apply to only high-priority jobs

### Solution:
Use namespaces and scopeSelector on `PriorityClass`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests:
      cpu: "4"
      memory: 8Gi
  scopeSelector:
    matchExpressions:
      - scopeName: PriorityClass
        operator: In
        values:
          - high
```

Repeat for `team-b` with smaller limits.

---

## ✅ Best Practices

- ✅ Use `scopeSelector` to **target quotas** on specific workloads.
- ✅ Combine both **flat and nested styles** for clarity.
- ✅ Add object limits (like `pods`, `services`) to **prevent abuse**.
- ✅ Monitor with `kubectl describe quota` to track usage.
