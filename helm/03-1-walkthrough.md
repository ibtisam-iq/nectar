# Helm — Introduction & Architecture

## Section 1: Why Helm & the Challenges It Solves

*(Already covered in detail — package management, complexity reduction, YAML templating, upgrades, rollbacks)*

## Section 2: Helm Architecture

*(Already covered — Helm client, tiller removal in v3, release storage in Secrets/ConfigMaps)*

## Section 3: Helm as a Package Manager

### 3.1 Searching from Artifact Hub

```bash
helm search hub nginx
```

Shows charts from the public Helm hub.

### 3.2 Adding a Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

### 3.3 Searching Inside a Repo

```bash
helm search repo nginx
```

### 3.4 Listing All Repositories

```bash
helm repo list
```

### 3.5 Removing a Repository

```bash
helm repo remove bitnami
```

### 3.6 Installing Directly from a Repo

```bash
helm install my-nginx bitnami/nginx
```

### 3.7 Installing Specific Version

```bash
helm install my-nginx bitnami/nginx --version 13.2.4
```

### 3.8 Pulling & Untarring a Chart

```bash
helm pull bitnami/nginx --untar
helm install my-nginx ./nginx
```

---

## 3.9 **Full Walkthrough — Installing Ingress-NGINX from Start to Finish**

### Step 1: Search from Artifact Hub

```bash
helm search hub ingress-nginx
```

Find the official ingress-nginx chart (maintained by Kubernetes).

### Step 2: Add the Official Repo

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

### Step 3: Update Repos (Always Do Before Installing)

```bash
helm repo update
```

### Step 4: Search in the Repo

```bash
helm search repo ingress-nginx
```

### Step 5: Install Latest Version

```bash
helm install my-ingress ingress-nginx/ingress-nginx
```

### Step 6: Verify Installation

```bash
kubectl get pods -n default
```

### Step 7: Upgrade to a Specific Version

```bash
helm upgrade my-ingress ingress-nginx/ingress-nginx --version 4.10.0
```

### Step 8: Uninstall When Done

```bash
helm uninstall my-ingress
```

**Exam Tip:** Always check `helm repo list` to confirm which repo Helm is pulling from, especially if you have multiple repos containing charts with the same name.

---

## Section 4: Creating & Managing Your Own Application Chart

### 4.1 Create a New Chart

```bash
helm create myapp
```

This generates a standard Helm chart folder structure with templates, values.yaml, and Chart.yaml.

### 4.2 Understand the Structure

* **Chart.yaml** → Metadata (name, version, description)
* **values.yaml** → Default configuration values
* **templates/** → Kubernetes manifest templates (Deployment, Service, etc.)
* **charts/** → Dependency charts
* **.helmignore** → Ignore files during packaging

### 4.3 Install Your Local Chart

```bash
helm install myapp ./myapp
```

### 4.4 Upgrade Your Chart

```bash
helm upgrade myapp ./myapp
```

### 4.5 Package Your Chart

```bash
helm package myapp
```

Produces a `.tgz` file for sharing or uploading to a Helm repository.

### 4.6 Push to a Repository (Example with ChartMuseum)

```bash
helm repo add myrepo https://mychartrepo.example.com
helm push myapp-0.1.0.tgz myrepo
```

### 4.7 Using Custom Values

```bash
helm install myapp ./myapp -f custom-values.yaml
```

Overrides default values in `values.yaml`.

### 4.8 Debugging Templates

```bash
helm template ./myapp
```

Renders the manifests locally without installing.

**Exam Tip:** Expect tasks requiring you to modify `values.yaml` to change application behavior, package and install a local chart, and perform upgrades with zero downtime.

