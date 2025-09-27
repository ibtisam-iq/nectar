# API deprecations

Enable the `v1alpha1` version for `rbac.authorization.k8s.io` API group on the controlplane node.

Add the `--runtime-config=rbac.authorization.k8s.io/v1alpha1` option to the kube-apiserver.yaml file.

**Official docs:** https://kubernetes.io/docs/tasks/administer-cluster/enable-disable-api/

---

Install the `kubectl convert` plugin on the `controlplane` node.

**Official docs:** https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-convert-plugin

```bash
controlplane ~ ➜  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   138  100   138    0     0   1550      0 --:--:-- --:--:-- --:--:--  1568
100 56.8M  100 56.8M    0     0  51.6M      0  0:00:01  0:00:01 --:--:-- 62.6M

controlplane ~ ➜  sudo install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert

controlplane ~ ➜  kubectl convert --help
Convert config files between different API versions. Both YAML and JSON formats are accepted.
```

---

Ingress manifest file is already given under the /root/ directory called `ingress-old.yaml`.

With help of the `kubectl convert` command, change the deprecated API version to the `networking.k8s.io/v1` and create the resource.

```bash
controlplane ~ ➜  cat ingress-old.yaml 
---
# Deprecated API version
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /video-service
        pathType: Prefix
        backend:
          serviceName: ingress-svc
          servicePort: 80

controlplane ~ ➜  kubectl-convert -f ingress-old.yaml --output-version networking.k8s.io/v1 | kubectl apply -f -
ingress.networking.k8s.io/ingress-space created

controlplane ~ ➜  kubectl-convert -f ingress-old.yaml --output-version networking.k8s.io/v1
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  name: ingress-space
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: ingress-svc
            port:
              number: 80
        path: /video-service
        pathType: Prefix
status:
  loadBalancer: {}

controlplane ~ ➜  
```

