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

✅ To pass **this specific question**, you need to:

1. Find the Secret for the SA:

   ```bash
   kubectl -n neptune get secret
   ```
2. Decode the token and write it:

   ```bash
   kubectl -n neptune get secret <secret-name> -o jsonpath='{.data.token}' | base64 -d > /opt/course/5/token
   ```

👉 In a **real CKA/CKAD exam on 1.29+**, you’d be right with `kubectl create token`.
👉 In **practice platforms**, follow exactly the task wording, even if it’s outdated — otherwise the grader marks it wrong.

---
