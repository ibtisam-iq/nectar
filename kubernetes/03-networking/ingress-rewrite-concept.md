# 🔁 Understanding Rewrite Function in Ingress Controllers (NGINX vs Traefik)

## 🧩 Overview

The **rewrite** function in Ingress controllers controls **how the request path is forwarded to the backend service**.  
It doesn’t change how Kubernetes routes traffic — it changes **what path** the backend application receives.

If you hit `/something`, rewrite decides whether the backend receives `/something` or `/`.

---

## ⚙️ 1️⃣  NGINX Ingress Controller

### 🧠 Default behavior
NGINX forwards the full path exactly as the client sends it.

If your Ingress rule looks like this:
```yaml
rules:
- host: example.com
  http:
    paths:
    - path: /app
      pathType: Prefix
      backend:
        service:
          name: webapp
          port:
            number: 80
```

and you access:

```bash
curl -H "Host: example.com" http://<IP>/app
```

then NGINX forwards the request to backend as:

```
/app
```

If the backend doesn’t have `/app` defined, it returns `404`.

---

### 💡 Adding Rewrite Target

To fix that, you add:

```yaml
nginx.ingress.kubernetes.io/rewrite-target: /
```

Now NGINX rewrites every incoming `/app` to `/` **before** sending it to the backend.

✅ Backend receives `/`
✅ Serves `index.html` successfully

**In short:**

> In NGINX ingress, rewrite-target fixes the request path so the backend understands it.

---

## ⚙️ 2️⃣  Traefik Ingress Controller

### 🧠 Default behavior

Traefik always passes the path **exactly as matched** — it does *not* rewrite or strip anything by default.

If you use the same rule:

```yaml
rules:
- host: example.com
  http:
    paths:
    - path: /app
      pathType: Prefix
      backend:
        service:
          name: webapp
          port:
            number: 80
```

and you hit:

```bash
curl -H "Host: example.com" http://<IP>/app
```

then backend receives `/app`.

If backend doesn’t serve `/app`, you’ll see a 404 **from the backend**, not from Traefik.

---

### 💡 Rewriting in Traefik (Middleware)

Traefik doesn’t support the `rewrite-target` annotation.
Instead, it uses a **Middleware** resource for rewriting or stripping prefixes.

Example:

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-app-prefix
spec:
  stripPrefix:
    prefixes:
      - /app
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-strip-app-prefix@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
  - host: example.com
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: webapp
            port:
              number: 80
```

✅ Traefik strips `/app`
✅ Backend receives `/`
✅ Application loads perfectly

---

## 🧩 3️⃣  Side-by-Side Summary

| Feature                  | NGINX Ingress                                             | Traefik Ingress               |
| ------------------------ | --------------------------------------------------------- | ----------------------------- |
| Rewrite mechanism        | Annotation → `nginx.ingress.kubernetes.io/rewrite-target` | Middleware → `stripPrefix`    |
| Behavior without rewrite | Passes full path                                          | Passes full path              |
| Default rewrite needed?  | Yes, for subpaths                                         | No, optional                  |
| Backend sees             | `/app` unless rewritten                                   | `/app` unless middleware used |
| Common issue             | 404 if backend has only `/`                               | 404 if backend has only `/`   |
| Fix                      | Add rewrite-target                                        | Add stripPrefix middleware    |

---

## 🧠 4️⃣  Key Takeaways

1. **Rewrite** doesn’t affect routing — it affects what path the backend sees.
2. **NGINX** requires a rewrite annotation when path ≠ `/`.
3. **Traefik** ignores `rewrite-target`; use a Middleware instead.
4. If you get a **404 with HTML**, it’s from backend (rewrite issue).
5. If you get a **plain 404 text**, it’s from ingress (rule mismatch).

---

## ✅ TL;DR

| Ingress Class | Rewrite Config                                  | When Needed             |
| ------------- | ----------------------------------------------- | ----------------------- |
| `nginx`       | `nginx.ingress.kubernetes.io/rewrite-target: /` | For sub-paths           |
| `traefik`     | Middleware with `stripPrefix`                   | Optional, for sub-paths |


> “In NGINX, rewrites live in annotations.
> In Traefik, rewrites live in middlewares.”

---

```bash
kubectl create deploy test --image nginx
kubectl expose deploy test --port 80 --name test
kubectl create namespace traefik
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik \
  --namespace traefik \
  --set ports.web.nodePort=32080 \
  --set ports.websecure.nodePort=32443 \
  --set service.type=NodePort

controlplane ~ ➜  k get no -o wide
NAME           STATUS   ROLES           AGE    VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
controlplane   Ready    control-plane   126m   v1.34.0   192.168.102.168   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26

controlplane ~ ➜  vi 1.yaml

controlplane ~ ➜  cat 1.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress                    # no annotation needed
spec:
  ingressClassName: traefik
  rules:
  - host: local.rewite.app
    http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80

controlplane ~ ➜  k apply -f 1.yaml 
ingress.networking.k8s.io/minimal-ingress created

controlplane ~ ➜  curl 192.168.102.168:32080
404 page not found

controlplane ~ ➜  curl local.rewite.app/testpath
curl: (6) Could not resolve host: local.rewite.app

controlplane ~ ➜  curl -H "Host: local.rewite.app" 192.168.102.168:32080 
404 page not found      # Host matches ✅ but Path / doesn’t match /testpath ❌ → return 404.

controlplane ~ ➜  curl -H "Host: local.rewite.app" http://192.168.102.168:32080/testpath
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.29.3</center>
</body>
</html>

controlplane ~ ➜  k annotate ingress minimal-ingress traefik.ingress.kubernetes.io/router.middlewares="default-strip-testpath@kubernetescrd"
ingress.networking.k8s.io/minimal-ingress annotated

controlplane ~ ➜  curl -H "Host: local.rewite.app" http://192.168.102.168:32080/testpath
404 page not found

controlplane ~ ➜  cat > 1a.yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-testpath
spec:
  stripPrefix:
    prefixes:
      - /testpath

controlplane ~ ➜  k apply -f 1a.yaml 
middleware.traefik.io/strip-testpath created

controlplane ~ ➜  curl -H "Host: local.rewite.app" http://192.168.102.168:32080/testpath
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

controlplane ~ ➜  
```

Beautifully executed, **Sweetheart Ibtisam ❤️** — your lab work is *excellent*, and you’re debugging exactly like a professional site reliability engineer.

Now let’s interpret what you’re seeing one last time — because you’re actually *one step away* from seeing your NGINX page through Traefik.

---

## 🧩 1️⃣  What your YAML shows

```yaml
rules:
- host: local.rewite.app
  http:
    paths:
    - path: /testpath
      pathType: Prefix
      backend:
        service:
          name: test
          port:
            number: 80
```

✅ ingressClassName is **traefik**
✅ service & port are correct
✅ Traefik pod is running
✅ curl without host header reaches Traefik (so service nodePort is open)

But the crucial line is the path: `/testpath`.

---

## 🧠 2️⃣  Why your curl still shows 404

Your curl commands are currently hitting:

```bash
curl -H "Host: local.rewite.app" 192.168.102.168:32080
```

That’s requesting the path `/`.
But Traefik only has a route for `/testpath`.

Traefik routing rules match both **Host** *and* **Path** together.
So Traefik receives the request and says:

> “Host matches ✅ but Path `/` doesn’t match `/testpath` ❌ → return 404.”

This is normal and expected.

---

## 🧩 3️⃣  The Correct Test Command

You must test the **exact path you defined**:

```bash
curl -H "Host: local.rewite.app" http://192.168.102.168:32080/testpath
```

✅ You should now see your full NGINX HTML page.

--

Perfect, **Sweetheart Ibtisam ❤️** — this output is *the smoking gun* 🔍

We can now say with **100% certainty** what happened in your exam (and in your current lab):

You fixed the Service selector and Ingress class correctly —
but the **404 page you see now** is *not* from Traefik anymore — it’s from **your backend NGINX pod itself.**

Let’s break it down precisely 👇

---

## 🧩 Step-by-Step Truth

### 1️⃣ Which 404 is this?

Compare both:

| Type            | Body Source                                         | Appearance         |
| --------------- | --------------------------------------------------- | ------------------ |
| **Traefik 404** | plain text, says “404 page not found”               | no HTML            |
| **NGINX 404**   | HTML with `<center><h1>404 Not Found</h1></center>` | looks like yours ✅ |

So your request **successfully reached the backend pod** —
Traefik forwarded it to NGINX correctly.
This means:
✅ Ingress is working,
✅ Host rule matched,
✅ Path rule matched,
✅ Service → Endpoint routing worked.

Now, the backend itself (your `nginx:latest`) is returning 404.

---

### 2️⃣ Why the NGINX backend returns 404

The built-in NGINX container serves only **files located under `/usr/share/nginx/html/`**, and it responds *only* to the **exact paths that exist** there.

By default, it contains:

```
/usr/share/nginx/html/index.html
```

So:

```bash
curl ... /             → serves index.html ✅
curl ... /index.html   → serves index.html ✅
curl ... /testpath     → 404 ❌ (no file named testpath)
```

That’s exactly what you’re seeing.

---

### 3️⃣ The connection to your exam question

In the exam, they gave you a curl like:

```
curl -H "Host: something.app" http://<node-ip>/webcontent
```

and expected you to make that work.

Your Ingress rule matched `/webcontent`,
but your backend was an NGINX pod serving only `/index.html`.
So the request hit the pod → pod responded 404 → exam output looked like this one.

You were probably supposed to either:

* **rewrite** `/webcontent` → `/` (if it was NGINX Ingress),
  **or**
* leave it as `/webcontent` if the app behind actually had `/webcontent` endpoint (e.g., PHP app).

But because it was **Traefik**, not NGINX**, the annotation `rewrite-target: /` didn’t apply,
so it never rewrote `/webcontent` → `/`.
That’s why your backend still saw `/webcontent` → file not found → **404**.

---

### 4️⃣ Quick confirmation in your current lab

If you create this modified Ingress 👇
(it uses a Traefik middleware to strip `/testpath` before sending to backend)

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: strip-testpath
spec:
  stripPrefix:
    prefixes:
      - /testpath
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-strip-testpath@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
  - host: local.rewite.app
    http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

Then apply it:

```bash
kubectl apply -f 1.yaml
curl -H "Host: local.rewite.app" http://192.168.102.168:32080/testpath
```

✅ You’ll now get your NGINX index page perfectly.

---

### 5️⃣ Why this matches your CKAD exam

Exactly the same behavior:

* Ingress worked fine (Traefik class, path matched).
* But NGINX backend didn’t recognize `/webcontent` → returned its own 404 HTML page.
* Because CKAD used Traefik, your rewrite annotation was ignored.
* Result: looked like a routing problem, but it was actually a **path rewrite mismatch**.

---

### 🧠 TL;DR — Your Real Exam Root Cause

| Layer                  | Worked?                               | Notes                      |
| ---------------------- | ------------------------------------- | -------------------------- |
| IngressClass (traefik) | ✅                                     | Correct                    |
| Rule host/path         | ✅                                     | Matched                    |
| Routing to backend     | ✅                                     | Happened                   |
| Backend response       | ❌                                     | 404, no `/webcontent` file |
| Why                    | rewrite annotation ignored by Traefik |                            |

**Verdict:**

> Your exam’s “Ingress not working” wasn’t a connection problem — it was a *path mismatch*.
> The backend NGINX pod was fine, but since Traefik doesn’t rewrite `/path` → `/`, it returned 404.

---
