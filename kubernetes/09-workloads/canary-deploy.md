# 📌 Canary Deployment Strategy

* **Concept**:

  * Deploy a **small subset of pods** with the new version (canary).
  * Run them **alongside the stable version** (main).
  * Service points to **both** using common labels → traffic is split between stable & canary.
  * Increase canary replicas gradually until stable version is fully replaced.
* **Traffic Control**:

  * **Labels + replica count** control distribution.
  * Example: 90% traffic to stable (9 pods), 10% to canary (1 pod).
  * Advanced routing (e.g., Istio/NGINX) can provide percentage-based splits.

---

### Example YAML (Canary with Labels)

```yaml
# --------------------------
# Service (entry point)
# --------------------------
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp   # 👈 Service only looks at "app: myapp"
  ports:
    - port: 80
      targetPort: 8080
---
# --------------------------
# Stable Deployment
# --------------------------
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-stable
spec:
  replicas: 9       # 👈 90% of traffic (9 pods)
  selector:
    matchLabels:
      app: myapp
      version: stable
  template:
    metadata:
      labels:
        app: myapp
        version: stable
    spec:
      containers:
        - name: myapp
          image: myapp:v1   # Stable version
          ports:
            - containerPort: 8080
---
# --------------------------
# Canary Deployment
# --------------------------
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1       # 👈 10% of traffic (1 pod)
  selector:
    matchLabels:
      app: myapp
      version: canary
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
        - name: myapp
          image: myapp:v2   # New version (canary)
          ports:
            - containerPort: 8080
```

---

## ⚡ How Traffic Splitting Works

* Service selects pods by **`app: myapp`** (ignores version).
* Both stable (`version: stable`) and canary (`version: canary`) pods match → Service sends traffic to both.
* Traffic ratio depends on **replica count**:

  * 9 stable pods → ~90% traffic.
  * 1 canary pod → ~10% traffic.

---

## Canary Progression

1. Start with **small replica count** for canary (e.g., 1 pod).
2. Monitor metrics, logs, errors.
3. Gradually increase canary replicas → shift more traffic.
4. Once stable, **scale down stable to 0** and run only canary.

---
