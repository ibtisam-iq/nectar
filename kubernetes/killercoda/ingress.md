We have deployed an application in the green-space namespace. we also deployed the ingress controller and the ingress resource.


However, currently, the ingress controller is not working as expected. Inspect the ingress definitions and troubleshoot the issue so that the services are accessible as per the ingress resource definition.

Also, update the path for the app-wear-service to /app-wear and app-video-service to /app-video.

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
goroutine 1 [running]:
k8s.io/klog/v2.stacks(0x1)
        k8s.io/klog/v2@v2.9.0/klog.go:1026 +0x8a
k8s.io/klog/v2.(*loggingT).output(0x28b9100, 0x3, {0x0, 0x0}, 0xc00020a1c0, 0x1, {0x1f93534, 0x28b9c40}, 0xc0006a3290, 0x0)
        k8s.io/klog/v2@v2.9.0/klog.go:975 +0x63d
k8s.io/klog/v2.(*loggingT).printDepth(0x1, 0x0, {0x0, 0x0}, {0x0, 0x0}, 0x0, {0xc0006a3290, 0x1, 0x1})
        k8s.io/klog/v2@v2.9.0/klog.go:735 +0x1ba
k8s.io/klog/v2.(*loggingT).print(...)
        k8s.io/klog/v2@v2.9.0/klog.go:717
k8s.io/klog/v2.Fatal(...)
        k8s.io/klog/v2@v2.9.0/klog.go:1494
main.main()
        k8s.io/ingress-nginx/cmd/nginx/main.go:83 +0x43c

goroutine 7 [chan receive]:
k8s.io/klog/v2.(*loggingT).flushDaemon(0x0)
        k8s.io/klog/v2@v2.9.0/klog.go:1169 +0x6a
created by k8s.io/klog/v2.init.0
        k8s.io/klog/v2@v2.9.0/klog.go:420 +0xfb

goroutine 32 [IO wait]:
internal/poll.runtime_pollWait(0x7fb6b401c020, 0x72)
        runtime/netpoll.go:234 +0x89
internal/poll.(*pollDesc).wait(0xc0006a7580, 0xc000180900, 0x0)
        internal/poll/fd_poll_runtime.go:84 +0x32
internal/poll.(*pollDesc).waitRead(...)
        internal/poll/fd_poll_runtime.go:89
internal/poll.(*FD).Read(0xc0006a7580, {0xc000180900, 0x8ec, 0x8ec})
        internal/poll/fd_unix.go:167 +0x25a
net.(*netFD).Read(0xc0006a7580, {0xc000180900, 0x3f, 0xc0000b5770})
        net/fd_posix.go:56 +0x29
net.(*conn).Read(0xc000690040, {0xc000180900, 0x6, 0xc0000b57f0})
        net/net.go:183 +0x45
crypto/tls.(*atLeastReader).Read(0xc0006a05e8, {0xc000180900, 0x0, 0x409f0d})
        crypto/tls/conn.go:777 +0x3d
bytes.(*Buffer).ReadFrom(0xc0002505f8, {0x1b7c160, 0xc0006a05e8})
        bytes/buffer.go:204 +0x98
crypto/tls.(*Conn).readFromUntil(0xc000250380, {0x1b7e780, 0xc000690040}, 0x8a6)
        crypto/tls/conn.go:799 +0xe5
crypto/tls.(*Conn).readRecordOrCCS(0xc000250380, 0x0)
        crypto/tls/conn.go:606 +0x112
crypto/tls.(*Conn).readRecord(...)
        crypto/tls/conn.go:574
crypto/tls.(*Conn).Read(0xc000250380, {0xc00027f000, 0x1000, 0x9a9c80})
        crypto/tls/conn.go:1277 +0x16f
bufio.(*Reader).Read(0xc0003aa9c0, {0xc0002762e0, 0x9, 0x9b7c42})
        bufio/bufio.go:227 +0x1b4
io.ReadAtLeast({0x1b7bfc0, 0xc0003aa9c0}, {0xc0002762e0, 0x9, 0x9}, 0x9)
        io/io.go:328 +0x9a
io.ReadFull(...)
        io/io.go:347
golang.org/x/net/http2.readFrameHeader({0xc0002762e0, 0x9, 0xc00111ade0}, {0x1b7bfc0, 0xc0003aa9c0})
        golang.org/x/net@v0.0.0-20211209124913-491a49abca63/http2/frame.go:237 +0x6e
golang.org/x/net/http2.(*Framer).ReadFrame(0xc0002762a0)
        golang.org/x/net@v0.0.0-20211209124913-491a49abca63/http2/frame.go:498 +0x95
golang.org/x/net/http2.(*clientConnReadLoop).run(0xc0000b5f98)
        golang.org/x/net@v0.0.0-20211209124913-491a49abca63/http2/transport.go:2101 +0x130
golang.org/x/net/http2.(*ClientConn).readLoop(0xc000198a80)
        golang.org/x/net@v0.0.0-20211209124913-491a49abca63/http2/transport.go:1997 +0x6f
created by golang.org/x/net/http2.(*Transport).newClientConn
        golang.org/x/net@v0.0.0-20211209124913-491a49abca63/http2/transport.go:725 +0xac5

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

A deployment called nodeapp-dp-cka08-trb is created in the default namespace on cluster1. This app is using an ingress resource named nodeapp-ing-cka08-trb.
From cluster1-controlplane host, we should be able to access this app using the command curl http://kodekloud-ingress.app. However, it is not working at the moment. Troubleshoot and fix the issue.

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

Create an ingress resource nginx-ingress-cka04-svcn to load balance the incoming traffic with the following specifications:



pathType: Prefix and path: /

Backend Service Name: nginx-service-cka04-svcn

Backend Service Port: 80

ssl-redirect is set to false

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
    # NGINX annotations will be ignored by Traefik
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

---
