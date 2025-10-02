## Q 1
Create an nginx pod called `nginx-resolver-cka06-svcn` using the image `nginx`, and expose it **internally** with a service called `nginx-resolver-service-cka06-svcn`.

Test that you are able to look up the service and pod names from within the cluster. Use the image `busybox:1.28` for dns lookup. Record results in `/root/CKA/nginx.svc.cka06.svcn` and `/root/CKA/nginx.pod.cka06.svcn` on cluster1-controlplane.

```bash
cluster1-controlplane ~ ➜  k run nginx-resolver-cka06-svcn --image nginx --port 80
pod/nginx-resolver-cka06-svcn created

cluster1-controlplane ~ ➜  k expose po nginx-resolver-cka06-svcn --name nginx-resolver-service-cka06-svcn
service/nginx-resolver-service-cka06-svcn exposed

cluster1-controlplane ~ ➜  k get po,svc -o wide
NAME                                       READY   STATUS    RESTARTS   AGE     IP           NODE              NOMINATED NODE   READINESS GATES
pod/nginx-resolver-cka06-svcn              1/1     Running   0          3m52s   172.17.1.9   cluster1-node01   <none>           <none>

NAME                                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE     SELECTOR
service/nginx-resolver-service-cka06-svcn   ClusterIP   172.20.34.168   <none>        80/TCP    3m29s   run=nginx-resolver-cka06-svcn

cluster1-controlplane ~ ➜  k run test -it --rm --image busybox:1.28 -- sh
If you don't see a command prompt, try pressing enter.
/ # nslookup nginx-resolver-service-cka06-svcn
Server:    172.20.0.10
Address 1: 172.20.0.10 kube-dns.kube-system.svc.cluster.local

Name:      nginx-resolver-service-cka06-svcn
Address 1: 172.20.34.168 nginx-resolver-service-cka06-svcn.default.svc.cluster.local
/ # 
/ # nslookup 172-17-1-9.default.pod.cluster.local
Server:    172.20.0.10
Address 1: 172.20.0.10 kube-dns.kube-system.svc.cluster.local

Name:      172-17-1-9.default.pod.cluster.local
Address 1: 172.17.1.9 172-17-1-9.nginx-resolver-service-cka06-svcn.default.svc.cluster.local
/ # exit
Session ended, resume using 'kubectl attach test -c test -i -t' command when the pod is running
pod "test" deleted

cluster1-controlplane ~ ➜  cat > /root/CKA/nginx.svc.cka06.svcn
Server:    172.20.0.10
Address 1: 172.20.0.10 kube-dns.kube-system.svc.cluster.local

Name:      nginx-resolver-service-cka06-svcn
Address 1: 172.20.34.168 nginx-resolver-service-cka06-svcn.default.svc.cluster.local

cluster1-controlplane ~ ➜  cat > /root/CKA/nginx.pod.cka06.svcn
Server:    172.20.0.10
Address 1: 172.20.0.10 kube-dns.kube-system.svc.cluster.local

Name:      172-17-1-9.default.pod.cluster.local
Address 1: 172.17.1.9 172-17-1-9.nginx-resolver-service-cka06-svcn.default.svc.cluster.local

cluster1-controlplane ~ ➜

---

/ # wget -O- nginx-resolver-service-cka06-svcn:80
Connecting to nginx-resolver-service-cka06-svcn:80 (172.20.247.131:80)
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
-                    100% |**************************************************************************************************************************|   615   0:00:00 ETA
/ # 
```

---

## Q2

The Deployment controller in Namespace `lima-control` communicates with various cluster internal endpoints by using their DNS FQDN values.

Update the **ConfigMap** used by the Deployment with the correct FQDN values for:

- **DNS_1:** Service `kubernetes` in Namespace `default`
- **DNS_2:** Headless Service `department` in Namespace `lima-workload`
- **DNS_3:** Pod `section100` in Namespace `lima-workload`. It should work even if the Pod IP changes
- **DNS_4:** A Pod with IP `1.2.3.4` in Namespace `kube-system`

Ensure the Deployment works with the updated values.

```bash
candidate@cka6016:~$ $ k -n lima-control get cm                
NAME               DATA   AGE
control-config     4      10m

# kubectl -n lima-workload edit pod section100
apiVersion: v1
kind: Pod
metadata:
  name: section100
  namespace: lima-workload
  labels:
    name: section
spec:
  hostname: section100  #  hostname
  subdomain: section    #  subdomain to same name as service
  containers:
    - image: httpd:2-alpine
      name: pod
...

candidate@cka6016:~$ k -n lima-control edit cm control-config
apiVersion: v1
data:
  DNS_1: kubernetes.default.svc.cluster.local                  # UPDATE
  DNS_2: department.lima-workload.svc.cluster.local            # UPDATE
  DNS_3: section100.section.lima-workload.svc.cluster.local    # UPDATE
  DNS_4: 1-2-3-4.kube-system.pod.cluster.local                 # UPDATE
kind: ConfigMap
metadata:
  name: control-config
  namespace: lima-control

candidate@cka6016:~$ kubectl -n lima-control rollout restart deploy controller
deployment.apps/controller restarted
And the Pod logs also look happy now:

candidate@cka6016:~$ k -n lima-control logs -f controller-54b5b69d7d-mgng2

+ nslookup kubernetes.default.svc.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   kubernetes.default.svc.cluster.local
Address: 10.96.0.1


+ nslookup department.lima-workload.svc.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   department.lima-workload.svc.cluster.local
Address: 10.32.0.2
Name:   department.lima-workload.svc.cluster.local
Address: 10.32.0.9


+ nslookup section100.section.lima-workload.svc.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   section100.section.lima-workload.svc.cluster.local
Address: 10.32.0.10


+ nslookup 1-2-3-4.kube-system.pod.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   1-2-3-4.kube-system.pod.cluster.local
Address: 1.2.3.4
```
