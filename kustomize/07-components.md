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
