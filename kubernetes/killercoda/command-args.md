
`--command -- sh -c "..."` → lets you run multiple shell commands in sequence.

```bash
k run alpine-app --image alpine -- 'echo "Main application is running"; sleep 3600'    # wrong, you need to open the shell in order to multiple commands
kubectl run alpine-app \
  --image=alpine \
  --restart=Always \
  --command -- sh -c "echo 'Main application is running' && sleep 3600"

root@student-node ~ ➜  cat 5.yaml 
apiVersion: v1
kind: Pod
  containers:
  - command:
    - sh
    - -c
    - echo "Main application is running"; sleep 3600
```

---

```bash
k create cj -n ckad-job learning-every-minute --schedule "* * * * *" --image busybox:1.28 -- echo "I am practicing for CKAD certification"
cronjob.batch/learning-every-minute created

containers:
            - command:
              - echo
              - I am practicing for CKAD certification
```

---
> **NOTE:** By default NGINX web server default location is at `/usr/share/nginx/html` which is located on the default file system of the Linux.
```bash
root@student-node ~ ✖ k exec -n ckad-pod-design basic-nginx -it -- sh
# echo "Hello from KodeKloud!" > /usr/share/nginx/html.index.html
# cat /usr/share/nginx/html.index.html
Hello from KodeKloud!
# exit
```
---
```bash
command:
  - "/bin/sh"          not "bin/sh"
  - "-c"
  - "sleep 10000"
```

---

## Wrong command

```bash
cluster4-controlplane ~ ➜  k describe po -n kube-system kube-controller-manager-cluster4-controlplane 
Name:                 kube-controller-manager-cluster4-controlplane
Namespace:            kube-system
    Command:
      kube-controller-manage
      --allocate-node-cidrs=true
Warning  Failed   19s (x6 over 3m6s)  kubelet  Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: exec: "kube-controller-manage": executable file not found in $PATH: unknown
```

## Wrong arg

```bash
cluster4-controlplane ~ ➜  k get po -n kube-system kube-scheduler-cluster4-controlplane 
NAME                                   READY   STATUS             RESTARTS       AGE
kube-scheduler-cluster4-controlplane   0/1     CrashLoopBackOff   5 (117s ago)   4m50s

cluster4-controlplane ~ ➜  k describe po -n kube-system kube-scheduler-cluster4-controlplane 
Name:                 kube-scheduler-cluster4-controlplane
Namespace:            kube-system
Events:
  Type     Reason   Age                   From     Message
  ----     ------   ----                  ----     -------
  Warning  BackOff  2m2s (x25 over 5m)    kubelet  Back-off restarting failed container kube-scheduler in pod kube-scheduler-cluster4-controlplane_kube-system(5f465a06e04c6bd15f30009df81607d1)

cluster4-controlplane ~ ➜  k logs -n kube-system kube-scheduler-cluster4-controlplane 
I0912 10:41:23.738329       1 serving.go:386] Generated self-signed cert in-memory
E0912 10:41:23.738713       1 run.go:72] "command failed" err="stat /etc/kubernetes/scheduler.config: no such file or directory"

cluster4-controlplane ~ ➜  ls /etc/kubernetes/
admin.conf  controller-manager.conf  kubelet.conf  manifests  pki  scheduler.conf  super-admin.conf

cluster4-controlplane ~ ➜  
```
