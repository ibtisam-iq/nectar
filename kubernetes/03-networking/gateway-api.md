# 🌐 Gateway API

## Install the Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```
> **Official Link:** https://github.com/kubernetes-sigs/gateway-api/releases

---

### 📁 1. `GatewayClass`: Defines the controller that manages Gateways.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: my-nginx-gateway-class  # Name used in Gateway to refer to this class
spec:
  controllerName: k8s.io/nginx-gateway-controller
  # This value MUST match the controller that's installed in your cluster.
  # For NGINX Gateway, it's usually "k8s.io/nginx-gateway-controller"
  # For Istio, it could be "istio.io/gateway-controller"
```

> ✅ `GatewayClass` is **cluster-scoped** and defines the implementation (e.g., NGINX, Istio) used for the `Gateway`.

---

### 🌐 2. `Gateway`: Defines a network endpoint (listener) that receives external traffic.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: my-nginx-gateway
  namespace: nginx-gateway  # Choose the namespace where the Gateway controller is watching
spec:
  gatewayClassName: my-nginx-gateway-class  # Referencing the GatewayClass above
  listeners:
  - name: http  # 👈 This is important! Used by HTTPRoute as sectionName
    protocol: HTTP
    port: 80
    hostname: example.com
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: tls-secret
    allowedRoutes:
      namespaces:
        from: Same
        # 'Same' = only allow HTTPRoutes from the same namespace as the Gateway
        # Use 'All' to allow from any namespace
```

> ✅ `Gateway` defines **listener(s)** like `http`, `https`, etc. Each has a name used by `HTTPRoute.sectionName`.

---

### 🚏 3. `HTTPRoute`: Defines routing rules that connect incoming traffic to backend services.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  namespace: nginx-gateway  # Must match allowedRoutes in Gateway
spec:
  parentRefs:
  - name: my-nginx-gateway  # 👈 This references the Gateway name
    namespace: nginx-gateway
    sectionName: http  # 👈 Matches the listener name in the Gateway
  rules:
  - matches:
    - path:
        type: PathPrefix  # Match all paths that start with "/"
        value: /
    backendRefs:
    - name: frontend-svc  # Service that receives traffic
      port: 80
      weight: 1  # Optional: used for traffic splitting if multiple backends
```

> ✅ `HTTPRoute` defines **routing rules** for HTTP traffic based on path, method, headers, etc. It forwards to a service.

### 📌 Why You Got Confused

Because:

* **Sometimes rules have only `matches`.**
* **Sometimes only `backendRefs`.**
* **Sometimes multiple `matches` conditions (path, headers, method, queryParams).**

It feels like “do I put it under `matches` or `backendRefs` or somewhere else?”

👉 The trick:

* **matches = when to send traffic** (conditions)
* **backendRefs = where to send traffic** (destination)
* **parentRefs = who listens and accepts this route**

### ✅ Mental Formula for HTTPRoute

* **parentRefs** = Gateway that owns the listener.
* **rules** = collection of conditions + actions.

  * **matches** = traffic conditions (path, headers, method, queryParams).
  * **backendRefs** = where to send traffic: destination (Services).

---

## 📦 Optional: `frontend-svc` (Target service)

Here’s a simple placeholder `Service` to connect to from the route.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: nginx-gateway
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 8080
```

And a matching Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: nginx-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx
        ports:
        - containerPort: 8080
```

---

## 📊 Summary of YAML Structure:

| Resource       | Scope        | Purpose                                 |
| -------------- | ------------ | --------------------------------------- |
| `GatewayClass` | Cluster-wide | Defines the type of Gateway controller  |
| `Gateway`      | Namespaced   | Exposes network listeners (HTTP, HTTPS) |
| `HTTPRoute`    | Namespaced   | Defines routing logic to Services       |
| `Service`      | Namespaced   | Connects Gateway traffic to app Pods    |
| `Deployment`   | Namespaced   | Creates Pods for backend                |

---

## 🧪 Want to Test it?

* Deploy a Gateway Controller (like [NGINX Gateway](https://github.com/nginxinc/nginx-gateway-fabric) or Istio).
* Apply all YAMLs above.
* Update `/etc/hosts` or DNS to resolve `example.com` to your ingress IP.
* Curl the app:

  ```bash
  curl http://example.com/
  ```

---

Perfect, sweetheart 🤝 Here’s the full set of **HTTPRoute rule scenarios** you can face in exams or practice.
Think of it as:

* **parentRefs → who listens (Gateway + listener)**
* **rules → collection of conditions + destinations**

  * **matches → when (path, headers, method, queryParams, etc.)**
  * **backendRefs → where (Services/ports, with optional weights)**
  * **filters**

---

## 🌱 Scenario 1: Only `backendRefs` (all traffic)

```yaml
rules:
- backendRefs:
  - name: frontend-svc
    port: 80
```

Once HTTPRoute resource is deployed, it will auto-add here:

```bash
Matches:
      Path:
        Type:   PathPrefix
        Value:  /
```

---

## 🌱 Scenario 2: Only `matches` (rare, often with filters)

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /
```

---

## 🌱 Scenario 3: Path-based routing

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /app
  backendRefs:
  - name: app-svc
    port: 80

- matches:
  - path:
      type: PathPrefix
      value: /api
  backendRefs:
  - name: api-svc
    port: 8080
```

---

## 🌱 Scenario 4: Header-based routing

```yaml
rules:
- matches:
  - headers:
    - type: Exact
      name: X-Env
      value: prod
  backendRefs:
  - name: prod-svc
    port: 80
```

---

## 🌱 Scenario 5: Method-based routing

```yaml
rules:
- matches:
  - method: POST
  backendRefs:
  - name: write-svc
    port: 8080
```

---

## 🌱 Scenario 6: Query param-based routing

```yaml
rules:
- matches:
  - queryParams:
    - type: Exact
      name: version
      value: v2
  backendRefs:
  - name: v2-svc
    port: 8080
```

---

## 🌱 Scenario 7: Multiple backends (traffic split)

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /
  backendRefs:
  - name: frontend-svc
    port: 80
    weight: 80
  - name: canary-svc
    port: 80
    weight: 20
```

---

## 🌱 Scenario 8: Combination (Path + Header)

```yaml
rules:
- matches:
  - path:
      type: PathPrefix
      value: /api
    headers:
    - type: Exact
      name: X-Env
      value: staging
  backendRefs:
  - name: staging-api-svc
    port: 8080
```

---

👉 Formula for remembering:

* **matches = when** (conditions to trigger rule)
* **backendRefs = where** (service/port to send traffic)
* **parentRefs = who** (gateway + listener this route binds to)

---
