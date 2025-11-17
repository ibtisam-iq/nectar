# CKAD NetworkPolicy – Xander → api-1/api-2 (Step‑by‑Step Playbook & Notes)

These notes capture the *full reasoning flow* we used to solve the lab where **pod `xander`** must be able to reach **`api-1`** and **`api-2`** in namespace `giles`, *without creating or modifying NetworkPolicies* — only by labeling pods.

---

## 1) Question (decoded)

> "In namespace `giles`, make pod **xander** able to **reach** **api-1** and **api-2** (and nothing else), without changing/adding/removing any NetworkPolicy. Only make changes to the **xander** pod."

**Key interpretation:** "reach" = **xander → api-1 / api-2** (outbound from xander). Enforcement is typically via **Ingress** policies attached to the **receivers** (api-1, api-2).

---

## 2) Cluster inventory (from the lab)

**Pods & labels**

```
api-1  : app=api-1
api-2  : app=api-2
api-3  : app=api-3
xander : (no labels)
```

**NetworkPolicies**

```
allow-api-1  : podSelector app=api-1
  ingress.from: podSelector api-1-access=true
  ports: 80/TCP

allow-api-2  : podSelector app=api-2
  ingress.from: podSelector api-2-access=true
  ports: 80/TCP

allow-all    : podSelector allow-all=true   (irrelevant here)

default-deny : podSelector {} + policyTypes [Ingress,Egress]
```

---

## 3) Explain each NetworkPolicy (line by line)

### `allow-api-1`

* **`podSelector: app=api-1`** → This policy **protects** *api-1* pods.
* **`ingress.from: podSelector api-1-access=true`** → Only pods with label `api-1-access=true` are allowed to **send traffic into** api-1.
* **Port 80/TCP** → Only HTTP/80 is allowed.

### `allow-api-2`

* **`podSelector: app=api-2`** → This policy **protects** *api-2* pods.
* **`ingress.from: podSelector api-2-access=true`** → Only pods with label `api-2-access=true` are allowed to **send traffic into** api-2.
* **Port 80/TCP** → Only HTTP/80 is allowed.

### `default-deny`

* **`podSelector: {}` with policyTypes `[Ingress,Egress]`** → Deny-all baseline for the namespace. Nothing talks unless explicitly allowed.

> **Crucial rule:** The **protected pods** are always found in the policy's **`spec.podSelector`**.
> The **senders allowed** are described under **`ingress.from`**; you put those labels on the **sender**.

---

## 4) Universal decision framework (apply to any NetPol question)

1. **Find the protected pod(s):**
   Look at **`spec.podSelector`**. Those pods are the *receivers* guarded by this policy.
2. **Map the direction:**

   * **Ingress → from** = "who can knock on my door" (senders).
   * **Egress → to** = "which rooms I can visit" (receivers of my outbound).
3. **Read the task sentence:**
   Identify which pods must **send** and which must **receive**.
4. **Apply labels to peers, not the protected pod:**

   * For **`ingress.from`** rules → label the **senders** with the labels shown under `from`.
   * For **`egress.to`** rules → label the **destinations** with the labels shown under `to`.
5. **Do not modify policies** (per task); only align labels.

---

## 5) Apply the framework to this question

* The question says: **xander must reach api-1 and api-2** → xander = **sender**, api-1/api-2 = **receivers**.
* The policies that **protect** the receivers are:

  * `allow-api-1` with **`from: api-1-access=true`**
  * `allow-api-2` with **`from: api-2-access=true`**
* Therefore, make the **sender (xander)** match both allowed-sender label sets.

### Commands

```bash
kubectl label pod xander -n giles api-1-access=true --overwrite=true
kubectl label pod xander -n giles api-2-access=true --overwrite=true
```

---

## 6) Verification (optional but recommended)

```bash
# confirm labels
kubectl get pods -n giles --show-labels

# functional checks (if curl/netcat available in xander)
kubectl exec -n giles xander -- curl -sS http://api-1:80   # should succeed
kubectl exec -n giles xander -- curl -sS http://api-2:80   # should succeed
kubectl exec -n giles xander -- curl -sS http://api-3:80   # should FAIL (default-deny)
```

---

## 7) Why this satisfies "only reach api-1 & api-2"

* Only **xander** has the allow labels; no other pods do.
* `api-1` and `api-2` accept traffic **only from** pods with their respective access labels.
* `api-3` has **no** allow policy for xander → blocked by `default-deny`.

---

## 8) Common pitfalls (exam traps)

* **Mistaking the protected pod:** Always take it from **`podSelector`**, *not* from the sentence subject.
* **Labeling the wrong side:** `from` labels go on **senders**; `to` labels go on **destinations**.
* **Forgetting ports:** If the policy restricts a specific port, your probe must hit that port.
* **Assuming bi‑direction:** Ingress allow does **not** imply egress allow (and vice versa).

---

## 9) Fast checklist (60‑second solve)

1. `kubectl get netpol -n <ns> -o yaml` → locate `podSelector` for the target receivers.
2. Read `ingress.from` / `egress.to` → extract required labels.
3. Decide who is sender vs receiver per task wording.
4. `kubectl label pod <name> key=value -n <ns> (--overwrite)` on the correct pods.
5. (Optional) verify with `--show-labels` and a quick curl.

---

## 10) Mini Q&A (to reinforce)

* **Q:** Task says "Pod A should reach Pod B" but policy only shows `ingress.from` on B. Who do I label?
  **A:** Label **A** (sender) with the label shown under B's `from`.
* **Q:** Task says "Pod A should send **and receive** traffic to/from Pod B" and both `from` & `to` use the **same** label. What do I do?
  **A:** Put that **same label on both pods** (A & B) so the policy's bidirectional rules match.
* **Q:** How do I know the *protected* pod?
  **A:** Always by **`spec.podSelector`** of the policy.

---

### Final one‑liner

> **PodSelector = protected pods.**
> **`from` labels → senders.**
> **`to` labels → destinations.**
> **Only change labels; don’t touch policies (unless the task says so).**
