# 📦 Kubernetes Resource Control Demo

This case study simulates a namespace where:

- **LimitRange** defines default CPU/memory **limits and requests** for pods that don’t explicitly specify them.
- **ResourceQuota** limits the **total resource usage** (aggregate across all pods).

We'll deploy a few pods and observe how Kubernetes **enforces the policies**.

---

## 🧱 1. Namespace with Policies

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: resource-lab
```

---

## 📏 2. LimitRange YAML

This sets **default CPU and memory** for containers that don’t specify them.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: resource-lab
spec:
  limits:
    - default:            # If container does NOT specify limits → use these
        cpu: "500m"
        memory: "128Mi"
      defaultRequest:     # If container does NOT specify requests → use these
        cpu: "250m"
        memory: "64Mi"
      type: Container
```

📝 **What this does:**

- Every new pod in `resource-lab` that doesn’t set its own CPU/mem:
  - Gets `250m` CPU + `64Mi` memory as request.
  - Gets `500m` CPU + `128Mi` memory as limit.

---

## 📊 3. ResourceQuota YAML

This limits the **total CPU and memory** across all pods in the namespace.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: resource-lab
spec:
  hard:
    requests.cpu: "1"       # Max total CPU requests: 1000m
    requests.memory: "512Mi"
    limits.cpu: "2"         # Max total CPU limits: 2000m
    limits.memory: "1Gi"
    pods: "5"
```

📝 **What this does:**

- Aggregates total pod resource usage.
- Kubernetes **prevents** creation of pods if totals exceed these thresholds.

---

## 🚀 4. Pod Without Resource Settings (Triggers LimitRange)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: defaulted-pod
  namespace: resource-lab
spec:
  containers:
    - name: app
      image: nginx
```

🔍 What happens:

- This pod **does not specify** requests/limits.
- Kubernetes auto-applies:
  ```yaml
  requests:
    cpu: 250m
    memory: 64Mi
  limits:
    cpu: 500m
    memory: 128Mi
  ```
- These **count toward** the ResourceQuota totals.

---

## ⚠️ 5. Pod That Exceeds ResourceQuota (Fails Admission)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: oversized-pod
  namespace: resource-lab
spec:
  containers:
    - name: heavy-app
      image: nginx
      resources:
        requests:
          cpu: "1"
          memory: "1Gi"
        limits:
          cpu: "2"
          memory: "2Gi"
```

🔍 What happens:

- This pod requests too much:
  - `requests.memory: 1Gi > quota of 512Mi`
  - `limits.memory: 2Gi > quota of 1Gi`
- ❌ Kubernetes **denies creation**:
  
  ```
  failed quota: team-quota: exceeded quota
  ```

---

## 💡 Final Insights

| Feature       | Role                                                |
|---------------|-----------------------------------------------------|
| **LimitRange** | Applies per-container defaults & max/min constraints |
| **ResourceQuota** | Enforces per-namespace aggregate resource limits     |
| **Interaction** | Pod requests/limits (explicit or defaulted) are tallied against quotas |

---

## 🧪 Bonus: View What Was Applied

After creating the defaulted pod, run:

```bash
kubectl get pod defaulted-pod -n resource-lab -o jsonpath='{.spec.containers[*].resources}'
```

You’ll see:

```json
{
  "limits": {
    "cpu": "500m",
    "memory": "128Mi"
  },
  "requests": {
    "cpu": "250m",
    "memory": "64Mi"
  }
}
```