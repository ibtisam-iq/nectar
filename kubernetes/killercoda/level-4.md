## Q1 Deploy Redis Deployment on Kubernetes

Create a redis deployment with following parameters:

Create a config map called my-redis-config having maxmemory 2mb in redis-config.

Name of the deployment should be redis-deployment, it should use
redis:alpine image and container name should be redis-container. Also make sure it has only 1 replica.

The container should request for 1 CPU.

Mount 2 volumes:

a. An Empty directory volume called data at path /redis-master-data.

b. A configmap volume called redis-config at path /redis-master.

c. The container should expose the port 6379.

Finally, redis-deployment should be in an up and running state.

```bash
thor@jumphost ~$ k get ns
NAME                 STATUS   AGE
default              Active   9m39s
kube-node-lease      Active   9m39s
kube-public          Active   9m39s
kube-system          Active   9m39s
local-path-storage   Active   9m30s
thor@jumphost ~$ cat > redis-config
maxmemory=2mb        
thor@jumphost ~$ k create cm my-redis-config --from-env-file redis-config
configmap/my-redis-config created
thor@jumphost ~$ k get cm
NAME               DATA   AGE
kube-root-ca.crt   1      12m
my-redis-config    1      6s
thor@jumphost ~$ k describe cm my-redis-config 
Name:         my-redis-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
maxmemory:
----
2mb

BinaryData
====

Events:  <none>
thor@jumphost ~$ k delete cm my-redis-config 
configmap "my-redis-config" deleted
thor@jumphost ~$ echo "maxmemory 2mb" > redis-config
kubectl create configmap my-redis-config --from-file=redis-config
configmap/my-redis-config created
thor@jumphost ~$ k describe cm my-redis-config 
Name:         my-redis-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
redis-config:
----
maxmemory 2mb


BinaryData
====

Events:  <none>
thor@jumphost ~$ k create deployment redis-deployment --image redis:alpine -r 1 --port 6379
deployment.apps/redis-deployment created
thor@jumphost ~$ k edit deployments.apps redis-deployment 
deployment.apps/redis-deployment edited
thor@jumphost ~$ k get po
NAME                                READY   STATUS    RESTARTS   AGE
redis-deployment-7bccd99d85-mwp5t   1/1     Running   0          10s
thor@jumphost ~$ k get deploy redis-deployment -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: redis-deployment
  name: redis-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-deployment
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: redis-deployment
    spec:
      containers:
      - image: redis:alpine
        name: redis-container
        ports:
        - containerPort: 6379
          protocol: TCP
        resources:
          requests:
            cpu: "1"
        volumeMounts:
        - mountPath: /redis-master-data
          name: data
        - mountPath: /redis-master
          name: redis-config
      restartPolicy: Always
      volumes:
      - emptyDir: {}
        name: data
      - configMap:
          defaultMode: 420
          name: my-redis-config
        name: redis-config
thor@jumphost ~$ 
```

Good question, meri jaan ❤️ — let’s clear it up.

In the requirement:

> "Create a config map called **my-redis-config** having `maxmemory 2mb` in **redis-config**."

Here’s what each part means:

* **my-redis-config** → this is the **name of the ConfigMap** (what Kubernetes will call it).
* **redis-config** → this is the **key inside the ConfigMap**, which acts like a file name.
* **maxmemory 2mb** → this is the **value** stored in that key, which is the Redis configuration line.

So the ConfigMap is like a folder 📂, and inside it you’re creating a file called `redis-config` with the content:

```
maxmemory 2mb
```

### Example breakdown

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-redis-config   # <-- ConfigMap name
data:
  redis-config: |         # <-- key (like a filename)
    maxmemory 2mb         # <-- content
```

If you later mount this ConfigMap into a Pod at `/redis-master/`, Kubernetes will create a file `/redis-master/redis-config` with this content.

Redis will then read that file as its config.

---

Exactly meri jaan ❤️ — you spotted it!

What happened is:

* You used `--from-env-file redis-config`.
* That treats the file as **key=value** pairs (like environment variables).
* Since your file had `maxmemory=2mb`, Kubernetes made a **key** called `maxmemory` with the **value** `2mb`.

But the requirement is different:

* ConfigMap should be named `my-redis-config`. ✅ (you did that)
* It should have a **single key named `redis-config`**, and the **contents** of that key should be `maxmemory 2mb`.

### Correct way

Use `--from-file` instead of `--from-env-file`:

```bash
echo "maxmemory 2mb" > redis-config
kubectl create configmap my-redis-config --from-file=redis-config
```
---

Yes sweetheart 💯 — both approaches are functionally **the same thing**:

* **Imperative way (`kubectl create configmap … --from-file`)**

  * You give Kubernetes a file.
  * It creates a ConfigMap where the **key = filename** (`redis-config`) and the **value = file content** (`maxmemory 2mb`).

* **Declarative way (YAML manifest)**

  * You explicitly define a ConfigMap object with the same key (`redis-config`) and value (`maxmemory 2mb`).

If you run:

```bash
kubectl get cm my-redis-config -o yaml
```

after using the imperative command, you’ll see almost exactly the same YAML that you wrote. ✅

So → yes, **both produce the same ConfigMap**.
The only difference is **workflow**:

* Imperative = quick one-liner.
* Declarative = more control, reusable YAML (preferred in GitOps / production).

---

## Q2 Deploy MySQL on Kubernetes

1.) Create a PersistentVolume mysql-pv, its capacity should be 250Mi, set other parameters as per your preference.


2.) Create a PersistentVolumeClaim to request this PersistentVolume storage. Name it as mysql-pv-claim and request a 250Mi of storage. Set other parameters as per your preference.


3.) Create a deployment named mysql-deployment, use any mysql image as per your preference. Mount the PersistentVolume at mount path /var/lib/mysql.


4.) Create a NodePort type service named mysql and set nodePort to 30007.


5.) Create a secret named mysql-root-pass having a key pair value, where key is password and its value is YUIidhb667, create another secret named mysql-user-pass having some key pair values, where frist key is username and its value is kodekloud_top, second key is password and value is dCV3szSGNA, create one more secret named mysql-db-url, key name is database and value is kodekloud_db9


6.) Define some Environment variables within the container:


a) name: MYSQL_ROOT_PASSWORD, should pick value from secretKeyRef name: mysql-root-pass and key: password


b) name: MYSQL_DATABASE, should pick value from secretKeyRef name: mysql-db-url and key: database


c) name: MYSQL_USER, should pick value from secretKeyRef name: mysql-user-pass key key: username


d) name: MYSQL_PASSWORD, should pick value from secretKeyRef name: mysql-user-pass and key: password

```bash
thor@jumphost ~$ vi abc.yaml
thor@jumphost ~$ k apply -f abc.yaml 
persistentvolume/mysql-pv created
persistentvolumeclaim/mysql-pv-claim created
secret/mysql-root-pass created
secret/mysql-user-pass created
secret/mysql-db-url created
deployment.apps/mysql-deployment created
service/mysql created
thor@jumphost ~$ k get po
NAME                               READY   STATUS              RESTARTS   AGE
mysql-deployment-68c9b5947-xprzj   0/1     ContainerCreating   0          20s
thor@jumphost ~$ k get po -w
NAME                               READY   STATUS              RESTARTS   AGE
mysql-deployment-68c9b5947-xprzj   0/1     ContainerCreating   0          28s
mysql-deployment-68c9b5947-xprzj   1/1     Running             0          34s
^Cthor@jumphost ~$ k get po
NAME                               READY   STATUS    RESTARTS   AGE
mysql-deployment-68c9b5947-xprzj   1/1     Running   0          49s
thor@jumphost ~$ cat abc.yaml 
---
# 1.) PersistentVolume: mysql-pv
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 250Mi          # Storage capacity
  accessModes:
    - ReadWriteOnce         # Only one node can mount at a time
  hostPath:                 # Using hostPath for simplicity (good for learning/demo)
    path: "/mnt/data/mysql" # Path on the worker node where data is stored
---
# 2.) PersistentVolumeClaim: mysql-pv-claim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi        # Must match PV size
---
# 5.) Secrets
apiVersion: v1
kind: Secret
metadata:
  name: mysql-root-pass
type: Opaque
stringData:
  password: YUIidhb667
---
apiVersion: v1
kind: Secret
metadata:
  name: mysql-user-pass
type: Opaque
stringData:
  username: kodekloud_top
  password: dCV3szSGNA
---
apiVersion: v1
kind: Secret
metadata:
  name: mysql-db-url
type: Opaque
stringData:
  database: kodekloud_db9
---
# 3.) Deployment: mysql-deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:8.0   # You can change to another version if needed
          ports:
            - containerPort: 3306
          env:
            # 6a) Root password
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-root-pass
                  key: password

            # 6b) Database
            - name: MYSQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: mysql-db-url
                  key: database

            # 6c) Username
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: mysql-user-pass
                  key: username

            # 6d) User password
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-user-pass
                  key: password

          volumeMounts:
            - name: mysql-storage
              mountPath: /var/lib/mysql   # MySQL data directory
      volumes:
        - name: mysql-storage
          persistentVolumeClaim:
            claimName: mysql-pv-claim
---
# 4.) Service: mysql (NodePort)
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  type: NodePort
  selector:
    app: mysql
  ports:
    - port: 3306       # Service port inside cluster
      targetPort: 3306 # Container port
      nodePort: 30007  # Exposed port on node

thor@jumphost ~$ 
```

---

## Q3 Kubernetes Nginx and PhpFPM Setup

1) Create a service to expose this app, the service type must be NodePort, nodePort should be 30012.


2.) Create a config map named nginx-config for nginx.conf as we want to add some custom settings in nginx.conf.


a) Change the default port 80 to 8093 in nginx.conf.


b) Change the default document root /usr/share/nginx to /var/www/html in nginx.conf.


c) Update the directory index to index  index.html index.htm index.php in nginx.conf.


3.) Create a pod named nginx-phpfpm .


b) Create a shared volume named shared-files that will be used by both containers (nginx and phpfpm) also it should be a emptyDir volume.


c) Map the ConfigMap we declared above as a volume for nginx container. Name the volume as nginx-config-volume, mount path should be /etc/nginx/nginx.conf and subPath should be nginx.conf


d) Nginx container should be named as nginx-container and it should use nginx:latest image. PhpFPM container should be named as php-fpm-container and it should use php:8.1-fpm-alpine image.


e) The shared volume shared-files should be mounted at /var/www/html location in both containers. Copy /opt/index.php from jump host to the nginx document root inside the nginx container, once done you can access the app using App button on the top bar.

```bash
thor@jumphost ~$ k get deploy
No resources found in default namespace.
thor@jumphost ~$ cat /opt/index.php 
It works!thor@jumphost ~$ 
thor@jumphost ~$ vi ibtisam.yaml
thor@jumphost ~$ k apply -f ibtisam.yaml 
configmap/nginx-config created
pod/nginx-phpfpm created
service/nginx-phpfpm-service created
thor@jumphost ~$ k get po -w
NAME           READY   STATUS    RESTARTS   AGE
nginx-phpfpm   2/2     Running   0          19s
^Cthor@jumphost ~kubectl cp /opt/index.php nginx-phpfpm:/var/www/html/index.php -c nginx-container
thor@jumphost ~$ cat ibtisam.yaml 
---
# 2.) ConfigMap for custom nginx.conf
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 8093;                           # (a) Changed from 80 → 8093
        root /var/www/html;                    # (b) Changed document root
        index index.html index.htm index.php;  # (c) Updated index

        location / {
          try_files $uri $uri/ =404;
        }

        location ~ \.php$ {
          fastcgi_pass 127.0.0.1:9000; # PHP-FPM runs inside same pod
          fastcgi_index index.php;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          include fastcgi_params;
        }
      }
    }
---
# 3.) Pod with two containers (nginx + php-fpm)
apiVersion: v1
kind: Pod
metadata:
  name: nginx-phpfpm
  labels:
    app: nginx-phpfpm
spec:
  volumes:
    # b) Shared volume for both containers
    - name: shared-files
      emptyDir: {}

    # c) ConfigMap volume for nginx.conf
    - name: nginx-config-volume
      configMap:
        name: nginx-config
        items:
          - key: nginx.conf
            path: nginx.conf

  containers:
    # d) Nginx container
    - name: nginx-container
      image: nginx:latest
      ports:
        - containerPort: 8093
      volumeMounts:
        - name: shared-files
          mountPath: /var/www/html
        - name: nginx-config-volume
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf

    # d) PHP-FPM container
    - name: php-fpm-container
      image: php:8.1-fpm-alpine
      volumeMounts:
        - name: shared-files
          mountPath: /var/www/html
---
# 1.) Service to expose the app
apiVersion: v1
kind: Service
metadata:
  name: nginx-phpfpm-service
spec:
  type: NodePort
  selector:
    app: nginx-phpfpm
  ports:
    - port: 8093        # Service port inside cluster
      targetPort: 8093  # Container port (nginx)
      nodePort: 30012   # NodePort on the worker node

thor@jumphost ~$ 
```

---

## Q4 Deploy Drupal App on Kubernetes

1) Configure a persistent volume drupal-mysql-pv with hostPath = /drupal-mysql-data (/drupal-mysql-data directory already exists on the worker Node i.e jump host), 5Gi of storage and ReadWriteOnce access mode.


2) Configure one PersistentVolumeClaim named drupal-mysql-pvc with storage request of 3Gi and ReadWriteOnce access mode.


3) Create a deployment drupal-mysql with 1 replica, use mysql:5.7 image. Mount the claimed PVC at /var/lib/mysql.


4) Create a deployment drupal with 1 replica and use drupal:8.6 image.


4) Create a NodePort type service which should be named as drupal-service and nodePort should be 30095.


5) Create a service drupal-mysql-service to expose mysql deployment on port 3306.

```bash
thor@jumphost ~$ ls -ld /drupal-mysql-data/
drwxr-xr-x 2 thor thor 4096 Sep  9 16:15 /drupal-mysql-data/
thor@jumphost ~$ vi ibtisam.yaml
thor@jumphost ~$ k apply -f ibtisam.yaml 
persistentvolume/drupal-mysql-pv created
persistentvolumeclaim/drupal-mysql-pvc created
deployment.apps/drupal-mysql created
deployment.apps/drupal created
service/drupal-service created
service/drupal-mysql-service created
thor@jumphost ~$ k get po
NAME                            READY   STATUS    RESTARTS   AGE
drupal-f5499f965-dnk27          1/1     Running   0          42s
drupal-mysql-78dfcb7c5d-lkqf9   1/1     Running   0          42s
thor@jumphost ~$ cat ibtisam.yaml 
---
# 1) PersistentVolume for MySQL
apiVersion: v1
kind: PersistentVolume
metadata:
  name: drupal-mysql-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /drupal-mysql-data   # Path already exists on the node
---
# 2) PersistentVolumeClaim for MySQL
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: drupal-mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
---
# 3) MySQL Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: drupal-mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: drupal-mysql
  template:
    metadata:
      labels:
        app: drupal-mysql
    spec:
      containers:
        - name: drupal-mysql
          image: mysql:5.7
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: drupalpass       # You can replace with Secret for real setups
            - name: MYSQL_DATABASE
              value: drupaldb
            - name: MYSQL_USER
              value: drupaluser
            - name: MYSQL_PASSWORD
              value: drupalpass
          ports:
            - containerPort: 3306
          volumeMounts:
            - name: mysql-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-storage
          persistentVolumeClaim:
            claimName: drupal-mysql-pvc
---
# 4) Drupal Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: drupal
spec:
  replicas: 1
  selector:
    matchLabels:
      app: drupal
  template:
    metadata:
      labels:
        app: drupal
    spec:
      containers:
        - name: drupal
          image: drupal:8.6
          ports:
            - containerPort: 80
          env:
            - name: DRUPAL_DB_HOST
              value: drupal-mysql-service   # Must match MySQL service name
            - name: DRUPAL_DB_NAME
              value: drupaldb
            - name: DRUPAL_DB_USER
              value: drupaluser
            - name: DRUPAL_DB_PASSWORD
              value: drupalpass
---
# 5) Drupal NodePort Service
apiVersion: v1
kind: Service
metadata:
  name: drupal-service
spec:
  type: NodePort
  selector:
    app: drupal
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30095
---
# 5) MySQL ClusterIP Service
apiVersion: v1
kind: Service
metadata:
  name: drupal-mysql-service
spec:
  selector:
    app: drupal-mysql
  ports:
    - port: 3306
      targetPort: 3306

thor@jumphost ~$ 
```

Good catch 👍

Let’s clarify:

* In **MySQL deployment**, we **must** provide `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, and `MYSQL_PASSWORD` → these set up the DB.
* In **Drupal deployment**, we only need the **connection details** (`host`, `dbname`, `user`, `password`). Drupal doesn’t care about MySQL’s root password.

That’s why:

* I **included `MYSQL_ROOT_PASSWORD`** inside the MySQL deployment.
* I **did not include it in Drupal deployment**, because Drupal should connect with the application user (`drupaluser`), not the MySQL root user.
* For **host**, I set it in Drupal (`DRUPAL_DB_HOST=drupal-mysql-service`) because Drupal must know where to reach the DB.

👉 If you’d like to make this setup **more consistent and secure**, we can:

1. Store all DB creds in a **Secret** (root password, user, password, db name).
2. Reference them via `env.valueFrom.secretKeyRef` in both deployments.
3. Keep `host` as plain value (since it’s just a service name).

---

Exactly 💡 — you’ve noticed the difference between **multi-container Pods** (like your Nginx + PHP-FPM case) and **multi-Pod Deployments** (like Drupal + MySQL).

Here’s why:

### 🔹 Case 1: Same Pod (sidecar/multi-container)

* All containers **share the same network namespace**.
* That means:

  * `localhost` or `127.0.0.1` is enough to connect between containers.
  * No Service is required for internal communication.
* Example (your Nginx + PHP-FPM):

  ```nginx
  fastcgi_pass 127.0.0.1:9000;
  ```

  because both are inside **one Pod**, so the network is shared.

### 🔹 Case 2: Different Pods (separate Deployments)

* Each Pod has its **own IP address** (ephemeral).
* To ensure stable communication, we expose one Pod (MySQL) via a **Service**.
* The **Service DNS name** (e.g., `drupal-mysql-service`) is used by Drupal to connect to MySQL.
* Example (your Drupal deployment):

  ```yaml
  - name: DRUPAL_DB_HOST
    value: drupal-mysql-service
  ```

✅ So:

* **Same Pod → use `localhost`**
* **Different Pods → use Kubernetes Service name**

---

## Q5 Deploy Guest Book App on Kubernetes

**BACK-END TIER**

1. Create a deployment named redis-master for Redis master.

a.) Replicas count should be 1.

b.) Container name should be master-redis-nautilus and it should use image redis.

c.) Request resources as CPU should be 100m and Memory should be 100Mi.

d.) Container port should be redis default port i.e 6379.

2. Create a service named redis-master for Redis master. Port and targetPort should be Redis default port i.e 6379.

3. Create another deployment named redis-slave for Redis slave.

a.) Replicas count should be 2.

b.) Container name should be slave-redis-nautilus and it should use gcr.io/google_samples/gb-redisslave:v3 image.

c.) Requests resources as CPU should be 100m and Memory should be 100Mi.

d.) Define an environment variable named GET_HOSTS_FROM and its value should be dns.

e.) Container port should be Redis default port i.e 6379.

4. Create another service named redis-slave. It should use Redis default port i.e 6379.

**FRONT END TIER**

1. Create a deployment named frontend.

a.) Replicas count should be 3.

b.) Container name should be php-redis-nautilus and it should use gcr.io/google-samples/gb-frontend@sha256:a908df8486ff66f2c4daa0d3d8a2fa09846a1fc8efd65649c0109695c7c5cbff image.

c.) Request resources as CPU should be 100m and Memory should be 100Mi.

d.) Define an environment variable named as GET_HOSTS_FROM and its value should be dns.

e.) Container port should be 80.

2. Create a service named frontend. Its type should be NodePort, port should be 80 and its nodePort should be 30009.

```bash
thor@jumphost ~$ k apply -f ibtisam.yaml 
deployment.apps/redis-master created
service/redis-master created
deployment.apps/redis-slave created
service/redis-slave created
deployment.apps/frontend created
service/frontend created
thor@jumphost ~$ k get po
NAME                            READY   STATUS    RESTARTS   AGE
frontend-7c9d48bc4-hg6b9        1/1     Running   0          2m47s
frontend-7c9d48bc4-lqc94        1/1     Running   0          2m47s
frontend-7c9d48bc4-q2jqh        1/1     Running   0          2m47s
redis-master-58d4c6498b-fbf9m   1/1     Running   0          2m47s
redis-slave-7fd75644dc-bf7bj    1/1     Running   0          2m47s
redis-slave-7fd75644dc-hsnhc    1/1     Running   0          2m47s

thor@jumphost ~$ k get no -o wide
NAME                      STATUS   ROLES           AGE   VERSION                     INTERNAL-IP   EXTERNAL-IP   OS-IMAGE       KERNEL-VERSION   CONTAINER-RUNTIME
kodekloud-control-plane   Ready    control-plane   35m   v1.27.16-1+f5da3b717fc217   172.17.0.2    <none>        Ubuntu 23.10   5.4.0-1106-gcp   containerd://1.7.1-2-g8f682ed69

thor@jumphost ~$ curl http://172.17.0.2:30009
curl: (28) Failed to connect to 172.17.0.2 port 30009: Connection timed out

thor@jumphost ~$ kubectl run tmp --rm -it --image=busybox:1.28 -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ # wget -qO- http://frontend:80
<html ng-app="redis">
  <head>
    <title>Guestbook</title>
  </body>
</html>
/ # exit
Session ended, resume using 'kubectl attach tmp -c tmp -i -t' command when the pod is running
pod "tmp" deleted
thor@jumphost ~$ kubectl port-forward svc/frontend 8080:80
Forwarding from [::1]:8080 -> 80
```

Perfect ✅ This looks like a **3-tier guestbook application** (Redis master → Redis slaves → Frontend).
Here’s the **full YAML manifest** with comments explaining each section:

```yaml
---
# BACK-END TIER
# Redis Master Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
      role: master
  template:
    metadata:
      labels:
        app: redis
        role: master
    spec:
      containers:
        - name: master-redis-nautilus
          image: redis
          resources:
            requests:
              cpu: "100m"
              memory: "100Mi"
          ports:
            - containerPort: 6379
---
# Redis Master Service
apiVersion: v1
kind: Service
metadata:
  name: redis-master
spec:
  selector:
    app: redis
    role: master
  ports:
    - port: 6379
      targetPort: 6379
---
# Redis Slave Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-slave
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redis
      role: slave
  template:
    metadata:
      labels:
        app: redis
        role: slave
    spec:
      containers:
        - name: slave-redis-nautilus
          image: gcr.io/google_samples/gb-redisslave:v3
          resources:
            requests:
              cpu: "100m"
              memory: "100Mi"
          env:
            - name: GET_HOSTS_FROM
              value: "dns"
          ports:
            - containerPort: 6379
---
# Redis Slave Service
apiVersion: v1
kind: Service
metadata:
  name: redis-slave
spec:
  selector:
    app: redis
    role: slave
  ports:
    - port: 6379
      targetPort: 6379
---
# FRONT END TIER
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: php-redis-nautilus
          image: gcr.io/google-samples/gb-frontend@sha256:a908df8486ff66f2c4daa0d3d8a2fa09846a1fc8efd65649c0109695c7c5cbff
          resources:
            requests:
              cpu: "100m"
              memory: "100Mi"
          env:
            - name: GET_HOSTS_FROM
              value: "dns"
          ports:
            - containerPort: 80
---
# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30009
```

---

### ⚡ Workflow Recap

* **Redis Master** runs on `redis-master` service.
* **Redis Slaves** connect to master and expose via `redis-slave` service.
* **Frontend** (PHP app) queries Redis through service names (`redis-master`, `redis-slave`).
* Externally, the app is accessible at:

  ```
  http://<NodeIP>:30009
  ```

---

  Got it 👍 If your `curl http://172.17.0.2:30009` is **hanging (no response)**, that means the **NodePort service isn’t able to connect to your frontend pods**.

Let’s troubleshoot step by step 🔎:

### Test inside the cluster

Run a temporary pod to check if service is reachable internally:

```bash
kubectl run tmp --rm -it --image=busybox:1.28 -- /bin/sh
wget -qO- http://frontend:80
```

* If this works, then the frontend service is fine and the NodePort may be blocked.
* If it fails, the frontend pods aren’t serving properly.

⚡ Common causes of `curl` hanging:

* Frontend pods crashed (`CrashLoopBackOff`).
* NodePort (30009) is exposed but pods aren’t backing it (wrong selector).
* Redis master/slave not available → frontend blocks waiting.
* You’re testing from **jump host**, but the NodePort is bound to another node IP.

---

Nice work 🚀 You just proved something important:

* ✅ Inside the cluster (`busybox pod`) → `wget http://frontend:80` **works fine** and returns the Guestbook HTML.
* ❌ From outside (`curl http://172.17.0.2:30009`) → connection **times out**.

That means:
👉 Your **frontend pods and service are working**, but the **NodePort is not reachable from the jump host**.

### Why this happens

* You’re running on a **single-node cluster (control-plane only)**.
* Some CKA/CKAD playgrounds (like KodeKloud) run the control-plane inside Docker-in-Docker, so **NodePorts aren’t exposed to your jump host**.
* That’s why inside the cluster you see the app, but outside the cluster you get timeout.

### 🔧 How to Fix / Work Around

You have 3 options:

1. **Use `kubectl port-forward` (easiest in labs):**

   ```bash
   kubectl port-forward svc/frontend 8080:80
   ```

   Then open:

   ```
   http://127.0.0.1:8080
   ```

   from the jump host.

2. **Use `kubectl proxy`:**

   ```bash
   kubectl proxy --port=8001 &
   curl http://127.0.0.1:8001/api/v1/namespaces/default/services/frontend/proxy/
   ```

3. **Check cluster networking (advanced):**
   Sometimes the jump host can’t reach `NodePort` because traffic isn’t routed to the container’s network namespace. In that case, only in-cluster traffic works.

⚡ In short:

* Your YAML is correct ✅
* The app runs fine ✅
* NodePort doesn’t work from jump host because of **lab environment network restrictions** ❌
