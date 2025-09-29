# Kustomize Components

We have already seen how **bases** define reusable core resources and how **overlays** extend them for environment-specific use cases.
But sometimes overlays alone are not enough. This is where **components** come in.

---

## Why Components?

Overlays are designed to represent **environments** (e.g., dev, staging, prod).
But in real-world scenarios, we also need to manage **optional features** that may or may not be enabled, regardless of the environment.

For example:

* Enabling **monitoring** with Prometheus/Grafana.
* Adding **service mesh sidecars**.
* Applying **network policies** only in certain deployments.

Instead of duplicating this logic in each overlay, Kustomize introduced **components** to keep such reusable, optional features separate.

---

## What Is a Component?

* A **component** is like a mini-base, but it cannot stand alone.
* It must be combined with a base or an overlay.
* Inside a component, you define a `kustomization.yaml` that may contain:

  * Resources
  * Patches
  * Transformers
* However, unlike overlays, a component is not tied to a specific environment — it represents a **feature toggle**.

---

## Example Directory Structure

```
my-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
└── components/
    ├── monitoring/
    │   ├── grafana.yaml
    │   └── kustomization.yaml
    └── network-policy/
        ├── netpol.yaml
        └── kustomization.yaml
```

---

## Example Component `kustomization.yaml`

**`components/monitoring/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - grafana.yaml
```

Notice:

* The `kind` is **`Component`**, not `Kustomization`.
* This makes it different from bases and overlays.

---

## Using Components in an Overlay

To enable a component, reference it inside the overlay’s `kustomization.yaml`:

**`overlays/prod/kustomization.yaml`**

```yaml
resources:
  - ../../base

components:
  - ../../components/monitoring
  - ../../components/network-policy
```

Here:

* The **base** defines the core app.
* The **prod overlay** pulls in the base.
* Then **components** add monitoring and network policy features on top.

---

## Key Points About Components

* They solve the problem of **optional features** that overlays alone cannot handle.
* Defined with `kind: Component` instead of `kind: Kustomization`.
* Must always be used **with a base or overlay**; they cannot be deployed directly.
* They keep features modular, reusable, and composable across multiple environments.

---

## Kustomize Components – Real World Case Study

To understand components more clearly, let’s walk through a real-world case.

### Scenario

We have a web application that needs to run in **development** and **production**.
Both environments share the same base (Deployment + Service).

* **Development** should remain lightweight, without any additional overhead.
* **Production** must include:

  * **Monitoring** (Grafana)
  * **Network Policies** for security

Instead of duplicating this configuration inside the production overlay, we define these features as **components**.

---

### Directory Structure

```
my-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
└── components/
    ├── monitoring/
    │   ├── grafana.yaml
    │   └── kustomization.yaml
    └── network-policy/
        ├── netpol.yaml
        └── kustomization.yaml
```

---

### Base `kustomization.yaml`

**`base/kustomization.yaml`**

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

---

### Component Example – Monitoring

**`components/monitoring/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - grafana.yaml
```

---

### Component Example – Network Policy

**`components/network-policy/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - netpol.yaml
```

---

### Overlay – Development

**`overlays/dev/kustomization.yaml`**

```yaml
resources:
  - ../../base
```

* Uses only the base.
* No additional monitoring or network policies.

---

### Overlay – Production

**`overlays/prod/kustomization.yaml`**

```yaml
resources:
  - ../../base

components:
  - ../../components/monitoring
  - ../../components/network-policy
```

* Reuses the base app.
* Adds monitoring and network policy components.

---

### Deployment Commands

```bash
# Deploy development
kubectl apply -k overlays/dev

# Deploy production
kubectl apply -k overlays/prod
```

---

### Outcome

* **Development** → App runs with only Deployment and Service.
* **Production** → App runs with Deployment, Service, Grafana, and Network Policies.

This shows how components make it possible to **mix and match optional features** without duplicating configurations across overlays.

---

👉 In summary:

* **Overlays** handle environment differences.
* **Components** handle optional, reusable features.
* Together, they give maximum flexibility in managing Kubernetes manifests.

---

## Lab

- What `components` are enabled in the `community` overlay?  **auth**
- What `components` are enabled in the `dev` overlay?        **auth,db,logging**
- How many `environment variables` does the `db` component add to the `api-deployment`? **2**
- What is the name of the `secret generator` created in the `db` component? **db-creds**
- Please add the `logging` component to the `community` overlay.

```bash
controlplane ~/code/project_mercury ➜  tree
.
├── base
│   ├── api-depl.yaml
│   ├── api-service.yaml
│   └── kustomization.yaml
├── components
│   ├── auth
│   │   ├── api-patch.yaml
│   │   ├── keycloak-depl.yaml
│   │   ├── keycloak-service.yaml
│   │   └── kustomization.yaml
│   ├── db
│   │   ├── api-patch.yaml
│   │   ├── db-deployment.yaml
│   │   ├── db-service.yaml
│   │   └── kustomization.yaml
│   └── logging
│       ├── kustomization.yaml
│       ├── prometheus-depl.yaml
│       └── prometheus-service.yaml
└── overlays
    ├── community
    │   └── kustomization.yaml
    ├── dev
    │   └── kustomization.yaml
    └── enterprise
        └── kustomization.yaml

9 directories, 17 files

controlplane ~/code/project_mercury ➜  cat overlays/community/kustomization.yaml 
bases:
  - ../../base

components:
  - ../../components/auth

controlplane ~/code/project_mercury ➜  cat overlays/dev/kustomization.yaml 
bases:
  - ../../base

components:
  - ../../components/auth
  - ../../components/db
  - ../../components/logging

controlplane ~/code/project_mercury ➜  cat components/db/api-patch.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    spec:
      containers:
        - name: api
          env:
            - name: DB_CONNECTION
              value: postgres-service
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-creds
                  key: password

controlplane ~/code/project_mercury ➜  cat components/db/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - db-deployment.yaml
  - db-service.yaml

secretGenerator:
  - name: db-creds
    literals:
      - password=password1

patches:
  - path: api-patch.yaml

controlplane ~/code/project_mercury ➜  cat overlays/community/kustomization.yaml 
resources:
  - ../../base

components:
  - ../../components/auth
  - ../../components/logging

controlplane ~/code/project_mercury ➜  
```

A new `caching` component needs to be created for the application.

There is already a directory located at: `project_mercury/components/caching/`

This directory contains the following files:

- redis-depl.yaml
- redis-service.yaml
  
Finish setting up this component by creating a `kustomization.yaml` file in the same directory and importing the above Redis configuration files.

```bash
controlplane ~/code/project_mercury ➜  tree components/caching/
components/caching/
├── kustomization.yaml
├── redis-depl.yaml
└── redis-service.yaml

0 directories, 3 files

controlplane ~/code/project_mercury ➜  cat components/caching/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - redis-depl.yaml
  - redis-service.yaml
controlplane ~/code/project_mercury ➜ 
```

With the database setup for the `caching` component complete, we now need to update the `api-deployment` so that it can connect to the Redis instance.

Create a **Strategic Merge Patch** to add the following environment variable to the container in the deployment:

- Name: REDIS_CONNECTION
- Value: redis-service

Note:

The patch file must be created at: `project_mercury/components/caching/ with name api-patch.yaml`

After creating the patch file, you must also update the `kustomization.yaml` file in the same directory (`components/caching/`) to include this patch under the patches field.

```bash
controlplane ~/code/project_mercury ➜  tree components/caching/
components/caching/
├── api-patch.yaml
├── kustomization.yaml
├── redis-depl.yaml
└── redis-service.yaml

0 directories, 4 files

controlplane ~/code/project_mercury ➜  cat components/caching/api-patch.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    spec:
      containers:
        - name: api
          env:
          - name: REDIS_CONNECTION
            value: redis-service

controlplane ~/code/project_mercury ➜  cat components/caching/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
  - redis-depl.yaml
  - redis-service.yaml
patches:
# - api-patch.yaml             # wrong 
  - path: api-patch.yaml 
```

Finally, let's add the `caching` component to the `Enterprise` edition of the application.

```bash
controlplane ~/code/project_mercury ➜  cat overlays/enterprise/kustomization.yaml 
bases:
  - ../../base

components:
  - ../../components/auth
  - ../../components/db
  - ../../components/caching

controlplane ~/code/project_mercury ➜  kubectl apply -k /root/code/project_mercury/overlays/enterprise
# Warning: 'bases' is deprecated. Please use 'resources' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
secret/db-creds-dd6525th4g created
service/api-service unchanged
service/keycloak-service unchanged
service/postgres-service created
service/redis-service created
deployment.apps/api-deployment configured
deployment.apps/keycloak-deployment unchanged
deployment.apps/postgres-deployment created
deployment.apps/redis-deployment created

controlplane ~/code/project_mercury ➜  
```
