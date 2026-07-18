# 📘 Kubernetes LimitRange Deep Dive

## 🌟 Introduction
`LimitRange` is a Kubernetes resource that sets **default**, **minimum**, and **maximum** resource constraints for containers and pods within a **namespace**. While `[ResourceQuota](01-resource-quota-guide.md)` enforces **aggregate resource usage limits**, `LimitRange` controls the **per-container/pod** resource policies.

They **complement** each other in a cluster’s resource policy setup.

---

## 🧠 Key Purpose of `LimitRange`

| Field                  | Purpose                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------  |
| `default`              | ✅ **Sets default `limits` only** (not requests), if a container doesn’t specify them.              |
| `defaultRequest`       | ✅ **Sets default `requests` only**, if a container doesn’t specify them.                           |
| `min`                  | ✅ Enforces a **minimum allowed value** for requests or limits (must be explicitly set in the Pod). |
| `max`                  | ✅ Enforces a **maximum allowed value** for requests or limits (must be explicitly set in the Pod). |
| `maxLimitRequestRatio` | ✅ Defines maximum ratio of `limit / request`. (Useful to prevent overprovisioning)                 |

---

## 🧪 Example: Full YAML with Descriptive Comments

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: dev
spec:
  limits:
    - type: Container       # Applies to individual containers (not whole pods)
      max:                  # Upper bound for requests and limits
        cpu: "1"            # Container can't request more than 1 CPU core
        memory: "1Gi"       # Container can't use more than 1Gi of memory
      min:                  # Lower bound for requests and limits
        cpu: "100m"         # At least 100 millicores must be requested
        memory: "128Mi"     # At least 128Mi memory must be requested
      default:              # this section defines default limits
        cpu: "500m"         # If not set in Pod spec, this value is used (Default resource.limit.cpu)
        memory: "512Mi"
      defaultRequest:       # this section defines default requests
        cpu: "200m"         # Default resource.request.cpu
        memory: "256Mi"
      maxLimitRequestRatio:
        cpu: "4"            # Limits can’t be more than 4x requests for CPU
```

---

## 🎯 Use Case Breakdown

### 🔹 1. Pod without Resource Requests or Limits
```yaml
containers:
  - name: test
    image: nginx
```
➡️ Kubernetes injects:
```yaml
resources:
  requests:
    cpu: 200m       # From defaultRequest
    memory: 256Mi
  limits:
    cpu: 500m       # From default
    memory: 512Mi
```

### 🔹 2. Pod Specifies Less Than `min`
```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
```
❌ Will be rejected — fails the `min` validation.

### 🔹 3. Pod Exceeds `max`
```yaml
resources:
  limits:
    cpu: 2
```
❌ Will be rejected — limit exceeds max.

### 🔹 4. Pod Violates `maxLimitRequestRatio`
```yaml
resources:
  requests:
    cpu: 100m
  limits:
    cpu: 1
```
❌ Invalid — ratio is 10x, while the allowed is only 4x.

---

## 🧩 Relationship Between `LimitRange` and `ResourceQuota`

| Feature               | `LimitRange`                          | `ResourceQuota`                        |
|------------------------|----------------------------------------|----------------------------------------|
| Scope                 | Per pod/container                      | Per namespace                          |
| Controls              | min/max/defaults for resource usage    | Total aggregate resource usage         |
| Enforcement time     | Pod admission time                     | Runtime tracking and enforcement       |
| Interaction           | Must obey both                        | Enforced in combination                |

### Example Conflict Scenario:
- `ResourceQuota` allows total `cpu: 2`
- A user tries to create 3 pods with limit `cpu: 1` (total = 3)
- ❌ Fails due to quota, even if `LimitRange` individually allows it


---

## 🔧 CLI Flags vs YAML for LimitRange

There is no direct `kubectl create limitrange` command with full feature flags like `--hard` in `ResourceQuota`. You need to apply YAML manifest.

---

## ⚖️ CPU & Memory Units Reference

### CPU
- `1` = 1 core
- `500m` = 0.5 cores
- `100m` = 0.1 cores

### Memory
- `Mi` = Mebibytes (base-2) → 1Mi = 1,048,576 bytes
- `Gi` = Gibibytes → 1Gi = 1024Mi

---

## ✅ Best Practices

- Set reasonable `defaultRequest` to guarantee scheduler efficiency.
- Use `LimitRange` to avoid resource hogs and noisy neighbors.
- Combine `LimitRange` with `ResourceQuota` to ensure predictable namespace limits.
- Document both resource policies clearly for development teams.

---

## 📎 Bonus: Pod Spec Validation Summary

| Condition                              | Trigger                         |
|----------------------------------------|----------------------------------|
| No resources specified                  | Kubernetes injects defaults      |
| Below min in LimitRange                | Pod rejected                     |
| Above max in LimitRange                | Pod rejected                     |
| Limit:Request ratio too high           | Pod rejected                     |
| Total resource exceeds ResourceQuota   | Pod rejected                     |


## Further Reading

- [Limit Range and Pod Sheduling](04-limitrange-and-pod-scheduling.md)
- [Limit Range and Resource Quota Demo](05-limitrange-resourcequota-demo.md)
- [Limit Range and Resource Quota Together in Kubernetes](03-limitrange-resourcequota-together.md)
