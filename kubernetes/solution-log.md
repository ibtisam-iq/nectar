
# ✅ Q7: Simple Ingress Rule

> You already have a deployment `amor` with service `amor` in namespace `amor`. Create an Ingress resource:

* Host: `demo.ckatest.com`
* Path: `/amor`
* Service: `amor`
* Port: `80`

✅ Add `demo.ckatest.com` to your `/etc/hosts` pointing to the node IP if testing from local laptop.

```bash
ubuntu@ip-172-31-23-169:~$ curl http://54.89.17.0:30160/amor
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

### `/amor` Ingress mismatch

Your `amor` Ingress uses:

```yaml
host: demo.ckatest.com
path: /amor
```

You're testing it with:

```bash
curl http://54.89.17.0:30160/amor
```

This will return 404 unless you also add:

```bash
-H "Host: demo.ckatest.com"
```

So do:

```bash
curl -H "Host: demo.ckatest.com" http://54.89.17.0:30160/amor
```

```bash
ubuntu@ibtisam-iq:~$ kubectl delete all -n amor --all
pod "amor-855d857fb5-gdfpg" deleted
service "amor" deleted
service "amor-access" deleted
deployment.apps "amor" deleted
ubuntu@ibtisam-iq:~$ kubectl apply -f amor.yaml
namespace/amor unchanged
deployment.apps/amor created
service/amor created
service/amor-nodeport created
ingress.networking.k8s.io/amor configured
ubuntu@ibtisam-iq:~$ kubectl get ingress -n amor -o wide
NAME   CLASS   HOSTS              ADDRESS         PORTS   AGE
amor   nginx   demo.ckatest.com   10.101.45.162   80      85m
ubuntu@ibtisam-iq:~$ curl -H "Host: demo.ckatest.com" http://54.89.17.0:30160/amor
<!DOCTYPE html>
<html lang="en" >
<head>
</body>
</html>
ubuntu@ibtisam-iq:~$ curl -H "Host: demo.ckatest.com" http://98.81.122.118:30160/amor # wrong IP
^C
```

---

# ✅ Q8: Multi-path Ingress

> Create 2 deployments and services in namespace `webapp`:

* `frontend`: image `nginx`
* `backend`: image `httpd`

Then create an Ingress:

* `/frontend` → service `frontend`, port 80
* `/backend` → service `backend`, port 80

✅ Test using curl with path-based routing.

```bash
ubuntu@ibtisam-iq:~$ kubectl create ns webapp
namespace/webapp created
ubuntu@ibtisam-iq:~$ kubectl create deploy frontend --image nginx --port 80 -l app=frontend -n webapp
error: unknown shorthand flag: 'l' in -l
See 'kubectl create deployment --help' for usage.
ubuntu@ibtisam-iq:~$ kubectl create deploy frontend --image nginx --port 80 -n webapp
deployment.apps/frontend created
ubuntu@ibtisam-iq:~$ kubectl create deploy backend --image httpd --port 80 -n webapp
deployment.apps/backend created
ubuntu@ibtisam-iq:~$ kubectl expose deploy frontend --port 80 -n webapp
service/frontend exposed
ubuntu@ibtisam-iq:~$ kubectl expose deploy backend --port 80 -n webapp
service/backend exposed
ubuntu@ibtisam-iq:~$ kubectl create ingress test-ingress --rule=ibtisam-iq.com/frontend=frontend:80 --rule=ibtisam-iq.com/backend=backend:80 --class nginx -n webapp -o yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: "2025-05-17T07:28:28Z"
  generation: 1
  name: test-ingress
  namespace: webapp
  resourceVersion: "7342"
  uid: a1ec6ab9-fc79-4ec5-abf0-e948d763af19
spec:
  ingressClassName: nginx
  rules:
  - host: ibtisam-iq.com
    http:
      paths:
      - backend:
          service:
            name: frontend
            port:
              number: 80
        path: /frontend
        pathType: Exact
      - backend:
          service:
            name: backend
            port:
              number: 80
        path: /backend
        pathType: Exact
status:
  loadBalancer: {}
ubuntu@ibtisam-iq:~$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

ubuntu@ibtisam-iq:~$ curl http://98.81.122.118/frontend
curl: (7) Failed to connect to 98.81.122.118 port 80 after 1 ms: Couldn't connect to server
ubuntu@ibtisam-iq:~$ kubectl get svc -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.101.45.162   <pending>     80:30160/TCP,443:31840/TCP   3m1s
ingress-nginx-controller-admission   ClusterIP      10.107.52.181   <none>        443/TCP                      3m1s
ubuntu@ibtisam-iq:~$ kubectl edit svc ingress-nginx-controller -n ingress-nginx
service/ingress-nginx-controller edited
ubuntu@ibtisam-iq:~$ kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.101.45.162   <none>        80:30160/TCP,443:31840/TCP   4m12s
ingress-nginx-controller-admission   ClusterIP   10.107.52.181   <none>        443/TCP                      4m12s
ubuntu@ibtisam-iq:~$ kubectl get ingress -o wide -n webapp
NAME           CLASS   HOSTS            ADDRESS         PORTS   AGE
test-ingress   nginx   ibtisam-iq.com   10.101.45.162   80      15m
ubuntu@ibtisam-iq:~$ kubectl get ingress -n webapp -o yaml
apiVersion: v1
items:
- apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    creationTimestamp: "2025-05-17T07:28:28Z"
    generation: 1
    name: test-ingress
    namespace: webapp
    resourceVersion: "8438"
    uid: a1ec6ab9-fc79-4ec5-abf0-e948d763af19
  spec:
    ingressClassName: nginx
    rules:
    - host: ibtisam-iq.com
      http:
        paths:
        - backend:
            service:
              name: frontend
              port:
                number: 80
          path: /frontend
          pathType: Exact
        - backend:
            service:
              name: backend
              port:
                number: 80
          path: /backend
          pathType: Exact
  status:
    loadBalancer:
      ingress:
      - ip: 10.101.45.162
kind: List
metadata:
  resourceVersion: ""
ubuntu@ibtisam-iq:~$ kubectl get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.101.45.162   <none>        80:30160/TCP,443:31840/TCP   25m
ingress-nginx-controller-admission   ClusterIP   10.107.52.181   <none>        443/TCP                      25m
ubuntu@ibtisam-iq:~$ curl http://98.81.122.118:30160/frontend # wrong IP, use worker node's Public IP where it is deployed.
ubuntu@ip-172-31-23-169:~$ curl ifconfig.me
54.89.17.0ubuntu@ip-172-31-23-169:~$
ubuntu@ibtisam-iq:~$ curl http://54.89.17.0:30160/frontend
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
ubuntu@ibtisam-iq:~$ curl http://54.89.17.0:30160/backend
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```
You're **very close** to a working setup, but the 404s are happening because the **Ingress Controller** (Nginx) is working, but it's **not correctly routing** your requests to the actual backend services due to either:

## ✅ 1. **Ingress path mismatch** (MOST LIKELY)

### Let's check your `webapp` Ingress again:

```yaml
rules:
- host: ibtisam-iq.com
  http:
    paths:
    - path: /frontend
      pathType: Exact
      backend:
        service:
          name: frontend
          port:
            number: 80
    - path: /backend
      pathType: Exact
      backend:
        service:
          name: backend
          port:
            number: 80
```

> You're using `pathType: Exact`, which means **the URL must exactly match `/frontend` or `/backend`**, **without a trailing slash**, or it returns 404.

### ✅ Recommended Fix:

Use **`pathType: Prefix`**, not `Exact`, so `/frontend`, `/frontend/abc`, etc., will all work.

### Updated YAML:

```yaml
path: /frontend
pathType: Prefix
```

And same for `/backend`.

> `kubectl create ingress test-ingress --rule=ibtisam-iq.com/frontend*=frontend:80 --rule=ibtisam-iq.com/backend*=backend:80 --class nginx -n webapp`

## ✅ 2. **Missing Host Header** in your `curl`

You're accessing via IP and NodePort:

```bash
curl http://54.89.17.0:30160/frontend
```

But your Ingress has:

```yaml
host: ibtisam-iq.com
```

So Nginx Ingress Controller **expects the Host header to be ibtisam-iq.com**, not the IP. If it's not, the request won’t match any rule and returns 404.

### ✅ Fix that by adding `--header 'Host: ibtisam-iq.com'` to your curl:

```bash
curl -H "Host: ibtisam-iq.com" http://54.89.17.0:30160/frontend
curl -H "Host: ibtisam-iq.com" http://54.89.17.0:30160/backend
```

This will match the `host` field in your Ingress.

---

