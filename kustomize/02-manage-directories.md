# Case Study – Managing Directories with and without Kustomize

Sometimes we only want to organize multiple Kubernetes manifests into a single directory and deploy them together, without adding overlays, patches, or transformers.
This is where **Kustomize’s Managing Directories feature** is useful.

In this case study, we will explore different approaches for managing directories, starting from plain Kubernetes commands (without Kustomize) and then moving to more structured setups with Kustomize.

---

## 1. Without Kustomize

### Option A – Apply Files One by One

If you only have a few manifests, you can directly apply them individually:

```bash
kubectl apply -f api-deploy.yaml
kubectl apply -f api-service.yaml
kubectl apply -f db-deploy.yaml
kubectl apply -f db-service.yaml
```

This works, but quickly becomes unmanageable when the number of files increases.

---

### Option B – Apply a Directory

Instead of applying files one by one, you can place all manifests inside a single directory and apply them together:

```bash
my-app/
├── api-deploy.yaml
├── api-service.yaml
├── db-deploy.yaml
└── db-service.yaml
```

Now you can run:

```bash
kubectl apply -f ./my-app
```

This applies all manifests in the directory at once.
However, this approach has limitations — you cannot easily manage different environments (staging, prod, etc.) or modularize the structure.

---

## 2. With Kustomize

Kustomize provides two ways to manage manifests more efficiently.

---

### Option A – Single `kustomization.yaml` in a Directory

You create a single `kustomization.yaml` that lists all resources:

```bash
my-app/
├── api-deploy.yaml
├── api-service.yaml
├── db-deploy.yaml
├── db-service.yaml
└── kustomization.yaml
```

**kustomization.yaml**

```yaml
resources:
  - api-deploy.yaml
  - api-service.yaml
  - db-deploy.yaml
  - db-service.yaml
```

Deploy with:

```bash
kubectl apply -k ./my-app
```

This already improves maintainability by making deployments declarative and reusable.

---

### Option B – Nested `kustomization.yaml` (Modular / Pro Version)

As the app grows, you may want to organize resources into sub-directories, each with its own `kustomization.yaml`. Then a top-level file combines them.

**Directory structure:**

```bash
my-app/
├── api/
│   ├── api-deploy.yaml
│   ├── api-service.yaml
│   └── kustomization.yaml
├── db/
│   ├── db-deploy.yaml
│   ├── db-service.yaml
│   └── kustomization.yaml
└── kustomization.yaml   # top-level
```

**api/kustomization.yaml**

```yaml
resources:
  - api-deploy.yaml
  - api-service.yaml
```

**db/kustomization.yaml**

```yaml
resources:
  - db-deploy.yaml
  - db-service.yaml
```

**top-level kustomization.yaml**

```yaml
resources:
  - ./api
  - ./db
```

Deploy everything with:

```bash
kubectl apply -k ./my-app
```

---

## Conclusion

* **Without Kustomize:**

  * You can either apply manifests one by one or apply an entire directory at once.
* **With Kustomize:**

  * You can manage manifests more systematically using `kustomization.yaml`.
  * Either put all manifests under one `kustomization.yaml` or go modular with sub-directories for better scalability.

This layered approach makes it easier to maintain, scale, and manage different environments in Kubernetes.
