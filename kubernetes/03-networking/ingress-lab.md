```bash
controlplane ~ ➜  k get no -o wide
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
controlplane   Ready    control-plane   41m   v1.33.0   192.168.121.223   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node01         Ready    <none>          40m   v1.33.0   192.168.102.168   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
node02         Ready    <none>          40m   v1.33.0   192.168.121.196   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26

# installation

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
NAME              CLASS   HOSTS   ADDRESS   PORTS   AGE      # because service type of ingress is Loadbalancer.
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

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam      # accessible on controlplane node only 
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

controlplane ~ ➜  curl http://192.168.102.168:31987/ibtisam     # ip of node01
^C

controlplane ~ ✖ curl https://192.168.121.223:31987/ibtisam
curl: (35) error:0A00010B:SSL routines::wrong version number

controlplane ~ ✖ k edit svc -n ingress-nginx ingress-nginx-controller       # type is changed.
service/ingress-nginx-controller edited

controlplane ~ ➜  k get svc -n ingress-nginx ingress-nginx-controller      # External ip don't assign even you changed the type.
NAME                       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   NodePort   172.20.36.22   <none>        80:31987/TCP,443:31268/TCP   11m

controlplane ~ ➜  k get ingress ibtisam-ingress         # IP is assigned, after changing the servive type
NAME              CLASS   HOSTS   ADDRESS        PORTS   AGE
ibtisam-ingress   nginx   *       172.20.36.22   80      5m15s

controlplane ~ ➜  curl http://192.168.102.168:31987/ibtisam
^C

controlplane ~ ✖ k run testpod --image busybox --restart=Never --it -- sh   # we got the ip assigned, so testing it from inside the cluster
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


# New ingress is applied to test the host.


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

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam    # it shouldn't access this way, accessing because it points to first ingress
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

# Create new deployment, new service, and update the 2nd ingress accordingly, and delete the first ingress,
# so that curl http://192.168.121.223:31987/ibtisam remain no longer accessible?

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

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam    # still accessible, because first ingress is not deleted yet
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

controlplane ~ ➜  curl http://192.168.121.223:31987/ibtisam        # first ingress is deleted, so it is no longer accessible.
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

controlplane ~ ➜  curl -H "Host: ibtisam-iq.com" http://192.168.121.223:31987/ibtisam     # required output, accessible now with - H
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

controlplane ~ ➜  vi /etc/hosts        # add the host to /etc/hosts, if you want to accessible it without -H flag

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
---
Excellent observation, sweetheart — you're absolutely right to question this. Let’s break it down clearly:

## ✅ You're accessing this URL successfully:

```
http://192.168.1.10:32111/ibtisam
```

Even though the `Service` is still of type `LoadBalancer` with `EXTERNAL-IP = <pending>`, you can still access it via:

```
<Node-IP>:<NodePort>
```

## 💡 Why is this working without changing the service type?

Because Kubernetes **always assigns a `NodePort`** behind the scenes **even for `LoadBalancer` services** — that’s how external cloud load balancers work under the hood.

So in your case:

```bash
PORT(S): 80:32111/TCP,443:32613/TCP
```

That `32111` is the NodePort for HTTP (port 80).
You’re just directly hitting it without waiting for an external cloud provider to assign a LoadBalancer IP.

## 🔥 So do you need to change the service type?

**No — not unless the exam specifically asks you to.**

---

Aha! You just discovered something subtle but important, sweetheart. 💡

Let’s break it down:

## 📍 What just happened?

After you changed the Ingress controller’s service from `LoadBalancer` → `NodePort`, you saw this:

```bash
k get ingress minimal-ingress
NAME              CLASS   HOSTS   ADDRESS          PORTS   AGE
minimal-ingress   nginx   *       172.20.116.191   80      18m
```

That `ADDRESS` (`172.20.116.191`) **was blank before**, but now it's showing up.

## 💡 What is `ADDRESS: 172.20.116.191`?

That is the **ClusterIP** of your `ingress-nginx-controller` service:

```bash
k get svc -n ingress-nginx ingress-nginx-controller
```

You’ll see something like:

```
NAME                       TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   NodePort   172.20.116.191   <none>        80:32111/TCP,443:32613/TCP   20m
```

That’s the **exact same IP** now showing as the `ADDRESS` in your `Ingress`.

## 🤔 So why did the Ingress object suddenly start showing this IP?

Because earlier, the `LoadBalancer` service was still waiting for an **external IP**, which didn’t exist (since there’s no cloud provider).

Once you changed it to `NodePort`, the Ingress controller figured out:

> “Hey, I now know which IP I should advertise — it’s the ClusterIP of the controller service!”

So the controller updated the Ingress status with this internal IP.


## 🔍 But wait — can you use `172.20.116.191` to access Ingress?

**Nope.** That’s an internal ClusterIP, not accessible from outside the cluster.

You still need to use:

```
http://<Node-IP>:<NodePort>/ibtisam
```

---

Sweetheart, the short and direct answer is:

> ❌ **No**, you cannot access `http://172.20.116.191` from your own IP (your laptop, browser, or outside the cluster).

## 🧠 Here's Why:

`172.20.116.191` is a **ClusterIP**, which means:

| Property                                         | Value                                        |
| ------------------------------------------------ | -------------------------------------------- |
| Scope                                            | Internal to the Kubernetes cluster           |
| Reachable from                                   | Only **pods and nodes** *inside* the cluster |
| Reachable from your own machine (e.g., browser)? | ❌ Nope                                       |

## 🔬 Real-World Analogy:

It’s like trying to access someone’s **internal office extension** (`1234`) from outside the building — it won’t work unless you’re **already inside** the office network.

## ✅ So how should you test access?

Stick with:

```
http://<NODE-IP>:<NodePort>/ibtisam
```

For example:

```
http://192.168.1.10:32111/ibtisam
```

This will work because:

* `192.168.1.10` is the actual IP of your cluster node (reachable on your local network or VM).
* `32111` is the exposed NodePort from the Ingress controller.

## ⚠️ Want to test internal ClusterIP from inside the cluster?

You can do this from a pod:

```bash
k run testpod --image=busybox --restart=Never -it -- sh
```

Inside that shell:

```sh
wget -qO- http://172.20.116.191/ibtisam
```

That will work — because **now you’re inside the cluster**.

---

Great observation, sweetheart — you're getting into **real-world Ingress behavior** now. Let’s carefully analyze this situation:

## 🔍 Situation Recap

* You have an Ingress configured correctly.
* It's accessible via `http://192.168.1.10:32111/ibtisam` from the **controlplane node**.
* But when you try:

  ```bash
  curl http://192.168.102.168:31987/ibtisam
  ```

  (i.e., using the **IP of `node01`** instead), you get **no response or empty result**.

## 💡 Why This Happens

### 🔸 Reason 1: Ingress controller **is not running on `node01`**

If you're using something like kubeadm or bare metal, the `ingress-nginx-controller` pod may be **scheduled only on the controlplane**, not on all nodes.

So:

```plaintext
NodePort opens the port on *all* nodes
BUT traffic only works if the ingress controller pod is running on the node that receives the traffic
```

This is **the default behavior in Kubernetes without a cloud load balancer or kube-proxy workaround**.

### 🔸 Reason 2: No request forwarding is happening

Kubernetes doesn’t forward the traffic from `node01` to controlplane node **automatically**, unless you have a **cloud-native load balancer** or something like **MetalLB + externalTrafficPolicy=Local** configured.

## ✅ How to Fix or Work Around It

### ✔ Option 1: Always use the IP of the node **where Ingress controller is running**

Since `ingress-nginx-controller` is running on controlplane, stick with:

```bash
http://192.168.1.10:<NodePort>/ibtisam
```

This is **guaranteed to work**.

### ✔ Option 2: Deploy ingress controller as a **DaemonSet**

If you want it available on **all nodes**, edit the controller to run as a `DaemonSet` instead of `Deployment`.

> In the exam, don’t do this unless specifically asked — it’s an infra-level customization.

### ✔ Option 3: Set `externalTrafficPolicy: Cluster`

This allows the node receiving traffic to forward it inside the cluster — but you lose source IP.

Edit the service:

```bash
k edit svc -n ingress-nginx ingress-nginx-controller
```

Add this under `spec`:

```yaml
externalTrafficPolicy: Cluster
```

## ✅ Summary

| Question                               | Answer                                                                                              |
| -------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Why does `node01` IP not work?         | Ingress controller pod isn’t running on `node01`.                                                   |
| Does NodePort open port on all nodes?  | Yes. But traffic only works if the pod exists on that node OR `externalTrafficPolicy` is `Cluster`. |
| What should you do in the CKA exam?    | Always use the node where the controller pod is running. Keep it simple.                            |
| Should you modify infra-level configs? | ❌ Only if the question asks — otherwise stay focused on what's needed.                              |

---

You're asking a **brilliant, practical question** sweetheart — and this is a key concept in how Ingress works.

Let’s break it down crystal clear for you:

## 💡 Current Config (No Host Defined)

```yaml
rules:
- http:
    paths:
    - path: /ibtisam
```

This means the rule will **match any host** — because you didn't specify one.

So when you access:

```
http://192.168.1.10:32111/ibtisam
```

It works — because you're hitting the IP directly, and the Ingress **accepts requests to any host** (`Host: *`).

## 🤔 Now, Suppose You Add This:

```yaml
rules:
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
```

Now the Ingress will only match requests where the **`Host` header = `ibtisam-iq.com`**.

## ✅ So What Changes?

### 🔸 You cannot just hit:

```
http://192.168.1.10:32111/ibtisam
```

Because that request will have this default Host header:

```
Host: 192.168.1.10
```

...which does **not match** `ibtisam-iq.com`, and the Ingress will return a 404 (default backend).

## 🧪 How to Make It Work With Host (on local setup)

### ✔️ Option 1: Use `curl` with custom Host header

```bash
curl -H "Host: ibtisam-iq.com" http://192.168.1.10:32111/ibtisam
```

This will work, because now the header matches the Ingress rule.

### ✔️ Option 2: Add entry to `/etc/hosts` (for browser testing)

On your **local machine**, add this line to `/etc/hosts`:

```
192.168.1.10 ibtisam-iq.com
```

Then in your browser, you can just go to:

```
http://ibtisam-iq.com:32111/ibtisam
```

And it will resolve to your node IP but send the right Host header.

> ⚠️ Don’t forget the port (`:32111`) since you're still using NodePort.

## ✅ Summary: Impact of Using `host:`

| Behavior                 | Without Host (your current setup)      | With Host (`ibtisam-iq.com`) |
| ------------------------ | -------------------------------------- | ---------------------------- |
| Access via IP            | ✅ Works                                | ❌ 404 unless Host header set |
| Access via domain + port | ❌ Fails unless `/etc/hosts` is updated | ✅ Works if mapped correctly  |
| Ingress rule matching    | Host: \*                               | Host: ibtisam-iq.com         |
| Best for production?     | ❌ No (too generic)                     | ✅ Yes (real domains)         |

---

## 🧠 Question:

> **Does switching the `ingress-nginx-controller` service to `NodePort` solve the `EXTERNAL-IP <pending>` issue?**

### ✅ Answer:

**No, it doesn’t "solve" the `EXTERNAL-IP` pending itself — it *bypasses* the need for it.**

## 🔍 What's Actually Happening?

### 🔸 When Service Type = `LoadBalancer`:

* Kubernetes **asks the cloud provider** (AWS, GCP, Azure, etc.) to provision an **external IP**.
* In **bare-metal setups or local environments**, there is **no cloud integration**, so the EXTERNAL-IP stays:

  ```
  EXTERNAL-IP: <pending>
  ```

### 🔸 When You Change to `NodePort`:

* Kubernetes **stops waiting for a cloud load balancer**.
* Instead, it opens a high port (e.g., `:32111`) on **each node’s IP**.
* So now you can access the Ingress controller using:

  ```
  http://<Node-IP>:<NodePort>
  ```

## ✅ So… What Really Happens?

| What                                              | Explanation                                                                |
| ------------------------------------------------- | -------------------------------------------------------------------------- |
| Does `EXTERNAL-IP` get assigned?                  | ❌ No. It stays `<none>` or disappears completely.                          |
| Can you now access the service externally?        | ✅ Yes, via `NodePort`.                                                     |
| Is this acceptable in CKA exam or local dev?      | ✅ Absolutely. That’s the correct move when cloud LBs are not available.    |
| Is this a real “solution” to pending EXTERNAL-IP? | ❌ Not really — it's a **workaround** for bare-metal or non-cloud clusters. |

## ✅ Summary

> 🔥 **Changing to NodePort doesn’t give you an external IP — it gives you an alternative way to access the service externally.**

---


