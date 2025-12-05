# 📡 Accessing Applications in a Kubernetes Cluster

This guide provides a comprehensive overview of methods to access applications running in a Kubernetes cluster, categorized by whether access originates from **inside the cluster** (e.g., nodes or Pods) or **outside the cluster** (e.g., a local machine or external network). The guide is designed for developers, administrators, and CKA exam candidates working in local, cloud, or hybrid environments.

---

## 1. Accessing from **Inside the Cluster**

These methods are used when you have direct access to cluster nodes or Pods, such as when SSH’d into a node, running commands from the control plane, or troubleshooting within a Pod. They are particularly useful in CKA exam scenarios or for debugging connectivity and DNS resolution.

### A. Direct `curl` from a Node or Control Plane
- **Description**: Access a Pod or Service directly using its IP address (Pod IP or ClusterIP) from a node or control plane. This method tests raw connectivity without relying on Kubernetes DNS.
- **Use Case**: Debugging Pod-to-Pod or Pod-to-Service connectivity, verifying Service ClusterIP accessibility.
- **Commands**:
  ```bash
  # Access a Pod directly
  curl http://<pod-ip>:<container-port>
  # Example: curl http://10.244.0.5:8081

  # Access a Service via ClusterIP
  curl http://<service-cluster-ip>:<service-port>
  # Example: curl http://10.96.0.15:80
  ```

- **Considerations**:
  - Requires SSH access to the node or control plane.
  - Pod IPs are ephemeral and change when Pods are rescheduled.
  - Ensure the container’s port is exposed and matches the Service’s target port.


### B. From a Temporary Pod
- **Description**: Launch a temporary Pod to test Service connectivity or DNS resolution from within the cluster. This simulates how applications communicate internally using Kubernetes DNS.
- **Use Case**: Verify Service name resolution, test DNS-based access, or troubleshoot in-cluster networking.
- **Commands**:
  ```bash
  # Launch a temporary Pod with an interactive shell
  kubectl run test --image=busybox -it --rm --restart=Never -- sh

  # Inside the Pod shell, test Service access
  wget <service-name>.<namespace>.svc.cluster.local
  # Example: wget amor.amor.svc.cluster.local

  # Inside Pod shell, test the pod directly by-passing service
  wget <pod-Ip>.<namespace>.pod.cluster.local
  # Example: wget 172-10-0-1.amor.pod.cluster.local

  # Inside Pod shell, get the response from the Service
  curl <svc-name>.<svc-ns>:<svc-port>
  # Example: curl project-plt-6cc-svc.dev:3333 or curl 10.96.12.55:3333
  ```

---

## 2. Accessing from **Outside the Cluster**

These methods enable access from a local machine, external network, or cloud environment, suitable for development, testing, or production. They are critical for interacting with applications from outside the Kubernetes cluster, such as during development on a laptop or exposing services to end users.

### A. Using NodePort
- **Description**: Expose a Service on a high-numbered port (30000–32767) across all cluster nodes. Access the Service using any node’s IP (public or private) and the assigned NodePort.
- **Use Case**: Simple external access to applications without requiring an Ingress or LoadBalancer, often used in development or testing.
- **Commands**:
  - From a local machine or external network:
    ```bash
    curl http://<node-public-ip>:<nodePort>
    # Example: curl http://54.242.167.17:30000
    ```
  - From the node itself (via SSH):
    ```bash
    curl http://localhost:<nodePort>
    curl http://<private-node-ip>:<nodePort>
    # Example: curl http://172.31.29.71:30000
    ```

- **Considerations**:
  - NodePort exposes the Service on all nodes, even if the Pod isn’t running on that node.
  - Not ideal for production due to lack of load balancing and security concerns.

### B. Port Forwarding
- **Description**: Forward a local port on your machine to a Pod or Service port in the cluster, creating a temporary tunnel for testing. This method is developer-focused and doesn’t require external exposure.
- **Use Case**: Local development, debugging, or testing an application without exposing it to the network.
- **Commands**:
  ```bash
  # Forward to a Service
  kubectl port-forward svc/<service-name> <local-port>:<service-port>
  # Example: kubectl port-forward svc/amor 8080:80

  # Forward to a Pod
  kubectl port-forward pod/<pod-name> <local-port>:<pod-port>
  # Example: kubectl port-forward pod/amor-pod 8080:80

  # On your local machine, access the application
  curl http://localhost:8080
  # Or open in browser: http://localhost:8080
  ```

- **Considerations**:
  - The port-forward session must remain active; closing the terminal stops access.
  - Only accessible from the machine running `kubectl port-forward`.
  - Suitable for HTTP, TCP, or other protocols supported by the application.

### C. Using Ingress
- **Description**: Route external HTTP/HTTPS traffic to Services based on domain names or paths, using an IngressController (e.g., NGINX, Traefik). Ingress is the preferred method for production HTTP applications.
- **Use Case**: Expose multiple Services under a single IP or domain, support path-based routing, or enable TLS.
- **Commands**:
  - If the IngressController is exposed via NodePort:
    ```bash
    curl http://<node-ip>:<nodePort>/<path>
    # Example: curl http://54.242.167.17:30080/asia
    ```
  - If DNS is configured:
    ```bash
    curl http://<domain-name>/<asia>
    # Example: curl http://local.ibtisam-iq.com/asia
    ```
  - For testing with a specific host header (bypassing DNS):
    ```bash
    curl -H "Host: local.ibtisam-iq.com" http://<node-ip>:<ingress-nodePort>/<asia>
    # Example: curl -H "Host: local.ibtisam-iq.com" http://54.242.167.17:30080/asia
    ```
  - Testing with ingress IP
    ```bash
    # this ingress doesn't contain any host.
    cluster3-controlplane ~ ➜  k get ingress
    NAME                       CLASS     HOSTS   ADDRESS          PORTS   AGE
    nginx-ingress-cka04-svcn   traefik   *       192.168.141.37   80      47m

    cluster3-controlplane ~ ➜  curl 192.168.141.37   # worked

    cluster3-controlplane ~ ➜  k get svc -n kube-system traefik 
    NAME      TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
    traefik   LoadBalancer   10.43.213.246   192.168.141.37   80:31459/TCP,443:31013/TCP   151m

    cluster3-controlplane ~ ➜  curl localhost:31459 # worked
    ```
    
```bash
cluster4-controlplane ~ ➜  cat ingress.yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: 
  name: pink-ing-cka16-trb
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /            # Not worked, if not added.
spec:
  ingressClassName: nginx
  rules:
    - host: kodekloud-pink.app
      http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: pink-svc-cka16-trb          # This must carry TCP, UDP
                port:
                  number: 5000
cluster4-controlplane ~ ➜  k get svc -n ingress-nginx 
NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    172.20.168.117   <none>        80:30242/TCP,443:31374/TCP   14m
ingress-nginx-controller-admission   ClusterIP   172.20.212.223   <none>        443/TCP                      14m

cluster4-controlplane ~ ➜  k get no -o wide
NAME                    STATUS   ROLES           AGE   VERSION   INTERNAL-IP       
cluster4-controlplane   Ready    control-plane   96m   v1.32.0   192.168.129.240   
cluster4-node01         Ready    <none>          96m   v1.32.0   192.168.36.224   

cluster4-controlplane ~ ➜  curl http://192.168.129.240:30242/    #  Not worked
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>

cluster4-controlplane ~ ➜  curl http://kodekloud-pink.app/       # worked # No need to add svc-port or node-port 
<!DOCTYPE html>

cluster4-controlplane ~ ➜  curl -H "Host: kodekloud-pink.app" curl 192.168.129.240:30242/  # worked
curl: (6) Could not resolve host: curl
<!DOCTYPE html>
```

### D. GatewayAPI 

```bash
cluster2-controlplane ~ ➜  k get svc -n nginx-gateway 
NAME            TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
nginx-gateway   NodePort   172.20.236.169   <none>        80:30080/TCP,443:30081/TCP   53m

cluster2-controlplane ~ ➜  k get gateway -n nginx-gateway -o yaml
apiVersion: v1
items:
- apiVersion: gateway.networking.k8s.io/v1
  kind: Gateway
  metadata:
    name: nginx-gateway
    namespace: nginx-gateway
  spec:
    gatewayClassName: nginx
    listeners:
    - allowedRoutes:
        namespaces:
          from: All
      name: http
      port: 80
      protocol: HTTP
  status:
    listeners:
    - attachedRoutes: 0

cluster2-controlplane ~ ➜  vi 9.yaml

cluster2-controlplane ~ ➜  k get svc -n cka3658 
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-portal-service-v1   ClusterIP   172.20.22.199   <none>        80/TCP    5m24s
web-portal-service-v2   ClusterIP   172.20.62.201   <none>        80/TCP    5m23s

cluster2-controlplane ~ ➜  k apply -f 9.yaml 
httproute.gateway.networking.k8s.io/web-portal-httproute created

cluster2-controlplane ~ ➜  k get gateway -n nginx-gateway -o yaml | grep -i attachedRoutes
    - attachedRoutes: 1

cluster2-controlplane ~ ➜  curl http://cluster2-controlplane:30080

    <h1>Hello from Web Portal App 2</h1>

cluster2-controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io -n cka3658 web-portal-httproute -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-portal-httproute
  namespace: cka3658
spec:
  hostnames:
  - cluster2-controlplane
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: nginx-gateway
    namespace: nginx-gateway
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: web-portal-service-v1
      port: 80
      weight: 80
    - group: ""
      kind: Service
      name: web-portal-service-v2
      port: 80
      weight: 20
    matches:
    - path:
        type: PathPrefix
        value: /

cluster2-controlplane ~ ➜  
```

### D. Using LoadBalancer (Cloud Environments)
- **Description**: Expose a Service externally using a cloud provider’s load balancer (e.g., AWS ELB, GCP Load Balancer). The Service is assigned an external IP or DNS name.
- **Use Case**: Production-grade external access with load balancing and high availability.
- **Commands**:
  ```bash
  # Get the external IP or hostname
  kubectl get svc <service-name> -o wide
  # Example output: amor  LoadBalancer  10.96.0.15  a12b3c4d.elb.amazonaws.com  80:30080/TCP

  # Access the Service
  curl http://<external-ip-or-hostname>:<port>
  # Example: curl http://a12b3c4d.elb.amazonaws.com
  ```

---

## 3. SSH and Shell Access Methods

These commands provide direct access to nodes or Pods for running the above methods or additional debugging.

| **Environment**       | **Command**                                              | **Use Case**                          | **Cluster Notes**                                                                 |
|-----------------------|----------------------------------------------------------|---------------------------------------|----------------------------------------------------------------------------------|
| **Minikube Node**     | `minikube ssh`                                          | Access Minikube VM                   | Single-node cluster; limited resources. Use `minikube ip` for node IP.           |
| **Kind Node**         | `docker exec -it <node-name> /bin/bash`                 | Access Kind containerized node       | Multi-node possible; install `curl` if missing (`apk add curl` or `apt-get`).    |
| **kubeadm Node**      | `ssh -i <key.pem> ubuntu@<public-ip>`                   | Access cloud or bare-metal node      | Cloud (e.g., AWS EC2) or on-prem; ensure SSH key and security group access.      |
| **Pod Shell**         | `kubectl exec -it <pod-name> -- sh`                     | Access a Pod’s container             | Use `bash` if `sh` is unavailable; specify container with `-c <container-name>`. |

- **Troubleshooting**:
  - For Minikube, ensure the VM is running (`minikube status`).
  - For Kind, list nodes with `docker ps` to find `<node-name>`.
  - For kubeadm, verify SSH access and key permissions (`chmod 400 <key.pem>`).
  - For Pods, check if the container has a shell (`kubectl describe pod <pod-name>`).

---

## 4. Summary of Access Methods

| **Method**           | **Access From**         | **Best For**                          | **Production-Ready?** |
|-----------------------|-------------------------|---------------------------------------|-----------------------|
| **Direct `curl`**     | Node/Control Plane      | Low-level IP-based testing            | No                    |
| **Temporary Pod**     | Inside Cluster          | DNS/Service resolution testing        | No                    |
| **NodePort**          | Local/External          | Simple external access                | Limited               |
| **Port Forwarding**   | Local Machine           | Developer testing                     | No                    |
| **Ingress**           | Local/External          | HTTP apps with DNS                    | Yes                   |
| **LoadBalancer**      | Local/External          | Cloud-based production access         | Yes                   |
