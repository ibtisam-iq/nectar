### 📌 ServiceAccount Token Mounting Rules

* **Default behavior**

  * `automountServiceAccountToken` is **true** by default (even if not written).
  * So any Pod using that SA automatically mounts a token under `/var/run/secrets/kubernetes.io/serviceaccount/`.

### Case 1: `automountServiceAccountToken: false` in **ServiceAccount YAML**

* All Pods using this SA will **NOT get a token mounted**,
  **unless** the Pod **overrides** it.

### Case 2: Pod spec also has `automountServiceAccountToken`

* **Pod spec overrides SA spec.**

  * Pod = `true` → token mounted, even if SA = `false`.
  * Pod = `false` → no token, even if SA = `true`.

### 🔑 Quick Effects

* **SA false + Pod default (not set)** → No token.
* **SA false + Pod true** → Token mounted.
* **SA true (default) + Pod false** → No token.
* **SA true (default) + Pod default (not set)** → Token mounted.

👉 In short: **Pod spec wins.**

```bash
controlplane:~$ k get sa secure-sa -o yaml
apiVersion: v1
automountServiceAccountToken: false                                  # key field, added manually.
kind: ServiceAccount
metadata:
  creationTimestamp: "2025-08-24T10:45:17Z"
  name: secure-sa
  namespace: default
  resourceVersion: "8700"
  uid: a9543735-8bff-4999-b509-492dcb306e57


controlplane:~$ k get po secure-pod -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  containers:
  - image: nginx
    name: secure-pod
  serviceAccount: secure-sa
  serviceAccountName: secure-sa              # The key automountServiceAccountToken: wasn't mentioned in the pod manifest.

# Verify that the service account token is NOT mounted to the pod  
controlplane:~$ kubectl exec secure-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
cat: /var/run/secrets/kubernetes.io/serviceaccount/token: No such file or directory
command terminated with exit code 1
controlplane:~$

---

controlplane ~ ➜  vi 1.yaml
 
controlplane ~ ➜  k apply -f 1.yaml 
pod/sa-token-not-automounted created
pod/sa-token-automounted created

controlplane ~ ➜  k exec sa-token-automounted -- ls /var/run/secrets/kubernetes.io/serviceaccount/token
/var/run/secrets/kubernetes.io/serviceaccount/token

controlplane ~ ➜  k exec sa-token-not-automounted -- ls /var/run/secrets/kubernetes.io/serviceaccount/token
ls: cannot access '/var/run/secrets/kubernetes.io/serviceaccount/token': No such file or directory
command terminated with exit code 2

controlplane ~ ➜  cat 1.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: sa-token-not-automounted
spec:
  serviceAccountName: secure-sa
  automountServiceAccountToken: false
  containers:
  - image: nginx
    name: without
---
apiVersion: v1
kind: Pod
metadata:
  name: sa-token-automounted
spec:
  serviceAccountName: secure-sa
  automountServiceAccountToken: true
  containers:
  - image: nginx
    name: with

controlplane ~ ➜
```


---

Team **Neptune** has its own ServiceAccount named `neptune-sa-v2` in Namespace `neptune`. 
A coworker needs the **token from the Secret** that belongs to that ServiceAccount. Write the **base64 decoded** token to file `/opt/course/5/token on ckad7326`.

```bash
controlplane ~ ➜  k get sa -n neptune 
NAME            SECRETS   AGE
default         0         24m
neptune-sa-v2   0         20m

controlplane ~ ➜  k get secrets -n neptune    # No automatic Secret is created anymore for ServiceAccounts.
No resources found in neptune namespace.

controlplane ~ ➜  k create token neptune-sa-v2 -n neptune
ey..........

controlplane ~ ➜  k create token neptune-sa-v2 -n neptune > /opt/course/5/token # This gives you the raw JWT (already decoded) directly.

controlplane ~ ➜  k get secrets -n neptune
No resources found in neptune namespace.

controlplane ~ ➜
```

Excellent observation 👏 — you’re absolutely right to pause here.
Let’s unpack what’s really happening step by step 👇

### 🧠 What You Know (and It’s True)

Starting from **Kubernetes v1.24**,
when you create a **ServiceAccount (SA)**,
➡️ **no Secret is automatically created** for it anymore.
Instead, pods using that SA get **ephemeral tokens** mounted as **projected volumes**.

So your confusion — “how can there be a token Secret if no Secret is created?” — is completely valid.

### 💡 What the Exam Question Means

In the **CKAD/CKA exam**, the environment **might use an older cluster version (≤ v1.23)**
**or** the cluster is **manually configured to still create token Secrets** (for backward compatibility).

That’s why the question says:

> “get the token from the Secret that belongs to that ServiceAccount.”

So — in that cluster, a Secret **does exist** for that SA.

### 🧩 Steps to Solve It

1. **Find the Secret linked to the ServiceAccount:**

   ```bash
   kubectl get sa neptune-sa-v2 -n neptune -o yaml
   ```

   Look under:

   ```yaml
   secrets:
     - name: neptune-sa-v2-token-xxxxx
   ```

2. **Get the token value (base64):**

   ```bash
   kubectl get secret neptune-sa-v2-token-xxxxx -n neptune -o jsonpath='{.data.token}'
   ```

3. **Decode it and save to the file:**

   ```bash
   kubectl get secret neptune-sa-v2-token-xxxxx -n neptune -o jsonpath='{.data.token}' | base64 -d > /opt/course/5/token
   ```

4. **Verify (optional):**

   ```bash
   cat /opt/course/5/token
   ```

   You should see a **plain JWT** (three dot-separated sections like `xxxxx.yyyyy.zzzzz`).

### ✅ **Rule (refined in one line):**

> In clusters using legacy ServiceAccount Secrets, get the token from the SA’s Secret (`.data.token`), decode it from base64, and save it as a plain JWT — but in newer clusters, tokens are ephemeral and must be created via `kubectl create token <sa>`.

--

Perfect — you just confirmed your intuition 💯

```bash
controlplane ~ ➜  k get secrets -n neptune
No resources found in neptune namespace.
```

That means your cluster is running a **modern Kubernetes version (v1.24+)**,
where **ServiceAccounts no longer auto-create Secret tokens.**

Let’s go through exactly what this means **and what you should do in the exam context.** 👇

### 🧠 Why No Secret Exists

Since Kubernetes **v1.24**,
ServiceAccount token Secrets are **not created automatically**.
Instead, tokens are:

* **ephemeral** (short-lived),
* **auto-mounted** into pods using that SA,
* and can be **manually created on demand** with `kubectl create token`.

### ✅ What To Do in This Scenario (Exam-Compatible)

Because the exam question asks for

> “the token from the Secret that belongs to that ServiceAccount,”

but **no Secret exists**, the *correct modern approach* is to **manually create a token**.

Run this command:

```bash
kubectl create token neptune-sa-v2 -n neptune > /opt/course/5/token
```

This will output a **plain JWT** (already decoded) and write it to the required path.

### 🧩 Verify

You can check:

```bash
cat /opt/course/5/token
```

You should see something like:

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IjY1Njg4NjM...<snip>...J9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiw...
```

### ✅ **Rule (refined in one line):**

> In Kubernetes v1.24+, ServiceAccounts no longer have Secrets — use `kubectl create token <sa> -n <ns>` to generate a plain JWT token instead of searching for a Secret.

---

