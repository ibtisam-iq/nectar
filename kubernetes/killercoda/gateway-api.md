Create an HTTPRoute named web-route in the nginx-gateway namespace that directs traffic from the web-gateway to a 
backend service named web-service on port 80 and ensures that the route is applied only to requests with the hostname cluster2-controlplane.

```bash
cluster2-controlplane ~ ➜  k get gateway -n nginx-gateway 
NAME          CLASS   ADDRESS   PROGRAMMED   AGE
web-gateway   nginx             True         75s

cluster2-controlplane ~ ➜  vi 6.yaml

cluster2-controlplane ~ ➜  k apply -f 6.yaml 
httproute.gateway.networking.k8s.io/web-route created

cluster2-controlplane ~ ➜  k describe httproutes.gateway.networking.k8s.io -n nginx-gateway web-route 
Name:         web-route
Namespace:    nginx-gateway
Labels:       <none>
Annotations:  <none>
API Version:  gateway.networking.k8s.io/v1
Kind:         HTTPRoute
Spec:
  Parent Refs:
    Group:      gateway.networking.k8s.io
    Kind:       Gateway
    Name:       web-gateway
    Namespace:  nginx-gateway
  Rules:
    Backend Refs:
      Group:   
      Kind:    Service
      Name:    web-service
      Port:    80
      Weight:  1
    Matches:
      Path:
        Type:   PathPrefix
        Value:  /
Events:           <none>

cluster2-controlplane ~ ➜  cat 6.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: nginx-gateway
spec:
  hostnames:
  - cluster2-controlplane                   # not added, so the question is marked wrong.
  parentRefs:
  - name: web-gateway
    namespace: nginx-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80

cluster2-controlplane ~ ➜  curl http://cluster2-controlplane:30080
<!DOCTYPE html>
<html>
</body>
</html>

cluster2-controlplane ~ ➜  k get svc -n nginx-gateway 
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
nginx-gateway   NodePort    172.20.220.38   <none>        80:30080/TCP,443:30081/TCP   36m
web-service     ClusterIP   172.20.11.94    <none>        80/TCP                       6m32s

cluster2-controlplane ~ ➜  
```

---
