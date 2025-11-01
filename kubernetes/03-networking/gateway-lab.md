```bash
controlplane ~ ➜  k get gateway
error: the server doesn't have a resource type "gateway"

# Install the Gateway API resources

controlplane ~ ✖ kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v1.5.1" | kubectl apply -f -
customresourcedefinition.apiextensions.k8s.io/gatewayclasses.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/gateways.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/grpcroutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/httproutes.gateway.networking.k8s.io created
customresourcedefinition.apiextensions.k8s.io/referencegrants.gateway.networking.k8s.io created

# Deploy the NGINX Gateway Fabric CRDs

controlplane ~ ➜  kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/crds.yaml
customresourcedefinition.apiextensions.k8s.io/clientsettingspolicies.gateway.nginx.org created
customresourcedefinition.apiextensions.k8s.io/nginxgateways.gateway.nginx.org created
customresourcedefinition.apiextensions.k8s.io/nginxproxies.gateway.nginx.org created
customresourcedefinition.apiextensions.k8s.io/observabilitypolicies.gateway.nginx.org created
customresourcedefinition.apiextensions.k8s.io/snippetsfilters.gateway.nginx.org created
customresourcedefinition.apiextensions.k8s.io/upstreamsettingspolicies.gateway.nginx.org created

# Deploy the NGINX Gateway Fabric

controlplane ~ ➜  kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v1.6.1/deploy/nodeport/deploy.yaml
namespace/nginx-gateway created
serviceaccount/nginx-gateway created
clusterrole.rbac.authorization.k8s.io/nginx-gateway created
clusterrolebinding.rbac.authorization.k8s.io/nginx-gateway created
configmap/nginx-includes-bootstrap created
service/nginx-gateway created
deployment.apps/nginx-gateway created
gatewayclass.gateway.networking.k8s.io/nginx created
nginxgateway.gateway.nginx.org/nginx-gateway-config created

controlplane ~ ➜  k get svc,deploy,gatewayclass,gateway -n nginx-gateway 
NAME                    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/nginx-gateway   NodePort   172.20.15.123   <none>        80:30141/TCP,443:31233/TCP   2m39s

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-gateway   1/1     1            1           2m39s

NAME                                           CONTROLLER                                   ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/nginx   gateway.nginx.org/nginx-gateway-controller   True       2m39s

controlplane ~ ➜  k get gatewayclass -n nginx-gateway 
NAME    CONTROLLER                                   ACCEPTED   AGE
nginx   gateway.nginx.org/nginx-gateway-controller   True       3m26s

controlplane ~ ➜  k describe gatewayclass -n nginx-gateway nginx
Name:         nginx
Namespace:    
Labels:       app.kubernetes.io/instance=nginx-gateway
              app.kubernetes.io/name=nginx-gateway
              app.kubernetes.io/version=1.6.1
Annotations:  <none>
API Version:  gateway.networking.k8s.io/v1
Kind:         GatewayClass
Metadata:
  Creation Timestamp:  2025-08-08T19:57:43Z
  Generation:          1
  Resource Version:    1802
  UID:                 f6e92bcc-8aea-4add-8fa0-67b53d2ea0fe
Spec:
  Controller Name:  gateway.nginx.org/nginx-gateway-controller
```
---

```bash
spec:
      containers:
      - image: traefik/whoami:latest
```
---

**Q. Create a Kubernetes Gateway resource with the following specifications**:

* **Name:** `nginx-gateway`
* **Namespace:** `nginx-gateway`
* **Gateway Class Name:** `nginx`

#### Listeners

* **Protocol:** `HTTP`
* **Port:** `80`
* **Name:** `http`
* **Allowed Routes:** All namespaces

```bash
controlplane ~ ➜  k apply -f nginx-gateway.yaml 
gateway.gateway.networking.k8s.io/nginx-gateway created

controlplane ~ ➜  cat nginx-gateway.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-gateway
  namespace: nginx-gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: All

controlplane ~ ➜  k get -n nginx-gateway gateway nginx-gateway 
NAME            CLASS   ADDRESS   PROGRAMMED   AGE
nginx-gateway   nginx             True         33s
```

```yaml
controlplane ~ ➜  k explain gateway.spec --recursive 
GROUP:      gateway.networking.k8s.io
KIND:       Gateway
VERSION:    v1

FIELD: spec <Object>


DESCRIPTION:
    Spec defines the desired state of Gateway.
    
FIELDS:
  addresses     <[]Object>
    type        <string>
    value       <string> -required-
  gatewayClassName      <string> -required-
  infrastructure        <Object>
    annotations <map[string]string>
    labels      <map[string]string>
    parametersRef       <Object>
      group     <string> -required-
      kind      <string> -required-
      name      <string> -required-
  listeners     <[]Object> -required-
    allowedRoutes       <Object>
      kinds     <[]Object>
        group   <string>
        kind    <string> -required-
      namespaces        <Object>
        from    <string>
        enum: All, Selector, Same
        selector        <Object>
          matchExpressions      <[]Object>
            key <string> -required-
            operator    <string> -required-
            values      <[]string>
          matchLabels   <map[string]string>
    hostname    <string>
    name        <string> -required-
    port        <integer> -required-
    protocol    <string> -required-
    tls <Object>
      certificateRefs   <[]Object>
        group   <string>
        kind    <string>
        name    <string> -required-
        namespace       <string>
      mode      <string>
      enum: Terminate, Passthrough
      options   <map[string]string>
```
---

Q. **A new pod named `frontend-app` and a service called `frontend-svc` have been deployed in the `default` namespace.**
**Expose the service on the `/` path by creating an HTTPRoute named `frontend-route`.**

```bash
controlplane ~ ➜  k get svc,po
NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/frontend-svc   ClusterIP   172.20.52.33   <none>        80/TCP    66s
service/kubernetes     ClusterIP   172.20.0.1     <none>        443/TCP   32m

NAME               READY   STATUS    RESTARTS   AGE
pod/frontend-app   1/1     Running   0          66s

controlplane ~ ➜  k apply -f frontend-route.yaml 
httproute.gateway.networking.k8s.io/frontend-route created

controlplane ~ ➜  cat frontend-route.yaml 
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: frontend-route
  namespace: default
spec:
  parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
    sectionName: http
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: frontend-svc
      port: 80

controlplane ~ ➜  k get -n nginx-gateway gateway nginx-gateway 
NAME            CLASS   ADDRESS   PROGRAMMED   AGE
nginx-gateway   nginx             True         11m

controlplane ~ ➜  k get httproutes.gateway.networking.k8s.io 
NAME             HOSTNAMES   AGE
frontend-route               46s
```
---

That’s because both your **`frontend-app` Pod** and **`frontend-svc` Service** were deployed into the **`default` namespace**, so by default any new object you create (like `HTTPRoute`) will also go there unless you explicitly set a different namespace.

### Why in our case?

* Your Gateway (`nginx-gateway`) is in its **own namespace** (`nginx-gateway`) because it’s part of the controller’s installation.
* Your app (`frontend-app`) and service (`frontend-svc`) were deployed without a `-n` flag or `metadata.namespace`, so Kubernetes put them in `default`.
* Since the HTTPRoute routes traffic to `frontend-svc`, and that service is in `default`, the `HTTPRoute` also belongs in `default` to keep things tidy.

💡 **Important:**
An `HTTPRoute` **does not have to** be in the same namespace as the Gateway, but it **does have to** be in the same namespace as the Service it references (unless you explicitly allow cross-namespace routing via `backendRefs.namespaces`).

---

In your `parentRefs` section, the `sectionName` field is **optional** — you only need it if you want the `HTTPRoute` to bind to a **specific listener** inside the `Gateway`.

### How it works:

A Gateway can have **multiple listeners**:

```yaml
listeners:
  - name: http
    port: 80
    protocol: HTTP
  - name: https
    port: 443
    protocol: HTTPS
```

Each listener’s `name` is what you would put in `sectionName` in your `HTTPRoute`:

```yaml
parentRefs:
  - name: nginx-gateway
    namespace: nginx-gateway
    sectionName: http   # bind only to the "http" listener
```

### If you omit `sectionName`

* The route will attach to **all compatible listeners** in that Gateway.
* In your case, since your Gateway has only **one listener** (probably port 80), leaving it out works fine.

💡 **Rule of thumb:**

* **Single listener?** → `sectionName` is optional.
* **Multiple listeners?** → Use `sectionName` if you want to bind to a specific one.

---

**Q. Configure the web-route to split traffic between `web-service` and `web-service-v2`.**
The configuration should ensure that 80% of the traffic is routed to `web-service` and 20% is routed to `web-service-v2`.

> Note: `web-gateway`, `web-service`, and `web-service-v2` have already been created and are available on the cluster.

```bash
controlplane ~ ➜  kubectl create -n default -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: default
spec:
  parentRefs:
    - name: web-gateway
      namespace: default
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: web-service
          port: 80
          weight: 80
        - name: web-service-v2
          port: 80
          weight: 20
EOF
httproute.gateway.networking.k8s.io/web-route created
```
