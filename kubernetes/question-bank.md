# 🎯 CKA Practice Questions: Pods, Services & Ingress

Each question mimics real CKA exam scenarios. If you want, I can also verify your YAML or solution attempts.

---

## 📦 PODS

---

### ✅ Q1: Basic Pod Creation

> Create a pod named `web-pod` in the `default` namespace using the image `nginx:alpine`. Expose port 80 in the pod.

✅ Bonus: Ensure it's running and accessible using `kubectl exec`.

---

### ✅ Q2: Pod with Commands

> Create a pod named `counter-pod` that uses the `busybox` image and runs this command on start:

```bash
while true; do echo "CKA Ready"; sleep 5; done
```

✅ Verify logs show `CKA Ready`.

---

### ✅ Q3: Pod in Custom Namespace

> Create a new namespace `ckanamespace`, then deploy a pod named `mypod` in it with image `httpd`.

---

## 🌐 SERVICES

---

### ✅ Q4: Expose a Pod with ClusterIP

> Use `kubectl run` to create a pod `nginx-pod` using image `nginx`, then expose it on port 80 using a **ClusterIP** service named `nginx-service`.

✅ Verify the service is reachable from inside a test pod.

---

### ✅ Q5: Create a NodePort Service

> You already have a pod `amor` in namespace `amor`. Create a **NodePort** service `amor-access` exposing it on target port 8081 and node port 30001.

✅ Confirm external access using `curl` from outside the cluster.

---

### ✅ Q6: Service with Custom Labels

> Deploy a pod with:

```yaml
labels:
  tier: backend
  env: staging
```

Then, create a service `backend-svc` that only targets this pod using the appropriate label selectors.

---

## 🚪 INGRESS

---

### ✅ Q7: Simple Ingress Rule

> You already have a deployment `amor` with service `amor` in namespace `amor`. Create an Ingress resource:

* Host: `demo.ckatest.com`
* Path: `/amor`
* Service: `amor`
* Port: `80`

✅ Add `demo.ckatest.com` to your `/etc/hosts` pointing to the node IP if testing from local laptop.

---

### ✅ Q8: Multi-path Ingress

> Create 2 deployments and services in namespace `webapp`:

* `frontend`: image `nginx`
* `backend`: image `httpd`

Then create an Ingress:

* `/frontend` → service `frontend`, port 80
* `/backend` → service `backend`, port 80

✅ Test using curl with path-based routing.

---

### ✅ Q9: Ingress with TLS (Advanced)

> You have cert-manager and an IngressController installed. Create a secret named `tls-secret` in namespace `default` containing TLS cert+key. Then:

* Create an Ingress for host `secure.ckatest.com`
* Attach the TLS secret
* Route `/` path to a service called `secure-svc` on port 443

✅ Test with:

```bash
curl https://secure.ckatest.com --resolve secure.ckatest.com:<port>:<node-ip> --insecure
```