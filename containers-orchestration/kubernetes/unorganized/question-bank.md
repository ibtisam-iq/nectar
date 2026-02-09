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

---

### ✅ **Pods – Hands-on Questions**

1. Create a pod named `nginx-pod` using the `nginx` image.
2. Create a pod that runs a `busybox` container and sleeps for 3600 seconds.
3. Create a pod with two containers: `nginx` and `busybox` (running `sleep 3600`).
4. Create a pod with a specific label `app=web`, and verify it using `kubectl get pods --show-labels`.
5. Create a pod with a volume mounted at `/data` using `emptyDir`.
6. Run a pod with environment variables set (e.g., `ENV=prod`, `DEBUG=true`).
7. Create a pod that uses a config map as environment variables.
8. Create a pod with a command override that runs `echo Hello Kubernetes && sleep 3600`.
9. Create a pod with a liveness probe that checks `/health` on port 80 every 5 seconds.
10. Create a pod with a readiness probe using `exec` to check file existence.
11. Create a pod and limit its CPU to 500m and memory to 128Mi.
12. Create a pod that mounts a secret to `/etc/secret-data`.

---

### ✅ **Services – Hands-on Questions**

13. Create a service of type ClusterIP that exposes `nginx-pod` on port 80.
14. Create a service of type NodePort for a `httpd` deployment.
15. Create a headless service for a StatefulSet.
16. Create a service with `app=backend` selector that points to port 8080 on pods.
17. Create a service with multiple ports exposed (e.g., 80 and 443).
18. Expose a deployment as a ClusterIP service named `web-service`.
19. Expose a pod directly using a service (without a deployment).
20. Create an ExternalName service pointing to `my.external.com`.
21. Verify service endpoints and understand why they may be empty.
22. Create a service using YAML with explicit `targetPort`, `port`, and `nodePort`.

---

### ✅ **Ingress – Hands-on Questions**

23. Deploy ingress-nginx controller using the official YAML.
24. Create an Ingress resource routing:

    * `/frontend` → service `frontend:80`
    * `/backend` → service `backend:80`
25. Create an Ingress with host `myapp.com` pointing `/` to service `web`.
26. Create an Ingress resource with TLS using a Kubernetes Secret.
27. Use pathType: `Prefix` and `Exact` in two different rules and explain the difference.
28. Configure multiple hosts in a single Ingress: `api.domain.com`, `admin.domain.com`.
29. Debug an Ingress showing 404 — how to identify whether the issue is with rules, service, or ingress controller.
30. Use annotations to enable HTTPS redirect in Ingress.
31. Add custom headers in an Ingress using annotations.
32. Configure Ingress to use a default backend.
