# Kubernetes Ingress Access & Testing

Ingress provides external access to Services within a Kubernetes cluster.
Below are the different ways to test and verify ingress rules after creating them.

---

## 1. Ingress without `host`

If the Ingress resource does **not** define a `host`:

```bash
curl http://<node-IP>:<nodePort>/<path>
```

* `<node-IP>` can be any cluster node (including controlplane).
* `<nodePort>` is the NodePort exposed by the ingress controller Service.

---

## 2. Ingress with `host`

If the Ingress resource specifies a `host` rule:

### ✅ Most reliable (works always)

```bash
curl -H "Host: <host-from-ingress>" http://<node-IP>:<nodePort>/<path>
```

* Explicitly sets the HTTP `Host` header, ensuring the request matches the Ingress rule.

### ➕ Optional (requires DNS or `/etc/hosts`)

```bash
curl http://<host-from-ingress>:<nodePort>/<path>
curl http://<host-from-ingress>/<path>
```

* Works only if the hostname resolves correctly (via DNS or `/etc/hosts`).

---

## 3. Ingress via LoadBalancer

If the ingress controller Service type is `LoadBalancer`:

```bash
curl http://<loadbalancer-IP>/<path>
```

* `<loadbalancer-IP>` is provisioned by your cloud provider or load balancer integration.

---

## 4. Debugging Ingress

Common checks when ingress is not working as expected:

* Verify ingress resource:

  ```bash
  kubectl get ingress
  kubectl describe ingress <name>
  ```
* Verify ingress controller Service (to find NodePort or LB IP):

  ```bash
  kubectl get svc -n ingress-nginx
  ```
* Check controller logs:

  ```bash
  kubectl logs -n ingress-nginx <controller-pod-name>
  ```

---

## ✅ Notes

* Always inspect the `host:` and `path:` fields in your Ingress manifest.
* Use `-H "Host: ..."` if you are unsure about DNS resolution.
* For production, Ingress is usually combined with DNS records pointing to the LoadBalancer or external IP.
