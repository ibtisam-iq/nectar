# 🧩 ServiceAccount Tokens in Kubernetes

## 🌱 1. What Is a ServiceAccount?

A **ServiceAccount (SA)** is like a digital *identity card* for Pods —
when a Pod runs in the cluster, it can “show” this identity to the API Server to prove who it is.

* Human users authenticate via **kubectl + kubeconfig**
* Pods authenticate via **ServiceAccount tokens**

Think of it this way:

> “If a Pod is a gardener in a protected greenhouse, the ServiceAccount is his ID badge.”

You create one like this:

```bash
kubectl create serviceaccount my-sa -n my-namespace
```

You assign it to a Pod:

```yaml
spec:
  serviceAccountName: my-sa
```

If you don’t specify one, Kubernetes automatically assigns the **default** ServiceAccount of that namespace.

---

## ⚙️ 2. Token Evolution — Old vs New

### 🕰️ Earlier (Legacy Behavior – pre-v1.24)

* When you created a ServiceAccount, Kubernetes automatically generated a Secret of type `kubernetes.io/service-account-token`.
* This Secret contained:

  ```yaml
  data:
    token: <base64-encoded JWT>
    ca.crt: <base64>
    namespace: <base64>
  ```
* The token was **long-lived (non-expiring)**.
* It was automatically **mounted into Pods** at
  `/var/run/secrets/kubernetes.io/serviceaccount/token`.

This was simple but risky:

> “Every gardener’s badge was permanent — if lost or stolen, anyone could sneak into the greenhouse forever.”

---

### 🔐 Modern Behavior (v1.24 and later)

Kubernetes improved security:

* Auto-creation of SA token Secrets is **disabled by default**.
* Tokens mounted into Pods are now **short-lived**, **auto-rotating**, and **bound** to the Pod (via TokenRequest API).
* If you need a long-lived token, you create a special Secret manually or use `kubectl create token`.

So now:

> “Badges are day-passes that expire. Each gardener gets a new badge daily, reducing risk.”

---

## 🪄 3. Ways to Get a ServiceAccount Token

### 🔸 Method 1 — From a Secret (Legacy Style)

If a Secret already exists for your ServiceAccount:

```bash
kubectl -n <namespace> get secret
kubectl -n <namespace> describe sa <serviceaccount>
```

Identify the Secret (annotation shows SA name):

```bash
kubectl -n <namespace> get secret <secret-name> -o yaml
```

Extract and decode the token:

```bash
kubectl -n <namespace> get secret <secret-name> \
  -o jsonpath='{.data.token}' | base64 --decode
```

> **Remember:** Secrets’ `.data` fields are Base64-encoded.
> The decoded output will look like a JWT token starting with `eyJhbGci...`

**To write to file (exam style):**

```bash
kubectl -n neptune get secret <secret-name> \
  -o jsonpath='{.data.token}' | base64 --decode > /opt/course/5/token
```

---

### 🔸 Method 2 — Using `kubectl create token` (Modern Way)

Simpler and safer (works on v1.24+):

```bash
kubectl create token <serviceaccount> -n <namespace>
```

Optional flags:

```bash
--duration=1h
--audience=kubernetes.default.svc
```

Example:

```bash
kubectl create token neptune-sa-v2 -n neptune > /opt/course/5/token
```

This uses the **TokenRequest API**, producing a **short-lived token**.

---

### 🔸 Method 3 — Automatic Token Mount in Pod

If a Pod uses a ServiceAccount, Kubernetes automatically mounts a projected token at:

```
/var/run/secrets/kubernetes.io/serviceaccount/token
```

Check it inside the Pod:

```bash
kubectl exec -it <pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

To **disable** this auto-mount:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: restricted-sa
automountServiceAccountToken: false
```

or at Pod level:

```yaml
spec:
  automountServiceAccountToken: false
```

> “Turning off `automountServiceAccountToken` means:
> Don’t automatically give the gardener a badge unless I say so.”

---

## 🧠 4. What the Exam Might Ask

Here’s what CKAD/CKA/CKS might throw at you:

| Scenario                                                          | What to Do                                                                                                                   |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **“Get the token from the Secret and write it decoded to file.”** | `kubectl get secret … -o jsonpath='{.data.token}' \| base64 --decode > /opt/course/x/token`                                  |
| **“Create a token for a ServiceAccount.”**                        | `kubectl create token <sa> -n <ns> > /opt/course/x/token`                                                                    |
| **“No Secret exists for SA (v1.24+).”**                           | Either use `kubectl create token` or create a Secret of type `kubernetes.io/service-account-token` manually with annotation. |
| **“Disable token mounting in a Pod.”**                            | Use `automountServiceAccountToken: false`                                                                                    |
| **“Mount token manually.”**                                       | Use projected volume with `serviceAccountToken` projection.                                                                  |

---

## 🧾 5. Quick Reference

| Task                       | Command                                                                            |
| -------------------------- | ---------------------------------------------------------------------------------- |
| Create SA                  | `kubectl create sa my-sa -n ns`                                                    |
| Describe SA                | `kubectl -n ns describe sa my-sa`                                                  |
| Get SA token (new way)     | `kubectl create token my-sa -n ns`                                                 |
| Get SA token (from Secret) | `kubectl -n ns get secret <secret> -o jsonpath='{.data.token}' \| base64 --decode` |
| Disable automount          | Add `automountServiceAccountToken: false`                                          |
| Check token inside pod     | `kubectl exec -it <pod> -- cat /var/run/secrets/.../token`                         |

---

## 🌍 6. Visual Analogy

| Concept                      | Analogy                                                           |
| ---------------------------- | ----------------------------------------------------------------- |
| ServiceAccount               | Gardener’s ID badge                                               |
| Token (old)                  | Permanent badge – risky if stolen                                 |
| Token (new)                  | Day-pass badge – safer, expires                                   |
| automountServiceAccountToken | Whether to automatically hand out a badge to every gardener (Pod) |
| `kubectl create token`       | Requesting a new badge from security desk                         |
| Secret’s `.data.token`       | The badge stored in Base64 – must decode before using             |

---

## 🧭 7. Recommended Strategy (for You)

Since you’re building **SilverKube** and preparing for **CKA**:

1. Add both examples — `serviceaccount-legacy.yaml` and `serviceaccount-modern.yaml`.
2. In each, write rich comments explaining:

   * How the token is stored
   * How to retrieve and decode it
   * What’s deprecated and what’s recommended
3. Add this cheat sheet in your markdown for quick review before exam.
4. Run practice:

   ```bash
   kubectl create sa test-sa
   kubectl create token test-sa > token.txt
   cat token.txt | cut -d. -f2 | base64 --decode
   ```

   to inspect JWT claims.

---
