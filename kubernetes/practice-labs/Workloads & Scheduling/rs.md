## Q1

**Create a replicaset with below specifications**
Name = **web-app**
Image = **nginx**
Replicas = **3**

Please note, there is already a pod running in our cluster named **web-frontend**, please make sure the total number of pods running in the cluster is not more than **3**.

```bash
controlplane ~ ➜  k get po --show-labels 
NAME           READY   STATUS    RESTARTS   AGE   LABELS
web-frontend   1/1     Running   0          20s   app=web-app

controlplane ~ ➜  k create deploy web-app --image nginx -r 3 --dry-run -o yaml > 11.yaml
W1106 12:13:58.819018   59682 helpers.go:731] --dry-run is deprecated and can be replaced with --dry-run=client.

controlplane ~ ➜  vi 11.yaml        # Change the kind, remove spec.strategy, and add lables app=web-app

controlplane ~ ➜  cat 11.yaml 
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  labels:
    app: web-app
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app            # match the labels to the existing pod
    spec:
      containers:
      - image: nginx
        name: nginx

controlplane ~ ➜  k apply -f 11.yaml 
replicaset.apps/web-app created

controlplane ~ ➜  k get po --show-labels 
NAME            READY   STATUS    RESTARTS   AGE   LABELS
web-app-jkn62   1/1     Running   0          30s   app=web-app
web-app-kgnf2   1/1     Running   0          30s   app=web-app
web-frontend    1/1     Running   0          60s   app=web-app

controlplane ~ ➜  k get rs
NAME      DESIRED   CURRENT   READY   AGE
web-app   3         3         3       50s

controlplane ~ ➜  k delete rs web-app 
replicaset.apps "web-app" deleted from default namespace

controlplane ~ ➜  k get po
No resources found in default namespace.
```

---
controlplane ~ ➜  
```
