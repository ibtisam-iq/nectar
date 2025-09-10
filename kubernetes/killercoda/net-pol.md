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
