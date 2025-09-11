
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
