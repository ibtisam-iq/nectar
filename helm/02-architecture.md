# Helm — Introduction & Architecture

> **Purpose:** Cover what Helm is, why it exists, and how it works under the hood (Helm v3 architecture). Includes practical examples, diagrams, and exam-oriented notes.

---

## 1. Introduction to Helm

### 1.1 What is Helm?

Helm is the package manager for Kubernetes. It bundles Kubernetes manifests into a single unit called a **chart**, enabling you to install, upgrade, and manage complex apps and controllers as single entities called **releases**.

**Metaphor:** Chart = recipe, Release = cooked meal, Repo = cookbook store.

### 1.2 Why Helm?

Helm solves:

* Managing many YAML manifests at once
* Reusing configs across environments with values files
* Easy upgrades and rollbacks
* Chart dependencies (subcharts)
* Reproducible deployments
* Installing from public repos quickly (e.g., ingress-nginx, cert-manager)

Example (install nginx):

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-nginx bitnami/nginx --set replicaCount=3
```

### 1.3 Chart vs Release vs Repo

* **Chart:** Template + values packaged as `.tgz`
* **Release:** An instance of a chart deployed to the cluster
* **Repo:** A collection of charts + index.yaml

---

## 2. Helm Architecture

### 2.1 Helm v2 vs v3

* **Helm v2:** Used server-side component *Tiller* to install charts; required cluster-admin rights.
* **Helm v3:** No Tiller. Everything is client-side, interacts directly with the Kubernetes API.

### 2.2 How Helm v3 Works (Step-by-Step)

1. **You run a Helm command** (e.g., `helm install myapp ./chart`).
2. **Helm client loads the chart** (local or from repo).
3. **Templates are rendered** using `values.yaml` + any overrides.
4. **Rendered YAML manifests** are sent to the Kubernetes API server.
5. **Kubernetes creates resources** (Deployments, Services, etc.).
6. **Release info is stored** in the cluster in a Secret inside the release’s namespace.

### 2.3 Where Helm Stores Data

* In **v3**, Helm stores release metadata as a **Secret** (type: `helm.sh/release.v1`) in the same namespace as the release.
* Naming format: `sh.helm.release.v1.<release-name>.v<revision>`
* This allows `helm list`, `helm rollback`, and `helm history` to work.

Check stored releases:

```bash
kubectl get secrets -n <namespace> | grep sh.helm.release
```

Inspect a release Secret:

```bash
kubectl get secret sh.helm.release.v1.my-nginx.v1 -o yaml
```

### 2.4 Diagram — Helm Workflow (v3)

```
Helm CLI (templates + values)
   |
   | render templates
   v
Kubernetes API Server
   |
   v
Cluster resources created (Pods, Svc, ConfigMaps)
   |
   v
Release metadata stored as Secret in namespace
```

### 2.5 Exam Tips for Architecture

* Know that **no Tiller exists in v3**.
* Understand that `helm history` works because Helm stores all revisions in Secrets.
* If `helm rollback` fails, check if the previous revision’s Secret still exists.
* Remember: Helm talks to K8s API just like `kubectl`.
