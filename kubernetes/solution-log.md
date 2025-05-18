
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

# ✅ **Pods – Hands-on Questions**

1. Create a pod named `nginx-pod` using the `nginx` image.
2. Create a pod that runs a `busybox` container and sleeps for 3600 seconds.
3. Create a pod with two containers: `nginx` and `busybox` (running `sleep 3600`).
4. Create a pod with a specific label `app=web`, and verify it using `kubectl get pods --show-labels`.
5. Create a pod with a volume mounted at `/data` using `emptyDir`.
6. Run a pod with environment variables set (e.g., `ENV=prod`, `DEBUG=true`).
7. Create a pod that uses a config map as environment variables.
8. Create a pod with a command override that runs `echo Hello Kubernetes && sleep 3600`.
9. Create a pod with a liveness probe that checks `/health` on port 80 every 5 seconds. **skipped**
10. Create a pod with a readiness probe using `exec` to check file existence. **skipped**
11. Create a pod and limit its CPU to 500m and memory to 128Mi.
12. Create a pod that mounts a secret to `/etc/secret-data`.

```bash
ubuntu@ip-172-31-29-122:~$ hostname
ibtisam-iq
ubuntu@ip-172-31-29-122:~$ kubectl run nginx-pod --image nginx
pod/nginx-pod created
ubuntu@ip-172-31-29-122:~$ kubectl get po nginx-pod -o wide
NAME        READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
nginx-pod   1/1     Running   0          19s   10.244.171.68   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl run abc --image busybox -o yaml -- "sleep 3600"
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2025-05-17T10:53:06Z"
  labels:
    run: abc
  name: abc
  namespace: default
  resourceVersion: "1622"
  uid: 6c452c4e-cd0b-483f-851b-893ef65ec891
spec:
  containers:
  - args:
    - sleep 3600
    image: busybox
ubuntu@ip-172-31-29-122:~$ kubectl get po -o wide
NAME        READY   STATUS              RESTARTS     AGE     IP              NODE     NOMINATED NODE   READINESS GATES
abc         0/1     RunContainerError   3 (4s ago)   50s     10.244.171.69   worker   <none>           <none>
nginx-pod   1/1     Running             0            2m22s   10.244.171.68   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl delete po abc
pod "abc" deleted
ubuntu@ip-172-31-29-122:~$ kubectl run abc --image busybox -o yaml -- sleep 3600
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2025-05-17T10:54:49Z"
  labels:
    run: abc
  name: abc
  namespace: default
  resourceVersion: "1813"
  uid: bd0f8927-adb7-4096-9eb1-02f519a6305c
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: busybox
ubuntu@ip-172-31-29-122:~$ kubectl get po -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   0          17s     10.244.171.70   worker   <none>           <none>
nginx-pod   1/1     Running   0          3m32s   10.244.171.68   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl get po abc -o yaml > def.yaml
ubuntu@ip-172-31-29-122:~$ vi def.yaml 
ubuntu@ip-172-31-29-122:~$ kubectl apply -f def.yaml 
pod/def created
ubuntu@ip-172-31-29-122:~$ cat def.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: def
  namespace: default
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: busybox
    name: busybox
  - image: nginx
    name: nginx
ubuntu@ip-172-31-29-122:~$ kubectl get po -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   0          6m5s    10.244.171.70   worker   <none>           <none>
def         2/2     Running   0          18s     10.244.171.71   worker   <none>           <none>
nginx-pod   1/1     Running   0          9m20s   10.244.171.68   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ 
ubuntu@ip-172-31-29-122:~$ kubectl run ghi --image nginx -l app=web
pod/ghi created
ubuntu@ip-172-31-29-122:~$ kubectl get pods --show-labels
NAME        READY   STATUS    RESTARTS   AGE     LABELS
abc         1/1     Running   0          8m24s   run=abc
def         2/2     Running   0          2m37s   <none>
ghi         1/1     Running   0          25s     app=web
nginx-pod   1/1     Running   0          11m     run=nginx-pod
ubuntu@ip-172-31-29-122:~$ kubectl get pods -l app=web
NAME   READY   STATUS    RESTARTS   AGE
ghi    1/1     Running   0          62s
ubuntu@ip-172-31-29-122:~$ vi def.yaml 
ubuntu@ip-172-31-29-122:~$ kubectl apply -f def.yaml 
pod/vol-mount created
ubuntu@ip-172-31-29-122:~$ cat def.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: vol-mount
  namespace: default
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: busybox
    name: busybox
    volumeMounts:
      - mountPath: /data
        name: abc
  volumes:
    - name: abc
      emptyDir: {}
ubuntu@ip-172-31-29-122:~$ kubectl get po -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   0          16m     10.244.171.70   worker   <none>           <none>
def         2/2     Running   0          10m     10.244.171.71   worker   <none>           <none>
ghi         1/1     Running   0          8m39s   10.244.171.72   worker   <none>           <none>
nginx-pod   1/1     Running   0          19m     10.244.171.68   worker   <none>           <none>
vol-mount   1/1     Running   0          26s     10.244.171.73   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl run xyz --image nginx --env ENV=prod --env DEBUG=true
pod/xyz created
ubuntu@ip-172-31-29-122:~$ kubectl get po -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   0          18m     10.244.171.70   worker   <none>           <none>
def         2/2     Running   0          12m     10.244.171.71   worker   <none>           <none>
ghi         1/1     Running   0          10m     10.244.171.72   worker   <none>           <none>
nginx-pod   1/1     Running   0          21m     10.244.171.68   worker   <none>           <none>
vol-mount   1/1     Running   0          2m29s   10.244.171.73   worker   <none>           <none>
xyz         1/1     Running   0          4s      10.244.171.74   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl create cm myconfigmap --from-literal city NYC
error: exactly one NAME is required, got 2
See 'kubectl create configmap -h' for help and examples
ubuntu@ip-172-31-29-122:~$ kubectl create cm myconfigmap --from-literal city=NYC
configmap/myconfigmap created
ubuntu@ip-172-31-29-122:~$ vi def.yaml 
ubuntu@ip-172-31-29-122:~$ kubectl apply -f def.yaml 
pod/cm created
ubuntu@ip-172-31-29-122:~$ cat def.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: cm
  namespace: default
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: busybox
    name: busybox
    envFrom:
    - configMapRef:     
       name: myconfigmap
ubuntu@ip-172-31-29-122:~$ kubectl get po -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   0          26m     10.244.171.70   worker   <none>           <none>
cm          1/1     Running   0          29s     10.244.171.75   worker   <none>           <none>
def         2/2     Running   0          20m     10.244.171.71   worker   <none>           <none>
ghi         1/1     Running   0          18m     10.244.171.72   worker   <none>           <none>
nginx-pod   1/1     Running   0          29m     10.244.171.68   worker   <none>           <none>
vol-mount   1/1     Running   0          10m     10.244.171.73   worker   <none>           <none>
xyz         1/1     Running   0          7m49s   10.244.171.74   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl exec cm -it -- sh
/ # echo $city
NYC
/ # exit
ubuntu@ip-172-31-29-122:~$ vi def.yaml 
ubuntu@ip-172-31-29-122:~$ kubectl apply -f def.yaml 
error: error parsing def.yaml: error converting YAML to JSON: yaml: line 9: did not find expected ',' or ']'
ubuntu@ip-172-31-29-122:~$ vi def.yaml 
ubuntu@ip-172-31-29-122:~$ kubectl apply -f def.yaml 
pod/cmd created
ubuntu@ip-172-31-29-122:~$ cat def.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: cmd
  namespace: default
spec:
  containers:
  - image: busybox
    name: busybox
    command: ["sh", "-c"]
    args: ["echo Hello Kubernetes && sleep 3600"]
ubuntu@ip-172-31-29-122:~$ kubectl logs cmd
Hello Kubernetes
ubuntu@ip-172-31-29-122:~$ kubectl get po -o wide
NAME        READY   STATUS    RESTARTS   AGE    IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   0          35m    10.244.171.70   worker   <none>           <none>
cm          1/1     Running   0          9m4s   10.244.171.75   worker   <none>           <none>
cmd         1/1     Running   0          43s    10.244.171.76   worker   <none>           <none>
def         2/2     Running   0          29m    10.244.171.71   worker   <none>           <none>
ghi         1/1     Running   0          27m    10.244.171.72   worker   <none>           <none>
nginx-pod   1/1     Running   0          38m    10.244.171.68   worker   <none>           <none>
vol-mount   1/1     Running   0          18m    10.244.171.73   worker   <none>           <none>
xyz         1/1     Running   0          16m    10.244.171.74   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl create secret generic mysecret --from-literal city NYC
error: exactly one NAME is required, got 2
See 'kubectl create secret generic -h' for help and examples
ubuntu@ip-172-31-29-122:~$ kubectl create secret generic mysecret --from-literal city=NYC
secret/mysecret created
ubuntu@ip-172-31-29-122:~$ vi sec.yaml
ubuntu@ip-172-31-29-122:~$ kubectl apply -f sec.yaml 
pod/sec-mount created
ubuntu@ip-172-31-29-122:~$ cat sec.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: sec-mount
  namespace: default
spec:
  containers:
  - args:
    - sleep
    - "3600"
    image: busybox
    name: busybox
    volumeMounts:
      - mountPath: "/etc/secret-data"
        name: def
  volumes:
    - name: def
      secret:
        secretName: mysecret

ubuntu@ip-172-31-29-122:~$ kubectl get pods -o wide
NAME        READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   0          44m   10.244.171.70   worker   <none>           <none>
cm          1/1     Running   0          18m   10.244.171.75   worker   <none>           <none>
cmd         1/1     Running   0          10m   10.244.171.76   worker   <none>           <none>
def         2/2     Running   0          38m   10.244.171.71   worker   <none>           <none>
ghi         1/1     Running   0          36m   10.244.171.72   worker   <none>           <none>
nginx-pod   1/1     Running   0          47m   10.244.171.68   worker   <none>           <none>
sec-mount   1/1     Running   0          28s   10.244.171.77   worker   <none>           <none>
vol-mount   1/1     Running   0          28m   10.244.171.73   worker   <none>           <none>
xyz         1/1     Running   0          25m   10.244.171.74   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ kubectl exec sec-mount -it -- sh
/ # echo $city

/ # ls
bin    dev    etc    home   lib    lib64  proc   root   sys    tmp    usr    var
/ # ls etc/secret-data/
city
/ # cat etc/secret-data/
cat: read error: Is a directory
/ # cat etc/secret-data/city 
NYC/ # exit
ubuntu@ip-172-31-29-122:~$ vi def.yaml 
ubuntu@ip-172-31-29-122:~$ kubectl apply -f def.yaml 
pod/resources created
ubuntu@ip-172-31-29-122:~$ kubectl get pods -o wide
NAME        READY   STATUS    RESTARTS        AGE   IP              NODE     NOMINATED NODE   READINESS GATES
abc         1/1     Running   1 (21m ago)     81m   10.244.171.70   worker   <none>           <none>
cm          1/1     Running   0               55m   10.244.171.75   worker   <none>           <none>
cmd         1/1     Running   0               47m   10.244.171.76   worker   <none>           <none>
def         2/2     Running   1 (15m ago)     75m   10.244.171.71   worker   <none>           <none>
ghi         1/1     Running   0               73m   10.244.171.72   worker   <none>           <none>
nginx-pod   1/1     Running   0               85m   10.244.171.68   worker   <none>           <none>
resources   1/1     Running   0               6s    10.244.171.78   worker   <none>           <none>
sec-mount   1/1     Running   0               37m   10.244.171.77   worker   <none>           <none>
vol-mount   1/1     Running   1 (5m32s ago)   65m   10.244.171.73   worker   <none>           <none>
xyz         1/1     Running   0               63m   10.244.171.74   worker   <none>           <none>
ubuntu@ip-172-31-29-122:~$ cat def.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: resources
  namespace: default
spec:
  containers:
  - image: busybox
    name: busybox
    command: ["sh", "-c"]
    args: ["echo Hello Kubernetes && sleep 3600"]
    resources:
      limits:
        cpu: "500m"
        memory: "128Mi"
ubuntu@ip-172-31-29-122:~$ 
```

### ✅ **Question**

> Create a pod with a **liveness probe** that checks `/health` on port `80` every `5 seconds`.

#### ✅ **Solution**: `liveness-pod.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-pod
  labels:
    app: liveness-demo
spec:
  containers:
  - name: myapp
    image: nginx
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /health      # <-- Probe will hit http://localhost/health
        port: 80           # <-- On container's port 80
      initialDelaySeconds: 5  # <-- Delay before first probe after container starts
      periodSeconds: 5        # <-- Probes every 5 seconds
```

> 💡 Note: `/health` must be a valid endpoint for this to succeed. In a real app, you'd ensure this route exists.


### ✅ **Question**

> Create a pod with a **readiness probe** using `exec` to check **file existence**.

#### ✅ **Solution**: `readiness-exec-pod.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-pod
  labels:
    app: readiness-demo
spec:
  containers:
  - name: myapp
    image: busybox
    command: ["/bin/sh", "-c", "touch /tmp/ready && sleep 3600"]
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/ready       # <-- Check if this file exists
      initialDelaySeconds: 5
      periodSeconds: 10
```

> 💡 The `touch /tmp/ready` ensures the file exists when the probe starts. Without it, the pod would be marked *NotReady*.

---

### ✅ **Services – Hands-on Questions**

13. Create a service of type ClusterIP that exposes `nginx-pod` on port 80.
14. Create a service of type NodePort for a `httpd` deployment.
15. Create a headless service for a StatefulSet.
16. Create a service with `app=backend` selector that points to port 8080 on pods.
17. Create a service with multiple ports exposed (e.g., 80 and 443).
18. Expose a deployment as a ClusterIP service named `web-service`.
19. Expose a pod directly using a service (without a deployment).
20. Create an ExternalName service pointing to `my.external.com`.
21. Verify service endpoints and understand why they may be empty.
22. Create a service using YAML with explicit `targetPort`, `port`, and `nodePort`.

```bash
ubuntu@ip-172-31-29-122:~$ kubectl run nginx-pod --image nginx --port 80 --expose
service/nginx-pod created
pod/nginx-pod created
ubuntu@ip-172-31-29-122:~$ kubectl get po,svc -o wide
NAME            READY   STATUS    RESTARTS   AGE   IP              NODE     NOMINATED NODE   READINESS GATES
pod/nginx-pod   1/1     Running   0          15s   10.244.171.79   worker   <none>           <none>

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE    SELECTOR
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   107m   <none>
service/nginx-pod    ClusterIP   10.109.118.167   <none>        80/TCP    15s    run=nginx-pod
ubuntu@ip-172-31-29-122:~$ curl 10.244.171.79:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
ubuntu@ip-172-31-29-122:~$ curl 10.109.118.167:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
ubuntu@ip-172-31-29-122:~$ kubectl create deploy httpd --image httpd -r 1 --port 80
deployment.apps/httpd created
ubuntu@ip-172-31-29-122:~$ kubectl expose deploy httpd --port 80 --type NodePort
service/httpd exposed
ubuntu@ip-172-31-29-122:~$ kubectl get po,svc -o wide
NAME                         READY   STATUS    RESTARTS   AGE     IP              NODE     NOMINATED NODE   READINESS GATES
pod/httpd-7cbf599dd4-x45fx   1/1     Running   0          52s     10.244.171.80   worker   <none>           <none>
pod/nginx-pod                1/1     Running   0          4m25s   10.244.171.79   worker   <none>           <none>

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE     SELECTOR
service/httpd        NodePort    10.100.142.57    <none>        80:31935/TCP   7s      app=httpd
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        112m    <none>
service/nginx-pod    ClusterIP   10.109.118.167   <none>        80/TCP         4m25s   run=nginx-pod
ubuntu@ip-172-31-29-122:~$ curl localhost:31935
<html><body><h1>It works!</h1></body></html>
ubuntu@ip-172-31-29-122:~$ curl ifconfig.me
34.229.168.73ubuntu@ip-172-31-29-122:~$ curl http://34.229.168.73:31935/
<html><body><h1>It works!</h1></body></html>
ubuntu@ip-172-31-29-122:~$ kubectl run test --image busybox --port 8080 -l app=backend -- sleep 3600
pod/test created
ubuntu@ip-172-31-29-122:~$ kubectl expose po test --port 8080
service/test exposed
ubuntu@ip-172-31-29-122:~$ kubectl describe svc test
Name:                     test
Namespace:                default
Labels:                   app=backend
Annotations:              <none>
Selector:                 app=backend
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.100.227.148
IPs:                      10.100.227.148
Port:                     <unset>  8080/TCP
TargetPort:               8080/TCP
Endpoints:                10.244.171.81:8080
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
ubuntu@ip-172-31-29-122:~$ kubectl create svc clusterip two-ports --tcp 80:80,443,443
error: failed to create ClusterIP service: Service "two-ports" is invalid: [spec.ports[2].name: Duplicate value: "443", spec.ports[2]: Duplicate value: core.ServicePort{Name:"", Protocol:"TCP", AppProtocol:(*string)(nil), Port:443, TargetPort:intstr.IntOrString{Type:0, IntVal:0, StrVal:""}, NodePort:0}]
ubuntu@ip-172-31-29-122:~$ kubectl create svc clusterip two-ports --tcp 80:80,443:443
service/two-ports created
ubuntu@ip-172-31-29-122:~$ kubectl describe svc two-ports
Name:                     two-ports
Namespace:                default
Labels:                   app=two-ports
Annotations:              <none>
Selector:                 app=two-ports
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.105.165.185
IPs:                      10.105.165.185
Port:                     80-80  80/TCP
TargetPort:               80/TCP
Endpoints:                
Port:                     443-443  443/TCP
TargetPort:               443/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
ubuntu@ip-172-31-29-122:~$ kubectl edit svc two-ports
service/two-ports edited
ubuntu@ip-172-31-29-122:~$ kubectl describe svc two-ports
Name:                     two-ports
Namespace:                default
Labels:                   app=two-ports
Annotations:              <none>
Selector:                 app=two-ports
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.105.165.185
IPs:                      10.105.165.185
Port:                     one  80/TCP
TargetPort:               80/TCP
Endpoints:                
Port:                     two  443/TCP
TargetPort:               443/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
ubuntu@ip-172-31-29-122:~$ kubectl get deploy
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
httpd   1/1     1            1           19m
ubuntu@ip-172-31-29-122:~$ kubectl expose deploy httpd --port 80 --name web-service
service/web-service exposed
ubuntu@ip-172-31-29-122:~$ kubectl run no-deploy --port 80 --expose --image nginx
service/no-deploy created
pod/no-deploy created
ubuntu@ip-172-31-29-122:~$ kubectl create svc externalname test-abc -o yaml --dry-run
error: required flag(s) "external-name" not set
ubuntu@ip-172-31-29-122:~$ kubectl create svc externalname --help
Create an ExternalName service with the specified name.
Usage:
  kubectl create service externalname NAME --external-name external.name [--dry-run=server|client|none] [options]

Use "kubectl options" for a list of global command-line options (applies to all commands).
ubuntu@ip-172-31-29-122:~$ kubectl create service externalname my-external-com --external-name my.external.com
service/my-external-com created
ubuntu@ip-172-31-29-122:~$ kubectl get po,deploy,svc -o wide
NAME                         READY   STATUS    RESTARTS   AGE    IP              NODE     NOMINATED NODE   READINESS GATES
pod/httpd-7cbf599dd4-x45fx   1/1     Running   0          28m    10.244.171.80   worker   <none>           <none>
pod/nginx-pod                1/1     Running   0          31m    10.244.171.79   worker   <none>           <none>
pod/no-deploy                1/1     Running   0          6m6s   10.244.171.82   worker   <none>           <none>
pod/test                     1/1     Running   0          19m    10.244.171.81   worker   <none>           <none>

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES   SELECTOR
deployment.apps/httpd   1/1     1            1           28m   httpd        httpd    app=httpd

NAME                      TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)          AGE     SELECTOR
service/httpd             NodePort       10.100.142.57    <none>            80:31935/TCP     27m     app=httpd
service/kubernetes        ClusterIP      10.96.0.1        <none>            443/TCP          139m    <none>
service/my-external-com   ExternalName   <none>           my.external.com   <none>           62s     app=my-external-com
service/nginx-pod         ClusterIP      10.109.118.167   <none>            80/TCP           31m     run=nginx-pod
service/no-deploy         ClusterIP      10.101.35.17     <none>            80/TCP           6m6s    run=no-deploy
service/test              ClusterIP      10.100.227.148   <none>            8080/TCP         18m     app=backend
service/two-ports         ClusterIP      10.105.165.185   <none>            80/TCP,443/TCP   13m     app=two-ports
service/web-service       ClusterIP      10.98.122.15     <none>            80/TCP           7m23s   app=httpd
ubuntu@ip-172-31-29-122:~$ 
```

---

## ✅ **Ingress – Hands-on Questions**

23. Deploy ingress-nginx controller using the official YAML.
24. Create an Ingress resource routing:

    * `/frontend` → service `frontend:80`
    * `/backend` → service `backend:80`
25. Create an Ingress with host `myapp.com` pointing `/` to service `web`.
26. Create an Ingress resource with TLS using a Kubernetes Secret.
27. Use pathType: `Prefix` and `Exact` in two different rules and explain the difference.
28. Configure multiple hosts in a single Ingress: `api.domain.com`, `admin.domain.com`.
29. Debug an Ingress showing 404 — how to identify whether the issue is with rules, service, or ingress controller.
30. Use annotations to enable HTTPS redirect in Ingress.
31. Add custom headers in an Ingress using annotations.
32. Configure Ingress to use a default backend.

### **23. Deploy ingress-nginx controller using the official YAML**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

> ✅ This deploys the ingress controller in the `ingress-nginx` namespace. It creates the necessary deployment, services, RBAC, etc.



### **24. Create an Ingress resource routing:**

* `/frontend` → service `frontend:80`
* `/backend` → service `backend:80`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /frontend
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /backend
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 80
```

> ✅ This routes `/frontend` and `/backend` traffic to respective services.



### **25. Create an Ingress with host `myapp.com` pointing `/` to service `web`**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80 # even if the question doesn't mention the number — you can assume 80 unless told otherwise.
```

> ✅ Access using curl with custom Host header:
> `curl -H "Host: myapp.com" http://<NODE-IP>:<NodePort>`



### **26. Create an Ingress resource with TLS using a Kubernetes Secret**

```bash
kubectl create secret tls my-tls-secret --cert=tls.crt --key=tls.key -n default
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.com
    secretName: my-tls-secret
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

> ✅ This enables HTTPS traffic for the Ingress.



### **27. Use pathType: `Prefix` and `Exact` in different rules**

```yaml
spec:
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /login
        pathType: Exact
        backend:
          service:
            name: login-service
            port:
              number: 80
```

> 🔍 **Prefix** matches `/api`, `/api/v1`, `/api/v1/test`
> 🔍 **Exact** matches only `/login`, nothing more.



### **28. Configure multiple hosts in a single Ingress**

```yaml
spec:
  ingressClassName: nginx
  rules:
  - host: api.domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api
            port:
              number: 80
  - host: admin.domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin
            port:
              number: 80
```

> ✅ Ingress supports multiple domains in one YAML.



### **29. Debug an Ingress showing 404**

> 💡 Step-by-step:

```bash
# 1. Check ingress rules
kubectl describe ingress <name>

# 2. Check services exist and ports match
kubectl get svc

# 3. Check endpoints exist
kubectl get endpoints

# 4. Check ingress controller logs
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller

# 5. Use correct Host header and path in curl
```

> ⚠️ 404 often means:
>
> * Incorrect path or service name
> * Service has no endpoints (pods not ready)
> * Missing Host header



### **30. Use annotations to enable HTTPS redirect**

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

> 🔐 This redirects all HTTP to HTTPS.

### **31. Add custom headers in Ingress using annotations**

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Content-Type-Options: nosniff";
```

> 🧠 This allows response headers to be modified.

### **32. Configure Ingress to use a default backend**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: default-ingress
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: fallback-service
      port:
        number: 80
```

> ✅ Traffic that doesn’t match any rule is forwarded to this service.

---

