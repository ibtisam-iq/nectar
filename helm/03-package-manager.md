# Helm — Introduction, Architecture & Package Manager

> **Purpose:** Cover what Helm is, why it exists, how it works (Helm v3), and a deep, hands‑on, step‑by‑step guide to using Helm as a **package manager** — searching, adding/removing repos, installing from repos, pulling and installing locally, and installing specific chart versions. Includes practical examples and CKA-oriented tips.

---
## Section 1

## 1. Introduction to Helm

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

### 1.9 Chart vs Release vs Repo [Recap]

* **Chart:** Template + values packaged as `.tgz`
* **Release:** An instance of a chart deployed to the cluster
* **Repo:** A collection of charts + index.yaml

---

## Section 2 

## Helm Architecture

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

---

## Section 3

## 3. Helm as a Package Manager (Pre-Built Charts)

**Goal:** Learn every way to find and install pre-built charts: searching Artifact Hub (the global index), adding repos, searching locally, installing from repos, pulling and installing locally, and installing a particular version.

### 3.1 Use cases & when to use this flow

* You want to install a community-maintained application or controller (ingress controller, cert-manager, metrics stack).
* You need a quick, repeatable way to deploy complex apps (many manifests) with sensible defaults.
* You want to manage upgrades using `helm upgrade` and keep revision history.

### 3.2 Two kinds of searches

* **Search the Hub (global) — `helm search hub`**

  * Searches Artifact Hub (artifacthub.io) for charts across many publishers.
  * Use this when you don't know which repo provides a chart or want to explore options.
  * Note: Artifact Hub is a **search index**, not a chart repository you can `helm repo add` directly. Find the repo URL on Artifact Hub and then add it to your Helm client.

  Example:

  ```bash
  helm search hub ingress-nginx
  # returns matching charts and the repository URL to add
  ```

* **Search local repos — `helm search repo`**

  * Searches only the repos you've already added to your Helm client (the local cache).
  * Always run `helm repo update` before searching if you want the latest index.

  Example:

  ```bash
  helm repo update
  helm search repo nginx
  # shows results like bitnami/nginx and repo/chartName in NAME column
  ```

### 3.3 Add a repository (`helm repo add`)

**Purpose:** Tell Helm where to find charts.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

* After adding, refresh your local cache:

```bash
helm repo update
```

* Verify repos:

```bash
helm repo list
# NAME           URL
# bitnami        https://charts.bitnami.com/bitnami
# ingress-nginx  https://kubernetes.github.io/ingress-nginx
```

**Exam tip:** If a task gives you a repo URL, `helm repo add` it and `helm repo update` before installing.

### 3.4 Search inside added repos (`helm search repo`)

* Syntax: `helm search repo <keyword>`
* The **NAME** column is `repo-name/chart-name` — this tells you exactly which repo contains the chart.

Example:

```bash
helm search repo nginx
# NAME                       CHART VERSION   APP VERSION DESCRIPTION
# bitnami/nginx              15.5.2          1.25.3      Nginx Open Source web server
```

You can also search a specific repo by prefixing the chart name:

```bash
helm search repo bitnami/nginx
```

### 3.5 Install directly from a repo (`helm install`)

**Most common command:**

```bash
helm install <release-name> <repo-name/chart> [flags]
```

Examples:

```bash
helm install my-nginx bitnami/nginx
# or with overrides and namespace
helm install my-nginx bitnami/nginx --namespace web --create-namespace --set replicaCount=3
```

**Install a specific chart version:**

```bash
helm install my-nginx bitnami/nginx --version 15.5.2
```

* `--version` picks a particular chart version from the repo (semver). If omitted, Helm uses the latest *stable* chart.
* Use `--devel` if you want pre-release versions (alpha/beta/rc) included in search & install results.

**Note:** Always run `helm repo update` if you expect a newly-published chart version to be available.
Yes — that’s correct in Helm terminology.

#### Breakdown:

* **bitnami** → **Repository name** (an alias you add when you run `helm repo add bitnami https://charts.bitnami.com/bitnami`)
* **nginx** → **Chart name** (the name of the package containing NGINX’s Kubernetes manifests)
* **bitnami/nginx** → **Chart reference** (repository alias + chart name)

When you install it:

```bash
helm install my-release bitnami/nginx
```

Helm looks inside the `bitnami` repo for the `nginx` chart.

### 3.6 Installing from a local chart directory

* Use this when you created or modified a chart locally (e.g., `helm create myapp`).

```bash
helm create myapp      # creates chart skeleton
helm install myapp-release ./myapp
```

* Upgrades work the same way:

```bash
# change values or templates, then
helm upgrade myapp-release ./myapp --Set image.tag=1.26.0
```

### 3.7 Pulling a chart and installing locally (`helm pull`)

* Use `helm pull` to download a packaged chart without installing it (good for inspection, auditing, or offline installs).

```bash
helm pull bitnami/redis            # downloads redis-<version>.tgz
helm pull bitnami/redis --untar    # downloads and untars into ./redis/
helm pull bitnami/redis --version 14.3.0 --untar
```

* After `--untar`, you can tweak values or templates then install from the unpacked directory:

```bash
cd redis
# optionally edit values.yaml
helm install redis-local ./redis -f ./redis/values.yaml
```

**Why pull?**

* Inspect the chart's templates and `values.yaml` before installing.
* Modify values or templates locally if you need custom behavior before installing.

### 3.8 Installing from a packaged chart (`.tgz`) or URL

* Package a chart:

```bash
helm package ./myapp
# produces myapp-0.1.0.tgz
```

* Install from the package file:

```bash
helm install myapp-release ./myapp-0.1.0.tgz
```

* You can also install directly from a URL pointing to a `.tgz` file:

```bash
helm install myapp-release https://my-cdn.example.com/charts/myapp-0.1.0.tgz
```

### 3.9 Upgrading & installing specific versions (`helm upgrade` + `--version`)

* Upgrade using the same chart reference (repo/chart) or local path:

```bash
helm upgrade my-nginx bitnami/nginx --set replicaCount=4
# or to force a chart version on upgrade
helm upgrade my-nginx bitnami/nginx --version 16.0.0
```

* `helm upgrade --install` can be used to install if the release does not exist (idempotent automation).

**Exam tip:** If you need to install a particular chart version during the exam, use `--version` and `helm repo update` first.

### 3.10 Removing a repo (`helm repo remove`)

* To remove one or more repos from your Helm client:

```bash
helm repo remove bitnami
# or the alias
helm repo rm bitnami
```

Check with:

```bash
helm repo list
```

### 3.11 Useful companion commands

* `helm repo update` — refresh local index cache.
* `helm show values repo/chart` — view default `values.yaml` of a chart without pulling.
* `helm template repo/chart` — render manifests locally (dry-run style) without installing.
* `helm list` / `helm list --all-namespaces` — list releases.
* `helm status <release>` — see release info.
* `helm history <release>` — view revision history.
* `helm uninstall <release>` — remove a release.

### 3.12 Step-by-step Practice Flow (CKA-friendly)

1. Search Hub to find candidate charts:

   ```bash
   helm search hub ingress-nginx
   ```
2. Add the repo you picked from Artifact Hub:

   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   ```
3. Search your added repos for the exact chart name:

   ```bash
   helm search repo ingress-nginx
   ```
4. (Optional) Pull and inspect the chart locally:

   ```bash
   helm pull ingress-nginx/ingress-nginx --untar
   ls ingress-nginx/
   cat ingress-nginx/values.yaml
   ```
5. Install from repo with overrides and namespace creation:

   ```bash
   helm install test-ingress ingress-nginx/ingress-nginx --namespace ingress --create-namespace --set controller.replicaCount=2
   ```
6. Verify workload:

   ```bash
   kubectl get pods -n ingress
   ```
7. Upgrade with a specific chart version or new values:

   ```bash
   helm upgrade test-ingress ingress-nginx/ingress-nginx --version 5.0.0 --set controller.replicaCount=3
   ```
8. Rollback if needed:

   ```bash
   helm rollback test-ingress 1
   ```
9. Clean up:

   ```bash
   helm uninstall test-ingress -n ingress
   helm repo remove ingress-nginx
   ```

### 3.13 Common pitfalls & exam tips

* **Cache stale results:** If `helm search repo` doesn’t show a newly-published chart, run `helm repo update`.
* **Artifact Hub is search-only:** You still need to `helm repo add` the chart’s repo URL found on Artifact Hub.
* **Version selection:** `--version` selects the chart package version from the repo. If you need to work offline or patch a chart, `helm pull --untar` then install from the local directory.
* **Namespace traps:** `helm install` uses the current namespace by default (or `--namespace`). Use `--create-namespace` during exams if you’re not sure the namespace exists.
* **`helm upgrade --install` + `--version`:** Use carefully in automation — prefer explicit `helm repo update` then `helm install`/`helm upgrade`.

---

