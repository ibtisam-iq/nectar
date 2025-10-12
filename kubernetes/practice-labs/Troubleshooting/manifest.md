## Q1

```bash
k apply -f /home/thor/mysql_deployment.yml

# ns is missing, wrong kind & its version
[resource mapping not found for name: "mysql-pv" namespace: "" from "/home/thor/mysql_deployment.yml": no matches for kind "Persistentvolume" in version "apps/v1"

ensure CRDs are installed first, resource mapping not found for name: "mysql-pv-claim" namespace: "" from "/home/thor/mysql_deployment.yml": no matches for kind "Persistentvolumeclaim" in version "v1"

# wrong field
Error from server (BadRequest): error when creating "/home/thor/mysql_deployment.yml": Service in version "v1" cannot be handled as a Service: strict decoding error: unknown field "metadata.app"
```

---

## Q2: wrong apiVersion

```bash
root@student-node ~ ➜  helm install webapp-color-apd /opt/webapp-color-apd/ -n frontend-apd
Error: INSTALLATION FAILED: unable to build kubernetes objects from release manifest: resource mapping not found for name: "webapp-color-apd" namespace: "frontend-apd" from "": no matches for kind "Deployment" in version "v1"
ensure CRDs are installed first
```

---

## Q3

```bash
cluster3-controlplane ~ ➜  k apply -f 13.yaml 
error: unable to decode "13.yaml": json: cannot unmarshal bool into Go struct field ObjectMeta.metadata.annotations of type string

cluster3-controlplane ~ ✖ k apply -f 13.yaml 
ingress.networking.k8s.io/nginx-ingress-cka04-svcn created

cluster3-controlplane ~ ➜  cat 13.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress-cka04-svcn
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"      # must be a string
```
