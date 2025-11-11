```bash
controlplane ~ ➜  cat > deploy.md
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pod-access-deploy
  namespace: app-space
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reader
  template:
    metadata:
      labels:
        app: reader
    spec:
      serviceAccountName: sa-pod-reader
      containers:
      - name: reader
        image: bitnami/kubectl:latest
        command: ["sh", "-c", "while true; do kubectl get pods -A; sleep 60; done"]

controlplane ~ ➜  k create ns app-space
namespace/app-space created

controlplane ~ ➜  k create sa -n app-space sa-app-space
serviceaccount/sa-app-space created

controlplane ~ ➜  k create role reader -n app-space --verb get,list,watch --resource pods
role.rbac.authorization.k8s.io/reader created

controlplane ~ ➜  k create rolebinding reader -n app-space --role reader --serviceaccount app-space:sa-app-space
rolebinding.rbac.authorization.k8s.io/reader created

controlplane ~ ➜  mv deploy.md deploy.yaml

controlplane ~ ➜  k apply -f deploy.yaml 
deployment.apps/pod-access-deploy created

controlplane ~ ➜  k get deploy -n app-space pod-access-deploy 
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
pod-access-deploy   0/1     0            0           20s

controlplane ~ ➜  k get rs -n app-space 
NAME                          DESIRED   CURRENT   READY   AGE
pod-access-deploy-7f77485fb   1         0         0       76s

controlplane ~ ➜  k get po -n app-space 
No resources found in app-space namespace.

controlplane ~ ➜  k describe rs -n app-space pod-access-deploy-7f77485fb 
Name:           pod-access-deploy-7f77485fb
Namespace:      app-space
Events:
  Type     Reason        Age                  From                   Message
  ----     ------        ----                 ----                   -------
  Warning  FailedCreate  19s (x15 over 101s)  replicaset-controller  Error creating: pods "pod-access-deploy-7f77485fb-" is forbidden: error looking up service account app-space/sa-pod-reader: serviceaccount "sa-pod-reader" not found

controlplane ~ ➜  k get sa -n app-space 
NAME           SECRETS   AGE
default        0         6m36s
sa-app-space   0         5m47s

controlplane ~ ➜  k set serviceaccount deploy pod-access-deploy sa-app-space -n app-space 
deployment.apps/pod-access-deploy serviceaccount updated

controlplane ~ ➜  k get po -n app-space 
NAME                                 READY   STATUS    RESTARTS   AGE
pod-access-deploy-86d55fcd46-lt2dv   1/1     Running   0          11s

controlplane ~ ➜  k logs -n app-space deployments/pod-access-deploy 
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope

controlplane ~ ➜  k create clusterrole reader -n app-space --verb get,list,watch --resource pods
clusterrole.rbac.authorization.k8s.io/reader created

controlplane ~ ➜  k create clusterrolebinding reader -n app-space --role reader --serviceaccount app-space:sa-app-space
error: unknown flag: --role
See 'kubectl create clusterrolebinding --help' for usage.

controlplane ~ ✖ k create clusterrolebinding reader -n app-space --clusterrole reader --serviceaccount app-space:sa-app-space
clusterrolebinding.rbac.authorization.k8s.io/reader created

controlplane ~ ➜  k logs -n app-space deployments/pod-access-deploy
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
app-space     pod-access-deploy-86d55fcd46-lt2dv         1/1     Running   0          4m7s
---
kube-system   kube-scheduler-controlplane                1/1     Running   0          25m

controlplane ~ ➜  k edit deployments -n app-space pod-access-deploy    # command updated: while true; do kubectl get pods,secrets; sleep 60; done
deployment.apps/pod-access-deploy edited

controlplane ~ ➜  k logs -n app-space deployments/pod-access-deploy
Found 2 pods, using pod/pod-access-deploy-86d55fcd46-lt2dv
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "pods" in API group "" at the cluster scope
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
app-space     pod-access-deploy-86d55fcd46-lt2dv         1/1     Running   0          4m7s
---
kube-system   kube-scheduler-controlplane                1/1     Running   0          25m


controlplane ~ ➜  k logs -n app-space deployments/pod-access-deploy
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "secrets" in API group "" in the namespace "app-space"
NAME                                 READY   STATUS              RESTARTS   AGE
pod-access-deploy-84947d649c-wwbpk   0/1     ContainerCreating   0          2s
pod-access-deploy-86d55fcd46-lt2dv   1/1     Running             0          6m2s

controlplane ~ ➜  k logs -n app-space deployments/pod-access-deploy
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "secrets" in API group "" in the namespace "app-space"
NAME                                 READY   STATUS              RESTARTS   AGE
pod-access-deploy-84947d649c-wwbpk   0/1     ContainerCreating   0          2s
pod-access-deploy-86d55fcd46-lt2dv   1/1     Running             0          6m2s
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:app-space:sa-app-space" cannot list resource "secrets" in API group "" in the namespace "app-space"
NAME                                 READY   STATUS    RESTARTS   AGE
pod-access-deploy-84947d649c-wwbpk   1/1     Running   0          63s

controlplane ~ ➜  
```
