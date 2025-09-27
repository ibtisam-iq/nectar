### 📌 Blue-Green Deployment Strategy (Label Focused)

* **Concept**:

  * Maintain **two environments**:

    * **Blue** → current live version.
    * **Green** → new version (standby).
  * Only one of them receives production traffic at a time.
* **Traffic Switching**:

  * Achieved using **labels + selectors** in Kubernetes.
  * **Service** routes traffic to Pods based on labels.
  * During switch: update the Service’s **selector label** from Blue → Green.
* **Rollback**:

  * Simply re-point Service back to the old label.
  * No pod termination/re-creation needed, traffic switch is instant.

---

### Example YAML (Blue-Green with Labels)

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
    app: myapp       # Constant app name
    version: blue    # 👈 Service currently pointing to "blue" version
  ports:
    - port: 80
      targetPort: 8080
---
# --------------------------
# Blue Deployment
# --------------------------
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue   # 👈 Label matches Service selector
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
        - name: myapp
          image: myapp:v1   # Old version
          ports:
            - containerPort: 8080
---
# --------------------------
# Green Deployment
# --------------------------
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green   # 👈 Label for new version
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
        - name: myapp
          image: myapp:v2   # New version
          ports:
            - containerPort: 8080
```

---

### ⚡ Switching Traffic (Blue → Green)

* Initially:

  ```yaml
  selector:
    app: myapp
    version: blue   # Traffic goes to Blue pods
  ```

* After switch:

  ```yaml
  selector:
    app: myapp
    version: green  # 👈 Change here → traffic now goes to Green pods
  ```

* Rollback: just change `green` back to `blue`.

---
