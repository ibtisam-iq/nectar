# Kubernetes API Deprecation

## 📌 API Evolution Path

Kubernetes features evolve gradually through API versions:

1. **Alpha (`v1alpha1`, `v1alpha2` …)**

   * Earliest stage, experimental.
   * Disabled by default.
   * Example: `flowcontrol.apiserver.k8s.io/v1alpha1`.

2. **Beta (`v1beta1`, `v1beta2` …)**

   * More stable, enabled by default.
   * Backward compatible within the same major version.
   * Example: `batch/v1beta1` for CronJobs (before it moved to `batch/v1`).

3. **Stable (`v1`)**

   * Fully supported, enabled by default.
   * No breaking changes.
   * Example: `apps/v1` for Deployment.

---

## 📜 Rules of API Deprecation

* **Alpha APIs**

  * May be dropped anytime without notice.
  * No guarantee of support.

* **Beta APIs**

  * Supported for **at least one release** after deprecation.
  * Safe for production but still transitional.

* **Stable APIs (v1)**

  * Supported for **at least one year or three releases** after deprecation notice.
  * Gives cluster operators time to migrate.

* **General Rule:**

  * New version introduced → old version marked **deprecated** → removed in future release.
  * API Server converts old objects to the **storage version** transparently.

---

## 🔄 Examples of Deprecation

* **Deployment**

  * Old: `extensions/v1beta1` → Deprecated.
  * New: `apps/v1`.

* **Ingress**

  * Old: `extensions/v1beta1`, `networking.k8s.io/v1beta1`.
  * New: `networking.k8s.io/v1`.

* **CronJob**

  * Old: `batch/v1beta1`.
  * New: `batch/v1`.

---

## ⚙️ Migration with `kubectl convert`

* `kubectl convert` helps update old manifests to new API versions.
* Example:

  ```bash
  kubectl convert -f deployment-old.yaml --output-version=apps/v1 > deployment-new.yaml
  ```

  * Reads manifest using old API version.
  * Converts it to `apps/v1`.
  * Outputs updated YAML.

👉 Note: `kubectl convert` may require **`kubectl-convert` plugin** if not available by default.

---

## 🖼️ API Evolution Flow

```
+------------+     +-------------+     +---------+
| v1alpha1   | --> | v1alpha2    | --> | v1beta1 |
| (disabled) |     | (disabled)  |     | (enabled by default) |
+------------+     +-------------+     +---------+
                                         |
                                         v
                                    +---------+
                                    | v1      |
                                    | Stable  |
                                    +---------+
```

---

## 🔑 Key Takeaways

* APIs evolve: **alpha → beta → stable**.
* **Alpha = disabled**, **Beta = enabled**, **Stable = permanent**.
* Deprecated APIs remain **backward compatible for a while** before removal.
* Always check:

  ```bash
  kubectl api-resources
  kubectl api-versions
  ```
* Use `kubectl convert` to safely migrate manifests to supported API versions.

---
