# 🧭 CKAD NetworkPolicy Exam Strategy & Labeling Guide

> **Goal:** Identify which pod is protected, which pods send traffic, which pods receive traffic — and apply correct labels based on the NetworkPolicy YAML.

---

## 🩵 Step 1 – Read the Question Carefully

* The **first pod name** in the question = your **protected pod**.
* That’s the one the NetworkPolicy applies to (the “room with the door”).

**Example**

> Pod `backend` should only receive traffic from `frontend` and send traffic to `database`.

✅ **Protected Pod:** `backend`
✅ It receives (Ingress) from `frontend`
✅ It sends (Egress) to `database`

---

## 🩵 Step 2 – Find the Correct NetworkPolicy

```bash
kubectl get netpol -n <namespace>
kubectl describe netpol <name> -n <namespace>
```

Look for:

```yaml
spec:
  podSelector:
    matchLabels:
      key=value
```

This shows **which pod the policy applies to.**

If that pod doesn’t already have the label → add it:

```bash
kubectl label pod <protected-pod> key=value -n <namespace>
```

---

## 🩵 Step 3 – Understand the Policy Sections

| Section        | Meaning                | Traffic Direction |
| -------------- | ---------------------- | ----------------- |
| `podSelector`  | The protected pod      | —                 |
| `ingress.from` | Who can talk **to** me | Incoming          |
| `egress.to`    | Who I can talk **to**  | Outgoing          |

---

## 🩵 Step 4 – Decide Labels Using Question Context

| Question phrase                  | Direction | Apply label from             | To which pod           |
| -------------------------------- | --------- | ---------------------------- | ---------------------- |
| “should receive traffic from …”  | Ingress   | `ingress.from`               | Sender pod(s)          |
| “should send traffic to …”       | Egress    | `egress.to`                  | Receiver pod(s)        |
| “should communicate only with …” | Both      | `ingress.from` + `egress.to` | Both sender + receiver |

---

## 🩵 Step 5 – Label Pods Accordingly

Example policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
```

**Labeling Commands:**

```bash
kubectl label pod frontend tier=frontend -n ckad-netpol
kubectl label pod backend tier=backend -n ckad-netpol
kubectl label pod database tier=database -n ckad-netpol
```

✅ backend = protected
✅ frontend = sender (`from`)
✅ database = receiver (`to`)

---

## 🩵 Step 6 – Verify Labels and Policies

```bash
kubectl get pods -n ckad-netpol --show-labels
kubectl describe netpol backend-policy -n ckad-netpol
```

(Optional)

```bash
kubectl exec -it frontend -- curl backend:80
```

---

## 🩵 Step 7 – Default-Deny Awareness

If this exists:

```yaml
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

Then all traffic is denied by default — only explicitly allowed NetworkPolicies will work.

---

## 🩵 Step 8 – Mental Model

```
frontend  --->  backend  --->  database
   |           |              |
  from      podSelector        to
(sender)   (protected pod)  (receiver)
```

✅ “from” = sender → ingress
✅ “to” = receiver → egress

---

## 🩵 Step 9 – Exam Shortcut

> 🧩 Who the question starts with → **protected pod**
> 🧩 Who it receives from → **ingress.from** (sender)
> 🧩 Who it sends to → **egress.to** (receiver)

---

## 🩵 Step 10 – Quick Command Template

```bash
# Identify all policies in namespace
kubectl get netpol -n <ns>

# View the right one
kubectl describe netpol <name> -n <ns>

# Label pods
kubectl label pod <protected> <key=value> -n <ns>
kubectl label pod <sender> <key=value> -n <ns>
kubectl label pod <receiver> <key=value> -n <ns>

# Confirm
kubectl get pods -n <ns> --show-labels
```

---

## 🪄 Memory Tip

🧠 Think in human language:

* “I am the protected room.” → `podSelector`
* “These people can knock on my door.” → `ingress.from`
* “These are the rooms I’m allowed to visit.” → `egress.to`
