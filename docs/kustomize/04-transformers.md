# Transformers in Kustomize

## What Are Transformers?

In Kustomize, **Transformers** are **modifiers** that change the base YAML without editing it directly.

Think of your base YAML as a *vanilla ice cream*, and transformers are like toppings — chocolate chips, syrup, nuts — all applied *without changing the original ice cream*.

---

## Common Transformers

Here’s the list of the most used **built-in transformers**.

| Transformer         | Purpose                              |
| ------------------- | ------------------------------------ |
| `labels`            | Add labels to **all** resources      |
| `commonAnnotations` | Add annotations to **all** resources |
| `namespace`         | Set namespace for **all** resources  |
| `namePrefix`        | Add a prefix to resource names       |
| `nameSuffix`        | Add a suffix to resource names       |
| `images`            | Override image name/tag              |

---

## Usage Pattern

All transformers are defined in **`kustomization.yaml`**.

---

### **A) Adding `commonLabels`**

**Do**: Add to `kustomization.yaml`

```yaml
# Warning: 'commonLabels' is deprecated. Please use 'labels' instead.
labels:
  app: payment
  team: backend
```

**Where**: Inside the same `kustomization.yaml` that points to your base resources.

**See Output**:
Before:

```yaml
metadata:
  name: my-deployment
```

After:

```yaml
metadata:
  name: my-deployment
  labels:
    app: payment
    team: backend
```

---

### **B) Adding `commonAnnotations`**

```yaml
commonAnnotations:
  owner: ibtisam
  environment: dev
```

Adds annotations to **all resources**.

---

### **C) Setting Namespace**

```yaml
namespace: dev
```

Before:

```yaml
metadata:
  name: my-deployment
```

After:

```yaml
metadata:
  name: my-deployment
  namespace: dev
```

---

### **D) Adding Prefix & Suffix to Names**

```yaml
namePrefix: dev-
nameSuffix: -v2
```

Before:

```yaml
metadata:
  name: my-deployment
```

After:

```yaml
metadata:
  name: dev-my-deployment-v2
```

---

### **E) Overriding Images**

```yaml
images:
  - name: nginx                              # name of the image, not container
    newName: myregistry.com/custom-nginx
    newTag: "1.19"                          # must contain ""
```

Before:

```yaml
image: nginx:latest
```

After:

```yaml
image: myregistry.com/custom-nginx:1.19
```

---

## Why This is Powerful for Exams

* In CKA, you can **quickly change namespace, image tags, or add metadata** without touching original YAML.
* Great for **multi-environment configs** (dev/prod/staging) from same base.

---

## Pro Tips

* Transformers **apply to all resources** unless scoped with selectors (advanced).
* You can chain multiple transformers in one `kustomization.yaml`.
* Always preview with:

```bash
kustomize build <dir>
```

* Be aware: transformers **overwrite** existing values if same key exists.

---

## Lab

Assign the following annotation to all `nginx` and `monitoring` resources: `owner: bob@gmail.com`

```bash
controlplane ~/code/k8s ➜  cat nginx/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - nginx-depl.yaml
  - nginx-service.yaml

commonAnnotations:
  owner: bob@gmail.com
controlplane ~/code/k8s ➜  cat monitoring/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - grafana-depl.yaml
  - grafana-service.yaml

namespace: logging

commonAnnotations:
  owner: bob@gmail.com
```

Transform `all postgres` images in the **project** to `mysql`.

```bash
Since the requirement is to change all postgres images to mysql this means adding an image transformer to the root kustomization.yaml file.

controlplane ~/code/k8s ➜  cat kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - db/
  - monitoring/
  - nginx/

commonLabels:
  sandbox: dev

images:
  - name: postgress
    newName: mysql
```

Transform all `nginx` images in the **nginx directory** to `nginx:1.23`.

```bash
controlplane ~/code/k8s ➜  cat nginx/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - nginx-depl.yaml
  - nginx-service.yaml

commonAnnotations:
  owner: bob@gmail.com

images:
  - name: nginx
    newTag: "1.23"
```
