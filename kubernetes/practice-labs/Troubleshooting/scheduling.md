## Q1: Wrong `nodeName`

```bash
controlplane:~$ k get no
NAME           STATUS   ROLES           AGE    VERSION
controlplane   Ready    control-plane   4d7h   v1.33.2
controlplane:~$ k describe po management-frontend-7b897f454f-2zpgh 
Name:             management-frontend-7b897f454f-2zpgh
Node:             staging-node1/      # cause
Status:           Pending
IP:               
IPs:              <none>
Events:            <none>            # effect, no events, not scheduled yet
controlplane:~$ k get events         # nothing special

controlplane:~$ k edit deploy management-frontend 
deployment.apps/management-frontend edited
controlplane:~$ k rollout restart deployment management-frontend 
deployment.apps/management-frontend restarted
controlplane:~$ k get po
NAME                                   READY   STATUS        RESTARTS   AGE
management-frontend-5987bc84b5-9hnsd   1/1     Running       0          4s
management-frontend-5987bc84b5-fczz4   1/1     Running       0          4s
management-frontend-5987bc84b5-gbr5k   1/1     Running       0          7s
management-frontend-5987bc84b5-h9mzz   1/1     Running       0          6s
management-frontend-5987bc84b5-ms7hl   1/1     Running       0          6s
```
---

## Q2 Wrong Node Label (it is restricted to change any pod feature)

```bash
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  72s   default-scheduler  0/2 nodes are available: 1 node(s) didn't match Pod's node affinity/selector, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

controlplane:~$ k get po -o yaml frontend 
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: NodeName
            operator: In
            values:
            - frontend

controlplane:~$ k label no node01 NodeName=frontend
error: 'NodeName' already has a value (frontendnodes), and --overwrite is false
controlplane:~$ k label no node01 NodeName=frontend --overwrite 
node/node01 labeled

NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          5m26s
controlplane:~$
```

---

