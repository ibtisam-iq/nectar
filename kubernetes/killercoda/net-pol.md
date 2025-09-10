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

create a NetworkPolicy .i.e. ckad-allow so that only pods with label criteria: allow can access the deployment on port 80 and apply it.

```bash
root@student-node ~ ➜  k get po --show-labels -n nginx-deployment 
NAME                            READY   STATUS    RESTARTS   AGE     LABELS
nginx-ckad11-5b864dcf9f-f9dvg   1/1     Running   0          3m33s   app=nginx-ckad,pod-template-hash=5b864dcf9f
nginx-ckad11-5b864dcf9f-v69f6   1/1     Running   0          3m33s   app=nginx-ckad,pod-template-hash=5b864dcf9f
test-pod                        1/1     Running   0          8m22s   criteria=allow

root@student-node ~ ➜  k apply -f 12.yaml 
deployment.apps/nginx-ckad11 configured
service/nginx-ckad11-service configured
networkpolicy.networking.k8s.io/ckad-allow created
```

Nice one 👍 this is again a **NetworkPolicy** that restricts access to your nginx Deployment.

Here’s the YAML for `ckad-allow`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ckad-allow
  namespace: nginx-deployment
spec:
  podSelector:
    matchLabels:
      app: nginx-ckad   # Selects nginx deployment pods
  policyTypes:
  - Ingress
  ingress:
  - from:
      - podSelector:
          matchLabels:
            criteria: allow   # Only allow pods with this label
    ports:
      - protocol: TCP
        port: 80             # Only allow on port 80
```

### 🔑 Explanation

* **`podSelector: app=nginx-ckad`** → this policy applies to your nginx deployment pods.
* **`ingress.from.podSelector`** → only pods with `criteria=allow` can reach nginx.
* **`ports: 80`** → limits allowed traffic to TCP port 80 only.
* Once this policy is active, all other traffic will be blocked by default.

---

We have created a Network Policy netpol-ckad13-svcn that allows traffic only to specific pods and it allows traffic only from pods with specific labels.

Your task is to edit the policy so that it allows traffic from pods with labels access = allowed.

Do not change the existing rules in the policy.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: netpol-ckad13-svcn
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: kk-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
           tier: server
# add the following in the manifest
    - podSelector:
        matchLabels:
           access: allowed
```
