# Kustomize Overlays

After defining the **base** configuration with `kustomization.yaml`, resources, transformers, and patches, the real power of Kustomize comes from **Overlays**.
Overlays are used to manage **environment-specific configurations**, such as staging, production, or development.

Instead of duplicating manifests for every environment, overlays allow us to **reuse the base** and only apply changes (patches, transformers, or additional manifests) where needed.

---

## What Are Overlays?

* An **overlay** is a directory that points to the base and contains a `kustomization.yaml`.
* Inside this file, you can:

  * **Modify** base resources (e.g., scale replicas, change images).
  * **Add** environment-specific resources (e.g., a monitoring tool like Grafana in production).
  * **Apply patches** for environment-specific changes.
* Each environment has its own overlay (e.g., `/overlays/dev`, `/overlays/staging`, `/overlays/prod`).

---

## Example Directory Structure

```
my-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── dev-config.yaml      # unique to dev
    ├── staging/
    │   ├── kustomization.yaml
    │   └── ingress.yaml         # staging-specific resource
    └── prod/
        ├── kustomization.yaml
        └── grafana.yaml         # unique to prod only
```

---

## Example Overlay `kustomization.yaml`

**Production Overlay:**

```yaml
resources:
  - ../../base          # reference to the base
  - grafana.yaml        # unique to prod, not in base

patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 5
```

Here:

* The **base resources** are imported.
* **Grafana** is added because it is only required in production.
* A **patch** scales replicas from the base value to `5` in production.

---

## Deploying with Overlays

Once overlays are defined, you can deploy environment-specific configs with one command:

```bash
kubectl apply -k overlays/dev
kubectl apply -k overlays/staging
kubectl apply -k overlays/prod
```

---

## Key Points About Overlays

* They are **environment-specific** configurations.
* They can **add new manifests** that don’t exist in the base.
* They can **modify base manifests** using patches or transformers.
* They keep your repo **organized and DRY (Don’t Repeat Yourself)** by reusing the base.

---

👉 In summary: Overlays are the main feature of Kustomize for managing **multiple environments**.
They let you extend or override base configurations while keeping everything centralized and maintainable.
