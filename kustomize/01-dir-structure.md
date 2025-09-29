# Chapter 1: Directory Structure in Kustomize

Kustomize organizes Kubernetes manifests in a **directory-based structure**, making it easier to manage multiple environments (e.g., development, staging, production) without duplicating YAML files. The three main directories used in Kustomize are:

---

## 1. Base

The **base** directory contains the common resources that are shared across all environments.

Typical contents of the base folder include:

* `kustomization.yaml` → The core file that defines which resources to include.
* Resource manifests → Such as `deployment.yaml`, `service.yaml`, `configmap.yaml`, etc.

The base acts as the foundation for all overlays and components. Any changes applied in overlays or components will reference this base.

---

## 2. Overlay

The **overlay** directory customizes the base configuration for specific environments (such as dev, staging, or prod).

Each overlay contains its own `kustomization.yaml` file, which usually:

* **References the base** (using `resources`).
* **Applies patches** (e.g., changing replica counts, environment variables, or image tags).
* **Adds extra manifests** that are needed only in that environment (such as an Ingress, Secrets, or environment-specific ConfigMaps).

This ensures that environment-unique resources are deployed only where needed and do not pollute the base configuration.

---

## 3. Components

The **components** directory is used for optional or reusable features that can be plugged into any overlay.

Examples of components:

* Adding monitoring tools (e.g., Prometheus sidecar).
* Applying specific security policies.
* Enabling/disabling certain features without affecting the entire base.

Each component also has its own `kustomization.yaml` file and can be referenced inside overlays.

---

## Why This Structure?

The folder structure in Kustomize is designed to solve a very common problem:
👉 Different environments (dev, staging, prod) often need slightly different configurations, but we don’t want to duplicate YAML files.

By separating **base**, **overlay**, and **components**:

* The **base** provides the shared foundation.
* The **overlay** adapts the base for environment-specific needs and adds unique manifests.
* The **components** provide reusable, optional features.

This makes Kustomize a powerful tool for environment management, ensuring DRY (Don’t Repeat Yourself) principles and better maintainability.

---

## Real-Time Example: Managing Multiple Environments

Imagine you are deploying a **web application** that has:

* A Deployment (for the app pods)
* A Service (to expose the app)

You need to run this app in three environments: **dev**, **staging**, and **prod**.

### Step 1: Folder Structure

```bash
my-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── dev-configmap.yaml        # only for dev
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── ingress.yaml              # only for staging
│   └── prod/
│       ├── kustomization.yaml
│       └── secret.yaml               # only for prod
```

---

### Step 2: Base Definition

**`base/deployment.yaml`**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: nginx:latest
          ports:
            - containerPort: 80
```

**`base/service.yaml`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

**`base/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
```

---

### Step 3: Overlays with Unique Manifests

#### Dev Overlay

**`overlays/dev/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base           # reference the base directory 
  - dev-configmap.yaml   # unique to dev, environment-specific manifest 

patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 1
```

**`overlays/dev/dev-configmap.yaml`**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-config
data:
  ENV: development
```

---

#### Staging Overlay

**`overlays/staging/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base     # reference the base directory 
  - ingress.yaml   # unique to staging

patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 2
```

**`overlays/staging/ingress.yaml`**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: staging-ingress
spec:
  rules:
    - host: staging.my-app.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

---

#### Prod Overlay

**`overlays/prod/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base    # reference the base directory
  - secret.yaml   # unique to prod

patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 5
```

**`overlays/prod/secret.yaml`**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: prod-secret
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQ=   # base64 encoded
```

---

### Step 4: Deploying with Kustomize

To deploy in **dev**:

```bash
kubectl apply -k overlays/dev
```

To deploy in **staging**:

```bash
kubectl apply -k overlays/staging
```

To deploy in **prod**:

```bash
kubectl apply -k overlays/prod
```

---

### Key Takeaway

* **Base** contains shared resources.
* **Overlays** not only patch the base but can also include **environment-specific manifests** (ConfigMaps, Ingress, Secrets, etc.).
* This approach avoids duplication while ensuring each environment gets exactly what it needs.
