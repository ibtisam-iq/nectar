# 🚀 Kubernetes Services – Key Indicators

## 🔹 1. External Server Access

* To access **external IP** via a ClusterIP Service:

  * Service has **no selector**.
  * You must create an **EndpointSlice** in the same namespace.
* Rules:

  * `spec.ports.name` in Service **must equal** `ports.name` in EndpointSlice.
  * `spec.ports.targetPort` in Service **must equal** `ports.port` in EndpointSlice.
* Debugging external node IP:

  * From controlplane: `ping <node-name>`
  * Or SSH into the node: `ip a` / `ifconfig`.

## 🔹 2. Special Service Types

* **ExternalName Service**

  * No selector.
  * Maps to an external **DNS name**.
  * Example: resolves to `externalName: google.com`.

* **LoadBalancer Service**

  * Allocates a **NodePort** under the hood.
  * NodePort can be **edited** later.

* **NodePort Service**

  * Exposes Service **outside the cluster**.
  * Must define `nodePort` (e.g., `31080`) if fixed port is required.

## 🔹 3. Expose Command Nuances

* `--port` flag is **optional** if Pod already defines `containerPort`.
* If multiple `--port` flags are provided, **only the last one takes effect**.

  ```bash
  k expose deployment nginx-app --name nginx-svc --port 80 --port 443
  # Result: service listens only on port 443
  ```

## 🔹 4. Service-to-Pod Relationship

* If multiple Pods share the same **selector labels**,

  * The Service will load-balance traffic across **all matching Pods**.

---

## Q1

We have an external webserver running on `student-node` which is exposed at port `9999`. We have created a service called `external-webserver-cka03-svcn` that can connect to our local webserver from within the kubernetes cluster3, but at the moment, it is not working as expected.

- Servive and EndpointSlice, both must share the same namespace & port name
- ip of node: `ping student-node` from the kubectl node `cluster3-controlplane` or  ssh into `student-node` and fetch it via `ip a` or `ifconfig`

```bash
cluster3-controlplane ~ ➜  ping student-node:9999
PING student-node:9999 (192.168.81.189): 56 data bytes
^C
--- student-node:9999 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.216/0.258/0.290 ms

cluster3-controlplane ~ ➜  k get svc -n kube-public external-webserver-cka03-svcn 
NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
external-webserver-cka03-svcn   ClusterIP   10.43.145.152   <none>        80/TCP    35m

cluster3-controlplane ~ ➜  k describe svc -n kube-public external-webserver-cka03-svcn 
Name:                     external-webserver-cka03-svcn
Namespace:                kube-public
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.145.152
IPs:                      10.43.145.152
Port:                     80/TCP                              # no name here
TargetPort:               80/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster3-controlplane ~ ➜  vi 14.yaml 

cluster3-controlplane ~ ➜  k apply -f 14.yaml 
endpointslice.discovery.k8s.io/external-webserver-cka03-svcn configured

cluster3-controlplane ~ ➜  cat 14.yaml 
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: external-webserver-cka03-svcn                                        # as per service name
  namespace: kube-public                                                     # as per service
  labels:
    kubernetes.io/service-name: external-webserver-cka03-svcn                # equal to service name
addressType: IPv4
ports:
  - name: http                                                               # "" or same as Service port name
    protocol: TCP
    port: 9999                                                               # port for web server
endpoints:
  - addresses:
      - "192.168.81.189"                                                     # ping student-node
cluster3-controlplane ~ ➜  k edit svc -n kube-public external-webserver-cka03-svcn  # spec.ports.name: http added
service/external-webserver-cka03-svcn edited

cluster3-controlplane ~ ➜  k describe svc -n kube-public external-webserver-cka03-svcn 
Name:                     external-webserver-cka03-svcn
Namespace:                kube-public
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.145.152
IPs:                      10.43.145.152
Port:                     http  80/TCP                       # name added and mandatory; no need to change port    
TargetPort:               80/TCP                             # no need to change the pod
Endpoints:                192.168.81.189:9999                # assinged now
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster3-controlplane ~ ➜  k get po
NAME         READY   STATUS    RESTARTS   AGE
nginx-wl06   1/1     Running   0          121m

cluster3-controlplane ~ ➜  k exec nginx-wl06 -it -- sh
# curl external-webserver-cka03-svcn.kube-public                # Worked
<!DOCTYPE html>
```

---

## Q2

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
  externalName: 8.8.8.8                 # ❌ Wrong in real life, but matches question
  ports:
    - name: http
      port: 53
      targetPort: 53


root@student-node ~ ➜  k describe svc ckad12-service 
Name:              ckad12-service
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          <none>                                # No selector, mark it
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

This creates successfully, but DNS resolution inside the cluster won’t work (as you saw).

```bash
controlplane ~ ➜  k exec po -it -- sh
/ # nslookup ckad12-service.default.svc.cluster.local
Server:         172.20.0.10
Address:        172.20.0.10:53

** server can't find ckad12-service.default.svc.cluster.local: NXDOMAIN

** server can't find ckad12-service.default.svc.cluster.local: NXDOMAIN

/ # exit
command terminated with exit code 1
```

---

## Q3

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

## Q4

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

## Q5

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

## Q6

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

