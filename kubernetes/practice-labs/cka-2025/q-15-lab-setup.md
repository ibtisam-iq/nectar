# 🎯 **FINAL LAB STRUCTURE (Clean, Professional, CKA-Style)**

### **Namespaces**

* `frontend`
* `backend`

### **Deployments**

* `frontend` → container repeatedly curls backend
* `backend` → nginx serving simple HTTP on port 80

### **Service**

* `backend-service` (port 80 → 80)

### **Network Policies**

1. **deny-all-ingress** (frontend)
2. **deny-all-egress** (frontend)
3. **deny-all-ingress** (backend)
4. **deny-all-egress** (backend)

➡ These simulate “full lockdown”.

5. **Three exam-provided policies** in `~/netpol/`

   * `netpol-1.yaml`
   * `netpol-2.yaml` (correct one)
   * `netpol-3.yaml`

➡ These ONLY allow **backend ingress**, and ONLY for certain labels.

6. **Custom policy (must be created)**

   * Because frontend egress is blocked by deny-all-egress
   * Must allow frontend → backend traffic on port 80

---

# 🟦 **Now I will give you the FULL LAB — all YAML files**

Just apply them and your entire lab will run exactly like the CKA exam scenario.

---

# ✅ **1. Namespaces**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: frontend
---
apiVersion: v1
kind: Namespace
metadata:
  name: backend
```

---

# ✅ **2. Backend Deployment (nginx)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend-container
          image: nginx
          ports:
          - containerPort: 80
          volumeMounts:
          - mountPath: /usr/share/nginx/html
            name: html
      initContainers:
      - command:
        - sh
        - -c
        - echo 'love you my sweetheart, Ibtisam' > /html/index.html
        image: busybox:1.28
        name: init-container
        volumeMounts:
        - mountPath: /html
          name: html
      volumes:
      - emptyDir: {}
        name: html
```

---

# ✅ **3. Backend Service**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
```

---

# ✅ **4. Frontend Deployment (your curl loop)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
        - name: frontend-container
          image: curlimages/curl:7.88.1
          command:
            - /bin/sh
            - -c
            - |
              while true; do
                echo "Sending request to backend..."
                curl -s http://backend-service.backend.svc.cluster.local
                sleep 5
              done
          ports:
            - containerPort: 80
```

---

# 🟥 **5. Deny-All Network Policies (same as exam style)**

### In frontend:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

### In backend:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-egress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

---

# 🟦 **6. Provided Exam Policies (~/netpol/)**

*(We keep them EXACTLY like your originals.)*

### **netpol-1.yaml**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-from-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
      ports:
        - protocol: TCP
          port: 80
    - ports:
      - protocol: UDP
        port: 53
```

---

### **netpol-2.yaml (least privilege, correct one)**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 80
```

---

### **netpol-3.yaml**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-nothing
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress: []
```

---

# 🟩 **7. Custom Egress Policy (the required one to finish the lab)**

This is the one the exam *expects you to create yourself*.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-backend
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: backend
          podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 80
    - ports:
        - protocol: UDP
          port: 53
```

---

# 🎉 **8. After Applying Everything — Test**

```bash
k logs -n frontend deploy/frontend-deployment -f
```

If everything is correct, you will see:

```
love you my sweetheart, Ibtisam
```

---

