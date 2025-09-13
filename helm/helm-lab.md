## 1

Your error:

```
Error: INSTALLATION FAILED: Unable to continue with install: could not get information about the resource Service "" in namespace "frontend-apd": resource name may not be empty
```

This is happening because in your `service.yaml` you wrote:

```yaml
metadata:
  name: {{ .Values.service.Name }}      # .name
```

But in Helm values, the key is usually lowercase (e.g. `service.name`), not `service.Name`.
Since `.Values.service.Name` doesn’t exist in your `values.yaml`, it resolves to an **empty string**, so Helm tries to create a Service with no name → error.

---

### ✅ Fix

```bash
root@student-node ~ ➜  vi /opt/webapp-color-apd/templates/service.yaml 

root@student-node ~ ➜  helm install -n frontend-apd webapp-color-apd /opt/webapp-color-apd/
NAME: webapp-color-apd
LAST DEPLOYED: Wed Sep 10 10:18:31 2025
NAMESPACE: frontend-apd
STATUS: deployed
REVISION: 1
TEST SUITE: None

root@student-node ~ ➜  cat /opt/webapp-color-apd/templates/service.yaml 
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service.name }}    # corrected
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: webapp-color-apd
  type: {{ .Values.service.type }}
```

---

## 2

The chart URL and other specifications are as follows: -


1. The chart URL link - https://kubernetes.github.io/dashboard/

2. The chart repository name should be kubernetes-dashboard.

3. The release name should be kubernetes-dashboard-server.

4. All the resources should be deployed on the cd-tool-apd namespace.

```bash
root@student-node ~ ➜  k create ns cd-tool-apd
namespace/cd-tool-apd created

root@student-node ~ ➜  helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
"kubernetes-dashboard" has been added to your repositories

root@student-node ~ ➜  helm search repo kubernetes-dashboard
NAME                                            CHART VERSION   APP VERSION     DESCRIPTION                                   
kubernetes-dashboard/kubernetes-dashboard       7.13.0                          General-purpose web UI for Kubernetes clusters

root@student-node ~ ✖ helm install kubernetes-dashboard-server kubernetes-dashboard/kubernetes-dashboard -n cd-tool-apd

NAME: kubernetes-dashboard-server
LAST DEPLOYED: Wed Sep 10 12:28:31 2025
NAMESPACE: cd-tool-apd
STATUS: deployed
REVISION: 1

root@student-node ~ ➜  helm list -n cd-tool-apd
NAME                            NAMESPACE       REVISION        UPDATED                                 STATUS         CHART                            APP VERSION
kubernetes-dashboard-server     cd-tool-apd     1               2025-09-10 12:28:31.427532996 -0400 EDT deployed       kubernetes-dashboard-7.13.0          
```

Ahh I see what confused you 🙂 — the repetition you noticed
`kubernetes-dashboard/kubernetes-dashboard`

is **not a mistake**. It’s just how Helm names things:

* The **first part** (`kubernetes-dashboard/`) is the **repository name** you added with

  ```bash
  helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
  ```

* The **second part** (`kubernetes-dashboard`) is the **chart name** inside that repository.

So the pattern is always:

```
<repo-name>/<chart-name>
```

In your case:

* Repo name = `kubernetes-dashboard`
* Chart name = `kubernetes-dashboard`

That’s why you see it repeated.
If the repo were named `foo`, you’d install like this:

```
helm install my-release foo/kubernetes-dashboard
```

Great question 👌 — let me show you exactly how I got the chart name.

When you add a Helm repository:

```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
```

You can **search charts in that repo** with:

```bash
helm search repo kubernetes-dashboard
```

You’ll get output like this:

```
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
kubernetes-dashboard/kubernetes-dashboard   6.x.x        2.x.x          General-purpose web UI for Kubernetes clusters
```

* The **first column (`NAME`)** shows `<repo-name>/<chart-name>`.
* In this case, the chart name **inside the repo** is `kubernetes-dashboard`.
* So, when installing, you reference both:

  ```bash
  helm install kubernetes-dashboard-server kubernetes-dashboard/kubernetes-dashboard -n cd-tool-apd
  ```

👉 In short:
I got the chart name by running `helm search repo kubernetes-dashboard`, which shows you the charts available in that repo.

---

One co-worker deployed an nginx helm chart on the cluster3 server called lvm-crystal-apd. A new update is pushed to the helm chart, and the team wants you to update the helm repository to fetch the new changes.


After updating the helm chart, upgrade the helm chart version to 18.1.15 and increase the replica count to 2.

```bash
cluster3-controlplane ~ ➜  helm list -A
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART         APP VERSION
lvm-crystal-apd crystal-apd-ns  1               2025-09-11 12:30:19.845328123 +0000 UTC deployed        nginx-18.1.0  1.27.0     

cluster3-controlplane ~ ➜  ls

cluster3-controlplane ~ ➜  helm repo list
NAME            URL                               
lvm-crystal-apd https://charts.bitnami.com/bitnami

cluster3-controlplane ~ ✖ helm status lvm-crystal-apd -n crystal-apd-ns
NAME: lvm-crystal-apd
LAST DEPLOYED: Thu Sep 11 12:30:19 2025
NAMESPACE: crystal-apd-ns
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: nginx
CHART VERSION: 18.1.0
APP VERSION: 1.27.0

cluster3-controlplane ~ ➜  helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "lvm-crystal-apd" chart repository
Update Complete. ⎈Happy Helming!⎈

cluster3-controlplane ~ ➜  helm upgrade lvm-crystal-apd lvm-crystal-apd/nginx \
  --version 18.1.15 \
  --namespace crystal-apd-ns \
  --set replicaCount=2
Release "lvm-crystal-apd" has been upgraded. Happy Helming!
NAME: lvm-crystal-apd
LAST DEPLOYED: Thu Sep 11 12:42:41 2025
NAMESPACE: crystal-apd-ns
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
CHART NAME: nginx
CHART VERSION: 18.1.15
APP VERSION: 1.27.1

cluster3-controlplane ~ ➜  helm list -n crystal-apd-ns
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART          APP VERSION
lvm-crystal-apd crystal-apd-ns  2               2025-09-11 12:42:41.750181533 +0000 UTC deployed        nginx-18.1.15  1.27.1     

cluster3-controlplane ~ ➜  kubectl get deploy -n crystal-apd-ns lvm-crystal-apd-nginx -o yaml | grep replicas
  replicas: 2
  replicas: 2
```
Aha 🚀 I get what you mean now — you want to know **how I knew that the release is using the nginx chart**, not assuming it blindly.

That comes from your own `helm list -A` output 👇

```
NAME            NAMESPACE       REVISION   UPDATED   STATUS    CHART         APP VERSION
lvm-crystal-apd crystal-apd-ns  1          ...       deployed nginx-18.1.0  1.27.0
```

* In the **CHART** column, it clearly shows `nginx-18.1.0`.
* That means the Helm release `lvm-crystal-apd` was deployed **from the `nginx` chart** (version `18.1.0`).

### 🔹 Commands to verify chart source

1. **Show detailed release info**:

   ```bash
   helm status lvm-crystal-apd -n crystal-apd-ns
   ```

   This shows which chart was used, its version, and values applied.

2. **Inspect the chart directly**:

   ```bash
   helm get all lvm-crystal-apd -n crystal-apd-ns
   ```

   This dumps manifests, chart name, and values.

3. **List available versions of nginx in repo**:

   ```bash
   helm search repo lvm-crystal-apd/nginx
   ```

   That’s how we know `18.1.15` exists.

---

One application, webpage-server-01, is deployed on the Kubernetes cluster by the Helm tool. Now, the team wants to deploy a new version of the application by replacing the existing one. A new version of the helm chart is given in the /root/new-version directory on the student-node. Validate the chart before installing it on the Kubernetes cluster. 
Use the helm command to validate and install the chart. After successfully installing the newer version, uninstall the older version. 

```bash
root@student-node ~ ➜  helm lint ./new-version/
==> Linting ./new-version/
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

root@student-node ~ ➜  helm list -A
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS      CHART                            APP VERSION
traefik                 kube-system     1               2025-09-11 11:07:23.720674237 +0000 UTC deployed    traefik-34.2.1+up34.2.0          v3.3.2     
traefik-crd             kube-system     1               2025-09-11 11:07:03.597608191 +0000 UTC deployed    traefik-crd-34.2.1+up34.2.0      v3.3.2     
webpage-server-01       default         1               2025-09-11 08:48:20.951166062 -0400 EDT deployed    webpage-server-01-0.1.0          v1         

root@student-node ~ ✖ helm upgrade --install webpage-server-01 ./new-version/
Release "webpage-server-01" has been upgraded. Happy Helming!
NAME: webpage-server-01
LAST DEPLOYED: Thu Sep 11 08:51:16 2025
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None

root@student-node ~ ➜  helm uninstall webpage-server-01 -n default
helm install webpage-server-01 ./new-version/ -n default
release "webpage-server-01" uninstalled
NAME: webpage-server-01
LAST DEPLOYED: Thu Sep 11 08:53:51 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

root@student-node ~ ➜  
```

Perfect 👌 you already nailed the workflow! Let me recap and highlight the key points the exam usually wants:

### 🔹 Steps You Did (and why)

1. **Validate the chart before installing**

   ```bash
   helm lint ./new-version/
   ```

   ✅ Output showed no failures (just a warning about missing icon). That means the chart is valid.

2. **Upgrade the release with the new chart**

   ```bash
   helm upgrade --install webpage-server-01 ./new-version/
   ```

   ✅ This replaced the old version with the new one in the **same release name** (`webpage-server-01`), revision bumped to `2`.

   * `--install` makes sure if the release didn’t exist, it would install.
   * In your case, since it existed, it upgraded instead.

3. **Check release**

   ```bash
   helm list -n default
   ```

   You’ll see `REVISION: 2`, confirming upgrade worked.

### 🔹 About uninstalling the old release

You don’t actually need to uninstall the old one separately because `helm upgrade` overwrites it in place (keeping history).

But if the requirement is to **completely remove the old release and keep only the new one**, the sequence would have been:

```bash
helm uninstall webpage-server-01 -n default
helm install webpage-server-01 ./new-version/ -n default
```

This destroys the old release first, then installs fresh.

---

```bash
cluster3-controlplane ~ ✖ helm install nginx-server polar/nginx -n cd-tool-apd
Error: INSTALLATION FAILED: failed to perform "FetchReference" on source: GET "https://registry-1.docker.io/v2/bitnamicharts/nginx/manifests/21.1.23": response status code 429: toomanyrequests: You have reached your unauthenticated pull rate limit. https://www.docker.com/increase-rate-limit
```

Ahh ⚡ you’ve hit the **Docker Hub rate limit** issue.

What’s happening:

* Bitnami’s nginx chart pulls its container image (`bitnami/nginx`) from **Docker Hub**.
* Without authentication, Docker Hub only allows a limited number of pulls per 6 hours.
* You got `429: toomanyrequests` = rate limit exceeded.

### 🔹 Ways to Fix

#### Option 1: Create a Docker Hub account & login

This is the cleanest fix.

```bash
docker login
```

(or if only kubectl/helm is available):

```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email> \
  -n cd-tool-apd
```

Then patch your `ServiceAccount` or Helm values to use this secret for pulling images.

#### Option 2: Use Bitnami’s own container registry (quay.io or ghcr.io)

Bitnami also mirrors their images to other registries that don’t have this limit.
For example, override values when installing:

```bash
helm install nginx-server polar/nginx \
  -n cd-tool-apd \
  --set image.registry=ghcr.io \
  --set image.repository=bitnami/nginx \
  --set image.tag=latest
```

This tells the chart to pull from **GitHub Container Registry** instead of Docker Hub.

#### Option 3: Wait (not great for exams 😅)

Rate limits reset after 6 hours for anonymous pulls.

### ✅ Best Exam-Safe Command

If authentication isn’t available, just switch registry:

```bash
helm install nginx-server polar/nginx \
  -n cd-tool-apd \
  --set image.registry=ghcr.io \
  --set image.repository=bitnami/nginx \
  --set image.tag=latest
```

---
`helm install --generate-name ./new-version`

We haven't got any release name in the task, so we can generate the random name from the `--generate-name` option.

---

## Deployment name is changed after helm updgade

```bash
cluster1-controlplane ~ ➜  helm list -A
NAME                            NAMESPACE       REVISION        UPDATED                                STATUS          CHART                           APP webpage-server-01               default         1               2025-09-12 16:11:55.860540337 +0000 UTCdeployed        webpage-server-01-0.1.0         v1         

cluster1-controlplane ~ ➜  helm lint /root/new-version/
==> Linting /root/new-version/
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

cluster1-controlplane ~ ➜  helm upgrade --install webpage-server-01 /root/new-version/
Release "webpage-server-01" has been upgraded. Happy Helming!
NAME: webpage-server-01
LAST DEPLOYED: Fri Sep 12 16:14:24 2025
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None

cluster1-controlplane ~ ➜  helm list -A
NAME                            NAMESPACE       REVISION        UPDATED                                STATUS          CHART                           APP VERSION     
webpage-server-01               default         2               2025-09-12 16:14:24.180738228 +0000 UTCdeployed        webpage-server-02-0.1.1         v2  

cluster1-controlplane ~ ➜  k get deploy
NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
webpage-server-02                                 3/3     3            3           3m2s     # name does not pick release name

cluster1-controlplane ~ ➜  cat /root/new-version/templates/deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    version: v2-cds
  name: {{ .Values.name }}

cluster1-controlplane ~ ➜  cat /root/new-version/values.yaml 

name: webpage-server-02
```

Nice, you shared the chart 🙌 — now it’s crystal clear why the Deployment comes out as `webpage-server-02`:

In **`deployment.yaml`**, the name is set like this:

```yaml
metadata:
  name: {{ .Values.name }}
```

…and in **`values.yaml`**, you’ve got:

```yaml
name: webpage-server-02
```

So Helm is simply substituting the value, which explains the mismatch.

### 🔧 How to tie it to the release name

Option **1 — simplest (exam friendly)**
Change the `deployment.yaml` line to:

```yaml
metadata:
  name: {{ .Release.Name }}
```

Now, when you run:

```bash
helm upgrade --install webpage-server-01 /root/new-version
```

Your Deployment will be named **`webpage-server-01`**.

Option **2 — values-driven (best practice)**
Instead of hardcoding `name` in `values.yaml`, use Helm’s built-in `fullnameOverride`.

1. In `values.yaml`, add:

```yaml
fullnameOverride: ""
```

2. In `deployment.yaml`, replace:

```yaml
name: {{ .Values.name }}
```

with:

```yaml
name: {{ include "new-version.fullname" . }}
```

…and in `_helpers.tpl` (if your chart has it), `fullname` is usually defined like this:

```yaml
{{- define "new-version.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name }}
{{- end }}
{{- end }}
```

This way:

* By default, the Deployment will follow the release name (`webpage-server-01`).
* If you want to override, you just set `fullnameOverride` in `values.yaml`.

Exactly 💯

If you switch to:

```yaml
metadata:
  name: {{ .Release.Name }}
```

👉 then you **don’t need to add anything in `values.yaml`**.
`Release.Name` is a built-in Helm object — it’s always available, no matter what’s in `values.yaml`.

So:

* `{{ .Values.* }}` → pulls from your `values.yaml` (or from `--set`, `-f`).
* `{{ .Release.Name }}` → comes directly from Helm itself (whatever name you used in `helm install <release-name> ...`).

That’s why it’s often the easiest fix: you just tie the Deployment (and Service, ConfigMap, etc.) names to the release name, and you don’t have to maintain a `name:` field in `values.yaml` at all.

👉 Helm also ships with helpers like `fullnameOverride` and `nameOverride` (defined in `_helpers.tpl` when you create a chart with `helm create`). Those **are not built-in**, they’re just conventions that the starter chart scaffolds for you.


---

One application, webpage-server-01, is deployed on the Kubernetes cluster by the Helm tool in default namespace. Now, the team wants to deploy a new version of the application by replacing the existing one. A new version of the helm chart is given in the /root/new-version directory on the cluster1-controlplane. Validate the chart before installing it on the Kubernetes cluster.

```bash
cluster1-controlplane ~ ➜  k get deploy
NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
webpage-server-02                                 3/3     3            3           7s

cluster1-controlplane ~ ➜  helm list
NAME                            NAMESPACE       REVISION        UPDATED                                       STATUS          CHART                        webpage-server-01               default         4               2025-09-13 19:18:06.215784958 +0000 UTC       deployed        webpage-server-02-0.1.1         v2         
cluster1-controlplane ~ ➜  cat /root/new-version/values.yaml 
name: webpage-server-02

cluster1-controlplane ~ ➜  cat /root/new-version/templates/deployment.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    version: v2-cds
  name: {{ .Values.name }}

cluster1-controlplane ~ ➜  helm install --generate-name /root/new-version/
Error: INSTALLATION FAILED: Unable to continue with install: ServiceAccount "webapp-sa-apd" in namespace "default" exists and cannot be imported into the current release: invalid ownership metadata; annotation validation error: key "meta.helm.sh/release-name" must equal "new-version-1757791172": current value is "webpage-server-01"

cluster1-controlplane ~ ✖ helm uninstall webpage-server-01 -n default
release "webpage-server-01" uninstalled

cluster1-controlplane ~ ➜  helm install --generate-name /root/new-version/
NAME: new-version-1757791197
LAST DEPLOYED: Sat Sep 13 19:19:57 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

cluster1-controlplane ~ ➜  k get deploy
NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
webpage-server-02                                 3/3     3            3           7s

cluster1-controlplane ~ ➜  helm list
NAME                            NAMESPACE       REVISION        UPDATED                                       STATUS          CHART                           APP VERSION
new-version-1757791197          default         1               2025-09-13 19:19:57.02837142 +0000 UTC        deployed        webpage-server-02-0.1.1         v2         
```

We haven't got any release name in the task, so we can generate the random name from the --generate-name option.

---
