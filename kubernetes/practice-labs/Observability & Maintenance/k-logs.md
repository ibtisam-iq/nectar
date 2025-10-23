`product` pod is running. when you access logs of this pod, it displays the output `Mi Tv Is Good`

Please update the pod definition file to utilize an **environment variable** with the value `Sony Tv Is Good` Then, recreate this pod with the modified configuration.


```bash
controlplane:~$ k get po
NAME      READY   STATUS    RESTARTS   AGE
product   1/1     Running   0          12m

controlplane:~$ k logs product 
Mi Tv Is Good

controlplane:~$ k get po product -o yaml
apiVersion: v1
kind: Pod
metadata:
  name: product
  namespace: default
spec:
  containers:
  - command:
    - sh
    - -c
    - echo 'Mi Tv Is Good' && sleep 3600
    image: busybox
    imagePullPolicy: Always
    name: product-container
  restartPolicy: Always

controlplane:~$ k get po product -o yaml > 1.yaml
controlplane:~$ vi 1.yaml 
controlplane:~$ k replace -f 1.yaml --force
pod "product" deleted
pod/product replaced

controlplane:~$ k logs product 
Sony Tv Is Good

controlplane:~$ cat 1.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: product
spec:
  containers:
  - command:
    - sh
    - -c
    - echo $abc && sleep 3600
    image: busybox
    env:
    - name: abc
      value: "Sony Tv Is Good"
    imagePullPolicy: Always
    name: product-container
controlplane:~$
```

