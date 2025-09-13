Create a ConfigMap named ckad04-config-multi-env-files-aecs in the default namespace from the environment(env) files provided at /root/ckad04-multi-cm directory.

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

We have deployed a 2-tier web application on the cluster3 nodes in the canara-wl05 namespace. However, at the moment, the web app pod cannot establish a connection with the MySQL pod successfully.

You can check the status of the application from the terminal by running the curl command with the following syntax:

curl http://cluster3-controlplane:NODE-PORT

To make the application work, create a new secret called db-secret-wl05 with the following key values: -

1. DB_Host=mysql-svc-wl05
2. DB_User=root
3. DB_Password=password123

Next, configure the web application pod to load the new environment variables from the newly created secret.
Note: Check the web application again using the curl command, and the status of the application should be success.

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
