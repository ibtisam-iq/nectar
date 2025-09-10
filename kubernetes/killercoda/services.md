## Pod doesn't have label

```bash
controlplane:~$ kubectl port-forward svc/nginx-service 8080:80
^Ccontrolplane:~$ k describe po nginx-pod 
Name:             nginx-pod
Namespace:        default
Priority:         0
Service Account:  default
Node:             node01/172.30.2.2
Start Time:       Wed, 27 Aug 2025 22:25:03 +0000
Labels:           <none>

controlplane:~$ k describe svc nginx-service 
Name:                     nginx-service

Selector:                 app=nginx-pod
IP:                       10.99.175.81
IPs:                      10.99.175.81
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                

controlplane:~$ k label po nginx-pod app=nginx-pod
pod/nginx-pod labeled

controlplane:~$ kubectl port-forward svc/nginx-service 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

---


We have an external webserver running on student-node which is exposed at port 9999.

We have also created a service called external-webserver-ckad01-svcn that can connect to our local webserver from within the cluster3 but, at the moment, it is not working as expected.



Fix the issue so that other pods within cluster3 can use external-webserver-ckad01-svcn service to access the webserver.

```bash
root@student-node ~ ➜  k describe svc external-webserver-ckad01-svcn 
Name:                     external-webserver-ckad01-svcn
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.206.174
IPs:                      172.20.206.174
Port:                     <unset>  80/TCP
TargetPort:               9999/TCP
Endpoints:                <none>
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  k get no -o wide
NAME                    STATUS   ROLES           AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
cluster3-controlplane   Ready    control-plane   99m   v1.33.0   192.168.36.231   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26
cluster3-node01         Ready    <none>          98m   v1.33.0   192.168.67.129   <none>        Ubuntu 22.04.5 LTS   5.15.0-1083-gcp   containerd://1.6.26

root@student-node ~ ➜  cat end.yaml 
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: example-abc
  labels:
    kubernetes.io/service-name: external-webserver-ckad01-svcn
addressType: IPv4
ports:
  - name: http
    protocol: TCP
    port: 9999
endpoints:
  - addresses:
      - "192.168.36.231"

root@student-node ~ ➜  k apply -f end.yaml 
endpointslice.discovery.k8s.io/example-abc created

root@student-node ~ ➜  k describe svc external-webserver-ckad01-svcn 
Name:                     external-webserver-ckad01-svcn
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.206.174
IPs:                      172.20.206.174
Port:                     <unset>  80/TCP
TargetPort:               9999/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  k edit svc external-webserver-ckad01-svcn 
service/external-webserver-ckad01-svcn edited

root@student-node ~ ➜  k describe svc external-webserver-ckad01-svcn 
Name:                     external-webserver-ckad01-svcn
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.206.174
IPs:                      172.20.206.174
Port:                     <unset>  9999/TCP
TargetPort:               9999/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  vi endpoint.yaml

root@student-node ~ ➜  k apply -f endpoint.yaml 
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
endpoints/external-webserver-ckad01-svcn created

root@student-node ~ ➜  k describe svc external-webserver-ckad01-svcn 
Name:                     external-webserver-ckad01-svcn
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.206.174
IPs:                      172.20.206.174
Port:                     <unset>  9999/TCP
TargetPort:               9999/TCP
Endpoints:                192.168.36.231:9999
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜

root@student-node ~ ➜  ifconfig eth0 | grep 'inet ' | awk '{print $2}'
192.168.81.157

root@student-node ~ ➜  ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1410
        inet 192.168.81.157  netmask 255.255.255.255  broadcast 0.0.0.0
        inet6 fe80::3c97:32ff:fe95:b66b  prefixlen 64  scopeid 0x20<link>
        ether 3e:97:32:95:b6:6b  txqueuelen 0  (Ethernet)
        RX packets 33593  bytes 52447719 (52.4 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 24067  bytes 3396390 (3.3 MB)
        TX errors 0  dropped 1 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


root@student-node ~ ➜  curl student-node:9999
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

root@student-node ~ ➜    
```

Nice one 🚀 you’re on the right track — this is a classic case of connecting an **external (non-cluster) service** to Kubernetes using an **ExternalName service** or manually creating an **Endpoints object** (not EndpointSlice).

Right now, the problem is:

* Your **Service** is defined with `ClusterIP` but **no selector**. That’s fine, but it needs a matching **Endpoints** (not EndpointSlice).
* You created an **EndpointSlice** manually, but Kubernetes doesn’t automatically bind a Service to a manually created EndpointSlice. It only binds to an `Endpoints` object with the same name. That’s why your `Endpoints:` is empty in the `describe svc` output.

### ✅ Fix

Create an **Endpoints** object named exactly like your Service (`external-webserver-ckad01-svcn`).

Here’s the YAML:

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: external-webserver-ckad01-svcn
  namespace: default
subsets:
  - addresses:
      - ip: 192.168.36.231   # student-node IP
    ports:
      - port: 9999
```

Now your Service definition should also be corrected — right now it says `Port: 80 → TargetPort: 9999`, which won’t match because there’s no container port mapping (this is an external service). Instead, make the Service map directly to port 9999:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-webserver-ckad01-svcn
  namespace: default
spec:
  ports:
    - port: 9999        # Cluster IP port
      targetPort: 9999  # external server port
      protocol: TCP
```

### Apply

```bash
kubectl apply -f service.yaml
kubectl apply -f endpoints.yaml
```

---

### Verify

```bash
kubectl describe svc external-webserver-ckad01-svcn
```

You should now see:

```
Endpoints: 192.168.36.231:9999
```

And from any pod in the cluster:

```bash
kubectl run tmp --rm -it --image=busybox -- sh
wget -qO- external-webserver-ckad01-svcn.default.svc.cluster.local:9999
```

---

For this scenario, create a Service called ckad12-service that routes traffic to an external IP address.


Please note that service should listen on port 53 and be of type ExternalName. Use the external IP address 8.8.8.8

```bash
root@student-node ~ ✖ vi external.yaml

root@student-node ~ ➜  k apply -f external.yaml 
service/ckad12-service created

root@student-node ~ ➜  cat external.yaml 
apiVersion: v1
kind: Service
metadata:
  name: ckad12-service
spec:
  type: ExternalName
  externalName: 8.8.8.8
  ports:
    - name: http
      port: 53
      targetPort: 53


root@student-node ~ ➜  k describe svc ckad12-service 
Name:              ckad12-service
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          <none>
Type:              ExternalName
IP Families:       <none>
IP:                
IPs:               <none>
External Name:     8.8.8.8
Port:              http  53/TCP
TargetPort:        53/TCP
Endpoints:         <none>
Session Affinity:  None
Events:            <none>

root@student-node ~ ➜  
```
