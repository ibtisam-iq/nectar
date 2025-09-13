# 📘 Vertical Pod Autoscaler (VPA) — Full Documentation

## 1. Introduction

A **Vertical Pod Autoscaler (VPA)** automatically adjusts the **CPU and memory *requests*** (not limits) of your containers in a Deployment, StatefulSet, or DaemonSet.

* **Why?**
  Many applications are over-provisioned (wasting resources) or under-provisioned (causing performance issues). VPA ensures pods get “just enough” CPU and memory for optimal utilization.

* **Key Point:**
  VPA **evicts and recreates pods** with new resource requests — unlike HPA, which changes replica count.

---

## 2. How VPA Works

1. **Recommender** → Observes historical and real-time CPU/memory usage, calculates optimal requests.
2. **Updater** → Decides whether to evict pods if current requests are far from recommendations.
3. **Admission Controller** → Applies recommendations when new pods are created.

---

## 3. VPA Modes

VPA can operate in **three modes** via `updatePolicy.updateMode`:

* `Off` → Only generates recommendations (default). No updates applied.
* `Initial` → Applies recommendations **only at pod creation time**, not later.
* `Auto` → Actively evicts and recreates pods to apply updated requests (full automation).

---

## 4. VPA Components

* **Recommender** (required)
* **Updater** (optional but needed for `Auto` mode)
* **Admission Controller** (optional but recommended)

In clusters created with **kubeadm**, VPA is not installed by default. You usually deploy it from the official YAML manifests.

---

## 5. VPA vs HPA

| Feature           | HPA (Horizontal)                | VPA (Vertical)                           |
| ----------------- | ------------------------------- | ---------------------------------------- |
| Scales            | Number of pod replicas          | Pod resource requests (CPU, memory)      |
| Resource Adjusted | CPU/Memory utilization triggers | Historical + observed CPU/memory usage   |
| Eviction          | No                              | Yes, pods may be restarted               |
| Common Use Case   | Web servers, stateless apps     | Databases, batch jobs, memory-heavy apps |

👉 They can be combined, but avoid conflicts (HPA scales replicas, VPA scales resources).

---

## 6. Full YAML Manifest (With Detailed Comments)

```yaml
# Vertical Pod Autoscaler definition
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  # Name of the VPA object (must be unique within namespace)
  name: analytics-vpa
  # Namespace where the target deployment resides
  namespace: cka24456
spec:
  # Target reference: this tells VPA which workload to monitor & adjust
  targetRef:
    apiVersion: "apps/v1"                # API version of the workload
    kind:       "Deployment"             # Supported kinds: Deployment, StatefulSet, DaemonSet
    name:       "analytics-deployment"   # The exact name of the workload

  # Policy controlling how VPA applies recommendations
  updatePolicy:
    updateMode: "Auto"                   # Options:
                                         # - "Off" (default): only recommend, no updates
                                         # - "Initial": apply only on pod creation
                                         # - "Auto": actively evict pods & apply changes

  # ResourcePolicy is OPTIONAL — only used if you want bounds or exclusions
  resourcePolicy:
    containerPolicies:
      # Apply this policy to all containers in the workload
      - containerName: "*"

        # Set lower and upper bounds for CPU and memory requests
        minAllowed:
          cpu: "200m"                     # Minimum CPU request: 200 millicores (0.2 vCPU)
          memory: "256Mi"                 # Minimum memory request: 256Mi
        maxAllowed:
          cpu: "2"                        # Maximum CPU request: 2 cores
          memory: "4Gi"                   # Maximum memory request: 4 GiB

        # Control what resources VPA is allowed to adjust
        controlledResources: ["cpu", "memory"]
        # By default, both are adjusted. You can restrict, e.g., ["cpu"] only.
        
        # Mode can override the global updateMode for this specific container
        mode: "Auto"                      # Options: "Off", "Initial", "Auto"
```

---

## 7. Useful Commands to Verify VPA

### Check VPA object

```bash
kubectl get vpa -n cka24456
```

### Describe VPA and see recommendations

```bash
kubectl describe vpa analytics-vpa -n cka24456
```

Look for:

```
Recommendation:
  Container Recommendations:
    Container Name:  app
    Target CPU:      500m
    Target Memory:   1Gi
```

### Watch pod restarts (because VPA evicts them)

```bash
kubectl get pods -n cka24456 -w
```

---

## 8. Best Practices & Gotchas

* VPA **does not manage limits**, only **requests**. Limits must be set manually if needed.
* Expect **pod restarts** when VPA evicts pods → not ideal for apps requiring 100% uptime.
* Use `minAllowed` and `maxAllowed` to prevent extreme recommendations.
* Works well for **stateful or resource-intensive apps** (databases, ML workloads).
* Combine **HPA + VPA carefully**:

  * HPA scales replicas.
  * VPA scales per-pod resources.
  * Avoid conflicts (e.g., if HPA scales on CPU% and VPA is adjusting CPU requests simultaneously).
* In production: start with `updateMode: Off` to gather safe recommendations, then move to `Auto`.

---

Do you want me to format this in **Markdown style** (with headings, tables, code blocks) so you can directly drop it into your repo’s `README.md`?

