Create an HTTPRoute named web-route in the nginx-gateway namespace that directs traffic from the web-gateway to a 
backend service named web-service on port 80 and ensures that the route is applied only to requests with the hostname cluster2-controlplane.

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
  - cluster2-controlplane                   # not added, so the question is marked wrong.
  parentRefs:
  - name: web-gateway
    namespace: nginx-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80

cluster2-controlplane ~ ➜  curl http://cluster2-controlplane:30080
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

Modify the existing web-gateway on cka5673 namespace to handle HTTPS traffic on port 443 for kodekloud.com, using a TLS certificate stored in a secret named kodekloud-tls.

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

---

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
