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

      # in case of dictionary

      - op: replace
        path: /spec/replicas
        value: 3
      - op: add                                           # it will append one more label     # org: ibtisam
        path: /spec/template/metadata/labels/org          # org → key      
        value: ibtisam                                    # ibtisam → value
      - op: remove
        path: /spec/template/metadata/labels/org          # it just removes one label, whose key is org
                                                          # no need to mention value in case of op: remove
      # in case of list

      - op: replace
        path: /spec/template/spec/containers/0/image      # a case of list, so we use indexing... 0 → first container
        value: nginx:1.27                                 # just changing continer image 
      - op: replace
        path: /spec/template/spec/containers/0      
        value:                                            # changing two values, container name and its image
          name: sidecar
          image: ubuntu
      - op: add
        path: /spec/template/spec/containers/-            # - → last container, append to the last of the list
        value:                                            # adding two values, container name & its image
          name: haproxy
          image: haproxy
      - op: remove
        path: /spec/template/spec/containers/1            # 1 → 2nd container
                                                          # op: remove, requires no value key.
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
  - patch: |-                  # this patch targets spec.replicas, spec.template.metadata.labels, and container... this is just for example.
      apiVersion: apps/v1      # in real-time, a one patch usually targets one thing only.
      kind: Deployment
      metadata:
        name: my-app
      spec:
        replicas: 4              # it will update, an example of op: replace

        template:
          metadata:
            labels:              # if org → key is not present, it will append one more label, an example of op: add
              org: ibtisam       # otherwise, if org → key is present, it will update, an example of op: replace
              org: null          # when, org → key is present, and you want to delete this label, an example of op: remove

          spec:
            containers:          # adds a new container to the list, or replaces if it already exists.
             - name: sidecar
               image: busybox
             - $patch: delete    # deletes an existing container, this is an unique way.
               name: sidecar     # container name
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
