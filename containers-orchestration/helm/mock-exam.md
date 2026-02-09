## **Helm Mock Exam Scenarios & Fast Solutions**

### **Scenario 1 – Basic Install**

**Question:** Install the `nginx` chart from Bitnami repo as release `web` in namespace `app-ns`.
If the namespace does not exist, create it.

**Solution:**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update
helm install web bitnami/nginx -n app-ns --create-namespace
```

---

### **Scenario 2 – Install Specific Version**

**Question:** Install version `15.0.2` of `nginx` chart from Bitnami repo as `ngapp` in `default` namespace.

**Solution:**

```bash
helm install ngapp bitnami/nginx --version 15.0.2
```

---

### **Scenario 3 – Custom Values from File**

**Question:** Install the `mysql` chart from Bitnami repo with settings from `/root/custom-mysql.yaml` as release `db`.

**Solution:**

```bash
helm install db bitnami/mysql -f /root/custom-mysql.yaml
```

---

### **Scenario 4 – Quick Value Override**

**Question:** Install `nginx` chart with exactly 4 replicas, without editing any files.
Release name: `fastweb`.

**Solution:**

```bash
helm install fastweb bitnami/nginx --set replicaCount=4
```

---

### **Scenario 5 – Upgrade Existing Release**

**Question:** Upgrade the release `web` with new values from `/root/web-update.yaml`.

**Solution:**

```bash
helm upgrade web bitnami/nginx -f /root/web-update.yaml
```

---

### **Scenario 6 – Rollback**

**Question:** Roll back release `db` to revision 1.

**Solution:**

```bash
helm rollback db 1
```

---

### **Scenario 7 – Pull & Install Locally**

**Question:** Download `nginx` chart from Bitnami repo, extract it, and install from local folder with release name `localweb`.

**Solution:**

```bash
helm pull bitnami/nginx --untar
helm install localweb ./nginx
```

---

### **Scenario 8 – Search for Chart**

**Question:** Find a chart with `wordpress` in its name from all configured repos.

**Solution:**

```bash
helm search repo wordpress
```

---

### **Scenario 9 – List Releases in All Namespaces**

**Question:** Show all Helm releases in all namespaces.

**Solution:**

```bash
helm list -A
```

---

### **Scenario 10 – Uninstall**

**Question:** Remove release `fastweb` from `default` namespace.

**Solution:**

```bash
helm uninstall fastweb
```

---

### **Scenario 11 – Namespace-Specific Install**

**Question:** Install `nginx` into namespace `exam-ns` without creating it.
Namespace already exists.

**Solution:**

```bash
helm install testng bitnami/nginx -n exam-ns
```

---

### **Scenario 12 – Multiple Values Override**

**Question:** Install `nginx` with replicas=3 and service type=NodePort, overriding values from two files: `/root/base.yaml` and `/root/extra.yaml`.

**Solution:**

```bash
helm install myng bitnami/nginx \
-f /root/base.yaml \
-f /root/extra.yaml \
--set replicaCount=3,service.type=NodePort
```

---

### **Scenario 13 – Dry Run Install**

**Question:** Preview the YAML output of installing `redis` without actually installing it.

**Solution:**

```bash
helm install testredis bitnami/redis --dry-run --debug
```

---

### **Scenario 14 – Find Chart Version**

**Question:** List all available versions of the `nginx` chart from Bitnami repo.

**Solution:**

```bash
helm search repo bitnami/nginx --versions
```

---

### **Scenario 15 – Show Installed Chart’s Values**

**Question:** Display all effective values of the installed release `web`.

**Solution:**

```bash
helm get values web -a
```

---
