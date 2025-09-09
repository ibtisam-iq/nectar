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
