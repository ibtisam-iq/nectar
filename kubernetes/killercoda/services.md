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
root@student-node ~ ➜  ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1410
        inet 192.168.67.177  netmask 255.255.255.255  broadcast 0.0.0.0

root@student-node ~ ➜  ip a
3: eth0@if63501: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1410 qdisc noqueue state UP group default 
    inet 192.168.67.177/32 scope global eth0


root@student-node ~ ➜  k describe svc external-webserver-ckad01-svcn 
Name:                     external-webserver-ckad01-svcn
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.72.32
IPs:                      172.20.72.32
Port:                     <unset>  80/TCP            # no name
TargetPort:               9999/TCP
Endpoints:                <none>                      # no endpoint

root@student-node ~ ➜  curl student-node:9999
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<p><em>Thank you for using nginx.</em></p>
</body>
</html>

root@student-node ~ ➜  vi endpointslice.yaml

root@student-node ~ ➜  cat endpointslice.yaml 
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
      - "192.168.67.177"

root@student-node ~ ➜  k apply -f endpointslice.yaml 
endpointslice.discovery.k8s.io/example-abc created

root@student-node ~ ➜  k describe endpointslice.discovery.k8s.io/example-abc
Name:         example-abc
Namespace:    default
Labels:       kubernetes.io/service-name=external-webserver-ckad01-svcn
Annotations:  <none>
AddressType:  IPv4
Ports:
  Name  Port  Protocol
  ----  ----  --------
  http  9999  TCP
Endpoints:
  - Addresses:  192.168.67.177
    Conditions:
      Ready:   <unset>
    Hostname:  <unset>
    NodeName:  <unset>
    Zone:      <unset>
Events:        <none>

root@student-node ~ ➜  k describe svc external-webserver-ckad01-svcn
Name:                     external-webserver-ckad01-svcn
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.72.32
IPs:                      172.20.72.32
Port:                     <unset>  80/TCP
TargetPort:               9999/TCP
Endpoints:                                            # nothing happened
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```

Got it ✅ — the issue is with how the Service and EndpointSlice are defined. Right now:

* Your Service `external-webserver-ckad01-svcn` has **no selector** (that’s fine, because you want to manually map to an external endpoint).
* But it also shows **no Endpoints** (`Endpoints:` is empty).
* That’s because the `EndpointSlice` you created isn’t being recognized by the Service, since the port names and numbers don’t align.

### 🔑 Fix

When you create a Service without a selector, you must provide either:

1. An **Endpoints object** (`kind: Endpoints`), or
2. A correctly labeled **EndpointSlice** with the proper port mapping.

Right now, your Service exposes **port 80** (frontend port) and maps it to **targetPort 9999**, but your `EndpointSlice` directly exposes **9999** instead of **80**. That’s why Kubernetes isn’t linking them.

### ✅ Solution 1: Use `Endpoints` (simpler)

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: external-webserver-ckad01-svcn
subsets:
  - addresses:
      - ip: 192.168.67.177
    ports:
      - port: 9999
```

Apply it:

```bash
kubectl apply -f endpoints.yaml
```

Then check:

```bash
kubectl describe svc external-webserver-ckad01-svcn
```

👉 You should now see `Endpoints: 192.168.67.177:9999`.

Pods inside the cluster can connect via:

```bash
curl external-webserver-ckad01-svcn:80
```

### ✅ Solution 2: Fix EndpointSlice

If you want to stick with EndpointSlice, the port must match the Service’s port **number or name**.

Your Service has:

```yaml
Port: 80/TCP
TargetPort: 9999/TCP
```

So your EndpointSlice should look like:

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: external-webserver-ckad01-svcn-slice
  labels:
    kubernetes.io/service-name: external-webserver-ckad01-svcn
addressType: IPv4
ports:
  - name: ""      # or same as Service port name
    protocol: TCP
    port: 9999
endpoints:
  - addresses:
      - "192.168.67.177"
```

```bash
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
IP:                       172.20.72.32
IPs:                      172.20.72.32
Port:                     http  80/TCP            # name is set, and endPoint then assigned.
TargetPort:               9999/TCP
Endpoints:                192.168.67.177:9999
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
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
