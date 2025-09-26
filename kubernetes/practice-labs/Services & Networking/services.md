## Q1 Pod doesn't have label

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
## Q2

We have an **external webserver** running on **student-node** which is exposed at port **9999**.

We have also created a service called `external-webserver-ckad01-svcn` that can connect to our local webserver from within the cluster3 but, at the moment, it is not working as expected.

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

- Servive and EndpointSlice, both must share the same namespace.
- ip of node: `ping student-node` from the kubectl node `cluster3-controlplane` or  ssh into `student-node` and fetch it via `ip a` or `ifconfig`

---

## Q3

For this scenario, create a Service called `ckad12-service` that routes traffic to an external IP address. Please note that service should listen on `port 53` and be of type **ExternalName**. Use the external IP address `8.8.8.8`

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
---

## Q4

We have deployed several applications in the `ns-ckad17-svcn` namespace that are exposed inside the cluster via **ClusterIP**.

Your task is to create a **LoadBalancer** type service that will serve traffic to the applications based on its labels. Create the resources as follows:

- Service `lb1-ckad17-svcn` for serving traffic at port `31890` to pods with labels `"exam=ckad, criteria=location"`.

- Service `lb2-ckad17-svcn` for serving traffic at port `31891` to pods with labels `"exam=ckad, criteria=cpu-high"`.

```bash
root@student-node ~ ➜  k get po -n ns-ckad17-svcn --show-labels
NAME               READY   STATUS    RESTARTS   AGE    LABELS                         IP
cpu-load-app       1/1     Running   0          109m   criteria=cpu-high,exam=ckad    172.17.1.3
geo-location-app   1/1     Running   0          109m   criteria=location,exam=ckad    172.17.1.2

root@student-node ~ ➜  k describe po -n ns-ckad17-svcn cpu-load-app geo-location-app | grep -i port
    Port:           80/TCP
    Host Port:      0/TCP
    Port:           80/TCP
    Host Port:      0/TCP

root@student-node ~ ➜  k expose po -n ns-ckad17-svcn geo-location-app --name lb1-ckad17-svcn --type LoadBalancer
service/lb1-ckad17-svcn exposed

root@student-node ~ ➜  k edit svc -n ns-ckad17-svcn lb1-ckad17-svcn                 # nodePort edited.
service/lb1-ckad17-svcn edited

root@student-node ~ ➜  k expose po -n ns-ckad17-svcn cpu-load-app --name lb2-ckad17-svcn --type LoadBalancer
service/lb2-ckad17-svcn exposed

root@student-node ~ ➜  k edit svc -n ns-ckad17-svcn lb2-ckad17-svcn 
service/lb2-ckad17-svcn edited

root@student-node ~ ➜  k describe svc -n ns-ckad17-svcn lb1-ckad17-svcn lb2-ckad17-svcn

Name:                     lb1-ckad17-svcn
Namespace:                ns-ckad17-svcn
Labels:                   criteria=location
                          exam=ckad
Annotations:              <none>
Selector:                 criteria=location,exam=ckad
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.179.143
IPs:                      172.20.179.143
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31890/TCP
Endpoints:                172.17.1.2:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>


Name:                     lb2-ckad17-svcn
Namespace:                ns-ckad17-svcn
Labels:                   criteria=cpu-high
                          exam=ckad
Annotations:              <none>
Selector:                 criteria=cpu-high,exam=ckad
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.139.184
IPs:                      172.20.139.184
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31891/TCP
Endpoints:                172.17.1.3:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:                   <none>  
```

---

## Q5

Configure a service named `nginx-svcn` for the application, which exposes the pods on multiple ports with different protocols.

- Expose port `80` using `TCP` with the name `http`
- Expose port `443` using `TCP` with the name `https`

```bash
root@student-node ~ ➜  k get deploy nginx-app-ckad 
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
nginx-app-ckad   3/3     3            3           38s

root@student-node ~ ➜  k expose deployment nginx-app-ckad --name nginx-svcn --port 80 --port 443         # only last --port added.
service/nginx-svcn exposed

root@student-node ~ ➜  k edit svc nginx-svcn         
service/nginx-svcn edited

root@student-node ~ ➜  k describe svc nginx-svcn 
Name:                     nginx-svcn
Namespace:                default
Labels:                   app=nginx-app-ckad
Annotations:              <none>
Selector:                 app=nginx-app-ckad
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.48.237
IPs:                      10.43.48.237
Port:                     http  80/TCP
TargetPort:               80/TCP
Endpoints:                10.42.0.16:80,10.42.2.13:80,10.42.1.14:80
Port:                     https  443/TCP
TargetPort:               443/TCP
Endpoints:                10.42.0.16:443,10.42.2.13:443,10.42.1.14:443
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

root@student-node ~ ➜  
```
---

## Q6

Create a ClusterIP service .i.e. `service-3421-svcn` in the `spectra-1267` ns which should expose the pods namely **pod-23** and **pod-21** with port set to `8080` and targetport to `80`.

```bash
root@student-node ~ ➜  k get po -o wide -n spectra-1267 pod-21 pod-23 --show-labels 
NAME     READY   STATUS    RESTARTS   AGE   IP            NODE                 LABELS
pod-21   1/1     Running   0          16m   172.17.1.11   cluster3-node01      env=prod,mode=exam,type=external
pod-23   1/1     Running   0          16m   172.17.1.10   cluster3-node01      env=dev,mode=exam,type=external

root@student-node ~ ➜  k describe svc -n spectra-1267 service-3421-svcn 
Name:                     service-3421-svcn
Namespace:                spectra-1267
Labels:                   env=prod
                          mode=exam
                          type=external
Annotations:              <none>
Selector:                 mode=exam,type=external       # important point, env is skipped, because it different for both pods.
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.182.195
IPs:                      172.20.182.195
Port:                     <unset>  8080/TCP
TargetPort:               80/TCP
Endpoints:                172.17.1.11:80,172.17.1.10:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```

---

## Q7

Please be noted that **service needs to be accessed from both inside and outside the cluster** (use port `31080`).

Got it ✅ You need:

* A **Service** named `ckad13-service`

  * Type: **NodePort** (so it’s accessible inside and outside the cluster)
  * NodePort: **31080**
  * Port: **80** → containerPort **80**

✅ Now you can access the service:

* From **inside cluster** → `http://ckad13-service:80`
* From **outside cluster** → `http://<NodeIP>:31080`

```bash
root@student-node ~ ➜  k expose deploy ckad13-deployment --name ckad13-service --type NodePort --port 80
service/ckad13-service exposed

root@student-node ~ ➜  k edit svc ckad13-service 
service/ckad13-service edited

root@student-node ~ ➜  k expose deploy ckad13-deployment --name ckad13-service --port 80
Error from server (AlreadyExists): services "ckad13-service" already exists
```

---

## Q8: Endpoint is assigned, but wrong port 

```bash
cluster1-controlplane ~ ➜  k get po purple-app-cka27-trb -o yaml | grep -i image:
  - image: nginx
    image: docker.io/library/nginx:latest

cluster1-controlplane ~ ➜  k get po purple-app-cka27-trb -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP            NODE              NOMINATED NODE   READINESS GATES
purple-app-cka27-trb   1/1     Running   0          32m   172.17.1.22   cluster1-node01   <none>           <none>

cluster1-controlplane ~ ➜  k describe svc purple-svc-cka27-trb 
Name:                     purple-svc-cka27-trb
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=purple-app-cka27-trb
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.10.168
IPs:                      172.20.10.168
Port:                     app  8080/TCP                                # set it to 80
TargetPort:               8080/TCP                                     # set it to 80
Endpoints:                172.17.1.22:8080
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster1-controlplane ~ ➜
```
---

## Q9: Endpoint is not yet assigned, wrong label

```bash
cluster1-controlplane ~ ➜  k describe svc curlme-cka01-svcn 
Name:                     curlme-cka01-svcn
Namespace:                default
Selector:                 run=curlme-ckaO1-svcn                 # 0 not O 
Type:                     ClusterIP
IP:                       172.20.218.134
IPs:                      172.20.218.134
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                
Events:                   <none>


cluster1-controlplane ~ ➜  k get po -o wide curlme-cka01-svcn curlpod-cka01-svcn --show-labels 
NAME                 READY   STATUS    RESTARTS   AGE    IP            NODE              NOMINATED NODE   READINESS GATES   LABELS
curlme-cka01-svcn    1/1     Running   0          4m4s   172.17.1.11   cluster1-node01   <none>           <none>            run=curlme-cka01-svcn
curlpod-cka01-svcn   1/1     Running   0          4m4s   172.17.3.12   cluster1-node02   <none>           <none>            run=curlpod-cka01-svcn
```

---

## Q10 
A pod called `pink-pod-cka16-trb` is created in the `default` namespace in cluster4. This app runs on port `tcp/5000`, and it is to be exposed to end-users using an ingress resource called `pink-ing-cka16-trb` such that it becomes accessible using the command `curl http://kodekloud-pink.app` on the `cluster4-controlplane` host. There is an ingress.yaml file under the root folder in cluster4-controlplane. Create an **ingress resource** by following the command and continue with the task.

However, even after creating the ingress resource, it is not working. Troubleshoot and fix this issue, making any necessary changes to the objects.

```bash
cluster4-controlplane ~ ➜  k get po pink-pod-cka16-trb -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: pink-pod-cka16-trb
spec:
  containers:
    ports:
    - containerPort: 80
      protocol: TCP
cluster4-controlplane ~ ➜  k describe svc pink-svc-cka16-trb 
Name:                     pink-svc-cka16-trb
Namespace:                default
Labels:                   <none>
Annotations:              <none>
Selector:                 app=pink-app-cka16-trb
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       172.20.39.102
IPs:                      172.20.39.102
Port:                     <unset>  5000/UDP                                # wrong protocol
TargetPort:               80/UDP
Endpoints:                172.17.1.3:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster4-controlplane ~ ➜  k edit svc pink-svc-cka16-trb                    # just change the protocol to TCP
service/pink-svc-cka16-trb edited

cluster4-controlplane ~ ➜  cat ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pink-ing-cka16-trb
spec:
  ingressClassName: nginx
  rules:
    - host: kodekloud-pink.app
      http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: pink-svc-cka16-trb
                port:
                  number: 5000                                                # ingress resource never contains protocol, just port number only

cluster4-controlplane ~ ➜  k apply -f ingress.yaml 
ingress.networking.k8s.io/pink-ing-cka16-trb created

cluster4-controlplane ~ ➜  curl http://kodekloud-pink.app
<title>Welcome to nginx!</title>
<h1>Welcome to nginx!</h1>
<p><em>Thank you for using nginx.</em></p>
```
