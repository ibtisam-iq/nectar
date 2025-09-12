
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
