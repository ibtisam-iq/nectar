# Helm — Introduction

> **Purpose of this section:** give a clear, exam-oriented foundation for *what Helm is*, *why it exists*, and *which problems it solves*. Includes practical examples comparing raw `kubectl` manifests vs Helm usage, and a short hands‑on mini workflow you can run during CKA practice.

---

## 1.1 What is Helm?

**Helm** is the de-facto package manager for Kubernetes. A Helm *chart* is a packaged, versioned collection of Kubernetes resource templates (YAML) plus metadata and default configuration (values). Helm lets you install, upgrade, and manage applications and controllers on a cluster as *releases* (instances of charts).

Short metaphor: **Chart = recipe**, **Release = meal you cooked from that recipe**, **Repo = cookbook store**.

---

## 1.2 Key concepts (quick reference)

* **Chart** — A package (directory or `.tgz`) containing `Chart.yaml`, `values.yaml`, and `templates/` (K8s manifests as templates).
* **Release** — A deployed instance of a chart in the cluster identified by a release name.
* **Repository (repo)** — A web-hosted index + collection of packaged charts (e.g. Bitnami, stable repos).
* **Values** — Configuration values (`values.yaml`) used to fill templates. Overridable at install/upgrade.
* **Templates** — Go-template formatted YAML files under `templates/` that expand into k8s manifests using `.Values`, `.Release`, and built-in functions.

---

## 1.3 Why Helm? — problems it solves

Helm solves a bunch of practical problems that become painful if you only use raw static YAML and `kubectl`:

1. **Managing many manifests**

   * Real apps often require Deployments, Services, ConfigMaps, Secrets, Ingress, RBAC, CRDs — dozens of files. Helm packages them and deploys as one logical unit (release).

2. **Parameterization & reuse**

   * Use `values.yaml` to change image tags, replica counts, resource requests, environment-specific configuration without editing templates.

3. **Versioning & upgrades**

   * Charts are versioned. `helm upgrade` applies changes in an ordered, trackable way. `helm rollback` returns to a previous release version.

4. **Dependency management**

   * Charts can declare subcharts and dependencies (e.g., an app that needs a database chart). Helm fetches and templates dependencies.

5. **Repeatability across environments**

   * Keep a base chart and feed different `values-` files per environment (dev/test/prod) to get reproducible installs.

6. **Ecosystem & community charts**

   * You can quickly install vetted operators and applications (ingress controllers, cert-manager, Prometheus) from public repos.

7. **Safe deployments & rollback-friendly changes**

   * With flags like `--wait` and built-in revision history, Helm reduces manual error-prone steps and helps recover from bad upgrades.

8. **Templating & logic**

   * Use conditionals and loops in templates so a single chart can support many deployment shapes.

---

## 1.4 What Helm DOES NOT replace

* Helm does **not** replace `kubectl` — you still use `kubectl` to inspect objects, debug pods, or apply low-level changes.
* Helm does **not** change Kubernetes primitives — it generates them from templates.
* For trivial single-file manifests, Helm is often overkill.

---

## 1.5 Quick examples — show the difference (raw YAML vs Helm)

### Example A — Deploy a simple nginx using raw `kubectl` manifests

`nginx-deployment.yaml` (simple snippet):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25.3
        ports:
        - containerPort: 80
```

Install with:

```bash
kubectl apply -f nginx-deployment.yaml
```

To change image or replicas you must edit the file (or `kubectl set image` / `kubectl scale`) — manual and error-prone across environments.

---

### Example B — Install nginx via Helm (chart from repo)

Commands:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx
helm install my-nginx bitnami/nginx
```

Why this is better:

* Single command fetches and deploys all required objects.
* You can override defaults using `--set` or `-f` (see next):

```bash
helm install my-nginx bitnami/nginx --set service.type=NodePort --set replicaCount=3
```

* The release `my-nginx` contains versioned state, so upgrades and rollback become straightforward:

```bash
helm upgrade my-nginx bitnami/nginx --set image.tag=1.26.0
helm rollback my-nginx 1  # rollback to revision 1
```

---

### Example C — Create & install your own chart (local app)

Create skeleton:

```bash
helm create myapp
```

This creates `myapp/` with `Chart.yaml`, `values.yaml` and `templates/`.

`values.yaml` (example):

```yaml
replicaCount: 1
image:
  repository: nginx
  tag: 1.25.3
service:
  type: ClusterIP
  port: 80
```

Install locally:

```bash
helm install myapp-release ./myapp
# Verify
kubectl get deployments,svc
```

Update values and upgrade:

```bash
# change replicas or image tag quickly without editing templates
helm upgrade myapp-release ./myapp --set replicaCount=3 --set image.tag=1.26.0
```

Rollback if needed:

```bash
helm rollback myapp-release 1
```

---

## 1.6 Mini hands-on workflow (practice sequence for CKA)

1. `helm repo add bitnami https://charts.bitnami.com/bitnami`
2. `helm repo update`
3. `helm search repo nginx`
4. `helm install test-nginx bitnami/nginx --set replicaCount=2`
5. `kubectl get pods -l app.kubernetes.io/name=nginx` (verify)
6. `helm upgrade test-nginx bitnami/nginx --set replicaCount=3`
7. `kubectl get pods` (verify new pods)
8. `helm rollback test-nginx 1`
9. `helm uninstall test-nginx`

Practice these commands until you can run them quickly without looking them up.

---

## 1.7 Short ASCII flow diagram

```
   Chart (templates + values)  <--- packaged (.tgz) --->  Repo (index.yaml + .tgz files)
              |                                          /
              | helm install                            / helm repo add + helm install
              v                                         /
         Release (name + revision history)  --->  Kubernetes objects (Deployment, Service, ...)
                         |
                         `-- helm upgrade / helm rollback / helm uninstall
```

---

## 1.8 Common exam tips (CKA)

* Practice `helm install`, `helm upgrade`, `helm rollback`, and `helm uninstall` until muscle memory forms.
* Use `helm template` to render manifests locally when you want to inspect what Helm will apply (useful during the exam if `kubectl apply -f -` is faster).
* If you need time-critical installs, prefer well-known chart repos (Bitnami, ingress-nginx) — but remember repo URLs may change in real life; in the exam use repo names/URLs provided by the task.
* Use `--dry-run --debug` when testing a change locally.

---
