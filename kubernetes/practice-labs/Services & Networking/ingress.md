# Ingress

## Ingress curl Cheatsheet (CKA Exam)

### 1. Ingress without `host`

Use the node’s IP + NodePort exposed by the ingress controller:

```bash
curl http://<node-IP>:<nodePort>/<path>
```

### 2. Ingress with `host`

**Most reliable method (works always):**

```bash
curl -H "Host: <host-from-ingress>" http://<node-IP>:<nodePort>/<path>
```

**Optional (only if DNS or `/etc/hosts` entry exists):**

```bash
curl http://<host-from-ingress>:<nodePort>/<path>
curl http://<host-from-ingress>/<path>
```

### 3. Ingress via LoadBalancer (if available)

If the ingress controller Service type is `LoadBalancer`:

```bash
curl http://<loadbalancer-IP>/<path>
```

✅ **Tips for exam**:

* You are usually on the **controlplane node** → treat it as `<node-IP>`.
* Always check the Ingress spec for `host:` and `path:` fields.
* If stuck, fall back to:

  ```bash
  curl -H "Host: <host>" http://<node-IP>:<nodePort>/<path>
  ```

  (This is the **most exam-safe command**.)

---

## 🌐 Ingress Exam Key Indicators

### 1️⃣ **Default Backend Service**

* Check controller logs:

  ```bash
  k logs -n ingress-nginx <ingress-nginx-controller-pod> | grep default-backend-service
  ```
* Ensure `--default-backend-service` flag in **ingress-nginx-controller Deployment** points to the correct namespace/name.
* ⚠️ Default backend service **does not need** to be in the same namespace as the Ingress object.

### 2️⃣ **Ingress Rules & Namespaces**

* **Rule target service (`backend.service.name`)** must exist **in the same namespace** as the Ingress object.
* `metadata.name` (Ingress name) and `spec.rules.http.paths.backend.service` share the same namespace.

### 3️⃣ **Service Port in Ingress**

* Use only **port number**, not protocol (HTTP assumed).

  ```yaml
  backend:
    service:
      name: my-service
      port:
        number: 80
  ```

✅ **Quick Exam Shortcut:**

* If it’s about *default backend service* → check controller logs + `--default-backend-service`.
* If it’s about *Ingress → Service mapping* → must be same namespace.
* If it’s about *port* → just number, no protocol.

---

## Q1 
We have deployed an application in the `green-space` namespace. we also deployed the ingress controller and the ingress resource. However, currently, the **ingress controller is not working** as expected. Inspect the ingress definitions and troubleshoot the issue so that the services are accessible as per the ingress resource definition. Also, update the path for the `app-wear-service` to `/app-wear` and `app-video-service` to `/app-video`.

```bash
root@student-node ~ ➜  k get po -n green-space 
NAME                               READY   STATUS    RESTARTS   AGE
app-video-7dd7d94477-hk5hs         1/1     Running   0          28s
app-wear-689d56b8fd-bhjwn          1/1     Running   0          28s
default-backend-569f95b877-7p26q   1/1     Running   0          28s

root@student-node ~ ➜  k get svc -n green-space 
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
app-video-service         ClusterIP   172.20.19.160    <none>        8080/TCP   84s
app-wear-service          ClusterIP   172.20.241.101   <none>        8080/TCP   84s
default-backend-service   ClusterIP   172.20.161.220   <none>        80/TCP     84s

root@student-node ~ ➜  k get po -n ingress-nginx 
NAME                                        READY   STATUS      RESTARTS      AGE
ingress-nginx-admission-create-kspvr        0/1     Completed   0             102s
ingress-nginx-admission-patch-t6px8         0/1     Completed   0             102s
ingress-nginx-controller-685f679564-m69vw   0/1     Error       4 (53s ago)   102s

root@student-node ~ ➜  k describe po -n ingress-nginx ingress-nginx-controller-685f679564-m69vw 
Name:             ingress-nginx-controller-685f679564-m69vw
Namespace:        ingress-nginx
    Args:
      /nginx-ingress-controller
      --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
      --election-id=ingress-controller-leader
      --watch-ingress-without-class=true
      --default-backend-service=default/default-backend-service      # wrong namespace
      --controller-class=k8s.io/ingress-nginx
      --ingress-class=nginx
      --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
      --validating-webhook=:8443
      --validating-webhook-certificate=/usr/local/certificates/cert
      --validating-webhook-key=/usr/local/certificates/key
Events:
  Type     Reason       Age                  From               Message
  ----     ------       ----                 ----               -------
 
  Warning  BackOff      8s (x13 over 112s)   kubelet            Back-off restarting failed container controller in pod ingress-nginx-controller-685f679564-m69vw_ingress-nginx(b0b86e95-fdf2-41e5-be9e-b26bdcbe162a)

root@student-node ~ ➜  k logs -n ingress-nginx ingress-nginx-controller-685f679564-m69vw 
-------------------------------------------------------------------------------
NGINX Ingress controller
  Release:       v1.1.2
  Build:         bab0fbab0c1a7c3641bd379f27857113d574d904
  Repository:    https://github.com/kubernetes/ingress-nginx
  nginx version: nginx/1.19.9

-------------------------------------------------------------------------------

W0911 00:54:25.993122      55 client_config.go:615] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0911 00:54:25.993223      55 main.go:223] "Creating API client" host="https://172.20.0.1:443"
I0911 00:54:26.126554      55 main.go:267] "Running in Kubernetes cluster" major="1" minor="33" git="v1.33.0" state="clean" commit="60a317eadfcb839692a68eab88b2096f4d708f4f" platform="linux/amd64"
F0911 00:54:26.128505      55 main.go:83] No service with name default-backend-service found in namespace default: services "default-backend-service" not found  # problem spotted

root@student-node ~ ➜  k get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   97m

root@student-node ~ ➜  k  edit deploy -n ingress-nginx ingress-nginx-controller
deployment.apps/ingress-nginx-controller edited

root@student-node ~ ➜  k get po -n ingress-nginx 
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-kspvr        0/1     Completed   0          6m10s
ingress-nginx-admission-patch-t6px8         0/1     Completed   0          6m10s
ingress-nginx-controller-5bdd94cfdf-4dsgx   1/1     Running     0          26s

root@student-node ~ ➜  k logs -n ingress-nginx ingress-nginx-controller-685f679564-m69vw
error: error from server (NotFound): pods "ingress-nginx-controller-685f679564-m69vw" not found in namespace "ingress-nginx"

root@student-node ~ ✖ k logs -n ingress-nginx ingress-nginx-controller-5bdd94cfdf-4dsgx 
-------------------------------------------------------------------------------
NGINX Ingress controller
  Release:       v1.1.2
  Build:         bab0fbab0c1a7c3641bd379f27857113d574d904
  Repository:    https://github.com/kubernetes/ingress-nginx
  nginx version: nginx/1.19.9

-------------------------------------------------------------------------------

W0911 00:57:03.754774      55 client_config.go:615] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0911 00:57:03.754900      55 main.go:223] "Creating API client" host="https://172.20.0.1:443"
I0911 00:57:04.290492      55 main.go:267] "Running in Kubernetes cluster" major="1" minor="33" git="v1.33.0" state="clean" commit="60a317eadfcb839692a68eab88b2096f4d708f4f" platform="linux/amd64"
I0911 00:57:04.293779      55 main.go:86] "Valid default backend" service="green-space/default-backend-service"
I0911 00:57:04.616098      55 main.go:104] "SSL fake certificate created" file="/etc/ingress-controller/ssl/default-fake-certificate.pem"
I0911 00:57:04.632310      55 ssl.go:531] "loading tls certificate" path="/usr/local/certificates/cert" key="/usr/local/certificates/key"
I0911 00:57:04.662025      55 nginx.go:255] "Starting NGINX Ingress controller"
I0911 00:57:04.666664      55 event.go:282] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"ingress-nginx", Name:"ingress-nginx-controller", UID:"7206a2cc-8dad-4bde-ba5e-30458b9748e0", APIVersion:"v1", ResourceVersion:"8554", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap ingress-nginx/ingress-nginx-controller
I0911 00:57:05.765655      55 store.go:427] "Found valid IngressClass" ingress="green-space/ingress-resource-uxz" ingressclass="nginx"
I0911 00:57:05.765807      55 event.go:282] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"green-space", Name:"ingress-resource-uxz", UID:"73c6a85d-a0c0-4d1a-b8e6-8b08c4064016", APIVersion:"networking.k8s.io/v1", ResourceVersion:"8534", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
I0911 00:57:05.863756      55 nginx.go:298] "Starting NGINX process"
I0911 00:57:05.863790      55 leaderelection.go:248] attempting to acquire leader lease ingress-nginx/ingress-controller-leader...
I0911 00:57:05.864039      55 nginx.go:318] "Starting validation webhook" address=":8443" certPath="/usr/local/certificates/cert" keyPath="/usr/local/certificates/key"
I0911 00:57:05.864259      55 controller.go:159] "Configuration changes detected, backend reload required"
I0911 00:57:05.868831      55 leaderelection.go:258] successfully acquired lease ingress-nginx/ingress-controller-leader
I0911 00:57:05.868867      55 status.go:84] "New leader elected" identity="ingress-nginx-controller-5bdd94cfdf-4dsgx"
I0911 00:57:05.874700      55 status.go:299] "updating Ingress status" namespace="green-space" ingress="ingress-resource-uxz" currentValue=[] newValue=[{IP:172.20.212.158 Hostname: Ports:[]}]
I0911 00:57:05.877995      55 event.go:282] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"green-space", Name:"ingress-resource-uxz", UID:"73c6a85d-a0c0-4d1a-b8e6-8b08c4064016", APIVersion:"networking.k8s.io/v1", ResourceVersion:"9224", FieldPath:""}): type: 'Normal' reason: 'Sync' Scheduled for sync
I0911 00:57:05.928446      55 controller.go:176] "Backend successfully reloaded"
I0911 00:57:05.928556      55 controller.go:187] "Initial sync, sleeping for 1 second"
I0911 00:57:05.928606      55 event.go:282] Event(v1.ObjectReference{Kind:"Pod", Namespace:"ingress-nginx", Name:"ingress-nginx-controller-5bdd94cfdf-4dsgx", UID:"f0099c90-411b-4b9e-a340-7588a80410e5", APIVersion:"v1", ResourceVersion:"9212", FieldPath:""}): type: 'Normal' reason: 'RELOAD' NGINX reload triggered due to a change in configuration

root@student-node ~ ➜  k get ingress -n green-space 
NAME                   CLASS   HOSTS   ADDRESS          PORTS   AGE
ingress-resource-uxz   nginx   *       172.20.212.158   80      9m51s

root@student-node ~ ➜  k describe ingress -n green-space 
Name:             ingress-resource-uxz
Labels:           <none>
Namespace:        green-space
Address:          172.20.212.158
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /app1   app-wear-service:8080 (172.17.1.2:8080)
              /app2   app-video-service:8080 (172.17.1.3:8080)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
              nginx.ingress.kubernetes.io/ssl-redirect: false
Events:
  Type    Reason  Age                    From                      Message
  ----    ------  ----                   ----                      -------
  Normal  Sync    7m14s (x2 over 7m14s)  nginx-ingress-controller  Scheduled for sync

root@student-node ~ ➜  k edit ingress -n green-space ingress-resource-uxz 
error: ingresses.networking.k8s.io "ingress-resource-uxz" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-82919705.yaml"
error: Edit cancelled, no valid changes were saved.

root@student-node ~ ➜  k replace -f /tmp/kubectl-edit-82919705.yaml --force
ingress.networking.k8s.io/ingress-resource-uxz replaced

root@student-node ~ ➜  k describe ingress -n green-space ingress-resource-uxz 
Name:             ingress-resource-uxz
Labels:           <none>
Namespace:        green-space
Address:          172.20.212.158
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /app-wear    app-wear-service:8080 (172.17.1.2:8080)        # path changed
              /app-video   app-video-service:8080 (172.17.1.3:8080)       # path changed
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
              nginx.ingress.kubernetes.io/ssl-redirect: false
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    10s (x2 over 32s)  nginx-ingress-controller  Scheduled for sync

root@student-node ~ ➜  
```

---

## Q2
A deployment called `nodeapp-dp-cka08-trb` is created in the default namespace on cluster1. This app is using an ingress resource named `nodeapp-ing-cka08-trb`.
From cluster1-controlplane host, we should be able to access this app using the command `curl http://kodekloud-ingress.app`. However, it is not working at the moment. Troubleshoot and fix the issue.

```bash
cluster1-controlplane ~ ➜  curl http://kodekloud-ingress.app
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

cluster1-controlplane ~ ➜  k get deploy 
NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
nodeapp-dp-cka08-trb                              1/1     1            1           2m44s

cluster1-controlplane ~ ➜  k get ingress
NAME                    CLASS   HOSTS         ADDRESS          PORTS   AGE
nodeapp-ing-cka08-trb   nginx   example.com   192.168.141.49   80      2m37s

cluster1-controlplane ~ ➜  k get svc
NAME                                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)            AGE
nodeapp-svc-cka08-trb                             ClusterIP   172.20.177.109   <none>        3000/TCP           3m24s

cluster1-controlplane ~ ➜  k get ingressclasses.networking.k8s.io 
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       4m31s

cluster1-controlplane ~ ➜  k get ingress nodeapp-ing-cka08-trb -o yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nodeapp-ing-cka08-trb
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: example.com                                        # wrong, change it to kodekloud-ingress.app
    http:
      paths:
      - backend:
          service:
            name: example-service                            # wrong, change it to nodeapp-svc-cka08-trb
            port:
              number: 80                                     # wrong, change it to 3000
        path: /
        pathType: Prefix

cluster1-controlplane ~ ➜  k edit ingress nodeapp-ing-cka08-trb
ingress.networking.k8s.io/nodeapp-ing-cka08-trb edited

cluster1-controlplane ~ ➜  curl http://kodekloud-ingress.app
Hello World
cluster1-controlplane ~ ➜  
```

---

## Q3
Create an ingress resource `nginx-ingress-cka04-svcn` to load balance the incoming traffic with the following specifications:

- pathType: Prefix and path: /
- Backend Service Name: nginx-service-cka04-svcn
- Backend Service Port: 80
- ssl-redirect is set to false

```bash
cluster3-controlplane ~ ➜  k get svc
NAME                        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kubernetes                  ClusterIP   10.43.0.1      <none>        443/TCP          136m
nginx-service-cka04-svcn    ClusterIP   10.43.249.67   <none>        80/TCP           38s
webapp-color-wl10-service   NodePort    10.43.94.88    <none>        8080:31354/TCP   50m

cluster3-controlplane ~ ✖ k get ingressclass
NAME      CONTROLLER                      PARAMETERS   AGE
traefik   traefik.io/ingress-controller   <none>       140m

cluster3-controlplane ~ ➜  kubectl get ingressclass -o yaml
apiVersion: v1
items:
- apiVersion: networking.k8s.io/v1
  kind: IngressClass
  metadata:
    annotations:
      ingressclass.kubernetes.io/is-default-class: "true"

cluster3-controlplane ~ ➜  kubectl get svc -n kube-system
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
kube-dns         ClusterIP      10.43.0.10      <none>           53/UDP,53/TCP,9153/TCP       145m
metrics-server   ClusterIP      10.43.69.78     <none>           443/TCP                      145m
traefik          LoadBalancer   10.43.113.178   192.168.141.16   80:32029/TCP,443:31286/TCP   145m

cluster3-controlplane ~ ➜  kubectl get svc -n kube-system
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
kube-dns         ClusterIP      10.43.0.10      <none>           53/UDP,53/TCP,9153/TCP       145m
metrics-server   ClusterIP      10.43.69.78     <none>           443/TCP                      145m
traefik          LoadBalancer   10.43.113.178   192.168.141.16   80:32029/TCP,443:31286/TCP   145m

cluster3-controlplane ~ ➜  rm -f 9.yaml 

cluster3-controlplane ~ ➜  vi 9.yaml

cluster3-controlplane ~ ➜  cat 9.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress-cka04-svcn
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"            # question marked wrong, because of its absence.
spec:
  ingressClassName: traefik
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service-cka04-svcn
            port:
              number: 80


cluster3-controlplane ~ ➜  k replace -f 9.yaml  --force
ingress.networking.k8s.io "nginx-ingress-cka04-svcn" deleted
ingress.networking.k8s.io/nginx-ingress-cka04-svcn replaced

cluster3-controlplane ~ ➜  k get ingress
NAME                       CLASS     HOSTS   ADDRESS          PORTS   AGE
nginx-ingress-cka04-svcn   traefik   *       192.168.141.16   80      9s

cluster3-controlplane ~ ➜  curl 192.168.141.16
<html>
<head><title>Hello World!</title>
  <style>
    html {
      font-size: 500.0%;
    }
    div {
      text-align: center;
    }
  </style>
</head>
<body>
  <div>Hello World!</div>
</body>
</html>

cluster3-controlplane ~ ➜  
```
Perfect! ✅

Your Traefik ingress is now working as expected:

* The **Ingress resource** `nginx-ingress-cka04-svcn` is using the **Traefik ingress class**.
* Requests to `http://192.168.141.16/` are hitting the **`nginx-service-cka04-svcn` backend**.
* Since you didn’t configure HTTPS, Traefik is serving plain HTTP by default, effectively mimicking `ssl-redirect: false`.

Your curl output showing the **“Hello World!”** page confirms that the traffic is properly routed to your service.

In short: ✅ **Traefik is now handling the ingress exactly as intended.**

--

Here’s why the check fails even if you include the annotation:

1. **Annotation is NGINX-specific**
   The annotation `nginx.ingress.kubernetes.io/ssl-redirect: "false"` is **only recognized by the NGINX Ingress Controller**. It tells NGINX not to redirect HTTP to HTTPS.

2. **Your cluster is running Traefik**
   Traefik ignores any annotations that it doesn’t understand. So even if the annotation exists on your Ingress resource, Traefik never applies it.

3. **Exam or automated checker**
   Many CKA exam auto-checkers **look for the annotation being “effectively applied”**, not just present in YAML. Because Traefik ignores it, the checker sees that `ssl-redirect` is not actually configured to `false`.

✅ So:

* Your ingress **works perfectly** for Traefik.
* The “ssl-redirect=false” requirement is **only relevant if using NGINX**, not Traefik.
* The checker fails because it expects NGINX behavior, which your cluster cannot provide.

If this were an actual exam question, the safest approach is to **use NGINX Ingress Controller** if the question explicitly mentions NGINX annotations.

---

## Q4

The Nginx Ingress Controller has been installed.

Create a new Ingress resource called `world` for domain name `world.universe.mine` . The domain points to the K8s Node IP via `/etc/hosts` .

The Ingress resource should have two routes pointing to the existing Services:

`http://world.universe.mine:30080/europe/`

and

`http://world.universe.mine:30080/asia/`

```bash
controlplane:~$ k get deploy -n world 
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
asia     2/2     2            2           105s
europe   2/2     2            2           105s
controlplane:~$ k expose deployment asia -n world --port 80
service/asia exposed
controlplane:~$ k expose deployment europe -n world --port 80
service/europe exposed
controlplane:~$ k get svc -n world 
NAME     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
asia     ClusterIP   10.104.4.232     <none>        80/TCP    27s
europe   ClusterIP   10.103.132.146   <none>        80/TCP    11s
controlplane:~$ k get ingressclasses.networking.k8s.io 
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       8m44s
controlplane:~$ vi ingress.yaml
controlplane:~$ k apply -f ingress.yaml 
ingress.networking.k8s.io/world created
controlplane:~$ k get ingress
No resources found in default namespace.
controlplane:~$ k get ingress -n world 
NAME    CLASS   HOSTS                 ADDRESS      PORTS   AGE
world   nginx   world.universe.mine   172.30.1.2   80      15s
controlplane:~$ k get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.109.137.75   <none>        80:30080/TCP,443:30443/TCP   17m
ingress-nginx-controller-admission   ClusterIP   10.104.104.54   <none>        443/TCP                      17m
controlplane:~$ cat /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
127.0.0.1 ubuntu
127.0.0.1 host01
127.0.0.1 controlplane
172.30.1.2 world.universe.mine
controlplane:~$ http://world.universe.mine:30080/europe/
bash: http://world.universe.mine:30080/europe/: No such file or directory
controlplane:~$ curl http://world.universe.mine:30080/europe/
hello, you reached EUROPE
controlplane:~$ curl http://world.universe.mine:30080/asia/
hello, you reached ASIA
```

---

## Q5

A new payment service has been introduced. Since it is a sensitive application, it is deployed in its own namespace `critical-space`. Inspect the resources and service created. You are requested to make the new application available at `/pay`. Create an ingress resource named `ingress-ckad09-svcn` for the payment application to make it available at `/pay`.

```bash
root@student-node ~ ➜  k get po -n ingress-nginx 
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-6dhz8       0/1     Completed   0          76s
ingress-nginx-admission-patch-pkv5s        0/1     Completed   0          76s
ingress-nginx-controller-68bb49f4f-kkr98   1/1     Running     0          76s

root@student-node ~ ➜  k get svc,po -n critical-space 
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/pay-service   ClusterIP   172.20.122.122   <none>        8282/TCP   103s

NAME                              READY   STATUS    RESTARTS   AGE
pod/webapp-pay-7df499586f-48cxm   1/1     Running   0          103s

root@student-node ~ ➜  k get po -n ingress-nginx ingress-nginx-controller-68bb49f4f-kkr98 -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: ingress-nginx-controller-68bb49f4f-kkr98
  namespace: ingress-nginx
spec:
  containers:
  - args:
    - /nginx-ingress-controller
    - --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
    - --election-id=ingress-controller-leader
    - --watch-ingress-without-class=true
    - --default-backend-service=app-space/default-backend-service        # Notice here
    - --controller-class=k8s.io/ingress-nginx
    - --ingress-class=nginx
    - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
    - --validating-webhook=:8443
    - --validating-webhook-certificate=/usr/local/certificates/cert
    - --validating-webhook-key=/usr/local/certificates/key


root@student-node ~ ➜  k get svc -n app-space 
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
default-backend-service   ClusterIP   172.20.122.209   <none>        80/TCP     7m48s    # present here, that's why controller pod is ruuning
video-service             ClusterIP   172.20.49.211    <none>        8080/TCP   7m48s
wear-service              ClusterIP   172.20.72.245    <none>        8080/TCP   7m48s

root@student-node ~ ➜  k get svc -n critical-space 
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
pay-service   ClusterIP   172.20.122.122   <none>        8282/TCP   8m13s

root@student-node ~ ➜  vi 11.yaml

root@student-node ~ ➜  k apply -f 11.yaml 
ingress.networking.k8s.io/ingress-ckad09-svcn created

root@student-node ~ ➜  k describe ingress -n critical-space 
Name:             ingress-ckad09-svcn
Labels:           <none>
Namespace:        critical-space
Address:          
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /pay   pay-service:8282 (172.17.1.7:8080)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    22s   nginx-ingress-controller  Scheduled for sync

root@student-node ~ ➜  cat 11.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-ckad09-svcn
  namespace: critical-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /pay
        pathType: Prefix
        backend:
          service:
            name: pay-service
            port:
              number: 8282 
```

Exactly ❤️ you’ve done it right.

Let’s read your `kubectl describe ingress` carefully:

```
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /pay   pay-service:8282 (172.17.1.7:8080)
```

### What this means

* **Default backend: `<default>`**
  👉 This just shows that the **Ingress Controller Pod itself** has a global default backend (configured via `--default-backend-service=app-space/default-backend-service`).
  👉 It’s **not coming from your Ingress resource**. Your Ingress does **not** define any `defaultBackend` section — so you’re ✅ safe.

* **Rules**

  * Path `/pay` → `pay-service:8282` (and we can see it’s sending traffic to Pod IP `172.17.1.7:8080` behind the service).
  * That’s exactly what the task wanted.


### Conclusion

Your Ingress **does not contain a backend service definition itself** — it only defines a rule.
The mention of `<default>` is just informational, showing the controller’s global default backend, not part of your YAML.

**Exactly ✅ you got it.**

Let me clear this up for you step by step:

### 1. Where the default backend is set

In your **Ingress Controller Pod args** (`ingress-nginx-controller` in `ingress-nginx` namespace), you have:

```yaml
--default-backend-service=app-space/default-backend-service
```

👉 This means the controller itself will use `default-backend-service` in the **`app-space` namespace** whenever:

* A request doesn’t match any Ingress rule, or
* An Ingress has no rules/paths defined.

### 2. Where your Ingress lives

Your Ingress resource:

* Namespace = `critical-space`
* Rules = only `/pay` → `pay-service:8282`

👉 This Ingress has **no defaultBackend field**, so it never overrides anything.
👉 It only routes requests for `/pay` to `pay-service`.


### 3. How they connect

* **Global default backend** = comes from the controller (in `app-space`).
* **Ingress-specific rules** = come from your Ingress (in `critical-space`).
* They do **not need to be in the same namespace**. The controller doesn’t care; it just knows where to send unmatched traffic globally.

✅ So yes: the default backend service in the controller args belongs to `app-space`, and it does **not** have to match the namespace where you created your Ingress (`critical-space`).


---

# Q6

Create a single ingress resource called `ingress-vh-routing`. The resource should route HTTP traffic to **multiple hostnames** as specified below:

The service `video-service` should be accessible on `http://watch.ecom-store.com:30093/video`

The service `apparels-service` should be accessible on `http://apparels.ecom-store.com:30093/wear`

To ensure that the path is correctly rewritten for the backend service, add the following annotation to the resource:

`nginx.ingress.kubernetes.io/rewrite-target: /`

Here `30093` is the port used by the Ingress Controller

```bash

controlplane ~ ➜  cat 4.yaml                 # Wrong, because I overlooked about multiple hostnames
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-vh-routing
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: "watch.ecom-store.com"
    http:
      paths:
      - path: /video
        pathType: Prefix
        backend:
          service:
            name: video-service
            port:
              number: 8080
      - path: /wear
        pathType: Prefix
        backend:
          service:
            name: apparels-service
            port:
              number: 8080


controlplane ~ ➜  cat > 4.yaml
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: ingress-vh-routing
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: watch.ecom-store.com
    http:
      paths:
      - pathType: Prefix
        path: "/video"
        backend:
          service:
            name: video-service
            port:
              number: 8080
  - host: apparels.ecom-store.com
    http:
      paths:
      - pathType: Prefix
        path: "/wear"
        backend:
          service:
            name: apparels-service
            port:
              number: 8080

controlplane ~ ➜  k replace -f 4.yaml --force
ingress.networking.k8s.io "ingress-vh-routing" deleted
ingress.networking.k8s.io/ingress-vh-routing replaced

controlplane ~ ➜
```
