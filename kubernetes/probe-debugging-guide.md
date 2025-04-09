# Debugging Liveness and Readiness Probes in Kubernetes

In Kubernetes, **liveness** and **readiness** probes are critical for ensuring application health and traffic management. However, probe misconfigurations or application issues can lead to traffic loss, unnecessary restarts, or prolonged downtimes. This guide walks you through **how to debug** probes using real-world tools and scenarios.

---

## 🔍 Step-by-Step Debugging Workflow

### ✅ 1. Check Pod Status with `kubectl get pods`

```bash
kubectl get pods
```

Look for:
- `STATUS`: Is it `Running`, `CrashLoopBackOff`, `Pending`?
- `READY`: Are all containers marked as ready (e.g., `1/1`)?

If the pod is running but not ready, suspect a **readiness probe** issue.
If the pod is restarting repeatedly, suspect a **liveness probe** failure.

---

### 📄 2. Describe the Pod with `kubectl describe pod`

```bash
kubectl describe pod <pod-name>
```

Check the following:
- **Conditions:** Look for `Ready=True/False`
- **Events:**
  - `Readiness probe failed:`
  - `Liveness probe failed:`

This tells you which probe is failing and whether Kubernetes is restarting the pod or removing it from service endpoints.

**Example failure message:**
```
Readiness probe failed: HTTP probe failed with statuscode: 500
```

---

### 📦 3. Inspect Container Logs

```bash
kubectl logs <pod-name> -c <container-name>
```

This helps answer:
- Is the container app actually up and responding?
- Is the readiness/liveness endpoint working as expected?
- Any crash messages or stack traces?

You can even combine `kubectl logs` with `-f` to tail logs in real-time.

```bash
kubectl logs -f <pod-name> -c <container-name>
```

---

### 🧪 4. Manually Curl the Probe Endpoint (if HTTP probe)

```bash
kubectl exec -it <pod-name> -- curl -v localhost:<port>/<path>
```

Example:
```bash
kubectl exec -it pod-with-issue -- curl -v localhost:8080/ready
```

Check for:
- HTTP 200 = Healthy
- HTTP 4xx/5xx = Probe will fail

If curl works inside but fails in the probe, check for:
- Wrong probe path
- Probe port mismatch
- App not listening on localhost

---

### 🔄 5. Check Probe Configuration in YAML

```bash
kubectl get pod <pod-name> -o yaml | grep -A10 readinessProbe
kubectl get pod <pod-name> -o yaml | grep -A10 livenessProbe
```

Common misconfigurations:
- Wrong `port` or `path`
- `initialDelaySeconds` too short for slow booting apps
- `timeoutSeconds` too low

---

## 🛠 Common Fix Patterns

| Problem | Fix |
|--------|------|
| Probe fails immediately after pod starts | Increase `initialDelaySeconds` |
| App takes time to start | Add `APP_START_DELAY` + readiness probe |
| App becomes unresponsive temporarily | Add liveness probe to restart it |
| Pod never becomes ready | Confirm readiness path and app behavior |
| App crashes after hitting endpoint | Add both readiness + liveness probes |

---

## 🧠 Bonus: Use Events + JSONPath to Filter Output

### View Events for Namespace
```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Get Probe Events Only
```bash
kubectl get events | grep -E 'Readiness|Liveness'
```

### Get Status of Readiness for All Pods
```bash
kubectl get pods -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

---

## ✅ Final Notes
- Always test probes locally before deploying.
- Start with loose probe configs (e.g., higher delays), tighten them over time.
- Avoid setting overly aggressive probe values in production.

---

📘 Continue reading: [probes-best-practices.md](./probes-best-practices.md)


