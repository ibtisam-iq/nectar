## Q1

Create a **ConfigMap** named `ckad04-config-multi-env-files-aecs` in the `default` namespace from the **environment(env) files** provided at `/root/ckad04-multi-cm directory`.

```bash
root@student-node ~ ➜  kubectl create configmap ckad04-config-multi-env-files-aecs \
         --from-env-file=/root/ckad04-multi-cm/file1.properties \
         --from-env-file=/root/ckad04-multi-cm/file2.properties
configmap/ckad04-config-multi-env-files-aecs created

root@student-node ~ ➜  ls /root/ckad04-multi-cm/
file1.properties  file2.properties

root@student-node ~ ➜  k get cm ckad04-config-multi-env-files-aecs 
NAME                                 DATA   AGE
ckad04-config-multi-env-files-aecs   6      39s

root@student-node ~ ➜  k describe cm ckad04-config-multi-env-files-aecs 
Name:         ckad04-config-multi-env-files-aecs
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
difficulty:
----
fairlyEasy

exam:
----
ckad

modetype:
----
openbook

practice:
----
must

retries:
----
2

allowed:
----
true


BinaryData
====

Events:  <none>

root@student-node ~ ➜  
```

---
## Q2

We have deployed a **2-tier web application** on the cluster3 nodes in the `canara-wl05` namespace. However, at the moment, the `web app pod` cannot establish a connection with the MySQL pod successfully.

You can check the status of the application from the terminal by running the curl command with the following syntax:

`curl http://cluster3-controlplane:NODE-PORT`

To make the application work, create a new secre called `db-secret-wl05` with the following key values: -

1. **DB_Host**=mysql-svc-wl05
2. **DB_User**=root
3. **DB_Password**=password123

Next, configure the *web application pod* to load the new environment variables from the newly created secret.
> **Note:** Check the web application again using the curl command, and the status of the application should be success.

```bash
cluster3-controlplane ~ ➜  k get po,svc -n canara-wl05
NAME                  READY   STATUS    RESTARTS   AGE
pod/mysql-wl05        1/1     Running   0          2m5s                                    # one env is configured
pod/webapp-pod-wl05   1/1     Running   0          2m5s                                    # no env is configured.

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/mysql-svc-wl05    ClusterIP   10.43.192.250   <none>        3306/TCP         2m5s
service/webapp-svc-wl05   NodePort    10.43.191.176   <none>        8080:31020/TCP   2m5s

cluster3-controlplane ~ ➜  k get po mysql-wl05 -o yaml -n canara-wl05 

  spec:
    containers:
    - env:
      - name: MYSQL_ROOT_PASSWORD                           # only one env is mentioned
        value: password123

cluster3-controlplane ~ ➜  curl http://cluster3-controlplane:31020
    <img src="/static/img/failed.png">
    <h3> Failed connecting to the MySQL database. </h3>
    
    <h2> Environment Variables: DB_Host=Not Set; DB_Database=Not Set; DB_User=Not Set; DB_Password=Not Set; 2003: Can&#39;t connect to MySQL server on &#39;localhost:3306&#39; (111 Connection refused) </h2>

cluster3-controlplane ~ ✖ vi sec.env

cluster3-controlplane ~ ➜  k create secret generic db-secret-wl05 -n canara-wl05 --from-env-file sec.env
secret/db-secret-wl05 created

cluster3-controlplane ~ ➜  k get secret -n canara-wl05 
NAME             TYPE     DATA   AGE
db-secret-wl05   Opaque   3      26s

cluster3-controlplane ~ ➜  k edit po -n canara-wl05 webapp-pod-wl05               # webpod, not database pod.             
error: pods "webapp-pod-wl05" is invalid
A copy of your changes has been stored to "/tmp/kubectl-edit-168556013.yaml"
error: Edit cancelled, no valid changes were saved.

envFrom:                                                      # added
    - secretRef:
        name: test-secret

cluster3-controlplane ~ ✖ k replace -f /tmp/kubectl-edit-168556013.yaml --force
pod "webapp-pod-wl05" deleted
pod/webapp-pod-wl05 replaced

cluster3-controlplane ~ ➜  curl http://cluster3-controlplane:31020
      <img src="/static/img/success.jpg">
    <h3> Successfully connected to the MySQL database.</h3>
  
    <h2> Environment Variables: DB_Host=mysql-svc-wl05; DB_Database=Not Set; DB_User=root; DB_Password=password123;  </h2>
```

---

## Q3

Create a ConfigMap called **db-user-pass-cka17-arch** in the default namespace using the contents of the file `/opt/db-user-pass` on the cluster1-controlplane.

```bash
cluster1-controlplane ~ ➜  ls /opt/db-user-pass 
/opt/db-user-pass

cluster1-controlplane ~ ➜  cat /opt/db-user-pass 
DB_USER
admin

cluster1-controlplane ~ ➜  k create cm db-user-pass-cka17-arch --from-literal DB_USER=admin   # wrong
configmap/db-user-pass-cka17-arch created

cluster1-controlplane ~ ✖ kubectl create cm db-user-pass-cka17-arch --from-file=/opt/db-user-pass
error: failed to create configmap: configmaps "db-user-pass-cka17-arch" already exists

cluster1-controlplane ~ ✖ k get cm 
NAME                      DATA   AGE
db-user-pass-cka17-arch   1      6m37s
kube-root-ca.crt          1      140m

cluster1-controlplane ~ ➜  k delete cm db-user-pass-cka17-arch 
configmap "db-user-pass-cka17-arch" deleted

cluster1-controlplane ~ ➜  kubectl create cm db-user-pass-cka17-arch --from-file=/opt/db-user-pass
configmap/db-user-pass-cka17-arch created

cluster1-controlplane ~ ➜  k get cm 
NAME                      DATA   AGE
db-user-pass-cka17-arch   1      4s
kube-root-ca.crt          1      140m

cluster1-controlplane ~ ➜  k describe cm db-user-pass-cka17-arch 
Name:         db-user-pass-cka17-arch
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
db-user-pass:
----
DB_USER
admin



BinaryData
====

Events:  <none>

cluster1-controlplane ~ ➜  k get cm db-user-pass-cka17-arch -o yaml
apiVersion: v1
data:
  db-user-pass: |
    DB_USER
    admin
kind: ConfigMap
metadata:
  creationTimestamp: "2025-09-14T15:25:39Z"
  name: db-user-pass-cka17-arch
  namespace: default
  resourceVersion: "14038"
  uid: a30dd633-65fd-4c2f-84e5-422a34f1c1c2

cluster1-controlplane ~ ➜  
```

---

## Q4

Create a secret named `mysql-root-pass` wih key/value pairs as below:

```bash
name: password
value: R00t
```
```bash
thor@jumphost ~$ cat > abc.env
name: password
value: R00t
thor@jumphost ~$ k create secret generic mysql-root-pass --from-env-file abc.env 
error: "name: password" is not a valid key name: a valid environment variable name must consist of alphabetic characters, digits, '_', '-', or '.', and must not start with a digit (e.g. 'my.env-name',  or 'MY_ENV.NAME',  or 'MyEnvName1', regex used for validation is '[-._a-zA-Z][-._a-zA-Z0-9]*')
thor@jumphost ~$
```

Ahh 👍 I see what happened.

The problem is that you wrote the `abc.env` file in **YAML style** (`name:` / `value:`), but `--from-env-file` expects a **simple `KEY=VALUE` format**.

For example, your file should look like this:

```bash
cat > abc.env <<EOF
password=R00t
EOF
```

Then create the secret:

```bash
kubectl create secret generic mysql-root-pass --from-env-file=abc.env
```

✅ This will create a secret named `mysql-root-pass` with:

* Key = `password`
* Value = `R00t`

---

## Q5

Create a Kubernetes Secret named `database-app-secret` in the default namespace using the contents of the file `database-data.txt`.

```bash
controlplane:~$ cat database-data.txt 
DB_User=REJfVXNlcj1teXVzZXI=
DB_Password=REJfUGFzc3dvcmQ9bXlwYXNzd29yZA==  

controlplane:~$ k create secret generic database-app-secret --from-env-file database-data.txt                            # wrong
secret/database-app-secret created

controlplane:~$ k delete secret database-app-secret 
secret "database-app-secret" deleted

controlplane:~$ k create secret generic database-app-secret --from-file database-data.txt                                # correct
secret/database-app-secret created
```
