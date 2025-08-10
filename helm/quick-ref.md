# 🏹 **Helm Quick Reference Guide (CKA Speed Mode)**

## **1️⃣ Repo Management**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo <keyword>          # Search in repos
helm search repo <chart> --versions # Show all versions
```

---

## **2️⃣ Install / Upgrade**

```bash
# Install (create namespace if not exists)
helm install <release> <chart> -n <ns> --create-namespace

# Install with file overrides
helm install <release> <chart> -f values.yaml

# Install with quick set
helm install <release> <chart> --set key1=val1,key2=val2

# Multiple value files + set overrides
helm install <release> <chart> \
-f base.yaml -f extra.yaml \
--set key=val

# Upgrade existing release
helm upgrade <release> <chart> -f values.yaml
```

---

## **3️⃣ View / Debug**

```bash
helm list -A                # All releases, all namespaces
helm get values <release>   # Show custom values
helm get values <release> -a # All (default+custom)
helm status <release>
helm history <release>
helm template <release> <chart> # Render without installing
helm install <release> <chart> --dry-run --debug # Preview
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

```bash
helm pull <chart> --untar
helm install <release> ./<chart_folder>
```

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

💡 **EXAM TIP FLOW**:
When you see a Helm task → **Repo add/update → Install/Upgrade → Verify → Rollback/Uninstall**.
Namespace mistakes & version requirements are the biggest traps.

---
