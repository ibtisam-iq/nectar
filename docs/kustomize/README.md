## 1. What is Kustomize?

* A Kubernetes-native configuration management tool.
* Allows you to **customize YAML manifests** without templates.
* Works by layering configurations in a structured way.

---

## 2. Managing Directories (Base)

* **Base** contains common manifests (e.g., Deployments, Services).
* `kustomization.yaml` in the base defines:

  * `resources` → Which manifests to include.
  * `transformers` (optional) → Modify labels, annotations, etc.
  * `patches` (optional) → Adjust specific fields.
* Purpose: Create a **clean, reusable starting point** for all environments.

---

## 3. Overlays (Environment-Specific Configs)

* **Overlays** extend or modify the base for each environment (dev, staging, prod).
* Each overlay has its own `kustomization.yaml`.
* Typical use cases:

  * Change replica counts.
  * Add or remove resources (e.g., Grafana only in prod).
  * Apply patches for environment-specific changes.
* Command example:

  ```bash
  kubectl apply -k overlays/dev
  kubectl apply -k overlays/prod
  ```

---

## 4. Components (Optional, Reusable Features)

* **Components** solve the problem of optional add-ons.
* Defined using `kind: Component`.
* Examples: Monitoring (Grafana), Network Policies, Logging.
* Integrated into overlays when needed:

  ```yaml
  components:
    - ../../components/monitoring
    - ../../components/network-policy
  ```
* Benefit: Reusable and mix-and-match features across environments.

---

## 5. Strategy & Flow

1. **Base** → Common configuration for all.
2. **Overlays** → Environment-specific adjustments.
3. **Components** → Optional features added on top.

This sequence ensures:

* **Reusability** (no duplication).
* **Flexibility** (easy per-environment differences).
* **Scalability** (clean management as apps grow).

---

## 6. Key Commands

```bash
# Validate output without applying
kustomize build overlays/prod

# Apply directly
kubectl apply -k overlays/prod
```

---

## Final Takeaway

* **Base** = foundation (always used).
* **Overlays** = environment-specific changes.
* **Components** = optional reusable features.
* Together, they give a structured and scalable way to manage Kubernetes manifests.
