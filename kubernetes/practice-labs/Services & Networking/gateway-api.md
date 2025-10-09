## Mental Formula for HTTPRoute

* **parentRefs → who listens (Gateway + listener)**
* **rules → collection of conditions + destinations**

  * **matches → when (path, headers, method, queryParams, etc.)**
  * **backendRefs → where to send traffic: destination (Services/ports, with optional weights)**
  * **filters**

---

## 🚦 Gateway API Exam Key Indicators

### 1️⃣ **BackendRefs Only (default routing)**

* **When to use:** Only service name + port are provided, no path/header conditions.
* **Example**: All other traffic should continue to be routed to `web-service` also on port `8080`.
* **Notes:**

  * Don’t add `path: "/"` unless explicitly required.
  * If `curl http://cluster2-controlplane:30080` →

    * Add `hostnames: ["cluster2-controlplane"]`.
    * No path needed.
  * Test can also be:

    ```bash
    curl http://cluster2-controlplane:30080
    # or
    curl -H "Host: cluster2-controlplane" http://<node-IP>:<nodePort>
    ```

### 2️⃣ **Multiple Backends (Traffic Split)**

* **When to use:** Multiple services with weighted traffic.
* Path usually `/` or unspecified.

### 3️⃣ **Matches Only**

* **When to use:** Rare; exam sometimes gives filters/conditions without backends changing.
* **Notes:** Focus on exact match conditions like `method` or `queryParams`.

### 4️⃣ **Path-based Routing**

* **When to use:** Path is explicitly provided (`/`, `/login`, `/app`, etc.).
  * Use `type: PathPrefix`.
  * `backendRef` is usually provided.

### 5️⃣ **Header-based Routing**

* **When to use:** Header condition is explicitly given.
* `backendRef` is usually provided.

### 6️⃣ **Combination (Path + Header)**

* **When to use:** Both path and header are given.
* Multiple conditions can be combined under one `matches` rule.
* `backendRef` is usually provided.

✅ **Exam Tip Shortcut:**

* If only **service+port** → backendRefs only.
* If **curl has hostname** → add it to `hostnames`.
* If **curl has path** → add `matches.path`.
* If **headers mentioned** → add `matches.headers`.
* If **multiple backends** → add weighted split.

---

## Q1
Create an **HTTPRoute** named `web-route` in the `nginx-gateway` namespace that directs traffic from the `web-gateway` to a backend service named `web-service` on port 80 and ensures that the route is applied only to requests with the hostname `cluster2-controlplane`.

```bash
cluster2-controlplane ~ ➜  k get gateway -n nginx-gateway 
NAME          CLASS   ADDRESS   PROGRAMMED   AGE
web-gateway   nginx             True         75s

cluster2-controlplane ~ ➜  vi 6.yaml

cluster2-controlplane ~ ➜  k apply -f 6.yaml 
httproute.gateway.networking.k8s.io/web-route created

cluster2-controlplane ~ ➜  k describe httproutes.gateway.networking.k8s.io -n nginx-gateway web-route 
Name:         web-route
Namespace:    nginx-gateway
Labels:       <none>
Annotations:  <none>
API Version:  gateway.networking.k8s.io/v1
Kind:         HTTPRoute
Spec:
  Parent Refs:
    Group:      gateway.networking.k8s.io
    Kind:       Gateway
    Name:       web-gateway
    Namespace:  nginx-gateway
  Rules:
    Backend Refs:
      Group:   
      Kind:    Service
      Name:    web-service
      Port:    80
      Weight:  1
    Matches:
      Path:
        Type:   PathPrefix
        Value:  /
Events:           <none>

cluster2-controlplane ~ ➜  cat 6.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: nginx-gateway
spec:
  hostnames:
  - cluster2-controlplane      # not added, so the question is marked wrong.
  parentRefs:
  - name: web-gateway
    namespace: nginx-gateway
  rules:
  - matches:
    - path:                    # Since the question does not mention a path, you can skip the / path match and keep the rule generic.
        type: PathPrefix
        value: /          
    backendRefs:
    - name: web-service
      port: 80

cluster2-controlplane ~ ➜  curl http://cluster2-controlplane:30080/
<!DOCTYPE html>
<html>
</body>
</html>

cluster2-controlplane ~ ➜  k get svc -n nginx-gateway 
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
nginx-gateway   NodePort    172.20.220.38   <none>        80:30080/TCP,443:30081/TCP   36m
web-service     ClusterIP   172.20.11.94    <none>        80/TCP                       6m32s

cluster2-controlplane ~ ➜  
```

---

## Q2

**Modify** the existing `web-gateway` on `cka5673` namespace to handle HTTPS traffic on port 443 for `kodekloud.com`, using a TLS certificate stored in a secret named `kodekloud-tls`.

```bash
cluster3-controlplane ~ ➜  k get gatewayclasses.gateway.networking.k8s.io
NAME    CONTROLLER                                   ACCEPTED   AGE
nginx   gateway.nginx.org/nginx-gateway-controller   True       70m

cluster3-controlplane ~ ➜  k get gateway -n cka5673 
NAME          CLASS   ADDRESS   PROGRAMMED   AGE
web-gateway   nginx             True         33m

cluster3-controlplane ~ ➜  k get gateway -n cka5673 web-gateway -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  creationTimestamp: "2025-09-14T10:30:33Z"
  generation: 3
  name: web-gateway
  namespace: cka5673
  resourceVersion: "4086"
  uid: 78666c5a-7b79-470b-971f-421cdaef106b
spec:
  gatewayClassName: nginx                      # previously kodekloud, changed to nginx
  listeners:
  - allowedRoutes:
      namespaces:
        from: Same
    hostname: kodekloud.com                   # added             
    name: https
    port: 443                                 # previously 80, changed to 443
    protocol: HTTPS                           # previously HTTP, changed to HTTPS 
    tls:                                      # added
      certificateRefs:
      - group: ""
        kind: Secret
        name: kodekloud-tls                   # just add it, rest all of filds under tls: will auto-add.
      mode: Terminate
status:
  conditions:
  - lastTransitionTime: "2025-09-14T10:58:17Z"
    message: Gateway is accepted
    observedGeneration: 3
    reason: Accepted
    status: "True"
    type: Accepted
  - lastTransitionTime: "2025-09-14T10:58:17Z"
    message: Gateway is programmed
    observedGeneration: 3
    reason: Programmed
    status: "True"
    type: Programmed
  listeners:
  - attachedRoutes: 0
    conditions:
    - lastTransitionTime: "2025-09-14T10:58:17Z"
      message: Listener is accepted
      observedGeneration: 3
      reason: Accepted
      status: "True"
      type: Accepted
    - lastTransitionTime: "2025-09-14T10:58:17Z"
      message: Listener is programmed
      observedGeneration: 3
      reason: Programmed
      status: "True"
      type: Programmed
    - lastTransitionTime: "2025-09-14T10:58:17Z"
      message: All references are resolved
      observedGeneration: 3
      reason: ResolvedRefs
      status: "True"
      type: ResolvedRefs
    - lastTransitionTime: "2025-09-14T10:58:17Z"
      message: No conflicts
      observedGeneration: 3
      reason: NoConflicts
      status: "False"
      type: Conflicted
    name: https
    supportedKinds:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
    - group: gateway.networking.k8s.io
      kind: GRPCRoute
```

Thanks for sharing the YAML and status output — this makes things clear.

Right now your **Gateway is not yet usable**, because it shows:

```
status:
  conditions:
  - message: Waiting for controller
    reason: Pending
    status: Unknown
    type: Accepted
  - message: Waiting for controller
    reason: Pending
    status: Unknown
    type: Programmed
```

That means:

* The **Gateway object exists**, but
* No **Gateway controller** (like `nginx-gateway`, `istio`, `envoy-gateway`, or your `kodekloud` controller) has picked it up yet.
* Because of that, there is **no ADDRESS assigned**:

  ```
  ADDRESS   PROGRAMMED
            Unknown
  ```

👉 Until a controller binds to this `GatewayClass` (`kodekloud` in your case), the Gateway won’t get an IP/hostname, and you cannot curl it.

--

### 🔎 How to Move Forward

1. **Check the GatewayClass**

```bash
kubectl get gatewayclass
```

You should see one named `kodekloud`.

2. **Check if the Gateway controller is running**

```bash
kubectl get pods -A | grep gateway
```

Look for something like `kodekloud-gateway-controller`. If it’s not there, the Gateway won’t work.

3. **If controller exists but not binding:**

   * Describe the GatewayClass:

     ```bash
     kubectl describe gatewayclass kodekloud
     ```
   * Check for conditions like `Accepted=True`.

4. **Until ADDRESS is populated** in `kubectl get gateway web-gateway -n cka5673`,
   you can’t `curl` because there’s nothing listening yet.

✅ Summary:

* Right now, your Gateway is only defined, but **no controller has programmed it**, so no IP address is available.
* First step is to **confirm the GatewayClass `kodekloud` is backed by a running controller**.

--

Perfect, thanks for the extra info 👍

Now we see the issue clearly:

* Your **Gateway** (`web-gateway`) is using **GatewayClass = kodekloud**
* But the only installed **GatewayClass** is `nginx` (accepted = True)
* And the **nginx-gateway-controller** is running fine.
* Since no controller manages `kodekloud`, your Gateway stays in `Pending` with no address.

### ✅ How to Fix

You need your Gateway to use the **nginx GatewayClass**, not `kodekloud`.

Edit your Gateway spec so it looks like this:

```yaml
spec:
  gatewayClassName: nginx      # 🔹 Use the working class
```

⚡ Summary:
Your Gateway was pointing to a non-existent controller (`kodekloud`). Switching it to `nginx` will let the existing `nginx-gateway-controller` pick it up and program it.

--

Got it 👍 Let’s map your question directly to the **requirements**:

### ✅ Requirement 1:

> *Is the web gateway configured to listen on the hostname `kodekloud.com`?*

In the YAML we edited:

```yaml
listeners:
  - name: https
    hostname: kodekloud.com   # ✅ Gateway listens only for this hostname
    port: 443
    protocol: HTTPS
```

Yes ✅ — the `hostname` field is explicitly set to `kodekloud.com`.
Without this, the Gateway would match all hostnames (`*` by default).

### ✅ Requirement 2:

> *Is the HTTPS listener configured with the correct TLS certificate?*

In the YAML:

```yaml
tls:
  mode: Terminate
  certificateRefs:
    - kind: Secret
      name: kodekloud-tls     # ✅ TLS secret reference
```

Yes ✅ — the listener uses **TLS Terminate** mode, and the certificate secret `kodekloud-tls` is configured.
This secret must exist in the **same namespace as the Gateway (`cka5673`)** and contain the keys:

* `tls.crt`
* `tls.key`

### 🔎 How you can verify in cluster

Check the Gateway config:

```bash
kubectl get gateway web-gateway -n cka5673 -o yaml
```

Look for:

* `hostname: kodekloud.com`
* `certificateRefs: name: kodekloud-tls`

Check the secret exists:

```bash
kubectl get secret kodekloud-tls -n cka5673
```

✅ So after modification, the **web-gateway** *is configured to listen on `kodekloud.com`* and *is using the correct TLS certificate (`kodekloud-tls`)*.

--

Perfect 🎉 You’ve got it working now!

Let’s confirm against the original exam-style requirements:

> **Modify the existing `web-gateway` on `cka5673` namespace to handle HTTPS traffic on port 443 for `kodekloud.com`, using a TLS certificate stored in a secret named `kodekloud-tls`.**

✅ **Gateway Class** → `nginx` (controller exists and programmed)
✅ **Listener** → `HTTPS` on port `443`
✅ **Hostname** → `kodekloud.com`
✅ **TLS** → Secret `kodekloud-tls`, `Terminate` mode
✅ **Status** → `Accepted` + `Programmed = True`

Everything matches 🎯

⚠️ One thing to note:
Your Gateway still shows no external `ADDRESS`:

```
NAME          CLASS   ADDRESS   PROGRAMMED
web-gateway   nginx             True
```

This depends on the cluster environment:

* If the cluster supports **Service of type LoadBalancer**, the controller will eventually allocate an external IP or hostname here.
* In bare-metal or exam clusters, you might only get a **ClusterIP Service**, meaning you’ll need `kubectl port-forward` or node IP + `--resolve` trick to curl it.

✅ So functionally: The Gateway is configured correctly.
👉 If this were in a **CKA/CKAD/CKS exam**, you’d already score full marks for this task.

--

```bash
cluster3-controlplane ~ ➜  k get svc -n nginx-gateway 
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
nginx-gateway   NodePort   10.43.27.175   <none>        80:30080/TCP,443:30081/TCP   63m

cluster3-controlplane ~ ➜  kubectl get nodes -o wide
NAME                    STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    
cluster3-controlplane   Ready    control-plane,master   84m   v1.32.0+k3s1   192.168.141.37   <none>        Alpine Linux v3.16   5.15.0-1083-gcp

cluster3-controlplane ~ ✖ curl -vk --resolve kodekloud.com:30081:192.168.141.37 https://kodekloud.com:30081/
* Added kodekloud.com:30081:192.168.141.37 to DNS cache
* Hostname kodekloud.com was found in DNS cache
*   Trying 192.168.141.37:30081...
* Connected to kodekloud.com (192.168.141.37) port 30081
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / [blank] / UNDEF
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=kodekloud.com; O=kodekloud
*  start date: Sep 14 10:30:33 2025 GMT
*  expire date: Sep 14 10:30:33 2026 GMT
*  issuer: CN=kodekloud.com; O=kodekloud
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
*   Certificate level 0: Public key type ? (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://kodekloud.com:30081/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: kodekloud.com:30081]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.5.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: kodekloud.com:30081
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/2 404 
< server: nginx
< date: Sun, 14 Sep 2025 11:07:15 GMT
< content-type: text/html
< content-length: 146
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host kodekloud.com left intact

```

Beautiful 🎉 You’ve successfully verified the Gateway’s TLS!

Let’s break down what happened:

* ✅ **TLS handshake succeeded** → Certificate from your `kodekloud-tls` secret was presented.

  ```
  subject: CN=kodekloud.com; O=kodekloud
  ```
* ✅ **HTTPS listener is working** on port `443` (via NodePort `30081`).
* ✅ **Gateway programming is correct** — no more pending status.
* ❌ **HTTP 404** → This is expected because while the Gateway is listening, you don’t yet have an `HTTPRoute` (or `GRPCRoute`) bound to it, so requests aren’t routed to any backend Service.

Once you apply this, your `curl` will stop returning 404 and instead hit the backend app.

✅ So in summary:

* Your **Gateway config is correct**.
* Your **TLS is working**.
* You only need an `HTTPRoute` to point traffic to a backend.

```bash
cluster3-controlplane ~ ➜  k get svc -n cka5673 
No resources found in cka5673 namespace.

cluster3-controlplane ~ ➜  k get po -n cka5673 
No resources found in cka5673 namespace.

cluster3-controlplane ~ ➜  vi test.yaml

cluster3-controlplane ~ ➜  k apply -f test.yaml 
deployment.apps/nginx-deploy created
service/nginx-svc created
httproute.gateway.networking.k8s.io/nginx-route created

cluster3-controlplane ~ ➜  curl -vk --resolve kodekloud.com:30081:192.168.141.37 https://kodekloud.com:30081/
* Added kodekloud.com:30081:192.168.141.37 to DNS cache
* Hostname kodekloud.com was found in DNS cache
*   Trying 192.168.141.37:30081...
* Connected to kodekloud.com (192.168.141.37) port 30081
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / [blank] / UNDEF
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=kodekloud.com; O=kodekloud
*  start date: Sep 14 10:30:33 2025 GMT
*  expire date: Sep 14 10:30:33 2026 GMT
*  issuer: CN=kodekloud.com; O=kodekloud
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
*   Certificate level 0: Public key type ? (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://kodekloud.com:30081/
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: kodekloud.com:30081]
* [HTTP/2] [1] [:path: /]
* [HTTP/2] [1] [user-agent: curl/8.5.0]
* [HTTP/2] [1] [accept: */*]
> GET / HTTP/2
> Host: kodekloud.com:30081
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/2 200 
< server: nginx
< date: Sun, 14 Sep 2025 11:35:09 GMT
< content-type: text/html
< content-length: 615
< last-modified: Wed, 13 Aug 2025 14:33:41 GMT
< etag: "689ca245-267"
< accept-ranges: bytes
< 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
* Connection #0 to host kodekloud.com left intact

cluster3-controlplane ~ ➜  
```

Got it 👍 — that explains the **404**. Your Gateway is alive and terminating TLS properly, but there’s nothing behind it yet (no Pods, no Services).

To see a real response, you need at least:

1. **A backend Deployment** (e.g. `nginx`),
2. **A Service** that exposes that Deployment,
3. **An HTTPRoute** that binds your `web-gateway` to that Service.

### ✅ Step 1 — Create a simple Nginx Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  namespace: cka5673
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

### ✅ Step 2 — Expose it with a Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
  namespace: cka5673
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### ✅ Step 3 — Route traffic via the Gateway

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: nginx-route
  namespace: cka5673
spec:
  parentRefs:
  - name: web-gateway
  hostnames:
  - "kodekloud.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx-svc
      port: 80
```

### 🔎 Test Again

After applying all three:

```bash
curl -vk --resolve kodekloud.com:30081:192.168.141.37 https://kodekloud.com:30081/
```

This time, instead of `404 Not Found`, you should see the **default Nginx welcome page HTML**.

---

# Q3

**Extend** the `web-route` on `cka7395` to direct traffic with the path prefix `/api` to a service named `api-service` on port `8080`, while all other traffic continues to route to `web-service`.

```bash

cluster3-controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io -n cka7395 
NAME        HOSTNAMES   AGE
web-route               44s

cluster3-controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io -n cka7395 web-route -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  creationTimestamp: "2025-09-14T11:41:20Z"
  generation: 1
  name: web-route
  namespace: cka7395
  resourceVersion: "6276"
  uid: 8fea7494-855a-4d40-a9d7-893c8a70a781
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: nginx-gateway
    namespace: nginx-gateway
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: web-service
      port: 80
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2025-09-14T11:41:20Z"
      message: All references are resolved
      observedGeneration: 1
      reason: ResolvedRefs
      status: "True"
      type: ResolvedRefs
    - lastTransitionTime: "2025-09-14T11:41:20Z"
      message: The Gateway is ignored by the controller
      observedGeneration: 1
      reason: GatewayIgnored
      status: "False"
      type: Accepted
    controllerName: gateway.nginx.org/nginx-gateway-controller
    parentRef:
      group: gateway.networking.k8s.io
      kind: Gateway
      name: nginx-gateway
      namespace: nginx-gateway

cluster3-controlplane ~ ➜  k get gateway -n nginx-gateway 
NAME            CLASS   ADDRESS   PROGRAMMED   AGE
nginx-gateway   nginx             False        2m24s

cluster3-controlplane ~ ➜  k get gatewayclasses.gateway.networking.k8s.io 
NAME    CONTROLLER                                   ACCEPTED   AGE
nginx   gateway.nginx.org/nginx-gateway-controller   True       103m

cluster3-controlplane ~ ➜  k get gateway -n nginx-gateway nginx-gateway -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  annotations:
  creationTimestamp: "2025-09-14T11:41:19Z"
  generation: 1
  name: nginx-gateway
  namespace: nginx-gateway
  resourceVersion: "6272"
  uid: 44a3eeb0-653e-40db-a223-a56cd1ac9253
spec:
  gatewayClassName: nginx
  listeners:
  - allowedRoutes:
      namespaces:
        from: All
    name: http
    port: 80
    protocol: HTTP
status:
  conditions:
  - lastTransitionTime: "2025-09-14T11:41:19Z"
    message: The resource is ignored due to a conflicting Gateway resource
    observedGeneration: 1
    reason: GatewayConflict
    status: "False"
    type: Accepted
  - lastTransitionTime: "2025-09-14T11:41:19Z"
    message: The resource is ignored due to a conflicting Gateway resource
    observedGeneration: 1
    reason: GatewayConflict
    status: "False"
    type: Programmed

cluster3-controlplane ~ ➜  kubectl get gateways -A
NAMESPACE       NAME            CLASS   ADDRESS   PROGRAMMED   AGE
cka5673         web-gateway     nginx             True         79m
nginx-gateway   nginx-gateway   nginx             False        9m8s

cluster3-controlplane ~ ➜  k edit httproutes.gateway.networking.k8s.io -n cka7395 web-route 
httproute.gateway.networking.k8s.io/web-route edited

cluster3-controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io -n cka7395 
NAME        HOSTNAMES   AGE
web-route               14m

cluster3-controlplane ~ ➜  k get no -o wide
NAME                    STATUS   ROLES                  AGE    VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
cluster3-controlplane   Ready    control-plane,master   141m   v1.32.0+k3s1   192.168.141.37   <none>        Alpine Linux v3.16   5.15.0-1083-gcp   containerd://1.6.8

cluster3-controlplane ~ ➜  k get svc -n nginx-gateway 
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
nginx-gateway   NodePort   10.43.27.175   <none>        80:30080/TCP,443:30081/TCP   121m

cluster3-controlplane ~ ➜  curl http://192.168.141.37:30081/api
<html>
<head><title>400 The plain HTTP request was sent to HTTPS port</title></head>
<body>
<center><h1>400 Bad Request</h1></center>
<center>The plain HTTP request was sent to HTTPS port</center>
<hr><center>nginx</center>
</body>
</html>

cluster3-controlplane ~ ➜  curl http://192.168.141.37:30081/
<html>
<head><title>400 The plain HTTP request was sent to HTTPS port</title></head>
<body>
<center><h1>400 Bad Request</h1></center>
<center>The plain HTTP request was sent to HTTPS port</center>
<hr><center>nginx</center>
</body>
</html>

cluster3-controlplane ~ ➜  curl http://192.168.141.37:30080/
curl: (7) Failed to connect to 192.168.141.37 port 30080 after 0 ms: Couldn't connect to server

cluster3-controlplane ~ ✖ curl http://192.168.141.37:30080/api
curl: (7) Failed to connect to 192.168.141.37 port 30080 after 0 ms: Couldn't connect to server

cluster3-controlplane ~ ✖ 
```

Got it 👍 This is an **HTTPRoute update** task, not Gateway.
The `web-route` is already pointing all traffic (`/`) to `web-service:80`.

👉 What you need to do:

* Add a **new rule** in the `HTTPRoute` for requests starting with `/api`.
* Route those to `api-service:8080`.
* Keep the existing rule so everything else (default `/`) continues to go to `web-service:80`.

Here’s the updated `HTTPRoute` manifest with detailed comments:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: cka7395
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: nginx-gateway
    namespace: nginx-gateway

  rules:
  # Rule 1: Match /api path and send to api-service:8080
  - matches:
    - path:
        type: PathPrefix   # Prefix match ensures /api, /api/v1, etc. go here
        value: /api
    backendRefs:
    - name: api-service
      port: 8080

  # Rule 2: Default rule for everything else
  - matches:
    - path:
        type: PathPrefix   # Prefix "/" matches all paths not matched above
        value: /
    backendRefs:
    - name: web-service
      port: 80
```

### Steps:

1. Edit the route:

   ```bash
   kubectl edit httproute -n cka7395 web-route
   ```

   (or apply the YAML above).

2. Verify:

   ```bash
   kubectl get httproute -n cka7395 web-route -o yaml
   ```
--

Alright sweetheart 💡 here’s a clean **debug flow for fixing a `Programmed: False` Gateway** in Kubernetes Gateway API (like in your lab).

## 🔎 Debugging Gateway with `Programmed: False`

### 1. Check the GatewayClass

```bash
kubectl get gatewayclass nginx -o yaml
```

* Look at `.status.conditions`.
* Must show `Accepted=True`.
  ✅ In your case, it’s already `Accepted=True`, so the class is fine.

--

### 2. Check for conflicting Gateways

Error in your YAML:

```
message: The resource is ignored due to a conflicting Gateway resource
reason: GatewayConflict
```

👉 This means **two Gateways in the same namespace are trying to use the same port (80)** with the same GatewayClass.

**Fix:**

```bash
kubectl get gateways -A
```

* Identify if another Gateway is using port 80 with the `nginx` class.
* Delete or edit the conflicting one:

```bash
kubectl delete gateway <other-gateway> -n <ns>
```

### 3. Verify Listener Section

Your Gateway has:

```yaml
listeners:
- name: http
  port: 80
  protocol: HTTP
  allowedRoutes:
    namespaces:
      from: All
```

✅ That’s valid.
But if there’s already another Gateway with the same spec, you’ll hit `GatewayConflict`.

--

Aha, got it sweetheart ❤️ — the error explains everything:

```
400 The plain HTTP request was sent to HTTPS port
```

That means:

* You are trying to use `http://` on port **30081**, but `30081` is mapped to the **HTTPS listener** of the `nginx-gateway`.
* For **HTTP traffic**, you must use **30080** (because in your NodePort service you have `80:30080/TCP, 443:30081/TCP`).

### 🔹 Correct Testing

#### Test **API service**:

```bash
curl http://192.168.141.37:30080/api
```

#### Test **Web service**:

```bash
curl http://192.168.141.37:30080/
```

👉 Use **30081** only if you’ve configured your Gateway to terminate TLS (with a `tls:` block in the listener) and you’re calling with `https://`.
👉 Since your `nginx-gateway` here is configured with only `protocol: HTTP` on port **80**, all traffic is plain HTTP and exposed on **30080**.

--

Got it sweetheart ❤️ let’s debug this step by step because now we’ve moved past config into **connectivity / routing issues**.

### 1️⃣ Confirm the Gateway listener

Your Gateway YAML showed:

```yaml
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
```

👉 That means it should listen on **port 80 (NodePort 30080)** for HTTP traffic.

But your status earlier said:

```
status:
  conditions:
  - message: The resource is ignored due to a conflicting Gateway resource
    reason: GatewayConflict
    status: "False"
    type: Accepted
```

⚠️ This means the `nginx-gateway` wasn’t fully programmed — **there’s a conflict** (maybe another Gateway in the same namespace with the same listener port).

### 2️⃣ Check if another Gateway is using port 80

Run:

```bash
kubectl get gateway -A
```

### 3️⃣ Confirm the controller actually attached

Check the logs of your `nginx-gateway` controller pod:

```bash
kubectl logs -n nginx-gateway deploy/nginx-gateway
```

Look for errors like *"conflicting Gateway"* or *"listener port already in use"*.

### 4️⃣ Quick check: service exposure

Let’s confirm the service is really binding NodePort `30080`:

```bash
kubectl get svc -n nginx-gateway nginx-gateway -o yaml | grep nodePort
```

You should see:

```yaml
nodePort: 30080
```

### 5️⃣ Test inside the cluster

Sometimes NodePort doesn’t respond if the controller never bound the listener. Let’s test from **inside a pod** in the cluster:

```bash
kubectl run tmp --rm -it --image=curlimages/curl -- sh
# inside pod:
curl http://nginx-gateway.nginx-gateway.svc.cluster.local:80/
curl http://nginx-gateway.nginx-gateway.svc.cluster.local:80/api
```

👉 If this works, but NodePort fails → NodePort is exposed but not bound due to Gateway conflict.

---

## Q4 

Configure a `web-portal-httproute` within the `cka3658` namespace to facilitate traffic distribution. Route **80%** of the traffic to `web-portal-service-v1` and **20%** to the new version, `web-portal-service-v2`.

> **Note: Gateway has already been created in the `nginx-gateway` namespace.**

To test the gateway, execute the following command:

`curl http://cluster2-controlplane:30080`

```bash
cluster2-controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io -A
No resources found

cluster2-controlplane ~ ➜  k get gateway -A 
NAMESPACE       NAME            CLASS   ADDRESS   PROGRAMMED   AGE
nginx-gateway   nginx-gateway   nginx             True         77s

cluster2-controlplane ~ ➜  k get svc -n cka3658 
NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
web-portal-service-v1   ClusterIP   172.20.34.1      <none>        80/TCP    106s
web-portal-service-v2   ClusterIP   172.20.133.219   <none>        80/TCP    105s

cluster2-controlplane ~ ➜  k get svc -n nginx-gateway 
NAME            TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
nginx-gateway   NodePort   172.20.19.62   <none>        80:30080/TCP,443:30081/TCP   90m

cluster2-controlplane ~ ➜  vi 9.yaml

cluster2-controlplane ~ ➜  k apply -f 9.yaml 
httproute.gateway.networking.k8s.io/web-portal-httproute created

cluster2-controlplane ~ ➜  curl http://cluster2-controlplane:30080

<html>
<head><title>Welcome</title></head>
<body>
    <h1>Hello from Web Portal App 2</h1>
</body>
</html>
cluster2-controlplane ~ ➜  cat 9.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-portal-httproute
  namespace: cka3658
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
  hostnames:
  - "cluster2-controlplane"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-portal-service-v1
      port: 80
      weight: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-portal-service-v2
      port: 80
      weight: 20

cluster2-controlplane ~ ➜  k get no
NAME                    STATUS   ROLES           AGE    VERSION
cluster2-controlplane   Ready    control-plane   112m   v1.32.0
cluster2-node01         Ready    <none>          111m   v1.32.0

cluster2-controlplane ~ ➜  k get no -o wide
NAME                    STATUS   ROLES           AGE    VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
cluster2-controlplane   Ready    control-plane   112m   v1.32.0   192.168.13.232   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
cluster2-node01         Ready    <none>          111m   v1.32.0   192.168.141.49   <none>        Ubuntu 22.04.4 LTS   5.15.0-1083-gcp   containerd://1.6.26

cluster2-controlplane ~ ➜  curl http://192.168.13.232:30080
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

cluster2-controlplane ~ ➜  curl http://192.168.141.49:30080
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

cluster2-controlplane ~ ➜  curl -H "Host: cluster2-controlplane" http://192.168.13.232:30080

<html>
<head><title>Welcome</title></head>
<body>
    <h1>Hello from Web Portal App 1</h1>
</body>
</html>
cluster2-controlplane ~ ➜   
```

Great question sweetheart ❤️ — let’s break this down clearly.

### 🔑 In Gateway API (like `HTTPRoute`)

* The `hostnames:` field is **optional**.
* If you don’t set it, the route will match **all hostnames** (wildcard).
* If you do set it, you can specify either:

  * A **fully qualified domain name (FQDN)** like `myapp.example.com`
  * A **wildcard domain** like `*.example.com`
  * Or even the **cluster node name / IP** if you test locally (but that’s not common practice).

### ✅ For your lab environment (KodeKloud / CKAD-style cluster)

* You don’t have a real domain (like `.com`) mapped.
* You usually **don’t need to set `hostnames`** — just leave it out, and it will work with `curl http://cluster2-controlplane:30080`.

So your YAML can simply skip the `hostnames:` block.

### Example: Your `HTTPRoute` for traffic splitting

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-portal-httproute
  namespace: cka3658
spec:
  parentRefs:
    - name: nginx-gateway
      namespace: nginx-gateway
  rules:
    - backendRefs:
        - name: web-portal-service-v1
          port: 80
          weight: 80
        - name: web-portal-service-v2
          port: 80
          weight: 20
```

Notice 👉 I did **not** include `hostnames:`.
That way, when you test with:

```bash
curl http://cluster2-controlplane:30080
```

it will still work, because the Gateway is listening on all hostnames.

### 📝 If you *had* a real DNS (e.g. `portal.example.com`)

Then you’d add:

```yaml
hostnames:
  - "portal.example.com"
```

But in your lab → not needed.

--

Nice catch ✅ — the behavior makes total sense.

Here’s what’s happening:

* When you curl **just the IP:30080**, you got `404 Not Found` → because your `HTTPRoute` has a `hostnames:` field.
  The Gateway only routes traffic if the **Host header matches**.

* When you curl with:

  ```bash
  curl -H "Host: cluster2-controlplane" http://192.168.13.232:30080
  ```

  you got a valid response → because now the Host header matches your YAML `hostnames`.

### 🔑 Options to fix

1. **Keep `hostnames:`**
   ✅ Then you *must always* use:

   ```bash
   curl -H "Host: cluster2-controlplane" http://<NODE-IP>:30080
   ```

   (Exactly like you just did — this works.)

2. **Remove `hostnames:` from your HTTPRoute YAML**
   ✅ Then any request hitting the Gateway on port `30080` will be routed (no Host header required).
   Example YAML adjustment:

   ```yaml
   spec:
     parentRefs:
     - name: nginx-gateway
       namespace: nginx-gateway
     rules:
     - matches:
       - path:
           type: PathPrefix
           value: /
       backendRefs:
       - name: web-portal-service-v1
         port: 80
         weight: 80
     - matches:
       - path:
           type: PathPrefix
           value: /
       backendRefs:
       - name: web-portal-service-v2
         port: 80
         weight: 20
   ```

   Now you can simply run:

   ```bash
   curl http://192.168.13.232:30080
   ```

👉 Since you’re working in a **lab/exam environment**, I’d recommend **removing `hostnames:`** (Option 2) to avoid needing `-H "Host: ..."`.

--

```bash
# this question was wrong.. it is what it is...
cluster2-controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io -A
NAMESPACE   NAME                   HOSTNAMES                   AGE
cka3658     web-portal-httproute   ["cluster2-controlplane"]   26m

cluster2-controlplane ~ ➜  ls
12.yaml  7.yaml  vpa-crds.txt  web-portal-httproute.yaml

cluster2-controlplane ~ ➜  vi web-portal-httproute.yaml 

cluster2-controlplane ~ ➜  k replace -f web-portal-httproute.yaml --force
httproute.gateway.networking.k8s.io "web-portal-httproute" deleted
httproute.gateway.networking.k8s.io/web-portal-httproute replaced

cluster2-controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io -A
NAMESPACE   NAME                   HOSTNAMES   AGE
cka3658     web-portal-httproute               20s

cluster2-controlplane ~ ➜  cat web-portal-httproute.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-portal-httproute
  namespace: cka3658
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: portal-service-v1
      port: 80
      weight: 80
    - name: portal-service-v2
      port: 80
      weight: 20

cluster2-controlplane ~ ➜  
```

---

## Q 5
Create the `web-app-route` in the `ck2145` namespace. This route should direct requests that contain the **header** `X-Environment: canary` to the `web-service-canary` on port `8080`. All other traffic should continue to be routed to `web-service` also on port `8080`.


> Note: Gateway has already been created in the `nginx-gateway` namespace.

To test the gateway, execute the following command:

`curl -H 'X-Environment: canary' http://localhost:30080`

```bash
cluster3-controlplane ~ ➜  k get svc -n ck2145 web-service
NAME          TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
web-service   ClusterIP   10.43.32.48   <none>        8080/TCP   12m

cluster3-controlplane ~ ➜  k get svc -n ck2145
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
web-service          ClusterIP   10.43.32.48     <none>        8080/TCP   12m
web-service-canary   ClusterIP   10.43.150.157   <none>        8080/TCP   12m

cluster3-controlplane ~ ➜  cat 13.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-app-route
  namespace: ck2145
spec:
  parentRefs:
  - name: nginx-gateway 
    namespace: nginx-gateway
  rules:
  - matches:
    - headers:
      - name: X-Environment
        value: canary
    backendRefs:
    - name: web-service-canary
      port: 8080
  - backendRefs:
    - name: web-service
      port: 8080
```
