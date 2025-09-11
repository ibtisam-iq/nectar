
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
