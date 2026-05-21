# 🏹 **Helm Quick Reference Guide (CKA Speed Mode)**

## **1️⃣ Repo Management**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo <keyword>          # Search in repos
helm search repo <chart> --versions # Show all versions
```

```bash
controlplane ~ ➜  helm search repo nginx
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                                       
bitnami/nginx                           21.1.23         1.29.1          NGINX Open Source is a web server that can be a...
bitnami/nginx-ingress-controller        12.0.7          1.13.1          NGINX Ingress Controller is an Ingress controll...
bitnami/nginx-intel                     2.1.15          0.4.9           DEPRECATED NGINX Open Source for Intel is a lig...

controlplane ~ ➜  helm search repo bitnami/nginx
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                                       
bitnami/nginx                           21.1.23         1.29.1          NGINX Open Source is a web server that can be a...
bitnami/nginx-ingress-controller        12.0.7          1.13.1          NGINX Ingress Controller is an Ingress controll...
bitnami/nginx-intel                     2.1.15          0.4.9           DEPRECATED NGINX Open Source for Intel is a lig...

controlplane ~ ➜  helm search repo bitnami/nginx --versions            # not version
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                                       
bitnami/nginx                           21.1.23         1.29.1          NGINX Open Source is a web server that can be a...
bitnami/nginx                           21.1.22         1.29.1          NGINX Open Source is a web server that can be a...
bitnami/nginx                           21.1.21         1.29.1          NGINX Open Source is a web server that can be a...
bitnami/nginx                           21.1.16         1.29.1          NGINX Open Source is a web server that can be a...
... much more
```

---

## **2️⃣ Install / Upgrade**

```bash
<chart> = bitnami/nginx    # repo/chart name

# Install (create namespace if not exists)
helm install <release> <chart> -n <ns> --create-namespace

# Install with file overrides
helm install <release> <chart> -f values.yaml

# Install with sepecific chart version
helm install <release> <chart> --version 9.3.5    # chart version — not the application (app) version

# Install with quick set
helm install <release> <chart> --set key1=val1,key2=val2

# Multiple value files + set overrides
helm install <release> <chart> \
-f base.yaml -f extra.yaml \
--set key=val

# Upgrade existing release
helm upgrade <release> <chart> -f values.yaml
or
helm upgrade --install <release> <chart> -f values.yaml
```

```bash
# While adding --set flag
# To see all values, including defaults or see values.yaml
controlplane ~ ➜  helm get values ingress-nginx --all | grep replica
  replicaCount: 1
  replicaCount: 1
```

---

## **3️⃣ View / Debug**

```bash
helm list -a -A  or helm ls --all -A  # All releases, all namespaces
helm get values <release>             # Show custom values
helm get values <release> -a          # All (default+custom)
helm status <release>
helm history <release>
helm template <release> <chart>       # Render without installing
helm install <release> <chart> --dry-run --debug # Preview
```

```
helm template silver-argo argo/argo-cd \
  --version 7.6.12 \
  --namespace argocd \
  --set installCRDs=false \
  > argocd-template.yaml
```

---

## **4️⃣ Rollback**

```bash
helm rollback <release> <revision>
```

---

## **5️⃣ Uninstall**

```bash
helm uninstall <release> -n <ns>
```

---

## **6️⃣ Chart Download & Local Install**

### Inspect without downloading

```bash
# View default values only (no local file needed)
helm show values <chart> --version <ver>

# Save default values to a local override file
helm show values <chart> --version <ver> > my-values.yaml

# View Chart.yaml metadata (name, version, description, dependencies)
helm show chart <chart> --version <ver>

# View all (values + chart metadata + README)
helm show all <chart> --version <ver>
```

> Works with OCI registries too:
> ```bash
> helm show values oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart --version 1.3.0
> ```

---

### Download chart as `.tgz`

```bash
# Download only (produces chart-version.tgz in current directory)
helm pull <chart> --version <ver>

# Download and untar in one step (produces a chart directory)
helm pull <chart> --version <ver> --untar
```

Resulting structure after untar:

```
retail-store-sample-catalog-chart/
├── Chart.yaml        ← chart name, version, description, dependencies
├── values.yaml       ← default values
└── templates/        ← all Kubernetes manifests (Deployment, Service, etc.)
```

> To inspect manually from an already-downloaded `.tgz`:
> ```bash
> tar xf retail-store-sample-catalog-chart-1.3.0.tgz
> ```

---

### Install from local `.tgz` or chart directory

```bash
# Install from local .tgz
helm install <release> ./chart-1.0.0.tgz

# Install from unpacked chart directory
helm install <release> ./chart-directory/

❌ helm install my-nginx .
✅ helm install my-nginx ./nginx
```

---

### Install with a specific values file (`-f`)

```bash
# Override defaults with a custom values file
helm install <release> ./chart-1.0.0.tgz -f my-values.yaml

# Multiple values files — merged in order, last one wins on conflict
helm install <release> ./chart-directory/ \
  -f values-base.yaml \
  -f values-baremetal.yaml
```

> When multiple `values-*.yaml` files exist in the same directory, select explicitly:
> ```bash
> helm install catalog ./retail-store-sample-catalog-chart -f values-dev.yaml
> helm install catalog ./retail-store-sample-catalog-chart -f values-eks-rds.yaml
> ```

---

### Full workflow: pull → edit → install → upgrade

```bash
# 1. Download and unpack
helm pull oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart \
  --version 1.3.0 --untar

# 2. Save defaults as override file and edit
cp retail-store-sample-catalog-chart/values.yaml catalog-local.yaml
# edit catalog-local.yaml as needed

# 3. First install
helm install catalog ./retail-store-sample-catalog-chart -f catalog-local.yaml

# 4. Edit catalog-local.yaml again (e.g., switch persistence provider, add endpoint)

# 5. Upgrade — same release name, same chart, updated values → new revision
helm upgrade catalog ./retail-store-sample-catalog-chart -f catalog-local.yaml
```

> `helm install` creates a new release (fails if it already exists).  
> `helm upgrade` updates an existing release and increments the revision number.  
> `helm upgrade --install` does both: creates if not found, upgrades if found.

---

## **7️⃣ Speed Scenarios**

| **Task**                     | **Command**                                                   |
| ---------------------------- | ------------------------------------------------------------- |
| Install `nginx` in `app-ns`  | `helm install web bitnami/nginx -n app-ns --create-namespace` |
| Install specific version     | `helm install app bitnami/nginx --version 15.0.2`             |
| Set replicas=4               | `helm install web bitnami/nginx --set replicaCount=4`         |
| Rollback to rev 1            | `helm rollback web 1`                                         |
| Show all versions of a chart | `helm search repo bitnami/nginx --versions`                   |
| List all releases            | `helm list -A`                                                |

---

```bash
controlplane ~ ➜  helm repo list
NAME            URL                                                 
bitnami         https://charts.bitnami.com/bitnami                  
puppet          https://puppetlabs.github.io/puppetserver-helm-chart
hashicorp       https://helm.releases.hashicorp.com                 

controlplane ~ ➜  helm install amaze-surf bitnami/apache
Pulled: us-central1-docker.pkg.dev/kk-lab-prod/helm-charts/bitnami/apache:11.3.2
Digest: sha256:1bd45c97bb7a0000534e3abc5797143661e34ea7165aa33068853c567e6df9f2
NAME: amaze-surf
LAST DEPLOYED: Sun Sep 28 11:45:40 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: apache
CHART VERSION: 11.3.2
APP VERSION: 2.4.63

controlplane ~ ➜  helm status amaze-surf
NAME: amaze-surf
LAST DEPLOYED: Sun Sep 28 11:45:40 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: apache
CHART VERSION: 11.3.2
APP VERSION: 2.4.63


controlplane ~ ➜  helm list -A                 # also tells chart name, chart version, and app version
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS       CHART           APP VERSION
amaze-surf      default         1               2025-09-28 11:45:40.183342347 +0000 UTC deployed     apache-11.3.2   2.4.63     
crazy-web       default         1               2025-09-28 11:46:31.183342347 +0000 UTC deployed     nginx-19.0.0    1.27.4     
happy-browse    default         1               2025-09-28 11:46:29.364833702 +0000 UTC deployed     nginx-19.0.0    1.27.4     

helm repo add <> <url>
helm repo update <>
helm repo list <> or helm repo ls <>
helm repo remove <>

helm ls -A or helm list -A
```

---
