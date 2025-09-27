# Kubernetes API Versions

## 📌 What are API Versions?

* Kubernetes objects (Pods, Deployments, ConfigMaps, etc.) are defined using **APIs**.
* Each API is grouped into **API Groups** and **Versions**.
* Example:

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  ```

  * `apps` → API group
  * `v1` → API version
  * `Deployment` → Kind

---

## 📂 Types of API Groups

1. **Core Group (no name, just `v1`)**

   * Examples: `Pod`, `Service`, `ConfigMap`, `Node`.
   * Usage:

     ```yaml
     apiVersion: v1
     kind: Pod
     ```

2. **Named API Groups**

   * Examples: `apps`, `batch`, `networking.k8s.io`, `rbac.authorization.k8s.io`.
   * Usage:

     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     ```

---

## 🏷️ API Versioning Stages

Kubernetes uses semantic-like versioning for APIs:

* **Alpha (`v1alpha1`, `v1alpha2`, …)**

  * Early stage, experimental.
  * May change or be removed anytime.
  * **Disabled by default** (must enable explicitly).

* **Beta (`v1beta1`, `v1beta2`, …)**

  * More stable, well-tested.
  * Enabled by default.
  * Features may still change.

* **Stable (`v1`)**

  * Fully tested, backward compatible.
  * Enabled by default.
  * API guarantees no breaking changes.

---

## 🔄 How Alpha → Beta → Stable Works

1. Feature starts as **alpha** (e.g., `networking.k8s.io/v1alpha1`).
2. After testing, moves to **beta** (`v1beta1`).
3. Once finalized, becomes **stable (`v1`)**.
4. Older versions (`alpha`/`beta`) are eventually **deprecated & removed**.

---

## ⚙️ Enabling APIs

* **Alpha APIs** → disabled by default. To enable:

  ```bash
  --runtime-config=api/all=true
  --runtime-config=apps/v1alpha1=true
  ```
* **Beta & Stable APIs** → enabled by default.

---

## 📌 Multiple Versions of the Same API

* Some resources exist in multiple versions (e.g., `Deployment` existed as `extensions/v1beta1`, later `apps/v1`).
* API Server has:

  * **Preferred version** → used by `kubectl get -o yaml`.
  * **Storage version** → the version in which object is stored in `etcd`.
* On retrieval, API Server **converts stored version → requested version** transparently.

---

## 🔍 How to Check API Versions

* List all API resources:

  ```bash
  kubectl api-resources
  ```
* List all API versions supported:

  ```bash
  kubectl api-versions
  ```
* Check preferred/storage version of CRDs:

  ```bash
  kubectl get crd <crd-name> -o yaml | grep versions -A 5
  ```

---

## 📊 What Do Versions Actually Mean?

* **Version = maturity of the API.**
* `v1alpha1` = experimental, may break.
* `v1beta1` = stable enough for production use, but still subject to change.
* `v1` = guaranteed stability and long-term support.

---

## 🖼️ Layout Diagram

```
                  +---------------------+
                  |   API Request       |
                  +---------------------+
                            |
                            v
         +--------------------------------------+
         |           kube-apiserver             |
         |   Admission + Validation + Storage   |
         +--------------------------------------+
            | Preferred Version | Storage Version
            |                   |
            v                   v
     apps/v1beta1 → apps/v1  |  etcd stores apps/v1
     batch/v1beta1 → batch/v1|
```

---

## 🔑 Key Takeaways

* APIs evolve: **alpha → beta → stable (v1)**.
* **Alpha = off by default**, Beta & Stable = enabled by default.
* Multiple versions may exist → API Server handles conversion.
* **Storage version** is what’s in etcd, but **preferred version** is what you interact with.
* Always check `kubectl api-resources` and `kubectl api-versions` to know what’s available.

---
