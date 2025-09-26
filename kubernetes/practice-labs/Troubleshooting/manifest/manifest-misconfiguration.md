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
