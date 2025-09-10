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
