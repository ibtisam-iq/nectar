You are requested to create a network policy named deny-all-svcn that denies all incoming and outgoing traffic to ckad12-svcn namespace.

Perfect 👍 To **deny all traffic (ingress + egress)** in a namespace using a NetworkPolicy, you must create a "default deny all" policy.

Here’s the YAML for your case:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-svcn
  namespace: ckad12-svcn
spec:
  podSelector: {}   # applies to all pods in the namespace
  policyTypes:
  - Ingress
  - Egress
```

### 🔎 Explanation

* `namespace: ckad12-svcn` → applies to that namespace.
* `podSelector: {}` → selects **all pods** in that namespace.
* `policyTypes: [Ingress, Egress]` → means it will control both incoming and outgoing traffic.
* Since **no rules** are specified under `ingress:` or `egress:`, **everything is denied by default**.

---

A policy database-ckad-netpol to limit access to database pods only to backend pods.

```bash
root@student-node ~ ➜  k get po -n app-ckad backend-pod-svcn database-pod-svcn --show-labels 
NAME                READY   STATUS    RESTARTS   AGE   LABELS
backend-pod-svcn    1/1     Running   0          17m   app=backend
database-pod-svcn   1/1     Running   0          17m   app=database

root@student-node ~ ✖ k apply -f 10.yaml 
networkpolicy.networking.k8s.io/database-ckad-netpol created

root@student-node ~ ➜  
```

Perfect 👍 you want a **NetworkPolicy** named `database-ckad-netpol` that ensures only pods with label `app=backend` can talk to the database pod (`app=database`).

Here’s the YAML:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-ckad-netpol
  namespace: app-ckad
spec:
  podSelector:
    matchLabels:
      app: database   # Apply policy to database pods
  policyTypes:
  - Ingress
  ingress:
  - from:
      - podSelector:
          matchLabels:
            app: backend   # Only backend pods allowed
```

### 🔑 Explanation

* `podSelector: app=database` → policy applies to the `database-pod-svcn`.
* `policyTypes: [Ingress]` → we’re controlling incoming traffic.
* `ingress.from.podSelector: app=backend` → only pods with label `app=backend` can access.
* All other pods in the namespace will be **denied** automatically because once a policy selects a pod, **deny-all is the default** unless explicitly allowed.

---
