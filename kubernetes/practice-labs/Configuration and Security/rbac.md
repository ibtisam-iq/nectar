## 🔑 RBAC Quick Indicators

* **Verbs + Namespace →** `Role + RoleBinding`
* **Verbs + Cluster/all namespaces →** `ClusterRole + ClusterRoleBinding`
  
  
* **Existing ClusterRole/Role mentioned →** Just create **binding**
  * **If ServiceAccount →** Use `kind: ServiceAccount` in binding
  * **If User →** Use `kind: User` in binding
* **Binding rule shortcut:**

  * Role ↔ RoleBinding (namespace only)
  * ClusterRole ↔ ClusterRoleBinding (cluster/global)
  * ClusterRole ↔ RoleBinding (cluster perms in one namespace)


## Q1

Create a new role named “sa-creator” that will allow creating service accounts in the default namespace.
```bash
controlplane:~$ k create sa sa-creator
serviceaccount/sa-creator created

controlplane:~$ k api-resources | grep -i serviceacc
serviceaccounts                     sa           v1                                true         ServiceAccount

controlplane:~$ k create role sa-creator --verb create --resource serviceaccounts
role.rbac.authorization.k8s.io/sa-creator created

controlplane:~$ k create role sa-creatorr --verb create --resource sa
role.rbac.authorization.k8s.io/sa-creatorr created
```

---

## Q2

There are existing Namespaces `ns1` and `ns2`. Create ServiceAccount `pipeline` in both Namespaces.

These SAs should be allowed to `view` almost everything in the *whole cluster*. You can use the default ClusterRole `view` for this.

These SAs should be allowed to `create` and `delete` Deployments in their Namespace.

Verify everything using `kubectl auth can-i` .

**Indicators**

* ServiceAccount mentioned → must create SA in both namespaces.
* Needs **view across whole cluster** → ClusterRoleBinding with default `view`.
* Needs **create/delete deployments in their own namespace** → Role (per namespace) + RoleBinding.

```bash
controlplane:~$ k create sa pipeline -n ns1 
serviceaccount/pipeline created
controlplane:~$ k create sa pipeline -n ns2 
serviceaccount/pipeline created
controlplane:~$ k get clusterrole
NAME                                                                   CREATED AT
view                                                                   2025-08-19T09:03:53Z
controlplane:~$ k create clusterrolebinding abc --help

Usage:
  kubectl create clusterrolebinding NAME --clusterrole=NAME [--user=username] [--group=groupname]
[--serviceaccount=namespace:serviceaccountname] [--dry-run=server|client|none] [options]

controlplane:~$ k create clusterrolebinding abc --clusterrole view --serviceaccount=ns2:pipeline --serviceaccount=ns1:pipeline
clusterrolebinding.rbac.authorization.k8s.io/abc created
controlplane:~$ k create role abc -n ns1 --verb=create,delete --resource=deployments
role.rbac.authorization.k8s.io/abc created
controlplane:~$ k create role abc -n ns2 --verb=create,delete --resource=deployments
role.rbac.authorization.k8s.io/abc created
controlplane:~$ k create rolebinding abc -n ns1 --role abc --serviceaccount=ns1:pipeline   
rolebinding.rbac.authorization.k8s.io/abc created
controlplane:~$ k create rolebinding abc -n ns2 --role abc --serviceaccount=ns2:pipeline
rolebinding.rbac.authorization.k8s.io/abc created

# namespace ns1 deployment manager
k auth can-i delete deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i create deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n ns1 # NO
k auth can-i update deployments --as system:serviceaccount:ns1:pipeline -n default # NO

# namespace ns2 deployment manager
k auth can-i delete deployments --as system:serviceaccount:ns2:pipeline -n ns2 # YES
k auth can-i create deployments --as system:serviceaccount:ns2:pipeline -n ns2 # YES
k auth can-i update deployments --as system:serviceaccount:ns2:pipeline -n ns2 # NO
k auth can-i update deployments --as system:serviceaccount:ns2:pipeline -n default # NO

# cluster wide view role
k auth can-i list deployments --as system:serviceaccount:ns1:pipeline -n ns1 # YES
k auth can-i list deployments --as system:serviceaccount:ns1:pipeline -A # YES
k auth can-i list pods --as system:serviceaccount:ns1:pipeline -A # YES
k auth can-i list pods --as system:serviceaccount:ns2:pipeline -A # YES
k auth can-i list secrets --as system:serviceaccount:ns2:pipeline -A # NO (default view-role doesn't allow)
```

---

## Q3

There is existing Namespace `applications`.
User `smoke` should be allowed to `create` and `delete` `Pods, Deployments and StatefulSets` in Namespace `applications`.
User smoke should have `view` permissions (like the permissions of the default `ClusterRole` named `view` ) in all Namespaces but not in `kube-system`.

**Indicators**

* User `smoke` mentioned → need binding with `kind: User`.
* Needs `create/delete` Pods, Deployments, StatefulSets in `applications` → Role + RoleBinding.
* Needs `view` in all namespaces (except kube-system) → use existing ClusterRole `view` + RoleBinding in each namespace except `kube-system`.


```bash
controlplane:~$ k create role abc --verb=create,delete --resource=pods,deployments,statefulsets -n applications 
role.rbac.authorization.k8s.io/abc created
controlplane:~$ k create rolebinding -n applications abc --user=smoke --role=abc    
rolebinding.rbac.authorization.k8s.io/abc created

controlplane:~$ k get ns
NAME                 STATUS   AGE
applications         Active   20m
default              Active   4d11h
kube-node-lease      Active   4d11h
kube-public          Active   4d11h
kube-system          Active   4d11h
local-path-storage   Active   4d11h

controlplane:~$ k create rolebinding abc -n applications --clusterrole=view --user=smoke
error: failed to create rolebinding: rolebindings.rbac.authorization.k8s.io "abc" already exists
controlplane:~$ k create rolebinding abcd -n applications --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n default --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n kube-node-lease --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n kube-public --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created
controlplane:~$ k create rolebinding abcd -n local-path-storage --clusterrole=view --user=smoke
rolebinding.rbac.authorization.k8s.io/abcd created

controlplane:~$ k auth can-i create deployments --as smoke -n applications
yes
controlplane:~$ k auth can-i get secrets --as smoke -n applications
no

# applications
k auth can-i create deployments --as smoke -n applications # YES
k auth can-i delete deployments --as smoke -n applications # YES
k auth can-i delete pods --as smoke -n applications # YES
k auth can-i delete sts --as smoke -n applications # YES
k auth can-i delete secrets --as smoke -n applications # NO
k auth can-i list deployments --as smoke -n applications # YES
k auth can-i list secrets --as smoke -n applications # NO
k auth can-i get secrets --as smoke -n applications # NO

# view in all namespaces but not kube-system
k auth can-i list pods --as smoke -n default # YES
k auth can-i list pods --as smoke -n applications # YES
k auth can-i list pods --as smoke -n kube-public # YES
k auth can-i list pods --as smoke -n kube-node-lease # YES
k auth can-i list pods --as smoke -n kube-system # NO
```

---

## Q4

```bash
controlplane ~ ➜  cat pod-only.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-pods-only
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pods-only
  template:
    metadata:
      labels:
        app: pods-only
    spec:
      serviceAccountName: sa-pod-only
      containers:
      - name: web
        image: bitnami/kubectl:latest
        command: ["/bin/sh","-c"]
        args:
        - |
          set -x
          while true; do
            kubectl get deploy
            kubectl get pods
            kubectl logs $(hostname)
            sleep 10
          done


controlplane ~ ➜  k get deploy -n demo 
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
app-pods-only   1/1     1            1           33m

controlplane ~ ➜  k get role -o yaml -n demo abc 
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: "2025-10-16T17:04:12Z"
  name: abc
  namespace: demo
  resourceVersion: "7367"
  uid: 0eec81d1-0184-45ec-84b7-67513217805d
rules:
- apiGroups:
  - ""
  resources:
  - pods                              # add - pods/log here too
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - get
  - list
  - watch

controlplane ~ ➜  k get RoleBinding -o yaml -n demo abc 
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: "2025-10-16T17:05:28Z"
  name: abc
  namespace: demo
  resourceVersion: "7482"
  uid: 7b27b2cc-e538-43f8-99c6-79c08ff53eb3
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: abc
subjects:
- kind: ServiceAccount
  name: sa-pod-only
  namespace: demo

controlplane ~ ➜  k logs -n demo deployments/app-pods-only    # - pods/log  not added yet
+ kubectl get deploy
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
app-pods-only   1/1     1            1           36m
+ kubectl get pods
NAME                            READY   STATUS    RESTARTS   AGE
app-pods-only-79954749c-59b9d   1/1     Running   0          36m
++ hostname
+ kubectl logs app-pods-only-79954749c-59b9d
Error from server (Forbidden): pods "app-pods-only-79954749c-59b9d" is forbidden: User "system:serviceaccount:demo:sa-pod-only" cannot get resource "pods/log" in API group "" in the namespace "demo"
+ sleep 10

# - pods/log added into role now
controlplane ~ ➜  kubectl auth can-i get pods/log -n demo --as=system:serviceaccount:demo:sa-pod-only
yes
