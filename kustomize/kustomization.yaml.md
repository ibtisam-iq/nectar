# Understanding `kustomization.yaml`

The heart of Kustomize is the **`kustomization.yaml`** file.
This file acts as the blueprint that tells Kustomize how to build and customize Kubernetes manifests.
Every Kustomize setup requires a `kustomization.yaml` at its root (whether it’s a **base, overlay, or component**).

---

## Key Components of `kustomization.yaml`

### 1. `apiVersion`

Specifies the Kustomize API version being used.
For example:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
```

This ensures Kustomize knows how to interpret the file.

---

### 2. `resources`

The `resources` field lists all the Kubernetes **manifests** or **sub-directories** we want to include.
This can point to:

* Direct manifest files (`.yaml`)
* Other directories containing their own `kustomization.yaml` files

Example:

```yaml
resources:
  - api-deploy.yaml
  - api-service.yaml
  - ../db
```

In our earlier case study:

* Without sub-directories: all manifests were directly listed here.
* With sub-directories: the top-level `kustomization.yaml` listed each sub-directory instead.

---

## Two Main Ways to Customize

Once we’ve listed our resources, we often need to customize them for different environments or requirements.
Kustomize provides two primary methods:

---

### 1. Using Transformers

**Transformers** are built-in Kustomize plugins that modify manifests automatically.
Examples include:

* `namePrefix` → Add a prefix to resource names
* `namespace` → Assign resources to a specific namespace
* `commonLabels` → Apply the same labels to all resources

Example:

```yaml
namespace: staging
commonLabels:
  app: my-app
```

Here, all resources are automatically placed in the `staging` namespace and labeled with `app=my-app`.
> **Note:** If we only want these applied to staging, we would put them **inside the staging overlay’s `kustomization.yaml`**.

---

### 2. Using Patches

**Patches** allow us to modify specific parts of a resource.
This is useful for environment-specific adjustments like replica counts, image versions, or resource limits.

Example:

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deploy
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 3
```

This patch changes the replica count of the `api-deploy` Deployment to 3.
> **Note:** Again, if we want this patch to apply **only in production**, we must put it inside the production overlay.

---

## How Customizations Are Applied

An important point to understand is that **everything we define in a `kustomization.yaml` applies to all resources listed under it**.
For example:

* If we set `commonLabels`, every resource in that kustomization will get those labels.
* If we patch a Deployment, the patch applies only to the matching resource within that kustomization.

However, if we don’t want a customization to apply globally, we must define it **only in the environment-specific overlay** or add the manifest **only in that overlay**.

In other words:

* **Base `kustomization.yaml`** → Defines configurations that should apply to all environments.
* **Overlay `kustomization.yaml`** → Defines configurations or unique manifests that should only apply to that specific environment (e.g., staging, production).

---

## Summary

* The `kustomization.yaml` file is the **entry point** for Kustomize.
* **`apiVersion`** defines compatibility, and **`resources`** define which manifests to include.
* Customization can be applied in two main ways:

  * **Transformers** → for bulk modifications like labels, namespaces, prefixes.
  * **Patches** → for fine-grained changes in individual resources.
* **Where you place the customization matters**:

  * In the **base**, it applies to all environments.
  * In an **overlay**, it applies only to that specific environment.

👉 We will later dedicate separate, detailed chapters to **Transformers** and **Patches**, exploring them in depth with real-time examples.
