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

## 📘 What is RBAC?

**RBAC (Role-Based Access Control)** lets you **control access** to Kubernetes resources based on a **user’s role** (i.e., their job/responsibility). You define **who** can perform **which actions** on **which resources**.

Example:
- Devs can read pods.
- Admins can delete deployments.
- A CI pipeline can create and update secrets.

---

## 🧩 Key Concepts

| Term              | Meaning                                                                 |
|-------------------|-------------------------------------------------------------------------|
| `Role`            | Defines **permissions** within a **namespace**                          |
| `ClusterRole`     | Defines **cluster-wide permissions** or permissions across namespaces   |
| `RoleBinding`     | Binds a `Role` to users/groups/serviceaccounts **in a namespace**       |
| `ClusterRoleBinding` | Binds a `ClusterRole` to users/groups/serviceaccounts **cluster-wide** |

---

## 🧱 RBAC Resources

Kubernetes uses the following **resources** to implement RBAC:

- **`Role`**: Defines allowed actions within a namespace.
- **`RoleBinding`**: Grants access to a `Role` for a user/group/service account in a namespace.
- **`ClusterRole`**: Same as Role, but for cluster-wide use.
- **`ClusterRoleBinding`**: Grants access to a `ClusterRole` for subjects across the whole cluster.

---

## 🧓‍♂️ Types of Subjects

A Role/ClusterRole is applied to a **subject**, which can be of three types:

| Subject Type     | Created In             | Managed By Kubernetes? | Example                         |
|------------------|------------------------|-------------------------|---------------------------------|
| `User`           | External (IAM, OIDC)   | ❌ No                   | `john@example.com`             |
| `Group`          | External (IAM/OIDC)    | ❌ No                   | `devs`, `admins`               |
| `ServiceAccount` | Internal (Kubernetes)  | ✅ Yes                  | `default:my-sa`                |

---

## 🔐 How Kubernetes Authenticates Users

Kubernetes does **NOT** manage users and groups internally.

It relies on **external authentication systems**:
- ✅ TLS Certificates (self-signed or signed by a CA)
- ✅ Cloud IAM (AWS IAM, Azure AD, GCP IAM)
- ✅ OIDC (Google, Okta, etc.)
- ✅ Webhooks (Custom user systems)

🧠 That's why you can **use `--user` or `--group` in RoleBindings**, even though you never created those inside the cluster!

---

## 🎯 Creating RBAC Rules – Examples

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

## 🔄 Step 4: Understanding API Groups

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

## 🔄 Step 5: Understanding Subresources

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

## 👤 ServiceAccount vs User vs Group

| Feature              | User              | Group           | ServiceAccount      |
|----------------------|-------------------|------------------|----------------------|
| Created by you?      | ❌ (external)      | ❌ (external)     | ✅ (via `kubectl`)   |
| Stored in Kubernetes | ❌                | ❌               | ✅                   |
| Used for scripts     | ❌ (harder)        | ❌               | ✅ (preferred)       |
| RoleBinding compatible | ✅              | ✅               | ✅                   |

---

## 📆 Tips for CKA and Practice

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


