- Always first look for already available priority classes before creating newer one
- To set priority in pod template, priority class needs to create first. 

---

Create new Pod named `important` of image `nginx:1.21.6-alpine` in the same Namespace. It should request `1Gi` memory resources.

**Assign a higher priority to the new Pod so it's scheduled instead of the existing one.**

```bash
controlplane:~$ vi 2.yaml 
controlplane:~$ k replace -f 2.yaml --force
pod "important" deleted
pod/important replaced

controlplane:~$ k get po -n lion
NAME        READY   STATUS        RESTARTS   AGE
4d37006c    0/1     OutOfmemory   0          3m8s        # priorityClassName: level2
important   1/1     Running       0          5s

controlplane:~$ cat 2.yaml 
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: important
  name: important
  namespace: lion
spec:
  priorityClassName: level3          # Note: don't create a new pc, it's been provided already.
  containers:
  - image: nginx:1.21.6-alpine
    name: important
    resources:
      requests:
        memory: 1Gi
  dnsPolicy: ClusterFirst
  restartPolicy: Always
controlplane:~$ k get pc
NAME                      VALUE        GLOBAL-DEFAULT   AGE     PREEMPTIONPOLICY
level2                    200000000    false            19m     PreemptLowerPriority
level3                    300000000    false            19m     PreemptLowerPriority
system-cluster-critical   2000000000   false            2d19h   PreemptLowerPriority
system-node-critical      2000001000   false            2d19h   PreemptLowerPriority
controlplane:~$ 
```

