```bash
root@student-node ~ ➜  k describe svc route-apd-svc
Name:                     route-apd-svc
Labels:                   app=route-apd-svc
Selector:                 version=v1         # one label, which shares between 2 pods, so it routed the traffic to both pods.
Type:                     NodePort

Endpoints:                172.17.1.5:8080,172.17.1.7:8080    # 2 pods

root@student-node ~ ➜  k get po -o wide --show-labels
NAME                         READY   STATUS    RESTARTS   AGE     IP            NODE                 LABELS
blue-apd-5ffd7768b8-lt2jj    1/1     Running   0          17m     172.17.1.5    cluster3-node01      type-one=blue,version=v1
green-apd-84bb78c876-k9bnr   1/1     Running   0          12m     172.17.1.7    cluster3-node01      type-two=green,version=v1
```
---

Create two environment variables for the above pod with below specifications:
`GREETINGS` with the data from configmap `ckad02-config1-aecs`

```bash
env:                                # not envFrom, it doesn't support key value.
      - name: GREETINGS
        valueFrom:
          configMapKeyRef:
            key: greetings.how
            name: ckad02-config1-aecs
```
---

## same namespace of backed as of targeted service

```bash
root@student-node ~ ➜  k get svc -n global-space 
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
default-backend-service   ClusterIP   10.43.232.194   <none>        80/TCP     3m36s
food-service              ClusterIP   10.43.167.191   <none>        8080/TCP   3m36s

root@student-node ~ ➜  kubectl config use-context cluster2
Switched to context "cluster2".

root@student-node ~ ➜  k get po -n ingress-nginx 
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-56p6j       0/1     Completed   0          5m58s
ingress-nginx-admission-patch-ktwd8        0/1     Completed   0          5m58s
ingress-nginx-controller-7446d746c-596xt   1/1     Running     0          5m58s

root@student-node ~ ➜  k describe deploy -n ingress-nginx ingress-nginx-controller | grep -i Args -5
    Args:
      /nginx-ingress-controller
      --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
      --election-id=ingress-controller-leader
      --watch-ingress-without-class=true
      --default-backend-service=global-space/default-backend-service

root@student-node ~ ➜  cat 11.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-resource-xnz
  namespace: global-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /eat
        pathType: Prefix
        backend: 
          service:
            name: food-service
            port:
              number: 8080

root@student-node ~ ➜  k apply -f 11.yaml 
ingress.networking.k8s.io/ingress-resource-xnz created
```
