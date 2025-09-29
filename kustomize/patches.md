# Kustomize Patches

Patches are the **second method** of customizing Kubernetes manifests with Kustomize.
Instead of redefining an entire manifest, a patch lets you modify only a **small part** of it.
This is useful when you want to make minor adjustments (like changing replicas, images, or labels) without duplicating the full YAML.

---

## How Patches Are Defined

Patches are always written inside **`kustomization.yaml`**, and there are two ways to include them:

1. **Inline Patch**

   * The patch content is written directly under the `patches` field in `kustomization.yaml`.
   * Useful for very small changes.

2. **External Patch File**

   * A separate YAML/JSON file is created and then referenced in `kustomization.yaml`.
   * Useful for larger or reusable patches.

---

## Patch Types

Kustomize supports two main patching strategies:

1. **JSON 6902 Patch**

   * Operation-based patching (RFC 6902).
   * Requires a `target` definition in `kustomization.yaml`, because the patch file itself contains only operations (`op`, `path`, `value`) and does not identify the resource.
   * Patch file can be written in **JSON** or **YAML**.

2. **Strategic Merge Patch (SMP)**

   * YAML-based patching that merges with the base manifest.
   * Does **not require `target`** if the patch file already includes `apiVersion`, `kind`, and `metadata.name`.
   * `target` can still be used optionally to further restrict scope.

---

## JSON 6902 Patch Examples

### (a) Inline Patch

```yaml
patches:
  - target:
      version: v1
      kind: Deployment
      name: my-app
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 3
```

### (b) External Patch (JSON file: `replica-patch.json`)

```json
[
  {
    "op": "replace",
    "path": "/spec/replicas",
    "value": 5
  }
]
```

`kustomization.yaml`:

```yaml
patches:
  - target:
      version: v1
      kind: Deployment
      name: my-app
    path: replica-patch.json
```

### (c) External Patch (YAML file: `replica-patch.yaml`)

```yaml
- op: replace
  path: /spec/replicas
  value: 5
```

`kustomization.yaml`:

```yaml
patches:
  - target:
      version: v1
      kind: Deployment
      name: my-app
    path: replica-patch.yaml
```

---

## Strategic Merge Patch Examples

### (a) Inline Patch

```yaml
patches:
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: my-app
      spec:
        replicas: 4
```

### (b) External Patch (YAML file: `replica-patch.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 4
```

`kustomization.yaml`:

```yaml
patches:
  - path: replica-patch.yaml
```

---

## JSON 6902 Deep Dive

When using JSON 6902 patches, each patch operation has the following fields:

* **op**: The type of operation to perform (`add`, `remove`, `replace`, `move`, `copy`, `test`).
* **path**: The location within the resource to apply the change (e.g., `/spec/replicas`).
* **value**: The new value to apply (required for `add` and `replace`).
* **target** (in `kustomization.yaml`): Identifies which resource to patch, using `kind`, `name`, `namespace`, and `version`.

Example (changing image):

```yaml
patches:
  - target:
      version: v1
      kind: Deployment
      name: my-app
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/image
        value: nginx:1.27
```

---

## Choosing Between Patch Types

* Use **JSON 6902 Patch** when you need **precise, fine-grained changes** (good for CI/CD automation).
* Use **Strategic Merge Patch** when you want **YAML-based edits** that feel natural in Kubernetes (simple changes like replicas, labels, annotations).

---

👉 In summary:

* JSON patches need `target` and can be in JSON or YAML format.
* Strategic Merge patches usually don’t need `target`, as resource identifiers are already inside the patch file.
* Both can be written inline or as external files.
