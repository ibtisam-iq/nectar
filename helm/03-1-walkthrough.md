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

---

## 5. Chart Values & Customization

In Helm, **values** define the customizable configuration for a chart. This section explains how to work with `values.yaml` files, override defaults, and use multiple values files.

---

### 5.1 Understanding `values.yaml`

* Each chart has a **default `values.yaml`** inside its chart directory.
* It stores default configuration parameters like replica counts, image versions, service types, etc.

Example from `nginx` chart:

```yaml
replicaCount: 2
image:
  repository: nginx
  tag: 1.21
service:
  type: ClusterIP
  port: 80
```

---

### 5.2 Overriding Values at Install Time

You can override values from `values.yaml` without editing the file.

**Option 1 — Inline `--set` flag:**

```bash
helm install mynginx bitnami/nginx --set replicaCount=3,image.tag=1.23
```

**Option 2 — Custom values file:**

```bash
# custom-values.yaml
replicaCount: 4
image:
  tag: 1.22
```

```bash
helm install mynginx bitnami/nginx -f custom-values.yaml
```

---

### 5.3 Using Multiple Values Files

When using multiple `-f` flags, Helm merges them in order — later files override earlier ones.

```bash
helm install myapp ./mychart -f base.yaml -f prod.yaml
```

---

### 5.4 Viewing Effective Values

To see what values were applied to a release:

```bash
helm get values mynginx
```

To see all values, including defaults:

```bash
helm get values mynginx --all
```

---

### 5.5 Updating Values After Installation

You can change values without reinstalling:

```bash
helm upgrade mynginx bitnami/nginx -f new-values.yaml
```

Or with inline:

```bash
helm upgrade mynginx bitnami/nginx --set replicaCount=5
```

---

### 5.6 Real-World Example — Changing NGINX Service Type

1. Install with default `ClusterIP`:

```bash
helm install mynginx bitnami/nginx
```

2. Change service type to `LoadBalancer`:

```bash
helm upgrade mynginx bitnami/nginx --set service.type=LoadBalancer
```

3. Verify:

```bash
kubectl get svc
```

---

**Exam Tip:** Be comfortable switching between `--set` and `-f` methods quickly, and remember `helm get values` for troubleshooting.
---

## Section 6 — Upgrading, Rolling Back & Uninstalling Releases

### 6.1 **Why This Matters**

Managing the lifecycle of a Helm release involves not just installing charts, but also upgrading them to newer versions, rolling back if issues occur, and cleanly uninstalling when no longer needed. In production, this is critical to ensure smooth application updates and minimize downtime.

---

### 6.2 **Upgrading a Release**

**Syntax:**

```bash
helm upgrade <release_name> <chart> [flags]
```

* `release_name`: The existing release to upgrade.
* `<chart>`: Chart reference (repo/chart, local path, or URL).

**Example:**

```bash
helm upgrade my-nginx bitnami/nginx --version 15.2.3
```

* Here, we are upgrading the `my-nginx` release to the `15.2.3` chart version.

**Using values during upgrade:**

```bash
helm upgrade my-nginx bitnami/nginx -f custom-values.yaml
```

* Applies the custom configuration during upgrade.

**Dry-run before upgrading:**

```bash
helm upgrade my-nginx bitnami/nginx --dry-run --debug
```

---

### 6.3 **Rolling Back a Release**

**Syntax:**

```bash
helm rollback <release_name> [revision] [flags]
```

* If `[revision]` is omitted, Helm rolls back to the previous revision.

**Example:**

```bash
helm rollback my-nginx 2
```

* Rolls back `my-nginx` to revision 2.

**Listing release history:**

```bash
helm history my-nginx
```

---

### 6.4 **Uninstalling a Release**

**Syntax:**

```bash
helm uninstall <release_name> [flags]
```

**Example:**

```bash
helm uninstall my-nginx
```

* Removes all Kubernetes resources created by the release.

**Keep history after uninstall:**

```bash
helm uninstall my-nginx --keep-history
```

* Useful for auditing or rollback purposes.

---

### 6.5 **End-to-End Example — Upgrade & Rollback Workflow**

```bash
# Step 1: Install an older version
helm install my-nginx bitnami/nginx --version 15.2.0

# Step 2: Upgrade to newer version
helm upgrade my-nginx bitnami/nginx --version 15.2.3

# Step 3: View history
helm history my-nginx

# Step 4: Rollback to previous version
helm rollback my-nginx 1

# Step 5: Verify rollback
kubectl get pods
```

---

### 6.6 **Exam Tip**

* Always use `--dry-run` before a risky upgrade.
* In troubleshooting, combine `helm history` + `helm get values` + `helm get manifest` for quick diagnosis.
* For CKA, you might be asked to roll back a failed deployment — know the `helm rollback` syntax by heart.

---

## Section 07

### **8. Troubleshooting Helm**

When working with Helm in production or during the CKA exam, troubleshooting skills can save valuable time. Here’s how to diagnose and fix common issues.

#### **8.1 Using `--dry-run` and `--debug`**

* **Purpose**: Test a Helm install or upgrade without actually deploying resources.

```bash
helm install myapp ./mychart --dry-run --debug
```

* **`--dry-run`**: Simulates the action without making changes.
* **`--debug`**: Shows detailed output, including rendered manifests and API requests.

#### **8.2 Viewing Rendered Manifests Before Install**

* **Purpose**: See the exact Kubernetes YAML that Helm will apply.

```bash
helm template myapp ./mychart > output.yaml
```

* **Use case**: Allows you to inspect YAML for errors before applying it.

#### **8.3 Common Errors and Solutions**

**Error**: `Error: Chart.yaml file is missing`

* **Cause**: You are in a directory that isn’t a valid Helm chart.
* **Solution**: Ensure `Chart.yaml` exists or run `helm create` to generate one.

**Error**: `Error: repository name (xyz) not found`

* **Cause**: The Helm repo hasn’t been added.
* **Solution**: Add the repo first:

```bash
helm repo add xyz https://example.com/charts
```

**Error**: `Error: INSTALLATION FAILED: cannot re-use a name that is still in use`

* **Cause**: A release with the same name exists.
* **Solution**: Either uninstall the existing release or use a different name.

```bash
helm uninstall myapp
```

**Error**: `values don't match schema` or `invalid YAML`

* **Cause**: Mistake in `values.yaml` formatting.
* **Solution**: Validate YAML with:

```bash
yamllint values.yaml
```

#### **Exam Tip**

In the CKA exam, always run `helm install` with `--dry-run --debug` first. This saves you from wasting time deleting broken resources.

---

## **9. Helm in CKA Exam Context**

### **9.1 Common Scenarios in the Exam**

These are the *most likely* Helm tasks you’ll see in the CKA exam, based on how Kubernetes is tested:

1. **Install an application from a Helm repo**

   * You’ll be given a repo URL and a chart name.
   * Example:

     ```bash
     helm repo add bitnami https://charts.bitnami.com/bitnami
     helm install mynginx bitnami/nginx
     ```

     ✅ *Tip*: Always run `helm repo update` after adding repos in the exam.

2. **Install a specific version of a chart**

   * Example:

     ```bash
     helm install mynginx bitnami/nginx --version 13.2.5
     ```

3. **Customize installation using values**

   * They might give you a `values.yaml` file or a single key-value override.
   * Example:

     ```bash
     helm install myapp ./mychart -f custom-values.yaml
     ```

     or

     ```bash
     helm install myapp ./mychart --set replicaCount=3
     ```

4. **Upgrade an existing release**

   * Example:

     ```bash
     helm upgrade myapp ./mychart -f new-values.yaml
     ```

5. **Roll back to a previous version**

   * Example:

     ```bash
     helm rollback myapp 1
     ```

6. **Pull a chart and install it locally**

   * Example:

     ```bash
     helm pull bitnami/nginx --untar
     helm install mynginx ./nginx
     ```

7. **List all Helm releases**

   * Example:

     ```bash
     helm list -A
     ```

8. **Uninstall a release**

   * Example:

     ```bash
     helm uninstall myapp
     ```

---

### **9.2 Fast Installation Tricks**

When the clock is ticking:

* **Skip the repo search** if the exam question already gives you chart path or URL.
* Use **`--set` for small changes** instead of creating a `values.yaml`.
* Always append `--dry-run --debug` first if unsure — avoids deleting later.
* Use **short names** for release to type less:

  ```bash
  helm install a bitnami/nginx
  ```
* For upgrades with multiple overrides, combine:

  ```bash
  helm upgrade a bitnami/nginx -f val1.yaml -f val2.yaml
  ```

---

### **9.3 Repo Management Under Time Pressure**

1. **Check which repos are configured:**

   ```bash
   helm repo list
   ```
2. **Add missing repos quickly:**

   ```bash
   helm repo add myrepo https://example.com/charts && helm repo update
   ```
3. **Remove unnecessary repos:**

   ```bash
   helm repo remove oldrepo
   ```
4. **Search in all repos:**

   ```bash
   helm search repo nginx
   ```

---

### **9.4 Common Exam Pitfalls**

* **Forgetting `--namespace`**: If the question specifies a namespace, install with:

  ```bash
  helm install myapp ./mychart -n custom-ns --create-namespace
  ```
* **Wrong chart name**: Always confirm with `helm search repo`.
* **Values merge confusion**: Remember that `--set` overrides `values.yaml`, and later `-f` files override earlier ones.
* **Time waste on YAML edits**: For small edits, `--set` is faster than editing and saving.

---

### **9.5 “Exam-Speed” Helm Commands Cheatsheet**

| Task                       | Command                                           |
| -------------------------- | ------------------------------------------------- |
| Add repo                   | `helm repo add NAME URL && helm repo update`      |
| Search chart               | `helm search repo keyword`                        |
| Install chart              | `helm install RELNAME REPO/CHART`                 |
| Install with custom values | `helm install RELNAME ./chart -f values.yaml`     |
| Install specific version   | `helm install RELNAME REPO/CHART --version X.Y.Z` |
| Upgrade release            | `helm upgrade RELNAME ./chart`                    |
| Rollback release           | `helm rollback RELNAME REVISION`                  |
| List releases              | `helm list -A`                                    |
| Uninstall release          | `helm uninstall RELNAME`                          |

---
