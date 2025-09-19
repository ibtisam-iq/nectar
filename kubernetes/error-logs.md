```bash
Warning  Failed       1s (x7 over 62s)  kubelet           Error: configmap "category" not found
Warning  Failed     8s (x2 over 10s)  kubelet            Error: secret "postgres-secrte" not found
Warning  Failed     2s (x3 over 18s)  kubelet            Error: couldn't find key db_user in Secret default/postgres-secret
Warning  FailedMount  10s (x6 over 25s)  kubelet          MountVolume.SetUp failed for volume "nginx-config" : configmap "nginx-config" not found

Warning  Failed     10s (x2 over 11s)  kubelet            Error: exec: "shell": executable file not found in $PATH: unknown  # sh not shell
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
stream-deployment   0/0     0            0           4m25s
Name:                   stream-deployment
Replicas:               0 desired | 0 updated | 0 total | 0 available | 0 unavailable   # replica is 0
NewReplicaSet:   stream-deployment-79cb7b68c (0/0 replicas created)
Events:          <none>

controlplane:~$ k edit deployments.apps postgres-deployment  # add  --env=POSTGRES_PASSWORD=<any-value> # Just keeps restarting because of Postgres startup failure

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
    subPath: default.conf                      # Key from ConfigMap




```
