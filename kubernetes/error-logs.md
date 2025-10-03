```bash
Warning  Failed       1s (x7 over 62s)  kubelet           Error: configmap "category" not found
Warning  Failed     8s (x2 over 10s)  kubelet            Error: secret "postgres-secrte" not found
Warning  Failed     2s (x3 over 18s)  kubelet            Error: couldn't find key db_user in Secret default/postgres-secret
Warning  FailedMount  10s (x6 over 25s)  kubelet          MountVolume.SetUp failed for volume "nginx-config" : configmap "nginx-config" not found

Warning  Failed     10s (x2 over 11s)  kubelet            Error: exec: "shell": executable file not found in $PATH: unknown  # wrong command
E0912 10:41:23.738713       1 run.go:72] "command failed" err="stat /etc/kubernetes/scheduler.config: no such file or directory" # wrong arg
Warning  Failed     4s    kubelet            Failed to pull image "nginx:ltest"

Warning  FailedScheduling  72s   default-scheduler  0/2 nodes are available: 1 node(s) didn't match Pod's node affinity/selector
Warning  FailedScheduling  21s   default-scheduler  0/2 nodes are available: persistentvolumeclaim "pvc-redis" not found.
Warning  FailedScheduling  2m31s  default-scheduler  0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims.

Warning  Unhealthy  4s (x8 over 34s)  kubelet            Readiness probe failed: stat: can't stat '/tmp/healthy': No such file or directory
k exec space-alien-welcome-message-generator-5c945bc5f9-m9nkb -- touch /tmp/ready

Warning Failed 3s (x3 over 17s) kubelet Error: failed to write "200000": .../cpu.cfs_quota_us: invalid argument   # wrong cpu

Node:             staging-node1/      # cause
Status:           Pending               
IPs:              <none>
Events:           <none>

controlplane:~$ k logs -n management deploy/collect-data -c httpd
(98)Address in use: AH00072: make_sock: could not bind to address [::]:80
(98)Address in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
both containers share same containerPort, either change one of them, or delete.

k edit po pod1     # mountPath: /etc/birke , not /etc/birke/*

controlplane:~$ k logs goapp-deployment-77549cf8d6-rr5q4
Error: PORT environment variable not set

NAME                READY   UP-TO-DATE   AVAILABLE   AGE
stream-deployment   0/0     0            0           4m25s   # replica = 0
black-cka25-trb     1/1     0            1           76s     # Progressing    Unknown  DeploymentPaused
web-ui-deployment   0/1     1            0           4m16s   # pod is yet pending, no scheduling yet

controlplane:~$ k edit deployments.apps postgres-deployment  # add  --env=POSTGRES_PASSWORD=<any-value> # Just keeps restarting because of Postgres startup failure
                                                             # MYSQL_ROOT_PASSWORD for MYSQL
cluster3-controlplane ~ ➜  curl http://cluster3-controlplane:31020
    <h3> Failed connecting to the MySQL database. </h3>
<h2> Environment Variables: DB_Host=ClusterIP svc name <mysql-svc-wl05>; DB_Database=<optional>; DB_User=<mandatory>; DB_Password=<mandatory>;
cluster3-controlplane ~ ➜  k edit po -n canara-wl05 webapp-pod-wl05   # webpod, not database pod.


no matches for kind "Persistentvolumeclaim" in version "v1"
no matches for kind "Persistentvolume" in version "apps/v1"
Error from server (BadRequest): strict decoding error: unknown field "metadata.app"

spec.ports[0].nodePort: Invalid value: 32345: provided port is already allocated
kubectl get svc -A | grep 32345

root@student-node ~ ➜  k logs ckad-flash89-aom --all-containers # CrashLoopBackOff
nginx: [alert] could not open error log file: open() "/var/log/nginx/error.log" failed (2: No such file or directory)
root@student-node ~ ➜  vi ckad-flash89.yaml         # mountPath: /var/log/ to /var/log/nginx


volumeMounts:
  - name: nginx-conf-vol
    mountPath: /etc/nginx/conf.d/default.conf  # Target file path inside container
    subPath: default.conf                      # Key from ConfigMap, Use subPath (when mounting one specific key to a file path)

root@student-node ~ ➜  k logs -n ingress-nginx ingress-nginx-controller-685f679564-m69vw
F0911 00:54:26.128505      55 main.go:83] No service with name default-backend-service found in namespace default: services "default-backend-service" not found  # problem spotted

The Pod "my-pod-cka" is invalid: spec.volumes[1].name: Duplicate value: "shared-storage"
* spec.volumes[0].persistentVolumeClaim: Forbidden: may not specify more than 1 volume type
If volume let say it is PVC in use, and you are asked to append a sidecar container, just add it without add new `volumes` section, instaed use the already in-use.
```

1. Wrong field in manifest; pod is exited, no restart ... no other clue 

```bash
# apiVersion: v11

controlplane ~ ➜  k get po
The connection to the server controlplane:6443 was refused - did you specify the right host or port?

controlplane ~ ✖ crictl ps -a | grep api
623cff8032649       90550c43ad2bc       4 hours ago         Exited              kube-apiserver            0                   312e69c925b14       kube-apiserver

controlplane ~ ➜  crictl logs 623cff8032649
I0919 14:27:26.602023       1 controller.go:128] Shutting down kubernetes service endpoint reconciler
I0919 14:27:26.611292       1 secure_serving.go:259] Stopped listening on [::]:6443

controlplane ~ ➜  journalctl -u kubelet -f
Sep 19 14:40:21 controlplane kubelet[191204]: E0919 14:40:21.211510  191204 reconstruct.go:189] "Failed to get Node status to reconstruct device paths" err="Get \"https://192.168.102.106:6443/api/v1/nodes/controlplane\": dial tcp 192.168.102.106:6443: connect: connection refused"
```

2. 
