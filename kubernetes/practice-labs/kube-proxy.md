You're asked to confirm that kube-proxy is running correctly. For this perform the following in Namespace `project-hamster`:

- Create `Pod p2-pod` with image `nginx:1-alpine`
- Create Service `p2-service` which exposes the Pod internally in the cluster on port `3000->80`
- Write the iptables rules of `node cka3962` belonging the created Service `p2-service` into file `/opt/course/p2/iptables.txt`
- Delete the Service and confirm that the iptables rules are gone again

```bash
candidate@cka3962:~$ k -n project-hamster run p2-pod --image=nginx:1-alpine
pod/p2-pod created

candidate@cka3962:~$ k -n project-hamster expose pod p2-pod --name p2-service --port 3000 --target-port 80

candidate@cka3962:~$ k -n project-hamster get pod,svc,ep
NAME                 READY   STATUS    RESTARTS   AGE
pod/p2-pod           1/1     Running   0          2m31s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/p2-service   ClusterIP   10.105.128.247   <none>        3000/TCP   1s

NAME                   ENDPOINTS       AGE
endpoints/p2-service   10.44.0.31:80   1s

candidate@cka3962:~$ sudo -i

root@cka3962$ crictl ps | grep kube-proxy
67cccaf8310a1   505d571f5fd56   9 days ago      Running    kube-proxy ...

root@cka3962~# crictl logs 67cccaf8310a1
I1029 14:10:23.984360       1 server_linux.go:66] "Using iptables proxy"
...

root@cka3962:~# iptables-save | grep p2-service
-A KUBE-SEP-55IRFJIRWHLCQ6QX -s 10.44.0.31/32 -m comment --comment "project-hamster/p2-service" -j KUBE-MARK-MASQ
-A KUBE-SEP-55IRFJIRWHLCQ6QX -p tcp -m comment --comment "project-hamster/p2-service" -m tcp -j DNAT --to-destination 10.44.0.31:80
-A KUBE-SERVICES -d 10.105.128.247/32 -p tcp -m comment --comment "project-hamster/p2-service cluster IP" -m tcp --dport 3000 -j KUBE-SVC-U5ZRKF27Y7YDAZTN
-A KUBE-SVC-U5ZRKF27Y7YDAZTN ! -s 10.244.0.0/16 -d 10.105.128.247/32 -p tcp -m comment --comment "project-hamster/p2-service cluster IP" -m tcp --dport 3000 -j KUBE-MARK-MASQ
-A KUBE-SVC-U5ZRKF27Y7YDAZTN -m comment --comment "project-hamster/p2-service -> 10.44.0.31:80" -j KUBE-SEP-55IRFJIRWHLCQ6QX
# Warning: iptables-legacy tables present, use iptables-legacy-save to see them
Great. Now let's write these logs into the requested file:

root@cka3962:~# iptables-save | grep p2-service > /opt/course/p2/iptables.txt

root@cka3962:~# k -n project-hamster delete svc p2-service
service "p2-service" deleted

root@cka3962:~# iptables-save | grep p2-service

root@cka3962:~#
```
