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
```
