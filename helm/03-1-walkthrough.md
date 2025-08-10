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
