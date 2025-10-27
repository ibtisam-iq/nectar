# In-Cluster API Access in Kubernetes

## 📘 Introduction

In Kubernetes, almost everything — Pods, Secrets, Deployments, Services — is managed through the **Kubernetes API Server**.
When we interact with the cluster, we are always communicating with this API — either **from outside** (via `kubectl`) or **from inside** (via Pods or internal processes).

This document explains how **in-cluster API access** works, how **ServiceAccounts** make it possible, and why even the *default ServiceAccount* exists inside every Pod.

---

## 🧩 1. Two Ways to Access the Kubernetes API

Kubernetes can be accessed in **two different contexts**:

| Access Type         | Who Uses It                                              | Authentication Method                                          | Example                               |
| ------------------- | -------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------- |
| **External Access** | Humans, via `kubectl` or API clients outside the cluster | Uses credentials from `~/.kube/config`                         | `kubectl get pods`                    |
| **Internal Access** | Applications or Pods running inside the cluster          | Uses ServiceAccount token automatically mounted inside the Pod | `curl https://kubernetes.default.svc` |

---

## 🧠 2. What Happens When You Run `kubectl get pods`

1. `kubectl` reads your **kubeconfig** file from your system:

   * Finds the API server address.
   * Loads your credentials (token, client cert, etc.).
2. It sends a **REST API request** to:

   ```
   GET /api/v1/namespaces/default/pods
   ```
3. The **API Server** authenticates the user, checks RBAC permissions, and returns a JSON response.
4. `kubectl` formats that JSON output into the familiar table view.

So `kubectl` is essentially a *friendly client* around the **Kubernetes REST API**.

---

## 🔗 3. Accessing the API Server from Inside a Pod

Every Pod in Kubernetes can also talk to the API Server directly — without `kubectl`.
When a Pod is created, Kubernetes automatically injects three important files inside it:

| File                                                      | Description                             |
| --------------------------------------------------------- | --------------------------------------- |
| `/var/run/secrets/kubernetes.io/serviceaccount/token`     | JWT token (used for authentication)     |
| `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`    | Cluster’s certificate (for HTTPS trust) |
| `/var/run/secrets/kubernetes.io/serviceaccount/namespace` | The namespace the Pod belongs to        |

Using these, any container inside the Pod can authenticate and securely call the Kubernetes API.

Example command:

```bash
APISERVER=https://kubernetes.default.svc
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

curl --cacert ${CACERT} \
     -H "Authorization: Bearer ${TOKEN}" \
     ${APISERVER}/api/v1/namespaces/default/pods
```

---

## 🔐 4. Authentication vs Authorization

Kubernetes security works in two distinct layers:

| Layer              | Meaning                                              | Example                                                        |
| ------------------ | ---------------------------------------------------- | -------------------------------------------------------------- |
| **Authentication** | Verifies *who* you are (using token or certificate). | Pod uses ServiceAccount token to prove its identity.           |
| **Authorization**  | Verifies *what* you can do.                          | RBAC rules decide whether you can list Secrets or create Pods. |

If a Pod authenticates but lacks permission, the API Server returns:

```json
{
  "status": "Failure",
  "reason": "Forbidden",
  "code": 403
}
```

This means:

> “I know who you are, but you’re not allowed to do this.”

---

## 🧾 5. Why Every Pod Has a ServiceAccount (Even If It Does Nothing)

When you create a Pod without specifying a ServiceAccount:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx:1-alpine
```

Kubernetes automatically attaches:

```
system:serviceaccount:<namespace>:default
```

### Reasons:

* Ensures every Pod has a **consistent identity**.
* Enables future API access without recreating the Pod.
* Supports uniform automation and auditing (every request can be traced to a ServiceAccount).

By default, the `default` ServiceAccount has **no permissions**,
but it’s still attached for identity and standardization.

---

## ⚙️ 6. When and Why to Use a Custom ServiceAccount

When a Pod (or an application inside it) needs to talk to the Kubernetes API — for example, to:

* Read or update Secrets
* Watch Deployments
* List Pods for monitoring

Then you must:

1. Create a **custom ServiceAccount**.
2. Grant it **permissions** via a **Role**.
3. Bind that Role using a **RoleBinding**.

Example:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-reader
  namespace: project-swan
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader-role
  namespace: project-swan
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-reader-binding
  namespace: project-swan
subjects:
- kind: ServiceAccount
  name: secret-reader
roleRef:
  kind: Role
  name: secret-reader-role
  apiGroup: rbac.authorization.k8s.io
```

Attach it to the Pod:

```yaml
spec:
  serviceAccountName: secret-reader
```

Now the Pod has permission to access Secrets in its namespace.

---

## 🧭 7. Default vs Custom ServiceAccount Summary

| Type                       | Purpose                               | Permissions       | Typical Use                                           |
| -------------------------- | ------------------------------------- | ----------------- | ----------------------------------------------------- |
| **Default ServiceAccount** | Every Pod gets one automatically      | None              | For regular workloads that don’t call the API         |
| **Custom ServiceAccount**  | Created manually and bound to Roles   | Custom (via RBAC) | For applications or Pods that need API access         |
| **Disabled token**         | `automountServiceAccountToken: false` | N/A               | For Pods that will never use the API (pure workloads) |

---

## 🧩 8. The Flow of In-Cluster Communication

```
Your Pod (with ServiceAccount)
          ↓
ServiceAccount Token (JWT)
          ↓
Kubernetes API Server
          ↓
RBAC Rules (Role/ClusterRole)
          ↓
etcd (cluster database)
          ↓
Response (JSON)
```

---

## 🧠 9. Key Takeaways

* `kubectl` uses **user credentials** from kubeconfig (outside cluster).
* Pods use **ServiceAccount tokens** (inside cluster).
* ServiceAccounts provide both **authentication** and **authorization**.
* Default ServiceAccounts exist for **identity consistency**, even with no privileges.
* Custom ServiceAccounts are used when Pods need to **access the API securely**.
* Deployments, Jobs, and DaemonSets all rely on **Pods** for any actual API communication.

---

## ⚠️ 10. Common Scenario: Deployment Pods Failing Due to Missing RBAC Permissions

Sometimes, a **Deployment** runs containers that execute Kubernetes commands such as:

```yaml
command: ["kubectl", "get", "pods"]
```

In such cases:

* The **Pod created by the Deployment** inherits the ServiceAccount specified in the Deployment spec.
* If that ServiceAccount does **not** have permission to perform the requested action (for example, to list Pods),
  the command will fail **inside the container**, even though the Deployment itself is created successfully.

When you check the Pod’s logs, you may see:

```bash
Error from server (Forbidden): pods is forbidden:
User "system:serviceaccount:project-swan:default" cannot list resource "pods"
in API group "" in the namespace "project-swan"
```

### 🔍 How to Troubleshoot

1. **Check the ServiceAccount** used by the Pod:

   ```bash
   kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.serviceAccountName}'
   ```

2. **Verify permissions**:

   ```bash
   kubectl auth can-i list pods --as=system:serviceaccount:<namespace>:<sa-name> -n <namespace>
   ```

3. **If denied**, create a Role and RoleBinding:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: pod-reader
     namespace: project-swan
   rules:
   - apiGroups: [""]
     resources: ["pods"]
     verbs: ["get", "list"]
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: pod-reader-binding
     namespace: project-swan
   subjects:
   - kind: ServiceAccount
     name: <serviceaccount-name>
   roleRef:
     kind: Role
     name: pod-reader
     apiGroup: rbac.authorization.k8s.io
   ```

4. **Re-run the Deployment**, then check logs again:

   ```bash
   kubectl logs <pod-name> -n <namespace>
   ```

   If permissions are correct, the command will succeed.

### 🧩 Key Lesson

Even though a **Deployment** defines the workload,
it’s the **Pod** that performs the API calls.
RBAC always applies to the **ServiceAccount attached to the Pod**, not the Deployment object itself.

This is a frequent **exam scenario (CKA/CKAD)** —
errors like `cannot list pods` or `forbidden` almost always point to a missing or incorrect RBAC configuration.

---

## 🧩 11. Real-World Analogy

Think of the Kubernetes API Server like a **secure office building**:

| Concept                       | Analogy                                                        |
| ----------------------------- | -------------------------------------------------------------- |
| User credentials (kubeconfig) | A visitor badge you use at the front desk                      |
| ServiceAccount token          | An employee ID badge for internal staff                        |
| Default ServiceAccount        | A badge with no building access but still shows who you are    |
| Custom ServiceAccount         | A badge that allows entry to specific rooms (defined by Roles) |

Every Pod gets an ID badge by default — even if it never leaves its desk.

---

## 🏁 Conclusion

In-cluster API access is one of the most important Kubernetes concepts to master.
It forms the foundation of how controllers, operators, and automated tools interact with the cluster securely.

Once you understand **how ServiceAccounts authenticate and how RBAC authorizes actions**,
you understand the *real inner workings* of Kubernetes.

---

✅ **File Path:** `/kubernetes/inside-cluster-api-access.md`
✅ **Category:** Kubernetes Core Concepts
✅ **Purpose:** Explains how Pods communicate with the API Server internally and the role of ServiceAccounts and RBAC in that process.
