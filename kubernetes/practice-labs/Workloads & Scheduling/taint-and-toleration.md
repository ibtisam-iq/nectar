## Taints and Tolerations

Just tainted node `node01`, update tolerations in this application-deployment.yaml pod template and create pod object

> **Note:** Don't remove any specification

```bash
controlplane:~$ vi application-deployment.yaml 
controlplane:~$ k taint no node01 name=ibtisam:NoSchedule      
node/node01 tainted
controlplane:~$ k apply -f application-deployment.yaml 

controlplane:~$ k apply -f application-deployment.yaml 
pod/redis-pod created
controlplane:~$ k get po
NAME        READY   STATUS    RESTARTS   AGE
redis-pod   0/1     Pending   0          5s

controlplane:~$ k describe po redis-pod 
Name:             redis-pod
Node-Selectors:              <none>
Tolerations:                 name=ibtisam:NoSchedule
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  20s   default-scheduler  0/2 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }, 1 node(s) had untolerated taint {nodeName: workerNode01}. preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

controlplane:~$ k edit no node01     # name=ibtisam:NoSchedule removed
node/node01 edited
controlplane:~$ vi application-deployment.yaml 
controlplane:~$ k replace -f application-deployment.yaml --force
pod "redis-pod" deleted
pod/redis-pod replaced
controlplane:~$ k get po
NAME        READY   STATUS    RESTARTS   AGE
redis-pod   1/1     Running   0          10s
controlplane:~$ 
```
