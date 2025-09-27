# Admission Control in Kubernetes

## 📌 What are Admission Controllers?

* Admission Controllers are **plugins** in the **Kube-API Server** that intercept API requests **after authentication & authorization** but **before persistence in etcd**.
* They act as **“guardians”** that can **validate**, **mutate**, or **reject** requests.
* Purpose: enforce **policies**, apply **defaults**, or inject **configurations** automatically.

---

## ⚙️ Functions of Admission Controllers

1. **Validation** – e.g., reject if namespace doesn’t exist (`NamespaceExists`).
2. **Mutation** – e.g., auto-assign a default storage class (`DefaultStorageClass`).
3. **Security Enforcement** – restrict privileges (e.g., `PodSecurity`).
4. **Policy Control** – control what resources can be created/modified.

---

## 🔍 How to Check Enabled Admission Plugins

### 1. Check running API Server process

```bash
ps -aux | grep apiserver | grep -i admission-plugins
```

### 2. Exec into API Server Pod and check help

```bash
kubectl -n kube-system exec -it kube-apiserver-controlplane -- \
  kube-apiserver -h | grep enable-admission-plugins
```

---

## 🔧 Enable / Disable Admission Controllers

* Enable:

  ```bash
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount
  ```
* Disable:

  ```bash
  --disable-admission-plugins=DefaultStorageClass
  ```

---

## ✅ Default vs Non-default Admission Controllers

* **Enabled by default (examples):**

  * `NamespaceExists` → ensures a namespace must exist before creating objects inside it.
  * `LimitRanger` → enforces resource limits.

* **Not enabled by default (examples):**

  * `NamespaceAutoProvision` → auto-creates a namespace if it doesn’t exist.

🔎 Example:

```bash
kubectl run nginx --image=nginx -n blue
# Error: namespaces "blue" not found
```

This fails because `NamespaceAutoProvision` is NOT enabled by default.

---

## 🧩 Types of Admission Controllers

1. **Mutating Admission Controllers**

   * Can **modify** requests (add/change fields).
   * Example: `DefaultStorageClass` → auto-assigns a default storage class if PVC doesn’t specify one.

2. **Validating Admission Controllers**

   * Can only **accept or reject**, cannot modify.
   * Example: `NamespaceExists` → rejects if namespace does not exist.

---

## 🕒 Order of Execution

1. **Mutating Admission Controllers run first** → they modify the request.
2. **Validating Admission Controllers run next** → they validate the final (mutated) request.

This ensures validation happens on the **final state** of the object.

---

## 🌐 Admission Webhooks

For dynamic/custom policies, Kubernetes allows webhooks:

1. **MutatingAdmissionWebhook**

   * External webhook that can modify requests.

2. **ValidatingAdmissionWebhook**

   * External webhook that validates requests but cannot change them.

---

## ⚡ Steps to Use Admission Webhooks

1. **Build a webhook server** (custom logic in Go/Python).
2. **Deploy webhook server** in cluster as a Deployment.
3. **Expose it as a Service** (so API Server can reach it).
4. **Create a ValidatingWebhookConfiguration or MutatingWebhookConfiguration** object to register the webhook with API Server.
5. API Server now calls the webhook during admission for matching requests.

---

## 🔑 Key Takeaways

* Admission Controllers = “traffic police” at API Server level.
* They enforce policies, mutate requests, and protect the cluster.
* Built-in ones (like `NamespaceExists`) are common; others need enabling.
* Order: **Mutating → Validating**.
* For custom rules → use **Admission Webhooks**.

---
