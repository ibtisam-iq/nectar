# 📝 ServiceAccount Tokens – Complete Notes

## 1. What is a ServiceAccount Token?

* A **JWT token** used by Pods (or external clients) to authenticate with the Kubernetes API.
* By default, if a Pod is linked to a ServiceAccount (SA), the token is mounted inside the Pod at:

  ```
  /var/run/secrets/kubernetes.io/serviceaccount/token
  ```
* Used for RBAC authorization checks when the Pod talks to the API server.

---

## 2. Old Behavior (< v1.24)

* **Each SA automatically got a Secret** of type `kubernetes.io/service-account-token`.
* That Secret contained:

  * `.data.token` → base64-encoded JWT
  * `.data.ca.crt` → cluster’s CA cert
  * `.data.namespace` → namespace name
* When a Pod used that SA, Kubernetes mounted this Secret into the Pod.

**How to extract token (old):**

```bash
k get secret <sa-secret> -n <ns> -o jsonpath='{.data.token}' | base64 -d
```

---

## 3. New Behavior (>= v1.24)

* **No automatic Secrets** are created for SAs anymore.
* Instead, Kubernetes uses **Projected ServiceAccount Tokens** (short-lived, auto-rotated).
* When a Pod uses an SA:

  * The kubelet requests a fresh JWT from the API server.
  * Token is mounted directly into the Pod filesystem (not from a Secret).
  * Token automatically refreshes before expiry.

**How to manually get a token (new):**

```bash
k create token <sa-name> -n <ns>
```

* This outputs the **raw decoded JWT** (no base64 step needed).

---

## 4. Mounting in Pods (What You See)

* Path is **same in old and new**:

  ```
  /var/run/secrets/kubernetes.io/serviceaccount/token
  ```
* The difference is **source of the token**:

  * **Old:** came from a long-lived Secret.
  * **New:** comes from kubelet as an ephemeral projected token.

---

## 5. `automountServiceAccountToken` Behavior

* Controls whether a token is mounted into a Pod.
* Can be set in:

  * ServiceAccount (`spec.automountServiceAccountToken`)
  * Pod spec (`spec.automountServiceAccountToken`)
* **Pod setting overrides SA setting.**

**Rules:**

* **SA false + Pod default (not set)** → No token.
* **SA false + Pod true** → Token mounted.
* **SA true (default) + Pod false** → No token.
* **SA true (default) + Pod default (not set)** → Token mounted.

👉 In short: **Pod spec wins.**

---

## 6. Comparison Table (Old vs New)

| Feature          | Old (<1.24)                            | New (>=1.24)                    |                             |
| ---------------- | -------------------------------------- | ------------------------------- | --------------------------- |
| Token storage    | Secret object auto-created             | No Secret, ephemeral projection |                             |
| Token format     | Base64 encoded in Secret `.data.token` | Raw JWT (already decoded)       |                             |
| How to get token | `kubectl get secret ...                | base64 -d`                      | `kubectl create token <sa>` |
| Token in Pod     | Mounted from Secret                    | Mounted directly from kubelet   |                             |
| Token lifetime   | Long-lived (until Secret deleted)      | Short-lived, auto-rotated       |                             |

---

## 7. Exam Quick Rules ⚡

* **If the question says "write decoded token"**:

  * Old cluster: `get secret ... | base64 -d`
  * New cluster: `kubectl create token <sa>` → already decoded
* **Secret ≠ token** → In old versions, the Secret *contained* the token. In new versions, there’s often no Secret at all.
* **Pod path unchanged**: Always `/var/run/secrets/kubernetes.io/serviceaccount/token`.

---
