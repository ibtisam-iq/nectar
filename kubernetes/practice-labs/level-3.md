The Nautilus DevOps team want to deploy a PHP website on Kubernetes cluster. They are going to use `Apache` as a web server and `Mysql` for database. The team had already gathered the requirements and now they want to make this website live. Below you can find more details:

1) Create a config map `php-config` for `php.ini` with `variables_order = "EGPCS"` data.

2) Create a deployment named `lamp-wp`.

3) Create two containers under it. First container must be `httpd-php-container` using image `webdevops/php-apache:alpine-3-php7` and second container must be `mysql-container` from image `mysql:5.6`. Mount `php-config` configmap in httpd container at `/opt/docker/etc/php/php.ini` location.

4) Create kubernetes generic secrets for mysql related values like `myql root password, mysql user, mysql password, mysql host and mysql database`. Set any values of your choice.

5) Add some environment variables for both containers:

a) `MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD and MYSQL_HOST`. Take their values from the secrets you created. Please make sure to use env field (do not use envFrom) to define the name-value pair of environment variables.

6) Create a node port type service `lamp-service` to expose the web application, nodePort must be `30008`.

7) Create a service for mysql named `mysql-service` and its port must be `3306`.

8) We already have `/tmp/index.php` file on jump_host server.

a) Copy this file into httpd container under Apache document root i.e `/app` and **replace the dummy values for mysql related variables with the environment variables** you have set for mysql related parameters. Please make sure you do not hard code the mysql related details in this file, you must use the environment variables to fetch those values.

b) You must be able to access this `index.php` on node port `30008` at the end, please note that you should see **Connected successfully** message while accessing this page.

```bash
thor@jumphost ~$ k create cm php-config --from-literal php.ini=variables_order="EGPCS"
configmap/php-config created

kubectl delete secret mysql
kubectl create secret generic mysql \
  --from-literal=MYSQL_ROOT_PASSWORD=abc \
  --from-literal=MYSQL_DATABASE=abc \
  --from-literal=MYSQL_USER=abc \
  --from-literal=MYSQL_PASSWORD=abc \
  --from-literal=MYSQL_HOST="127.0.0.1"

kubectl create configmap index-php \
  --from-literal=index.php='<?php
$dbname = getenv("MYSQL_DATABASE");
$dbuser = getenv("MYSQL_USER");
$dbpass = getenv("MYSQL_PASSWORD");
$dbhost = getenv("MYSQL_HOST");

$connect = mysqli_connect($dbhost, $dbuser, $dbpass, $dbname);

if (!$connect) {
    die("Connection failed: " . mysqli_connect_error());
}
echo "Connected successfully";
?>'

thor@jumphost ~$ cat deploy.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lamp-wp
  labels:
    app: lamp-wp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lamp-wp
  template:
    metadata:
      labels:
        app: lamp-wp
    spec:
      containers:
      - name: httpd-php-container
        image: webdevops/php-apache:alpine-3-php7
        volumeMounts:
        - name: php-config
          mountPath: /opt/docker/etc/php/php.ini
          subPath: php.ini
        - name: index-php
          mountPath: /app/index.php
          subPath: index.php
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_ROOT_PASSWORD
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_DATABASE
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_PASSWORD
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_HOST

      - name: mysql-container
        image: mysql:5.6
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_ROOT_PASSWORD
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_DATABASE
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_PASSWORD
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql
              key: MYSQL_HOST

      volumes:
      - name: php-config
        configMap:
          name: php-config
      - name: index-php
        configMap:
          name: index-php


thor@jumphost ~$ k apply -f deploy.yaml 
deployment.apps/lamp-wp created
thor@jumphost ~$ k get deploy
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
lamp-wp   1/1     1            1           7m13s
thor@jumphost ~$ k get po
NAME                       READY   STATUS    RESTARTS   AGE
lamp-wp-6d58b97958-n89v9   2/2     Running   0          71s

thor@jumphost ~$ k expose deploy lamp-wp --name lamp-service --port 80 --type NodePort
service/lamp-service exposed
thor@jumphost ~$ k edit svc lamp-service 
service/lamp-service edited
thor@jumphost ~$ k create svc clusterip mysql-service --tcp=3306:3306
service/mysql-service created
thor@jumphost ~$ kubectl get svc lamp-service
NAME           TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
lamp-service   NodePort   10.96.80.30   <none>        80:30008/TCP   5m5s
thor@jumphost ~$ k get svc mysql-service 
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
mysql-service   ClusterIP   10.96.2.246   <none>        3306/TCP   3m38s
thor@jumphost ~$ k describe svc mysql-service 
Name:              mysql-service
Namespace:         default
Labels:            app=mysql-service
Annotations:       <none>
Selector:          app=mysql-service
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.2.246
IPs:               10.96.2.246
Port:              3306-3306  3306/TCP
TargetPort:        3306/TCP
Endpoints:         <none>
Session Affinity:  None
Events:            <none>

thor@jumphost ~$ curl http://172.18.0.5:30008/index.php
Connected successfullythor@jumphost ~$

---

thor@jumphost ~$ kubectl delete svc mysql-service
kubectl expose deploy lemp-wp --name=mysql-service --port=3306 --target-port=3306
service "mysql-service" deleted
service/mysql-service exposed

thor@jumphost ~$ k get svc
NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes      ClusterIP   10.96.0.1      <none>        443/TCP        73m
lemp-service    NodePort    10.96.206.12   <none>        80:30008/TCP   24m
mysql-service   ClusterIP   10.96.215.98   <none>        3306/TCP       3m26s
thor@jumphost ~$ k describe svc mysql-service 
Name:              mysql-service
Namespace:         default
Labels:            app=lemp-wp
Annotations:       <none>
Selector:          app=lemp-wp
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.215.98
IPs:               10.96.215.98
Port:              <unset>  3306/TCP
TargetPort:        3306/TCP
Endpoints:         10.244.0.7:3306
Session Affinity:  None
Events:            <none>
thor@jumphost ~$ k describe svc lemp-service 
Name:                     lemp-service
Namespace:                default
Labels:                   app=lemp-wp
Annotations:              <none>
Selector:                 app=lemp-wp
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.206.12
IPs:                      10.96.206.12
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  30008/TCP
Endpoints:                10.244.0.7:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
thor@jumphost ~$  
```
---

## Q4
Got it 👍 You need a Pod with an `httpd:latest` container, mounting a PVC (`pvc-datacenter`) at Apache’s **document root** (`/usr/local/apache2/htdocs`).

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-datacenter
spec:
  containers:
    - name: container-datacenter
      image: httpd:latest
      volumeMounts:
        - name: web-content
          mountPath: /usr/local/apache2/htdocs
  volumes:
    - name: web-content
      persistentVolumeClaim:
        claimName: pvc-datacenter
```


