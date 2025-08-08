```bash
controlplane ~ ➜  k get no -o wide
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
controlplane   Ready    control-plane   41m   v1.33.0   192.168.121.223   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node01         Ready    <none>          40m   v1.33.0   192.168.102.168   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node02         Ready    <none>          40m   v1.33.0   192.168.121.196   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26

controlplane ~ ➜  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.0/deploy/static/provider/cloud/deploy.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created

controlplane ~ ➜  k get all -n ingress-nginx 
NAME                                           READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-95f6586c6-2mskp   1/1     Running   0          55s

NAME                                         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   172.20.36.22    <pending>     80:31987/TCP,443:31268/TCP   55s
service/ingress-nginx-controller-admission   ClusterIP      172.20.215.37   <none>        443/TCP                      55s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           55s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-95f6586c6   1         1         1       55s

controlplane ~ ➜  k get svc -n ingress-nginx 
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   172.20.36.22    <pending>     80:31987/TCP,443:31268/TCP   89s
ingress-nginx-controller-admission   ClusterIP      172.20.215.37   <none>        443/TCP                      89s

controlplane ~ ➜  k create deploy nginx -r 3 --port 80
error: required flag(s) "image" not set

controlplane ~ ✖ k create deploy nginx -r 3 --port 80 --image nginx
deployment.apps/nginx created

controlplane ~ ➜  k expose deployment nginx --port 80
service/nginx exposed

controlplane ~ ➜  k get svc nginx 
NAME    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
nginx   ClusterIP   172.20.17.23   <none>        80/TCP    19s

controlplane ~ ➜  k describe svc nginx 
Name:                     nginx
Namespace:                default
Labels:                   app=nginx
Annotations:              <none>
Selector:                 app=nginx
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.17.23
IPs:                      172.20.17.23
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                172.17.1.4:80,172.17.2.3:80,172.17.2.4:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

controlplane ~ ➜  vi ingress.yaml

controlplane ~ ➜  k describe deploy -n ingress-nginx 
Name:                   ingress-nginx-controller
Namespace:              ingress-nginx
CreationTimestamp:      Fri, 08 Aug 2025 12:49:44 +0000
Labels:                 app.kubernetes.io/component=controller
                        app.kubernetes.io/instance=ingress-nginx
                        app.kubernetes.io/name=ingress-nginx
                        app.kubernetes.io/part-of=ingress-nginx
                        app.kubernetes.io/version=1.13.0
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  1 max unavailable, 25% max surge
Pod Template:
  Labels:           app.kubernetes.io/component=controller
                    app.kubernetes.io/instance=ingress-nginx
                    app.kubernetes.io/name=ingress-nginx
                    app.kubernetes.io/part-of=ingress-nginx
                    app.kubernetes.io/version=1.13.0
  Service Account:  ingress-nginx
  Containers:
   controller:
    Image:           registry.k8s.io/ingress-nginx/controller:v1.13.0@sha256:dc75a7baec7a3b827a5d7ab0acd10ab507904c7dad692365b3e3b596eca1afd2
    Ports:           80/TCP, 443/TCP, 8443/TCP
    Host Ports:      0/TCP, 0/TCP, 0/TCP
    SeccompProfile:  RuntimeDefault
    Args:
      /nginx-ingress-controller
      --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
      --election-id=ingress-nginx-leader
      --controller-class=k8s.io/ingress-nginx
      --ingress-class=nginx
      --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
      --validating-webhook=:8443
      --validating-webhook-certificate=/usr/local/certificates/cert
      --validating-webhook-key=/usr/local/certificates/key
    Requests:
      cpu:      100m
      memory:   90Mi
    Liveness:   http-get http://:10254/healthz delay=10s timeout=1s period=10s #success=1 #failure=5
    Readiness:  http-get http://:10254/healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:
      POD_NAME:        (v1:metadata.name)
      POD_NAMESPACE:   (v1:metadata.namespace)
      LD_PRELOAD:     /usr/local/lib/libmimalloc.so
    Mounts:
      /usr/local/certificates/ from webhook-cert (ro)
  Volumes:
   webhook-cert:
    Type:          Secret (a volume populated by a Secret)
    SecretName:    ingress-nginx-admission
    Optional:      false
  Node-Selectors:  kubernetes.io/os=linux
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   ingress-nginx-controller-95f6586c6 (1/1 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  6m32s  deployment-controller  Scaled up replica set ingress-nginx-controller-95f6586c6 from 0 to 1

controlplane ~ ➜  cat ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ibtisam-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /ibtisam
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80


controlplane ~ ➜  k apply -f ingress.yaml 
ingress.networking.k8s.io/ibtisam-ingress created

controlplane ~ ➜  k get ingress
NAME              CLASS   HOSTS   ADDRESS   PORTS   AGE
ibtisam-ingress   nginx   *                 80      9s

controlplane ~ ➜  k describe ingress ibtisam-ingress 
Name:             ibtisam-ingress
Labels:           <none>
Namespace:        default
Address:          
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /ibtisam   nginx:80 (172.17.1.4:80,172.17.2.3:80,172.17.2.4:80)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    24s   nginx-ingress-controller  Scheduled for sync

controlplane ~ ➜  k get no -o wide
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
controlplane   Ready    control-plane   50m   v1.33.0   192.168.121.223   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node01         Ready    <none>          49m   v1.33.0   192.168.102.168   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node02         Ready    <none>          49m   v1.33.0   192.168.121.196   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26

controlplane ~ ➜  k get svc -n ingress-nginx 
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   172.20.36.22    <pending>     80:31987/TCP,443:31268/TCP   8m41s
ingress-nginx-controller-admission   ClusterIP      172.20.215.37   <none>        443/TCP                      8m41s

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam
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

controlplane ~ ➜  curl http://192.168.102.168:31987/ibtisam
^C

controlplane ~ ✖ curl https://192.168.121.223:31987/ibtisam
curl: (35) error:0A00010B:SSL routines::wrong version number

controlplane ~ ✖ k edit svc -n ingress-nginx ingress-nginx-controller
service/ingress-nginx-controller edited

controlplane ~ ➜  k get svc -n ingress-nginx ingress-nginx-controller
NAME                       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   NodePort   172.20.36.22   <none>        80:31987/TCP,443:31268/TCP   11m

controlplane ~ ➜  k get ingress ibtisam-ingress 
NAME              CLASS   HOSTS   ADDRESS        PORTS   AGE
ibtisam-ingress   nginx   *       172.20.36.22   80      5m15s

controlplane ~ ➜  curl http://192.168.102.168:31987/ibtisam
^C

controlplane ~ ✖ k run testpod --image busybox --restart=Never --it -- sh
error: unknown flag: --it
See 'kubectl run --help' for usage.

controlplane ~ ✖ k run testpod --image busybox --restart=Never -it -- sh
If you don't see a command prompt, try pressing enter.
/ # curl 172.20.36.22/ibtisam
sh: curl: not found
/ # wget -qO http://172.20.36.22/ibtisam
BusyBox v1.37.0 (2024-09-26 21:31:42 UTC) multi-call binary.

Usage: wget [-cqS] [--spider] [-O FILE] [-o LOGFILE] [--header STR]
        [--post-data STR | --post-file FILE] [-Y on/off]
        [--no-check-certificate] [-P DIR] [-U AGENT] [-T SEC] URL...

Retrieve files via HTTP or FTP

        --spider        Only check URL existence: $? is 0 if exists
        --header STR    Add STR (of form 'header: value') to headers
        --post-data STR Send STR using POST method
        --post-file FILE        Send FILE using POST method
        --no-check-certificate  Don't validate the server's certificate
        -c              Continue retrieval of aborted transfer
        -q              Quiet
        -P DIR          Save to DIR (default .)
        -S              Show server response
        -T SEC          Network read timeout is SEC seconds
        -O FILE         Save to FILE ('-' for stdout)
        -o LOGFILE      Log messages to FILE
        -U STR          Use STR for User-Agent header
        -Y on/off       Use proxy
/ # wget -qO- http://172.20.36.22/ibtisam
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
/ # exit

controlplane ~ ➜  k describe ingress ibtisam-ingress 
Name:             ibtisam-ingress
Labels:           <none>
Namespace:        default
Address:          172.20.36.22
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /ibtisam   nginx:80 (172.17.1.4:80,172.17.2.3:80,172.17.2.4:80)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    11m (x2 over 16m)  nginx-ingress-controller  Scheduled for sync

controlplane ~ ➜  vi ingress-2.yaml

controlplane ~ ➜  cat ingress-2.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ibtisam-ingress2
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    # Rule 1: Match with host "ibtisam-iq.com"
    - host: ibtisam-iq.com
      http:
        paths:
          - path: /ibtisam
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80

controlplane ~ ➜  k apply -f ingress-2.yaml 
ingress.networking.k8s.io/ibtisam-ingress2 created

controlplane ~ ➜  k get ingress
NAME               CLASS   HOSTS            ADDRESS        PORTS   AGE
ibtisam-ingress    nginx   *                172.20.36.22   80      26m
ibtisam-ingress2   nginx   ibtisam-iq.com                  80      25s

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam
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

controlplane ~ ➜  k expose create deploy nginx2 --image nginx -r 3
error: unknown flag: --image
See 'kubectl expose --help' for usage.

controlplane ~ ✖ k  create deploy nginx2 --image nginx -r 3
deployment.apps/nginx2 created

controlplane ~ ➜  k expose deploy nginx2 --port 80
service/nginx2 exposed

controlplane ~ ➜  k edit ingress ibtisam-ingress2 
ingress.networking.k8s.io/ibtisam-ingress2 edited

controlplane ~ ➜  k get ingress
NAME               CLASS   HOSTS            ADDRESS        PORTS   AGE
ibtisam-ingress    nginx   *                172.20.36.22   80      32m
ibtisam-ingress2   nginx   ibtisam-iq.com   172.20.36.22   80      6m37s

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam
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

controlplane ~ ➜  k delete ingress ibtisam-ingress
ingress.networking.k8s.io "ibtisam-ingress" deleted

controlplane ~ ➜  k get ingress
NAME               CLASS   HOSTS            ADDRESS        PORTS   AGE
ibtisam-ingress2   nginx   ibtisam-iq.com   172.20.36.22   80      8m31s

controlplane ~ ➜  k get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   172.20.0.1       <none>        443/TCP   84m
nginx        ClusterIP   172.20.17.23     <none>        80/TCP    39m
nginx2       ClusterIP   172.20.117.247   <none>        80/TCP    3m12s

controlplane ~ ➜  k describe ingress ibtisam-ingress2 
Name:             ibtisam-ingress2
Labels:           <none>
Namespace:        default
Address:          172.20.36.22
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host            Path  Backends
  ----            ----  --------
  ibtisam-iq.com  
                  /ibtisam   nginx2:80 (172.17.1.6:80,172.17.2.5:80,172.17.1.7:80)
Annotations:      nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                    From                      Message
  ----    ------  ----                   ----                      -------
  Normal  Sync    2m45s (x3 over 9m13s)  nginx-ingress-controller  Scheduled for sync

controlplane ~ ➜  k get svc -n ingress-nginx ingress-nginx-controller
NAME                       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   NodePort   172.20.36.22   <none>        80:31987/TCP,443:31268/TCP   43m

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

controlplane ~ ➜  curl -H "Host: ibtisam-iq.com" http://192.168.121.223:31987/ibtisam
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

controlplane ~ ➜  vi /etc/hosts

controlplane ~ ➜  cat /etc/hosts
# Kubernetes-managed hosts file.
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
fe00::0 ip6-mcastprefix
fe00::1 ip6-allnodes
fe00::2 ip6-allrouters
192.168.121.223 controlplane
192.168.121.223 ibtisam-iq.com
# Entries added by HostAliases.
10.0.0.6        docker-registry-mirror.kodekloud.com
10.0.0.6 docker-registry-mirror.kodekloud.com

controlplane ~ ➜  curl http://ibtisam-iq.com:31987/ibtisam
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

controlplane ~ ➜    
```
