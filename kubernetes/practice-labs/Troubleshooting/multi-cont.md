Fix the Deployment in Namespace `management` where both containers try to listen on port `80`.

Remove one container.

```bash
controlplane:~$ k get deployments.apps -n management 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
collect-data   0/2     2            0           28s

controlplane:~$ k logs -n management deployments/collect-data 
Found 2 pods, using pod/collect-data-5759c5c888-n9nxd
Defaulted container "nginx" out of: nginx, httpd
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/10/22 09:54:56 [notice] 1#1: using the "epoll" event method
2025/10/22 09:54:56 [notice] 1#1: nginx/1.21.6
2025/10/22 09:54:56 [notice] 1#1: built by gcc 10.3.1 20211027 (Alpine 10.3.1_git20211027) 
2025/10/22 09:54:56 [notice] 1#1: OS: Linux 6.8.0-51-generic
2025/10/22 09:54:56 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/10/22 09:54:56 [notice] 1#1: start worker processes
2025/10/22 09:54:56 [notice] 1#1: start worker process 33

controlplane:~$ k logs -n management deployments/collect-data -c httpd
Found 2 pods, using pod/collect-data-5759c5c888-n9nxd
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.0.6. Set the 'ServerName' directive globally to suppress this message
(98)Address in use: AH00072: make_sock: could not bind to address [::]:80
(98)Address in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
no listening sockets available, shutting down
AH00015: Unable to open logs

controlplane:~$ k get deployments.apps -o yaml -n management collect-data 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: collect-data
  namespace: management
spec:
  replicas: 2
  selector:
    matchLabels:
      app: collect-data
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: collect-data
    spec:
      containers:
      - image: nginx:1.21.6-alpine
        imagePullPolicy: IfNotPresent
        name: nginx

      - image: httpd:2.4.52-alpine
        imagePullPolicy: IfNotPresent
        name: httpd

controlplane:~$ k edit deployments.apps -n management collect-data       # - name: httpd     # removed
deployment.apps/collect-data edited

controlplane:~$ k get deployments.apps -n management 
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
collect-data   2/2     2            2           8m41s
```
