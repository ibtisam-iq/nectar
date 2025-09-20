There is a Pod YAML provided at `/root/hobby.yaml`. That Pod should be preferred to be only scheduled on Nodes where Pods with label `level=restricted` are running. For the topologyKey use `kubernetes.io/hostname`. There are no taints on any Nodes which means no tolerations are needed.

```bash

controlplane:~$ k get po --show-labels 
NAME         READY   STATUS    RESTARTS   AGE    LABELS
restricted   1/1     Running   0          115s   level=restricted
controlplane:~$ k get po --show-labels -o wide
NAME         READY   STATUS    RESTARTS   AGE     IP            NODE     NOMINATED NODE   READINESS GATES   LABELS
restricted   1/1     Running   0          2m14s   192.168.1.4   node01   <none>           <none>            level=restricted
controlplane:~$ vi hobby.yaml 
controlplane:~$ k apply -f hobby.yaml 
pod/hobby-project created
controlplane:~$ k get po -o wide
NAME            READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
hobby-project   1/1     Running   0          11s   192.168.1.5   node01   <none>           <none>
restricted      1/1     Running   0          13m   192.168.1.4   node01   <none>           <none>

Extend the provided YAML at /root/hobby.yaml :

  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: level
              operator: In
              values:
              - restricted
          topologyKey: kubernetes.io/hostname

Another way to solve the same requirement would be:

...
  affinity:
    podAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              level: restricted
          topologyKey: kubernetes.io/hostname
```
