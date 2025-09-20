
## Q 10
Create a pod called `time-check` in the `nautilus` namespace. The pod should contain a container named `time-check`, utilizing the busybox image with the latest tag (specify as `busybox:latest`).

Create a config map named `time-config` with the data `TIME_FREQ=10` in the same namespace.

Configure the time-check container to execute the command: `while true; do date; sleep $TIME_FREQ;done`. Ensure the result is written `/opt/dba/time/time-check.log`. Also, add an environmental variable `TIME_FREQ` in the container, fetching its value from the config map `TIME_FREQ` key.

Create a volume `log-volume` and mount it at `/opt/dba/time` within the container.

```bash
thor@jumphost ~$ k get po -n nautilus 
NAME         READY   STATUS    RESTARTS   AGE
time-check   1/1     Running   0          8s
thor@jumphost ~$ cat /tmp/kubectl-edit-3729583849.yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
# pods "time-check" was not valid:
# * <nil>: Invalid value: "The edited file failed validation": yaml: line 19: could not find expected ':'
#
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: time-check
  name: time-check
  namespace: nautilus
spec:
  containers:
  - image: busybox:latest
    imagePullPolicy: Always
    name: time-check
    command:
    - sh
    - -c 
    - while true; do date > /opt/dba/time/time-check.log; sleep $TIME_FREQ;done
    envFrom:
    - configMapRef:
        name: time-config
    volumeMounts:
    - mountPath: /opt/dba/time
      name: log-volume
  volumes:
  - name: log-volume
#   emptyDir: {}   # wrong, but the pod will run fine...
    hostPath: /opt/dba/time
    type: DirectoryOrCreate
thor@jumphost ~$ 
```

Thanks for sharing the full YAML 🙌.
The root cause is this part:

```yaml
args:
- while true; do date > /opt/dba/time/time-check.log; sleep $TIME_FREQ;done
```
👉 Kubernetes treats that whole string as a **binary to execute**, but `while true; do ...` is a shell loop, not an executable.
That’s why you see:

```
exec: "while true; do date ...": no such file or directory
```

### ✅ Fix

Wrap your script inside a shell:

```yaml
args:
- sh
- -c
- while true; do date > /opt/dba/time/time-check.log; sleep $TIME_FREQ; done
```

---

## Q14

The pod name is `nginx-phpfpm` and configmap name is `nginx-config`. Identify and fix the problem.
Once resolved, copy `/home/thor/index.php` file from the jump host to the `nginx-container` within the nginx document root. After this, you should be able to access the website using Website button on the top bar.

```bash
thor@jumphost ~$ k get po
NAME           READY   STATUS    RESTARTS   AGE
nginx-phpfpm   2/2     Running   0          75s
thor@jumphost ~$ k get cm
NAME               DATA   AGE
kube-root-ca.crt   1      6m17s
nginx-config       1      117s
thor@jumphost ~$ k describe cm nginx-config 
Name:         nginx-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
nginx.conf:
----
events {
}
http {
  server {
    listen 8099 default_server;
    listen [::]:8099 default_server;

    # Set nginx to serve files from the shared volume!
    root /var/www/html;
    index  index.html index.htm index.php;
    server_name _;
    location / {
      try_files $uri $uri/ =404;
    }
    location ~ \.php$ {
      include fastcgi_params;
      fastcgi_param REQUEST_METHOD $request_method;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      fastcgi_pass 127.0.0.1:9000;
    }
  }
}


BinaryData
====

Events:  <none>
thor@jumphost ~$ k describe po nginx-phpfpm 
Name:             nginx-phpfpm
Namespace:        default
Priority:         0
Service Account:  default
Node:             kodekloud-control-plane/172.17.0.2
Start Time:       Mon, 08 Sep 2025 17:59:20 +0000
Labels:           app=php-app
Annotations:      <none>
Status:           Running
IP:               10.244.0.5
IPs:
  IP:  10.244.0.5
Containers:
  php-fpm-container:
    Container ID:   containerd://569c2092d5fc8860d4065b63527c43199f3455c1e6b21498b789c751d9a783c5
    Image:          php:7.2-fpm-alpine
    Image ID:       docker.io/library/php@sha256:2e2d92415f3fc552e9a62548d1235f852c864fcdc94bcf2905805d92baefc87f
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Mon, 08 Sep 2025 17:59:24 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-zht62 (ro)
      /var/www/html from shared-files (rw)
  nginx-container:
    Container ID:   containerd://afae3c27f8aa6fde587c561e48636fd7d04cbf1ec28da5da867e87973c8d3e6e
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:33e0bbc7ca9ecf108140af6288c7c9d1ecc77548cbfd3952fd8466a75edefe57
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Mon, 08 Sep 2025 17:59:31 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /etc/nginx/nginx.conf from nginx-config-volume (rw,path="nginx.conf")
      /usr/share/nginx/html from shared-files (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-zht62 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  shared-files:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:     
    SizeLimit:  <unset>
  nginx-config-volume:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      nginx-config
    Optional:  false
  kube-api-access-zht62:
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
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  2m38s  default-scheduler  Successfully assigned default/nginx-phpfpm to kodekloud-control-plane
  Normal  Pulling    2m37s  kubelet            Pulling image "php:7.2-fpm-alpine"
  Normal  Pulled     2m34s  kubelet            Successfully pulled image "php:7.2-fpm-alpine" in 2.816028442s (2.81604534s including waiting)
  Normal  Created    2m34s  kubelet            Created container php-fpm-container
  Normal  Started    2m34s  kubelet            Started container php-fpm-container
  Normal  Pulling    2m34s  kubelet            Pulling image "nginx:latest"
  Normal  Pulled     2m27s  kubelet            Successfully pulled image "nginx:latest" in 6.791700819s (6.791718123s including waiting)
  Normal  Created    2m27s  kubelet            Created container nginx-container
  Normal  Started    2m27s  kubelet            Started container nginx-container
thor@jumphost ~$ cat /home/thor/index.php 
<?php
phpinfo();
?>thor@jumphost ~$ k edit po nginx-phpfpm 
Edit cancelled, no changes made.
thor@jumphost ~$ k get po nginx-phpfpm -o yaml > po.yaml 
thor@jumphost ~$ k delete po nginx-phpfpm 
pod "nginx-phpfpm" deleted
thor@jumphost ~$ k apply -f po.yaml 
pod/nginx-phpfpm created
thor@jumphost ~$ k get po
NAME           READY   STATUS    RESTARTS   AGE
nginx-phpfpm   2/2     Running   0          5s
thor@jumphost ~$ k get svc
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP          21m
nginx-service   NodePort    10.96.176.218   <none>        8099:30008/TCP   6m16s
thor@jumphost ~$ cat po.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: nginx-phpfpm
  labels:
    app: php-app
spec:
  containers:
  - name: php-fpm-container
    image: php:7.2-fpm-alpine
    volumeMounts:
    - name: shared-files
      mountPath: /var/www/html     # same path for php-fpm
  - name: nginx-container
    image: nginx:latest
    volumeMounts:
    - name: shared-files
      mountPath: /var/www/html     # same path for nginx
    - name: nginx-config-volume
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: shared-files
    emptyDir: {}
  - name: nginx-config-volume
    configMap:
      name: nginx-config
```
