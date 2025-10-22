In K8s DaemonSets are often used to configure certain things on Nodes.

Create a DaemonSet named configurator , it should:

- be in Namespace `configurator`
- use image `bash`
- mount `/configurator` as HostPath volume on the Node it's running on
- write `aba997ac-1c89-4d64` into file `/configurator/config` on its Node via the command: section
- be kept running using `sleep 1d` or similar after the file write command
- There are no taints on any Nodes which means no tolerations are needed.

```bash
controlplane:~$ k logs -n configurator configurator-5zgfq 
sh: can't create /configuration/config: nonexistent directory

controlplane:~$ cat ds.yaml 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: configurator
  namespace: configurator
  labels:
    k8s-app: configurator
spec:
  selector:
    matchLabels:
      name: configurator
  template:
    metadata:
      labels:
        name: configurator
    spec:
      containers:
      - name: configurator
        image: bash
        command:
          - sh
          - -c
          - 'echo aba997ac-1c89-4d64 > /configuration/config && sleep 1d'    # put /configurator/config 
        volumeMounts:
        - name: vol
          mountPath: /configurator
      volumes:
      - name: vol
        hostPath:
          path: /configurator
          type: DirectoryOrCreate
controlplane:~$ vi ds.yaml
controlplane:~$ k replace -f ds.yaml --force 
daemonset.apps "configurator" deleted
daemonset.apps/configurator replaced
controlplane:~$ k get ds -n configurator 
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
configurator   2         2         2       2            2           <none>          11s
controlplane:~$ k get po -n configurator -o wide
NAME                 READY   STATUS    RESTARTS   AGE     IP            NODE           NOMINATED NODE   READINESS GATES
configurator-c267f   1/1     Running   0          8m51s   192.168.0.6   controlplane   <none>           <none>
configurator-pjw2d   1/1     Running   0          8m51s   192.168.1.6   node01         <none>           <none> 

controlplane:~$ cat /configurator/config 
aba997ac-1c89-4d64
controlplane:~$ ssh node01 -- cat /configurator/config
aba997ac-1c89-4d64
```
