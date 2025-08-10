# Helm — Introduction, Architecture & Package Manager

> **Purpose:** Cover what Helm is, why it exists, how it works (Helm v3), and a deep, hands‑on, step‑by‑step guide to using Helm as a **package manager** — searching, adding/removing repos, installing from repos, pulling and installing locally, and installing specific chart versions. Includes practical examples and CKA-oriented tips.

---

## 1. Introduction to Helm (recap)

### 1.1 What is Helm?

Helm is the de-facto package manager for Kubernetes. A Helm **chart** is a packaged, versioned collection of Kubernetes resource **templates** plus metadata and a `values.yaml` file. Helm lets you install, upgrade, and manage charts as **releases** (instances) in your cluster.

**Metaphor:** Chart = recipe, Release = cooked meal, Repo = cookbook store.

### 1.2 Why Helm?

Helm solves common pain points of managing Kubernetes apps:

* Bundles many manifests into one logical unit
* Parameterizes configuration with `values.yaml`
* Provides versioned upgrades + rollbacks
* Manages chart dependencies (subcharts)
* Enables repeatable installs across environments
* Quick installs from community repos (Ingress, cert-manager, Prometheus)

---

## 2. Helm Architecture (brief)

* **Helm v3** is client-side only (no Tiller). The Helm CLI renders templates and talks directly to the Kubernetes API.
* Release metadata (revisions) is stored **in-cluster as Secrets** named `sh.helm.release.v1.<release>.v<revision>`.
* This storage enables `helm history`, `helm rollback`, and `helm list`.

Check release secrets:

```bash
kubectl get secrets -n <ns> | grep sh.helm.release
kubectl get secret sh.helm.release.v1.my-release.v1 -o yaml -n <ns>
```

---

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

