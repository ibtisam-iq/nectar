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

### Key Takeaway

* **Base** contains shared resources.
* **Overlays** not only patch the base but can also include **environment-specific manifests** (ConfigMaps, Ingress, Secrets, etc.).
* This approach avoids duplication while ensuring each environment gets exactly what it needs.
