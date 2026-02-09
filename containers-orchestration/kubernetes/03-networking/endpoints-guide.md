# Endpoints

## 1. What is an Endpoints Resource?

An **Endpoints** resource in Kubernetes is a low-level object that tracks the network addresses (IP and port) of Pods or external resources that a Service routes traffic to. It acts as the bridge between a Service’s abstract definition (based on a selector or manual configuration) and the actual Pods or external endpoints that handle traffic.

### Key Characteristics
- **Dynamic Mapping**: For Services with a `selector`, the Endpoints resource is automatically updated to reflect the IPs and ports of matching Pods as they are created, deleted, or rescheduled.
- **Manual Configuration**: For Services without a `selector` (e.g., external services or custom setups), you manually define an Endpoints resource to specify target IPs and ports.
- **Load Balancing**: The Service uses the Endpoints resource to distribute traffic across listed endpoints.
- **Dependency**: Every Service with a `selector` has a corresponding Endpoints resource (same name as the Service) managed by Kubernetes. Services without a `selector` require a manually created Endpoints resource.

### Example Context
In the web application use case from the Services documentation (exposing `my-app` Pods), the `my-app-service` Service relies on an Endpoints resource to track the IPs and ports of Pods labeled `app=my-app`. If a Pod’s IP changes (e.g., due to rescheduling), the Endpoints resource updates to ensure traffic is routed correctly.

---

## 2. Role of Endpoints in Service Connectivity

Endpoints are the mechanism by which a Service translates its logical definition (e.g., a ClusterIP and `port`) into concrete network targets (Pod IPs and `targetPort`). Here’s how Endpoints fit into the connectivity flow described in the Services documentation:

### Connectivity Flow with Endpoints
1. **Client Request**:
   - A client (internal or external) sends traffic to the Service’s ClusterIP and `port` (e.g., `10.96.0.1:80`) or DNS name (e.g., `my-app-service.default.svc.cluster.local:80`).
2. **Service Lookup**:
   - The kube-proxy (running on each node) intercepts the request and consults the Service’s Endpoints resource to determine the target Pod IPs and `targetPort`.
3. **Endpoints Resolution**:
   - The Endpoints resource lists the IPs and ports of Pods matching the Service’s `selector`. For example, if three Pods have IPs `192.168.1.2:8080`, `192.168.1.3:8080`, and `192.168.1.4:8080`, these are listed in the Endpoints.
4. **Traffic Forwarding**:
   - Kube-proxy load-balances the request to one of the Endpoints’ IPs and `targetPort`, which corresponds to the Pod’s `containerPort`.
5. **External Access**:
   - For **NodePort** or **LoadBalancer** Services, external traffic (e.g., via `<Node-IP>:30080` or a cloud load balancer) follows the same path, with kube-proxy redirecting to the Endpoints.

### Visual Diagram (Updated with Endpoints)
Below is an updated version of the traffic flow diagram from the Services documentation, incorporating the Endpoints resource for a **NodePort** Service:

```
[External Client]  ---->  [Node: <Node-IP>:30080]
                                 |
                                 v
                         [Service: my-app-service]
                         [ClusterIP: 10.96.0.1:80]
                                 |
                                 v
                         [Endpoints: my-app-service]
                         [192.168.1.2:8080, 192.168.1.3:8080, 192.168.1.4:8080]
                                 |
                                 v
        [Pod 1]  [Pod 2]  [Pod 3]
        [192.168.1.2:8080] [192.168.1.3:8080] [192.168.1.4:8080]
```

**Explanation**:
- **Client**: Sends a request to `<Node-IP>:30080` (NodePort).
- **Service**: Kube-proxy redirects to the Service’s ClusterIP (`10.96.0.1:80`).
- **Endpoints**: The Service queries the Endpoints resource, which lists the Pods’ IPs and `targetPort` (`8080`).
- **Pods**: Traffic is load-balanced to one of the Pods’ `containerPort` (`8080`).

---

## 3. Endpoints Structure and Placeholders

The Endpoints resource is defined in a YAML manifest, automatically managed for Services with a `selector` or manually created for those without. Below is its structure and key placeholders, tied to the Service’s placeholders (`port`, `targetPort`, `nodePort`, `containerPort`).

### Basic Structure
```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: my-app-service
subsets:
- addresses:
  - ip: 192.168.1.2
  - ip: 192.168.1.3
  - ip: 192.168.1.4
  ports:
  - port: 8080
    protocol: TCP
    name: http
```

### Key Placeholders
1. **metadata.name**:
   - Must match the Service’s name (e.g., `my-app-service`) to associate the Endpoints with the Service.
   - Ensures the Service uses this Endpoints resource for routing.

2. **subsets**:
   - A list of endpoint groups, each containing addresses and ports.
   - Allows multiple sets of endpoints with different ports or conditions (e.g., ready vs. not ready).

3. **subsets[].addresses**:
   - Lists the IP addresses of target endpoints (typically Pod IPs for Services with a `selector`).
   - Subfields:
     - **ip**: The IP address (e.g., `192.168.1.2`).
     - **targetRef**: Optional reference to a Pod or other object (used for tracking).
     - **nodeName**: Optional, indicates the node hosting the endpoint.
   - For manual Endpoints, you specify IPs (e.g., external servers).

4. **subsets[].ports**:
   - Defines the ports where traffic is sent, matching the Service’s `targetPort`.
   - Subfields:
     - **port**: The port number (e.g., `8080`) or named port (e.g., `http`) that corresponds to the Pod’s `containerPort`.
     - **protocol**: The protocol (default: `TCP`; also `UDP`, `SCTP`).
     - **name**: Optional, matches the Service’s `ports[].name` for multi-port Services.
   - Must align with the Service’s `targetPort` and Pod’s `containerPort`.

5. **subsets[].notReadyAddresses** (Optional):
   - Lists endpoints for Pods that are not ready (e.g., failing readiness probes).
   - Traffic is typically routed only to `addresses` (ready endpoints), unless configured otherwise.

### Relationship with Service Placeholders
- **port (Service)**: The Service’s `port` (e.g., `80`) is where clients send traffic. The Endpoints resource doesn’t directly use this but relies on the Service to map it to `targetPort`.
- **targetPort (Service)**: The Service’s `targetPort` (e.g., `8080` or `http`) matches the `subsets[].ports.port` in the Endpoints resource, ensuring traffic reaches the correct Pod port.
- **containerPort (Pod)**: The Pod’s `containerPort` (e.g., `8080`) is the actual port the container listens on, reflected in the Endpoints’ `subsets[].ports.port`.
- **nodePort (Service)**: For NodePort Services, the `nodePort` (e.g., `30080`) is the entry point, but the Endpoints resource determines the final Pod IPs and ports.

---

## 4. Endpoints and Service Types

The behavior of the Endpoints resource varies by Service type, as described in the Services documentation.

### 1. ClusterIP
- **Endpoints Role**: Automatically tracks Pod IPs and `targetPort` for internal load balancing.
- **Example**: For `my-app-service` (ClusterIP), the Endpoints lists Pod IPs like `192.168.1.2:8080`.
- **Headless Service** (`spec.clusterIP: None`):
  - Endpoints still lists Pod IPs, but clients resolve DNS to Pod IPs directly (no ClusterIP proxying).
  - Common for Jobs with Indexed completion mode (e.g., `comprehensive-computation` Job), where Pods need deterministic DNS names (e.g., `job-name-0.compute-service`).

### 2. NodePort
- **Endpoints Role**: Same as ClusterIP, but traffic enters via `<Node-IP>:<nodePort>` and is routed to Endpoints’ IPs and ports.
- **Example**: External traffic to `<Node-IP>:30080` is redirected to Endpoints like `192.168.1.2:8080`.

### 3. LoadBalancer
- **Endpoints Role**: Identical to ClusterIP/NodePort, but the cloud load balancer forwards traffic to the Service, which uses Endpoints to reach Pods.
- **Example**: A LoadBalancer routes traffic to the Service’s `port`, then to Endpoints’ IPs and `targetPort`.

### 4. ExternalName
- **Endpoints Role**: No Endpoints resource is created, as ExternalName Services map to an external DNS name (e.g., `api.example.com`) without proxying.
- **Note**: Endpoints are irrelevant here, as no Pods or local IPs are involved.

### Manual Endpoints (No Selector)
- **Use Case**: For Services targeting external resources (e.g., an external database).
- **Configuration**: Create a Service without a `selector` and a matching Endpoints resource.
- **Example**:
  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: external-db
  spec:
    ports:
    - port: 3306
      targetPort: 3306
  ---
  apiVersion: v1
  kind: Endpoints
  metadata:
    name: external-db
  subsets:
  - addresses:
    - ip: 192.168.50.10
    ports:
    - port: 3306
  ```
  - Routes traffic to an external MySQL server at `192.168.50.10:3306`.

---

## 5. Endpoints and Ingress

**Ingress** relies on Services to route external HTTP/HTTPS traffic, and thus indirectly on Endpoints. The Ingress Controller sends traffic to the Service’s `port`, which uses the Endpoints resource to reach Pods.

### Integration
- **Service Reference**: The Ingress specifies a Service (e.g., `my-app-service`) and its `port` (e.g., `80`).
- **Endpoints Lookup**: The Service queries its Endpoints resource to forward traffic to Pod IPs and `targetPort`.
- **Example** (from the Services use case):
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: my-app-ingress
  spec:
    rules:
    - host: ibtisam-iq.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: my-app-service
              port:
                number: 80
  ```
  - Traffic to `https://ibtisam-iq.com` reaches `my-app-service:80`, which uses the `my-app-service` Endpoints to route to Pods’ `8080`.

### Headless Service with Ingress
- For headless Services (e.g., for Jobs), Ingress can route to specific Pod IPs listed in the Endpoints, but this is rare, as Ingress typically targets ClusterIP Services for load balancing.

---

## 6. Endpoints and LoadBalancer

For **LoadBalancer** Services, the Endpoints resource functions the same as for ClusterIP/NodePort. The cloud load balancer sends traffic to the Service’s `port`, and the Endpoints resource provides the Pod IPs and `targetPort` for routing.

### Example
- **Service**:
  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: app-lb-service
  spec:
    selector:
      app: app
    ports:
    - port: 80
      targetPort: 8080
    type: LoadBalancer
  ```
- **Endpoints** (auto-managed):
  ```yaml
  apiVersion: v1
  kind: Endpoints
  metadata:
    name: app-lb-service
  subsets:
  - addresses:
    - ip: 192.168.1.2
    - ip: 192.168.1.3
    ports:
    - port: 8080
      name: http
  ```
- **Flow**: Load balancer → `app-lb-service:80` → Endpoints (`192.168.1.2:8080`, `192.168.1.3:8080`).

---

## 7. Endpoints in the Use Case Example

In the web application use case (`my-app` with ClusterIP and NodePort Services), the Endpoints resource is critical for routing traffic to the Deployment’s Pods.

### Configuration Recap
- **Deployment**:
  - Pods labeled `app=my-app`, listening on `containerPort: 8080`.
- **ClusterIP Service** (`my-app-service`):
  - `port: 80`, `targetPort: http`, `selector: app=my-app`.
- **NodePort Service** (`my-app-nodeport`):
  - `port: 80`, `targetPort: 8080`, `nodePort: 30080`, `selector: app=my-app`.
- **Ingress**:
  - Routes `https://ibtisam-iq.com` to `my-app-service:80`.

### Endpoints Resources
1. **For `my-app-service`**:
   ```yaml
   apiVersion: v1
   kind: Endpoints
   metadata:
     name: my-app-service
   subsets:
   - addresses:
     - ip: 192.168.1.2
     - ip: 192.168.1.3
     - ip: 192.168.1.4
     ports:
     - port: 8080
       name: http
       protocol: TCP
   ```
   - Auto-managed by Kubernetes, listing the three Pods’ IPs and `targetPort` (`8080`, named `http`).

2. **For `my-app-nodeport`**:
   - Similar Endpoints resource, also listing the same Pod IPs and `targetPort: 8080`.

### Traffic Flow with Endpoints
- **Internal (ClusterIP)**:
  - Request to `my-app-service.default.svc.cluster.local:80`.
  - Kube-proxy uses `my-app-service` Endpoints to route to `192.168.1.2:8080`, `192.168.1.3:8080`, or `192.168.1.4:8080`.
- **External (NodePort)**:
  - Request to `<Node-IP>:30080`.
  - Kube-proxy redirects to `my-app-nodeport` Endpoints, then to a Pod’s `8080`.
- **Ingress**:
  - Request to `https://ibtisam-iq.com`.
  - Ingress Controller routes to `my-app-service:80`, which uses Endpoints to reach a Pod’s `8080`.

### Updated Diagram
```
[External Client]  ---->  [Ingress Controller: https://ibtisam-iq.com]
                                 |
                                 v
                         [Service: my-app-service]
                         [ClusterIP: 10.96.0.1:80]
                                 |
                                 v
                         [Endpoints: my-app-service]
                         [192.168.1.2:8080, 192.168.1.3:8080, 192.168.1.4:8080]
                                 |
                                 v
        [Pod 1]  [Pod 2]  [Pod 3]
        [192.168.1.2:8080] [192.168.1.3:8080] [192.168.1.4:8080]

[Testing Client]  ---->  [Node: <Node-IP>:30080]
                                 |
                                 v
                         [Service: my-app-nodeport]
                         [ClusterIP: 10.96.0.2:80]
                                 |
                                 v
                         [Endpoints: my-app-nodeport]
                         [192.168.1.2:8080, 192.168.1.3:8080, 192.168.1.4:8080]
                                 |
                                 v
        [Pod 1]  [Pod 2]  [Pod 3]
        [192.168.1.2:8080] [192.168.1.3:8080] [192.168.1.4:8080]
```

---

## 8. Troubleshooting Endpoints

Endpoints issues can disrupt Service connectivity. Common problems and fixes include:

- **Empty Endpoints**:
  - **Cause**: No Pods match the Service’s `selector`, or Pods are not ready.
  - **Fix**: Check `kubectl get endpoints my-app-service` and verify Pod labels (`kubectl get pods -l app=my-app`). Ensure Pods pass readiness probes.
- **Outdated Endpoints**:
  - **Cause**: Kubernetes controller hasn’t updated Endpoints after Pod changes.
  - **Fix**: Restart the kube-controller-manager or wait for reconciliation. Check `kubectl describe endpoints my-app-service` for events.
- **Manual Endpoints Not Working**:
  - **Cause**: Mismatch between Service and Endpoints names or ports.
  - **Fix**: Ensure `metadata.name` matches and `subsets[].ports.port` aligns with `targetPort`.
- **Headless Service Issues**:
  - **Cause**: DNS resolution fails for Pod-specific names.
  - **Fix**: Verify `spec.clusterIP: None` and check DNS with `kubectl exec -it <pod> -- nslookup comprehensive-computation-0.compute-service`.

---

## 9. Best Practices for Endpoints

1. **Rely on Auto-Management**: For Services with a `selector`, let Kubernetes manage the Endpoints resource to avoid manual errors.
2. **Use Headless Services for Jobs**: For Indexed Jobs, create headless Services to leverage Endpoints for direct Pod communication.
3. **Validate Selectors**: Ensure Service `selector` matches Pod labels to populate Endpoints correctly.
4. **Monitor Endpoints**: Use `kubectl get endpoints` to verify active endpoints, especially during scaling or failures.
5. **Manual Endpoints for External Services**: Use manual Endpoints for external resources, but document IPs and ports clearly to avoid misconfiguration.

---
We have an external webserver running on student-node which is exposed at port 9999. We have created a service called external-webserver-cka03-svcn that can connect to our local webserver from within the kubernetes cluster3, but at the moment, it is not working as expected.

```bash
cluster3-controlplane ~ ✖ curl student-node:9999
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

cluster3-controlplane ~ ➜  k describe svc -n kube-public external-webserver-cka03-svcn 
Name:                     external-webserver-cka03-svcn
Namespace:                kube-public
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.109.238
IPs:                      10.43.109.238
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                <none>
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

cluster3-controlplane ~ ➜  k get no -o wide
NAME                    STATUS   ROLES                  AGE    VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
cluster3-controlplane   Ready    control-plane,master   154m   v1.32.0+k3s1   192.168.141.31   <none>        Alpine Linux v3.16   5.15.0-1083-gcp   containerd://1.6.8

cluster3-controlplane ~ ➜  ifconfig eth0 | grep inet | head -n1 | awk '{print $2}'
addr:192.168.141.31

```

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: external-webserver-cka03-svcn
  namespace: kube-public
  labels:
    kubernetes.io/service-name: external-webserver-cka03-svcn
addressType: IPv4
ports:
  - protocol: TCP
    port: 9999
endpoints:
  - addresses:
      - 192.168.141.31   # IP of student node
```

```bash
cluster3-controlplane ~ ➜  vi 14.yaml

cluster3-controlplane ~ ➜  k apply -f 14.yaml 
endpointslice.discovery.k8s.io/external-webserver-cka03-svcn configured

cluster3-controlplane ~ ➜  k describe svc -n kube-public external-webserver-cka03-svcn
Name:                     external-webserver-cka03-svcn
Namespace:                kube-public
Labels:                   <none>
Annotations:              <none>
Selector:                 <none>
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.109.238
IPs:                      10.43.109.238
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                192.168.141.31:9999
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```
---
## Conclusion

The **Endpoints** resource is a critical component of Kubernetes Services, translating the Service’s logical configuration (ClusterIP, `port`, `targetPort`) into concrete network targets (Pod IPs, `containerPort`). It enables dynamic load balancing for ClusterIP, NodePort, and LoadBalancer Services and direct Pod access for headless Services, as seen in Jobs like `comprehensive-computation`. In the context of the web application use case, Endpoints ensure traffic reaches `my-app` Pods, whether via internal ClusterIP, NodePort testing, or Ingress for production. By understanding Endpoints’ structure, placeholders, and integration with Service types, Ingress, and LoadBalancer, you can troubleshoot connectivity issues and optimize networking for your SilverKube repository or CKA exam scenarios. This explanation complements the Services documentation, providing a complete picture of Kubernetes networking.
