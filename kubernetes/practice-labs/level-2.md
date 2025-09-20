FYI, deployment name is `lamp-wp` and its using a service named `lamp-service`. The Apache is using `http` default port and nodeport is `30008`. From the application logs it has been identified that application is facing some issues while connecting to the database in addition to other issues. Additionally, there are some environment variables associated with the pods like `MYSQL_ROOT_PASSWORD, MYSQL_DATABASE,  MYSQL_USER, MYSQL_PASSWORD, MYSQL_HOST`.

```bash
thor@jumphost ~$ ls
thor@jumphost ~$ k get po
NAME                       READY   STATUS    RESTARTS   AGE
lamp-wp-56c7c454fc-76dkp   2/2     Running   0          44s
thor@jumphost ~$ k describe po
Name:             lamp-wp-56c7c454fc-76dkp
Namespace:        default
Priority:         0
Service Account:  default
Node:             kodekloud-control-plane/172.17.0.2
Start Time:       Tue, 09 Sep 2025 14:07:35 +0000
Labels:           app=lamp
                  pod-template-hash=56c7c454fc
                  tier=frontend
Annotations:      <none>
Status:           Running
IP:               10.244.0.5
IPs:
  IP:           10.244.0.5
Controlled By:  ReplicaSet/lamp-wp-56c7c454fc
Containers:
  httpd-php-container:
    Container ID:   containerd://49cae750bd33223a348da69bd7a0c5a844cec1dc633a15fca577319fc99924d7
    Image:          webdevops/php-apache:alpine-3-php7
    Image ID:       docker.io/webdevops/php-apache@sha256:bb68c986d4947d4cb49e2753a268e33ad3d69df29c8e9a7728090f4738d5bdb9
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 09 Sep 2025 14:07:46 +0000
    Ready:          True
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  <set to the key 'password' in secret 'mysql-root-pass'>  Optional: false
      MYSQL_DATABASE:       <set to the key 'database' in secret 'mysql-db-url'>     Optional: false
      MYSQL_USER:           <set to the key 'username' in secret 'mysql-user-pass'>  Optional: false
      MYSQL_PASSWORD:       <set to the key 'password' in secret 'mysql-user-pass'>  Optional: false
      MYSQL_HOST:           <set to the key 'host' in secret 'mysql-host'>           Optional: false
    Mounts:
      /opt/docker/etc/php/php.ini from php-config-volume (rw,path="php.ini")
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-hhsr8 (ro)
  mysql-container:
    Container ID:   containerd://808cba4ac892ba36c99c80fe9a259c3235514c1abccd3e80774b5941c5e2b7c5
    Image:          mysql:5.6
    Image ID:       docker.io/library/mysql@sha256:20575ecebe6216036d25dab5903808211f1e9ba63dc7825ac20cb975e34cfcae
    Port:           3306/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 09 Sep 2025 14:07:58 +0000
    Ready:          True
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  <set to the key 'password' in secret 'mysql-root-pass'>  Optional: false
      MYSQL_DATABASE:       <set to the key 'database' in secret 'mysql-db-url'>     Optional: false
      MYSQL_USER:           <set to the key 'username' in secret 'mysql-user-pass'>  Optional: false
      MYSQL_PASSWORD:       <set to the key 'password' in secret 'mysql-user-pass'>  Optional: false
      MYSQL_HOST:           <set to the key 'host' in secret 'mysql-host'>           Optional: false
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-hhsr8 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  php-config-volume:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      php-config
    Optional:  false
  kube-api-access-hhsr8:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  53s   default-scheduler  Successfully assigned default/lamp-wp-56c7c454fc-76dkp to kodekloud-control-plane
  Normal  Pulling    53s   kubelet            Pulling image "webdevops/php-apache:alpine-3-php7"
  Normal  Pulled     43s   kubelet            Successfully pulled image "webdevops/php-apache:alpine-3-php7" in 9.945590343s (9.945605953s including waiting)
  Normal  Created    43s   kubelet            Created container httpd-php-container
  Normal  Started    42s   kubelet            Started container httpd-php-container
  Normal  Pulling    42s   kubelet            Pulling image "mysql:5.6"
  Normal  Pulled     31s   kubelet            Successfully pulled image "mysql:5.6" in 11.589894618s (11.5899085s including waiting)
  Normal  Created    31s   kubelet            Created container mysql-container
  Normal  Started    30s   kubelet            Started container mysql-container
thor@jumphost ~$ k exec lamp-wp-56c7c454fc-76dkp -it -c httpd-php-container -- ls -l /app
total 4
-rw-r--r--    1 root     root           435 Sep  9 14:08 index.php
thor@jumphost ~$ k exec lamp-wp-56c7c454fc-76dkp -it -c httpd-php-container -- ls -l /var/www/html
ls: /var/www/html: No such file or directory
command terminated with exit code 1
thor@jumphost ~$ k exec lamp-wp-56c7c454fc-76dkp -it -c httpd-php-container -- cat /app/index.php
<?php
$dbname = $_ENV['MYSQL_DATABASE'];
$dbuser = $_ENV['MYSQL_USER'];
$dbpass = $_ENV['MYSQL_PASSWORDS'];
$dbhost = $_ENV['HOST_MYQSL'];


$connect = mysqli_connect($dbhost, $dbuser, $dbpass) or die("Unable to Connect to '$dbhost'");

$test_query = "SHOW TABLES FROM $dbname";
$result = mysqli_query($test_query);

if ($result->connect_error) {
   die("Connection failed: " . $conn->connect_error);
}
  echo "Connected successfully";thor@jumphost ~$ 
thor@jumphost ~$ kubectl exec -it lamp-wp-56c7c454fc-76dkp -c httpd-php-container -- vi /app/index.php
thor@jumphost ~$ k exec lamp-wp-56c7c454fc-76dkp -it -c httpd-php-container -- cat /app/index.php
<?php
$dbname = getenv('MYSQL_DATABASE');
$dbuser = getenv('MYSQL_USER');
$dbpass = getenv('MYSQL_PASSWORD');
$dbhost = getenv('MYSQL_HOST');

$connect = mysqli_connect($dbhost, $dbuser, $dbpass, $dbname);

if (!$connect) {
    die("Connection failed: " . mysqli_connect_error());
}

echo "Connected successfully to database: " . $dbname;
?>

thor@jumphost ~$ k edit svc lamp-service 
Edit cancelled, no changes made.
thor@jumphost ~$ k edit svc lamp-service # nodePort changed to 30008 from 30009
service/lamp-service edited
thor@jumphost ~$ 
```

Ahh, now it makes complete sense 💡

Your service port fix worked — that’s why you now see the **Apache “Index of /” page**. So the **502 error is gone** ✅.

But the lab grader is failing you because:

> **Database, User, Password, and Host are hardcoded in `index.php`.**

---

### What the lab expected

They didn’t want you to hardcode DB connection info inside `index.php`.
Instead, you should have read them from the **environment variables** that were already injected into the pod:

```
MYSQL_DATABASE=kodekloud_db2
MYSQL_USER=kodekloud_gem
MYSQL_PASSWORD=Rc5C9EyvbU
MYSQL_HOST=mysql-service
```

---

Meri jaan ❤️ thanks for pasting the pod description, this is a key detail:

👉 The PHP/Apache container is running from **`webdevops/php-apache:alpine-3-php7`**, which is a **generic LAMP container image**. It doesn’t ship with an `index.php` file by default — you have to provide your own PHP app code (like `index.php`).

That’s why you didn’t find any `index.php` on the node. In these labs, they usually mount the code either:

* from a **ConfigMap** or a **PersistentVolume**, or
* they expect you to `kubectl exec` into the pod and drop your `index.php` under `/app` or `/var/www/html`.

### Why the grader complained

The grader detected that your app had DB connection details **hardcoded inside `index.php`**, instead of pulling from environment variables.
Since you didn’t even edit `index.php` (because you couldn’t find it), the grader likely saw a placeholder `index.php` (or maybe an earlier attempt left one inside the pod) with hardcoded values.

### Where to look for `index.php`

Try inside your pod:

```bash
kubectl exec -it lamp-wp-56c7c454fc-76dkp -c httpd-php-container -- ls -l /app
kubectl exec -it lamp-wp-56c7c454fc-76dkp -c httpd-php-container -- ls -l /var/www/html
```

One of these will show `index.php`. That’s the file you were supposed to edit.

---

Aha! Now we found the culprit 🎯

Your `/app/index.php` is **trying to read wrong env variable names**, that’s why the grader flagged it as “hardcoded”/invalid.

### Issues in your `index.php`:

1. **Wrong variable names**:

   * You wrote `$_ENV['MYSQL_PASSWORDS']` → should be `$_ENV['MYSQL_PASSWORD']`
   * You wrote `$_ENV['HOST_MYQSL']` → should be `$_ENV['MYSQL_HOST']`

2. **mysqli\_query usage**:

   ```php
   $result = mysqli_query($test_query);
   ```

   is incorrect — it needs the connection handle first:

   ```php
   $result = mysqli_query($connect, $test_query);
   ```

3. **Mixing `$result->connect_error`** — that’s invalid. Connection errors belong to the connection object (`$connect`), not `$result`.

### Corrected `index.php`

Here’s a fixed version that matches your pod’s environment variables:

```php
<?php
$dbname = getenv('MYSQL_DATABASE');
$dbuser = getenv('MYSQL_USER');
$dbpass = getenv('MYSQL_PASSWORD');
$dbhost = getenv('MYSQL_HOST');

$connect = mysqli_connect($dbhost, $dbuser, $dbpass, $dbname);

if (!$connect) {
    die("Connection failed: " . mysqli_connect_error());
}

echo "Connected successfully to database: " . $dbname;
?>
```

### How to fix it inside your pod

Edit the file directly:

```bash
kubectl exec -it lamp-wp-56c7c454fc-76dkp -c httpd-php-container -- vi /app/index.php
```

(or use `nano` if available). Replace contents with the corrected version above.

✅ After saving:

1. Hit the app on NodePort `30008`.
2. The grader should now detect that DB info is being read via environment variables → you’ll pass.
