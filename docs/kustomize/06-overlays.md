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
# Warning: 'bases' is deprecated. Please use 'resources' instead.
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

👉 In summary: Overlays are the main feature of Kustomize for managing **multiple environments**.
They let you extend or override base configurations while keeping everything centralized and maintainable.
