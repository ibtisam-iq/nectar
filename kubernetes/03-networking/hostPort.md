# 🧩 Kubernetes `hostPort` — Full Guide

## 📘 What is `hostPort`?

In Kubernetes, the `hostPort` field in a Pod’s container specification allows a container port to be **exposed directly on the IP address of the Node** (host machine) where the Pod is running.

This means:
- Traffic sent to the Node’s IP at `hostPort` is routed directly to the container’s `containerPort`.
- It enables **host-level access** without requiring a Kubernetes `Service` or `kubectl port-forward`.

---

## ⚙️ Basic YAML Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-hostport
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80      # Port inside the container
      hostPort: 8080         # Port on the Node's IP
```

### 🔎 Explanation

| Field           | Purpose                                                |
| --------------- | ------------------------------------------------------ |
| `containerPort` | Port on which the application listens inside container |
| `hostPort`      | Port on the host (Node IP) exposed to outside traffic  |

After this deployment, the app can be accessed at:

```
http://<node-ip>:8080
```

---

## 🧠 Real-World Analogy

Imagine a house (Node) running a TV (Container) on HDMI 1 (port 80).
`hostPort` is like routing that HDMI signal directly to an external display input on the building (Node’s wall jack), so others can plug in and see the screen externally at wall port 8080.

---

## 🧭 When to Use `hostPort`

✅ Use `hostPort` when:

* You need to expose containers directly on the host (Node) without a LoadBalancer or Ingress.
* You're running **Node-local agents** like:

  * Prometheus Node Exporter
  * Logging daemons
  * VPN services
* You're in a **bare-metal environment** with no cloud-native LoadBalancer.

---

## 🚫 When NOT to Use `hostPort`

Avoid `hostPort` when:

* You can use `kubectl port-forward` for temporary access.
* You're already exposing traffic through a `Service` or `Ingress`.
* You want high pod scheduling flexibility.
* You're managing a large cluster and want to avoid port conflicts.

---

## ⚠️ Important Considerations

### ❗ Port Conflict

Two Pods on the **same Node** **cannot** use the same `hostPort`. Kubernetes will not schedule a Pod if:

* The `hostPort` is already in use by another Pod on the same Node.

### ❗ Node Affinity Implied

Pods using `hostPort` are bound to:

* Nodes where that port is available
* Therefore, `hostPort` indirectly creates a **node affinity constraint**

### ❗ Security

* Traffic to `hostPort` is **not filtered by Kubernetes RBAC**
* It's directly exposed on the Node's IP → treat it like opening a firewall port

---

## 🔁 Comparison with Other Port Types

| Feature             | containerPort | hostPort    | NodePort        | targetPort      | port (Service)               |
| ------------------- | ------------- | ----------- | --------------- | --------------- | ---------------------------- |
| Scope               | Inside Pod    | Node (host) | Node (external) | Pod (container) | Service cluster IP           |
| Needed for app      | ✅ Required    | ❌ Optional  | ❌ Optional      | ✅ Required      | ✅ Required                   |
| Exposes to Node IP  | ❌ No          | ✅ Yes       | ✅ Yes           | ❌ No            | ❌ No                         |
| Exposes to outside  | ❌ No          | ✅ Yes       | ✅ Yes           | ❌ No            | Via ClusterIP / LoadBalancer |
| Flexible Scheduling | ✅ Yes         | ❌ Limited   | ✅ Yes           | ✅ Yes           | ✅ Yes                        |

---

## 🖼️ Traffic Flow Diagram (Described)

### Scenario: `hostPort: 8080` + `containerPort: 80`

```
[Client Browser] 
     |
     v
[Node IP:8080] -------------------> [hostPort mapping] 
                                      |
                                      v
                               [ContainerPort:80]
                               [NGINX running here]
```

---

## 🧪 Quick Testing

1. Deploy the Pod using `kubectl apply -f hostport.yaml`
2. Get the Node IP:

   ```bash
   kubectl get nodes -o wide
   ```
3. Access the app:

   ```bash
   curl http://<node-ip>:8080
   ```

---

## 📦 Advanced: Multi-Container Pod with `hostPort`

Only one container per Pod can bind to a `hostPort` on the Node. If two containers in the same Pod declare the same `hostPort`, the Pod will fail to start.

---

## 🧼 Cleanup

To remove the Pod and free up the `hostPort`:

```bash
kubectl delete pod nginx-hostport
```

---

## 📚 Summary

* `hostPort` maps a container port to the Node’s IP directly.
* Useful for system agents, bare-metal clusters, custom proxies.
* Avoid in large clusters due to scheduling and port collision.
* Prefer `Services`, `Ingress`, or `NodePort` for scalable app exposure.
