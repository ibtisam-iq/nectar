# 🔐 Kubernetes RBAC (Role-Based Access Control) – A Deep Dive

RBAC (Role-Based Access Control) is one of the **most crucial topics** in Kubernetes administration, especially for **CKA certification**. It controls **who can do what** in a Kubernetes cluster.

---

## 🧠 Table of Contents
1. [What is RBAC?](#what-is-rbac)
2. [Key Concepts](#key-concepts)
3. [RBAC Resources](#rbac-resources)
4. [Types of Subjects](#types-of-subjects)
5. [How Kubernetes Authenticates Users](#how-kubernetes-authenticates-users)
6. [Creating Roles and RoleBindings](#creating-roles-and-rolebindings)
7. [Step 4: Understanding API Groups](#step-4-understanding-api-groups)
8. [Step 5: Understanding Subresources](#step-5-understanding-subresources)
9. [ServiceAccount vs User vs Group](#serviceaccount-vs-user-vs-group)
10. [Tips for CKA and Practice Ideas](#tips-for-cka-and-practice-ideas)

---

## 📘 What is RBAC? {: #what-is-rbac }

**RBAC (Role-Based Access Control)** lets you **control access** to Kubernetes resources based on a **user’s role** (i.e., their job/responsibility). You define **who** can perform **which actions** on **which resources**.

Example:
- Devs can read pods.
- Admins can delete deployments.
- A CI pipeline can create and update secrets.

---

## 🧩 Key Concepts {: #key-concepts }

| Term              | Meaning                                                                 |
|-------------------|-------------------------------------------------------------------------|
| `Role`            | Defines **permissions** within a **namespace**                          |
| `ClusterRole`     | Defines **cluster-wide permissions** or permissions across namespaces   |
| `RoleBinding`     | Binds a `Role` to users/groups/serviceaccounts **in a namespace**       |
| `ClusterRoleBinding` | Binds a `ClusterRole` to users/groups/serviceaccounts **cluster-wide** |

---

## 🧱 RBAC Resources {: #rbac-resources }

Kubernetes uses the following **resources** to implement RBAC:

- **`Role`**: Defines allowed actions within a namespace.
- **`RoleBinding`**: Grants access to a `Role` for a user/group/service account in a namespace.
- **`ClusterRole`**: Same as Role, but for cluster-wide use.
- **`ClusterRoleBinding`**: Grants access to a `ClusterRole` for subjects across the whole cluster.

---

## 🧓‍♂️ Types of Subjects {: #types-of-subjects }

A Role/ClusterRole is applied to a **subject**, which can be of three types:

| Subject Type     | Created In             | Managed By Kubernetes? | Example                         |
|------------------|------------------------|-------------------------|---------------------------------|
| `User`           | External (IAM, OIDC)   | ❌ No                   | `john@example.com`             |
| `Group`          | External (IAM/OIDC)    | ❌ No                   | `devs`, `admins`               |
| `ServiceAccount` | Internal (Kubernetes)  | ✅ Yes                  | `default:my-sa`                |

---

## 🔐 How Kubernetes Authenticates Users {: #how-kubernetes-authenticates-users }

Kubernetes does **NOT** manage users and groups internally.

It relies on **external authentication systems**:
- ✅ TLS Certificates (self-signed or signed by a CA)
- ✅ Cloud IAM (AWS IAM, Azure AD, GCP IAM)
- ✅ OIDC (Google, Okta, etc.)
- ✅ Webhooks (Custom user systems)

🧠 That's why you can **use `--user` or `--group` in RoleBindings**, even though you never created those inside the cluster!

---

## 🎯 Creating RBAC Rules – Examples {: #creating-roles-and-rolebindings }

### 1. **Create a Role**
```bash
kubectl create role pod-reader \
  --verb=get --verb=list --verb=watch \
  --resource=pods
```

### 2. **Create a RoleBinding**
```bash
kubectl create rolebinding read-pods-binding \
  --role=pod-reader \
  --user=john@example.com \
  --namespace=dev
```

### 3. **Using API Groups**
```bash
kubectl create role foo \
  --verb=get,list,watch \
  --resource=rs.apps
```

### 4. **Using SubResources**
```bash
kubectl create role foo \
  --verb=get,list,watch \
  --resource=pods,pods/status
```

---

## 🔄 Step 4: Understanding API Groups {: #step-4-understanding-api-groups }

Kubernetes resources are split into **API Groups**:

| API Group          | Resources                                     |
|--------------------|-----------------------------------------------|
| `""` (core)        | `pods`, `services`, `configmaps`, `secrets`   |
| `apps`             | `deployments`, `replicasets`, `statefulsets` |
| `batch`            | `jobs`, `cronjobs`                            |
| `rbac.authorization.k8s.io` | `roles`, `rolebindings`, etc.        |

To know the group for a resource:
```bash
kubectl api-resources
```

Example:
```bash
kubectl create role foo --verb=get --resource=deployments.apps
```
Means:
- Resource: `deployments`
- API Group: `apps`

Format: `--resource=resourceName.groupName`

---

## 🔄 Step 5: Understanding Subresources {: #step-5-understanding-subresources }

Some Kubernetes resources have **subresources**. These are attached to the main resource but represent a sub-functionality:

| Main Resource | Subresource   | Use Case                               |
|---------------|---------------|----------------------------------------|
| `pods`        | `status`      | View pod status info                   |
| `pods`        | `log`         | Read container logs                    |
| `pods`        | `exec`        | Execute commands inside containers     |
| `deployments` | `scale`       | Scale deployment replicas              |

Format:
```bash
--resource=resource/subresource
```
Or with API group:
```bash
--resource=resource.group/subresource
```

Example:
```bash
kubectl create role viewer --verb=get --resource=pods/status
```
Means the subject can only **view the status** of pods, not update or delete them.

---

### Understanding `--resource=resource.group/subresource`

When using the `--resource` flag in `kubectl create role`, you're defining the exact API target the role will apply to. This flag can have **three components**:

- **`resource`** → The main Kubernetes object.  
  _Examples_: `pods`, `deployments`, `services`

- **`group`** → The API group the resource belongs to.  
  _Examples_: `apps`, `batch`, `rbac.authorization.k8s.io`

- **`subresource`** (optional) → A more specific part or action related to the resource.  
  _Examples_:  
  - `pods/log` – to access logs from a pod  
  - `deployments/scale` – to allow scaling of deployments  
  - `pods/status` – to read or modify the status subresource of a pod

> 📌 **Format:**  
> `--resource=resource.group/subresource`  
> All three components are not always required. For core resources (like `pods`), the `group` may be empty. And `subresource` is only used when needed.

#### Examples:
```bash
# Targeting the core 'pods' resource
--resource=pods

# Targeting the 'replicasets' resource in the 'apps' API group
--resource=replicasets.apps

# Targeting the 'status' subresource of pods
--resource=pods/status
```

---

## 👤 ServiceAccount vs User vs Group {: #serviceaccount-vs-user-vs-group }

| Feature              | User              | Group           | ServiceAccount      |
|----------------------|-------------------|------------------|----------------------|
| Created by you?      | ❌ (external)      | ❌ (external)     | ✅ (via `kubectl`)   |
| Stored in Kubernetes | ❌                | ❌               | ✅                   |
| Used for scripts     | ❌ (harder)        | ❌               | ✅ (preferred)       |
| RoleBinding compatible | ✅              | ✅               | ✅                   |

---

## 📆 Tips for CKA and Practice {: #tips-for-cka-and-practice-ideas }

- Use **`kubectl auth can-i`** to test permissions:
  ```bash
  kubectl auth can-i delete pods --as john@example.com
  ```

- Practice creating:
  - Role and RoleBinding
  - ClusterRole and ClusterRoleBinding
  - With API group, subresources, and resource names
  - For service accounts and users

- Use `kubectl explain` to dig into any resource:
  ```bash
  kubectl explain role
  ```

---

## 📦 Real-World Use Case: CI/CD Pipeline

You have a CI/CD tool running as a Pod with a ServiceAccount. You want it to only create/update deployments.

**1. Create Role**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cicd-role
  namespace: dev
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create", "update"]
```

**2. Create RoleBinding**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cicd-bind
  namespace: dev
subjects:
- kind: ServiceAccount
  name: cicd-sa
  namespace: dev
roleRef:
  kind: Role
  name: cicd-role
  apiGroup: rbac.authorization.k8s.io
```

## 🛠️ All Verbs Explained (with Real-Life Examples)

| Verb               | Meaning in Kubernetes                         | Real-life analogy (🧍)                          |
| ------------------ | --------------------------------------------- | ----------------------------------------------- |
| `get`              | Read a specific object                        | Viewing a file or record                        |
| `list`             | List all objects of a type                    | Listing all documents in a folder               |
| `watch`            | Subscribe to live updates about objects       | Getting live notifications about folder changes |
| `create`           | Create a new object                           | Making a new Google Doc                         |
| `update`           | Change an existing object                     | Editing an existing document                    |
| `patch`            | Modify part of an object                      | Suggesting a small fix (e.g., typo)             |
| `delete`           | Remove an object                              | Deleting a document                             |
| `deletecollection` | Delete a **group** of objects at once         | Deleting all documents in a folder at once      |
| `bind`             | Bind a Role to a user (only for RoleBindings) | Assigning someone a job role                    |
| `impersonate`      | Act as another user/resource                  | Logging in as someone else (if authorized)      |
| `escalate`         | Allow assigning higher permissions            | Letting someone assign admin rights             |
| `approve`          | Approve CSR (certificate signing request)     | Approving someone's access request              |
| `deny`             | Deny CSR (rare, specific usage)               | Rejecting access                                |
| `use`              | Use a named resource (like PSP or SCC)        | Being allowed to wear a specific uniform        |

---

```bash
controlplane ~ ➜  k describe clusterrole cluster-admin
Name:         cluster-admin
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  *.*        []                 []              [*]
             [*]                []              [*]
```

## 🔍 `kubectl describe clusterrole cluster-admin` Explained

You ran:

```bash
kubectl describe clusterrole cluster-admin
```

And got this core info:

| Field                 | Value                                                |
| --------------------- | ---------------------------------------------------- |
| **Resources**         | `*.*` (All API groups, all resources)                |
| **Non-Resource URLs** | `[*]` (All API paths that aren't resources)          |
| **Resource Names**    | `[]` (Applies to all resource names)                 |
| **Verbs**             | `[*]` (All actions: get, list, create, update, etc.) |

---

## 🧠 What This Means in Layman's Terms

Imagine Kubernetes is a **city**, and every API call is like accessing a building or facility (hospital, bank, etc.).

* 🧑‍⚖️ **ClusterRole: `cluster-admin`**
  \= The Mayor + Police Chief + Super Admin — has full access to **all buildings, all services, and all paths** in the entire city (cluster).

---

## 🔐 Field-by-Field Breakdown

### 1. **Resources: `*.*`**

This means:

* `*` = All **API groups** (like core, apps, networking.k8s.io, etc.)
* `*` = All **resources** in those API groups (pods, services, secrets, etc.)

📦 Effect: "You can access every resource in the cluster regardless of API group."

---

### 2. **Non-Resource URLs: `[*]`**

These are URLs like:

* `/healthz`
* `/metrics`
* `/api`
* `/version`
* `/logs`

📦 Effect: "You can also call any non-resource endpoints that are outside the Kubernetes object model."

---

### 3. **Resource Names: `[]`**

Empty means **"applies to all objects"**.

Example:

* If this was `[my-secret]`, it would only apply to one specific resource.
* But since it’s empty, it applies to **all resource names** of every kind.

---

### 4. **Verbs: `[*]`**

This means:

```yaml
["get", "list", "watch", "create", "update", "patch", "delete", "deletecollection", "bind", "impersonate", ...]
```

📦 Effect: "You can do *everything possible* with any resource."

---

## 🛡️ Summary: Why This Role Is So Powerful

💥 `cluster-admin` has:

* All **verbs**
* On all **resources**
* Across all **namespaces**
* Including **non-resource URLs**

This is the **equivalent of `root` on Linux**.

---

## ✅ Where This Is Used

By default:

* The user who bootstraps the cluster (like `kubeadm init`) gets `cluster-admin`.
* You can assign this role using a `ClusterRoleBinding`.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-admin-binding
subjects:
- kind: User
  name: ibtisam
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

---