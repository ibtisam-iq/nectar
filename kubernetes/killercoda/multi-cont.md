In the ckad-multi-containers namespaces, create a ckad-neighbor-pod pod that matches the following requirements.


Pod has an emptyDir volume named my-vol.


The first container named main-container, runs nginx:1.16 image. This container mounts the my-vol volume at /usr/share/nginx/html path.


The second container is a co-located container named neighbor-container, and runs the busybox:1.28 image. This container mounts the volume my-vol at /var/log path.

Every 5 seconds, this container should write the current date along with greeting message Hi I am from neighbor container to index.html in the my-vol volume.

```bash
root@student-node ~ ✖ k replace -f 1.yaml --force
pod "ckad-neighbor-pod" deleted
pod/ckad-neighbor-pod replaced

root@student-node ~ ➜  cat 1.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: ckad-neighbor-pod
  namespace: ckad-multi-containers
spec:
  volumes:
    - name: my-vol
      emptyDir: {}
  containers:
    - name: main-container
      image: nginx:1.16
      volumeMounts:
        - name: my-vol
          mountPath: /usr/share/nginx/html
    - name: neighbor-container
      image: busybox:1.28
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
            echo "$(date) - Hi I am from neighbor container" > /var/log/index.html;
            sleep 5;
          done
      volumeMounts:
        - name: my-vol
          mountPath: /var/log
root@student-node ~ ➜  k get po -n ckad-multi-containers 
NAME                READY   STATUS    RESTARTS   AGE
ckad-neighbor-pod   2/2     Running   0          15s
```
