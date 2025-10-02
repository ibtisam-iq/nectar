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

## Q2: Endpoint is not yet assigned, wrong label

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

## Q3: Endpoint is assigned, but wrong port 

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

## Q4: Wrong Protocol
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

### 🔎 What you actually have

Pod (`pink-pod-cka16-trb`):

```yaml
containers:
  ports:
  - containerPort: 80   # ✅ Pod is listening on 80
```

Service (`pink-svc-cka16-trb`):

```
Port:        5000/UDP     # ❌ wrong, it should be TCP
TargetPort:  80/UDP       # points to Pod’s port (80), but also marked UDP
Endpoints:   172.17.1.3:80
```

### 🚨 What went wrong

1. The **exam question said**: *“App runs on port 5000”* → we assumed Pod’s containerPort = 5000.
2. But in reality, the Pod YAML shows `containerPort: 80`.

   * That means the Pod app is **actually running on 80, not 5000**.
3. The Service was created incorrectly:

   * Used `port: 5000` with **UDP**, while it should be TCP.
   * Service should expose **TCP 80**, not UDP 5000.



