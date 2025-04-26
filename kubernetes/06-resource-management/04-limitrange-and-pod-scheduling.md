# 🎓 LimitRange and Pod Scheduling — Case Study

This document explains how a `LimitRange` interacts with Pods in Kubernetes, particularly when resource `requests` and `limits` are defined or omitted.

We analyze two example Pods and determine which one will be scheduled, and why.

---

## 📜 LimitRange Manifest

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-resource-constraint
spec:
  limits:
  - default:             # Applies if no limits are defined in the container
      cpu: 500m
    defaultRequest:      # Applies if no requests are defined in the container
      cpu: 500m
    max:                 # Upper bound for requests and limits
      cpu: "1"
    min:                 # Lower bound for requests and limits
      cpu: 100m
    type: Container
```

### 🔍 What this means
- If a Pod doesn’t define `requests` or `limits`, default values (500m) will be applied.
- Any container's CPU must fall between `100m` and `1` (i.e., 100m ≤ value ≤ 1000m).
- If only one (request or limit) is defined, Kubernetes may attempt to default the other using this policy.

---

## 🧪 Pod-One: Fails to Schedule

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-one
spec:
  containers:
  - name: demo
    image: registry.k8s.io/pause:3.8
    resources:
      requests:
        cpu: 700m
```

### 🔍 What happens here?
- **Request defined**: 700m
- **Limit not defined**: Defaults to 500m (from LimitRange)

Result:
- 🚫 **Invalid**: `requests.cpu (700m)` > `limits.cpu (500m)` → Violates policy
- ❌ **Pod will not be scheduled**
- ❗ Error message:
  
  ```
  spec.containers[].resources.requests.cpu: Invalid value: "700m": must be less than or equal to cpu limit
  ```

---

## ✅ Pod-Two: Successfully Scheduled

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-two
spec:
  containers:
  - name: demo
    image: registry.k8s.io/pause:3.8
    resources:
      requests:
        cpu: 700m
      limits:
        cpu: 700m
```

### 🔍 What happens here?
- **Request = Limit = 700m**
- ✅ Within LimitRange bounds: `100m ≤ 700m ≤ 1`
- ✅ No defaulting required

✔️ **Pod will be scheduled successfully**

---

## ✅ Summary Table

| Pod Name | requests.cpu | limits.cpu | Result | Why |
|----------|--------------|------------|--------|-----|
| pod-one  | 700m         | 500m (defaulted) | ❌ Rejected | Request > Limit |
| pod-two  | 700m         | 700m       | ✅ Accepted | All values valid |

---

## 🔄 Let's Add a `ResourceQuota` for Combined Demo

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    requests.cpu: "1"
    limits.cpu: "2"
```

### ✅ Now Let’s Analyze:

- **Pod-Two:**
  - `requests.cpu = 700m`, `limits.cpu = 700m`
  - ✅ Fits within quota (request ≤ 1, limit ≤ 2)

- **Adding another pod:** with same values would exceed `requests.cpu > 1`

📌 So `LimitRange` enforces individual pod constraints.
📌 `ResourceQuota` enforces total usage in the namespace.

---

## Let's Create a `Multi-container Pod` with `ResourceQuota` and `LimitRange` in place

We will create a pod with two containers, keeping in mind `LimitRange` and `ResourceQuota` we created earlier.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: 300m
      limits:
        cpu: 500m
  - name: sidecar
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
    resources:
      requests:
        cpu: 300m
      limits:
        cpu: 500m
```

### 🔍 Evaluation

| Checkpoint                  | Value from both containers   | ResourceQuota Limit | Result   |
|----------------------------|-------------------------------|----------------------|----------|
| `requests.cpu` total       | 300m + 300m = **600m**        | ≤ 1 (1000m)          | ✅ Pass  |
| `limits.cpu` total         | 500m + 500m = **1000m**       | ≤ 2 (2000m)          | ✅ Pass  |
| Per-container `requests`   | Both ≥ 100m                   | LimitRange minimum   | ✅ Pass  |
| Per-container `limits`     | Both ≤ 1 core                 | LimitRange maximum   | ✅ Pass  |

### ✅ Conclusion

The multi-container pod **will be scheduled** because:

- Each container respects the `LimitRange` (min ≤ cpu ≤ max)
- The sum of `requests` and `limits` across containers is within the `ResourceQuota`

---
## 🧠 Final Notes

- Always check `LimitRange` and `ResourceQuota` **together** for scheduling decisions.
- `requests` must be ≤ `limits`
- `requests` and `limits` must fall between `min` and `max` defined in `LimitRange`
- Namespace-wide usage must respect the `ResourceQuota`
- When using `LimitRange`, be aware that omitted values may be filled in using the policy.
- Use `kubectl describe limitrange <name>` to inspect your active policy.



