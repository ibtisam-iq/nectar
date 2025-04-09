# Probes Best Practices in Kubernetes

Kubernetes provides **readiness** and **liveness probes** to manage the lifecycle and availability of containers. When misconfigured, they can cause unnecessary restarts or traffic loss. Below are production-grade best practices and recommendations to ensure your workloads stay resilient and healthy.

---

## ✅ General Guidelines

### 1. **Always Use Readiness Probes for Delayed Start Applications**
- Apps with initialization time should not receive traffic until they are fully ready.
- Example: Web servers that rely on database connections, cache warm-up, or file sync.

### 2. **Use Liveness Probes for Long-Running Containers**
- Ensures Kubernetes can automatically restart containers that hang or enter deadlock states.
- Only use when you know your application might get stuck **but not crash**.

### 3. **Don’t Use the Same Probe for Both Readiness & Liveness**
- Readiness: "Can I handle traffic now?"
- Liveness: "Am I still functioning?"

> Same probe = confusing signal → pod may get restarted unnecessarily.

### 4. **Design Probes to be Lightweight**
- Use endpoints like `/healthz`, `/ready`, `/live` that return simple 200 OK.
- Avoid calling external services (e.g., DB queries or auth checks) in probes.

---

## 🔧 Probe Configuration Best Practices

### 5. **Add `initialDelaySeconds` for Delayed Apps**
- Prevents probes from failing during container warm-up.
- For example, if your app takes 70s to start:

```yaml
initialDelaySeconds: 80
```

### 6. **Tweak `periodSeconds`, `failureThreshold`, `timeoutSeconds` Carefully**
| Parameter              | Description                                    | Default |
|------------------------|------------------------------------------------|---------|
| `periodSeconds`       | Time between each probe execution              | 10s     |
| `timeoutSeconds`      | Time to wait for a response                    | 1s      |
| `failureThreshold`    | # of failed checks before taking action        | 3       |
| `successThreshold`    | # of successes to mark probe as successful     | 1       |

> For HTTP-based probes: 2s timeout is usually safer than the default 1s.

---

## 🧪 Probe Types: When to Use What

| Type        | Use Case                                                     | Example                |
|-------------|--------------------------------------------------------------|------------------------|
| HTTP GET    | App exposes `/health`, `/ready`, etc.                       | Web servers, APIs      |
| TCP Socket  | Port-based readiness (e.g., DB, services with no HTTP)      | Redis, PostgreSQL      |
| Exec        | Fine-grained in-container check using shell commands        | Check file existence   |

---

## 🧼 Probe Hygiene Checklist

✅ Clearly separate readiness and liveness roles  
✅ Match delays with app startup times  
✅ Define `/live` and `/ready` endpoints in app  
✅ Avoid slow or expensive probe logic  
✅ Use meaningful `initialDelaySeconds` and `periodSeconds`  
✅ Test failure scenarios in staging with `/crash` or `/freeze`

---

## 🧠 Pro Tip
> Readiness failures **don’t restart** the pod — only mark it as unavailable for traffic.
> Liveness failures **do restart** the pod — use with caution!


