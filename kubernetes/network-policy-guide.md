# 🗭️ Kubernetes NetworkPolicy: Full Guide

## 📌 What is NetworkPolicy?

`NetworkPolicy` is a **Kubernetes object** that controls **network traffic** between **pods**, and between **pods and other network endpoints**. It acts like a **firewall** for pod-to-pod communication.

> 🧠 Think of it as security guards controlling who can enter or leave a building (pod). Without it, anyone can come and go freely.

---

## ❌ Default Behavior

By **default**, if no `NetworkPolicy` is defined:
- All pods can **talk to all other pods**.
- Any external IP can **reach any pod**.

But once a `NetworkPolicy` is applied to a pod:
- The pod becomes **isolated**.
- Only allowed traffic defined by the policy is permitted.

---

## 📀 NetworkPolicy Structure

Here’s a **full example** with all major fields and detailed comments.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-access
  namespace: bankapp  # 🔹 The namespace where this policy is applied

spec:
  podSelector:
    matchLabels:
      role: db  # 🌟 Target only pods with label 'role=db'

  policyTypes:
    - Ingress   # ⬅️ Controls incoming traffic to the selected pods
    - Egress    # ➡️ Controls outgoing traffic from the selected pods

  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: api  # ✅ Only allow pods with label 'role=api' to access
        - namespaceSelector:
            matchLabels:
              team: frontend  # ✅ Allow any pod from namespace with label team=frontend
      ports:
        - protocol: TCP
          port: 5432  # ✅ Allow access only on PostgreSQL port (5432)

  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/24  # ✅ Allow outgoing traffic to internal network
            except:
              - 10.0.0.5/32    # ❌ Block this specific IP
      ports:
        - protocol: TCP
          port: 53             # ✅ Allow DNS resolution (TCP DNS)
```

---

## 🔍 Field-by-Field Breakdown

| Field | Description |
|-------|-------------|
| `podSelector` | Defines which pods this policy applies to. |
| `policyTypes` | Can be `Ingress`, `Egress`, or both. |
| `ingress` | Controls which sources can send traffic *to* the selected pods. |
| `egress` | Controls which destinations selected pods can send traffic *to*. |
| `namespaceSelector` | Controls access based on namespace labels. |
| `ipBlock` | Allows you to whitelist or blacklist IP ranges. |
| `ports` | Limits communication to specific ports and protocols. |

---

## 🎯 Real World Case Study

**Use Case: BankApp Security**

Your banking backend (`role=db`) should:
- Only be accessible by `role=api` pods.
- Not communicate to any IP outside your internal network except DNS.

You apply this policy:
- API pods can talk to DB pods.
- DB pods can only go out to 10.0.0.0/24, but not 10.0.0.5.
- No one else can talk to DB pods.

---

## 📌 Additional Examples

### Example 1: Allow traffic only from same namespace
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
spec:
  podSelector: {}
  ingress:
    - from:
        - podSelector: {}
```

### Example 2: Deny all ingress traffic (isolate pod)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
    - Ingress
  ingress: []  # Deny all incoming
```

### Example 3: Allow egress only to specific DNS IP
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-dns
spec:
  podSelector:
    matchLabels:
      app: webapp
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 8.8.8.8/32  # Google DNS
      ports:
        - protocol: UDP
          port: 53
```

---

## 📂 Create YAML Imperatively?

No built-in `kubectl create networkpolicy` command. You must:

```bash
kubectl create -f network-policy.yaml
```

---

## 📋 Related Resources

- [Kubernetes Official Docs: NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [CNI Plugins and Policy Support](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)

---


