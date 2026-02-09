# Managing Kubernetes [Objects](https://github.com/ibtisam-iq/nectar/blob/main/kubernetes/01-core-concepts/objects.md) Using Imperative Commands

### Official Documentation

- https://kubernetes.io/docs/reference/kubectl/kubectl/
- https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands

### Cluster Formation

**1.** [**KodeKloud**](https://kodekloud.com/public-playgrounds)

**2. `kind`**

- One control-plane node and one worker node with default CNI (Flannel)
    ```bash
    curl -s https://raw.githubusercontent.com/ibtisam-iq/SilverKube/main/kind-config-file.yaml | kind create cluster --config -
    ```

- One control-plane node and one worker node with Calico CNI
    ```bash
    curl -sL https://raw.githubusercontent.com/ibtisam-iq/infra-bootstrap/main/k8s-kind-calico.sh | sudo bash
    ```

**3. `kubeadm`**

- First control-plane initialization
    ```bash
    curl -sL https://raw.githubusercontent.com/ibtisam-iq/infra-bootstrap/main/K8s-Control-Plane-Init.sh | sudo bash
    ```

- Worker node initialization
    ```bash
    curl -sL https://raw.githubusercontent.com/ibtisam-iq/infra-bootstrap/main/K8s-Node-Init.sh | sudo bash
    ```

> **Note:** Kubernetes supports both `--flag=value` and `--flag value` formats.

--- 

## Pod
Create and run a particular image.

```bash
kubectl run <name> --image=<image> \
    --port=<port> \       # The port that this container exposes.
    --expose =<expose> \
    -l, --labels=<key>=<value>,<key>=<value> \  # -l, --labels=''
    --env=<key>=<value> --env=<key>=<value> \   # --env=[]:
    -n, --namespace=<namespace> \
    -- <arg1> <arg2> ... <argN> \   # use default command, but use custom arguments (arg1 .. argN) for that command
    --command -- <cmd> <arg1> ... <argN> \  # use a different command and custom arguments
    --restart=Never \
    --dry-run=client \
    -o, --output=yaml > <output file>
```

Fetch a resource.
```bash
kubectl get pods -A, --all-namespaces \
    --no-headers \
    -l, --selector key1=value1,key2=value2 \
    --show-labels \
    --sort-by <field> \
    -w, --watch
```

### Example
```bash
# Create two objects in YAML: pod named "my-pod" and generate service (ClusterIP type)

kubectl run my-nginx --image=nginx:1.14.2 --port=80 --expose \
  --labels=app=my-nginx,type=sam --env=MY_VAR=hello --env=flower=lily \
  --namespace=default --restart=Never --dry-run=client -o yaml > my-nginx.yaml

kubectl run my-nginx --image nginx:1.14.2 --port 80 --expose \
  --labels app=my-nginx,type=sam --env MY_VAR=hello --env flower=lily \
  --namespace default --restart Never --dry-run client -o yaml > my-nginx.yaml

# Override Only Arguments (Keeping Default Command)
kubectl run <> --image nginx -- -g "daemon off;"
kubectl run <> --image busybox -- sleep 1000							# args: ["sleep", "1000"]
kubectl run <> --image busybox -- "sleep 1000"							# args: ["sleep 1000"]
kubectl run test --image busybox -- echo "hello sweetheart, ibtisam"	# args: ["echo", "hello sweetheart, ibtisam"]
k run <> --image kodekloud/webapp-color --dry-run=client -o yaml -- --color red # Parsed as two args: ["--color", "red"]

# Override the Command and Arguments
k run alpine-app --image alpine -- 'echo "jaan-e-mann"; sleep 3600' # wrong, you need to open the shell in order to multiple commands
k run alpine-app --image alpine --command -- sh -c 'echo "jaan-e-mann"; sleep 3600' # correct
kubectl exec -it pv-test-pod -- sh -c "echo 'Hello from PV' > /data/hello.txt"
k run nginx --image=nginx --restart=Never --command -- /bin/sh -c "echo Hello Sweetheart, Ibtisam; sleep 10"
kubectl run <> --image busybox --dry-run client -o yaml --command -- sleep 1000			# wrong
kubectl run <> --image busybox --dry-run=client -o yaml --command -- sleep 1000			# right

# Start a busybox pod and keep it in the foreground, don't restart it if it exits
kubectl run -i -t busybox --image=busybox --restart=Never
kubectl run -i -t busybox --image=busybox --restart=Never --rm				# also delete the pod once it exits
kubectl run -i -t busybox --image=busybox --restart=Never --rm -- sh		# also run desired command
# Start a pod using --rm but without -it → error: --rm should only be used for attached containers
```

* The `--expose` flag is valid with `kubectl run`, but it only creates a **ClusterIP Service**.
* The `--port` flag is required; otherwise, Kubernetes does not know which port to expose.
* `--expose` is useful for **quick testing**, but limited for customization. For external access, use `kubectl expose` separately and specify `--type=NodePort` or `--type=LoadBalancer`.

* If multiple `--port` or `--image` flags are specified, **the last occurrence overrides all previous ones**.
* The `--` separator ensures everything after it is treated as **arguments** to the container.

  * Example: `-- sleep 1000` → `args: ["sleep", "1000"]`
  * To pass a single string as one argument, quote it: `-- "sleep 1000"`

* Use `--command --` to explicitly define a custom command.
* The `command` field overrides the container image’s **ENTRYPOINT**.
* The `args` field overrides the container image’s **CMD**.
* **Golden rule:**

  * No `--command` → values go into `args` (override CMD).
  * With `--command` → values go into `command` (override ENTRYPOINT).
* To run multiple commands, you must start a shell:

  ```bash
  --command -- sh -c 'echo hello; sleep 3600'
  ```

  Otherwise, Kubernetes treats the string as a single command/argument.


| Aspect                | `--port`                                   | `--expose`                                   |
|-----------------------|--------------------------------------------|---------------------------------------------|
| **Purpose**           | *Declares* the port the container listens on | Creates a Service to expose the Pod         |
| **Resource Affected** | Pod (container spec)                      | Pod + Service                              |
| **Networking Impact** | None (no external access)                 | Creates a Service for cluster/external access |
| **Output in YAML**    | Adds `containerPort` to Pod spec          | Pod spec + Service (if not dry-run)        |
| **Use Case**          | Document container's listening port       | Enable network access to the Pod           |
| **Dependency**        | Independent                               | Requires a port (e.g., via `--port`)       |


> **Note:** `kubectl run` defaults to creating a Pod directly. The `pod` keyword is unnecessary and can lead to confusion. `kubectl run nginx --image nginx` is correct. `kubectl run pod nginx --image nginx` is incorrect.

---

## Deployment
Create a deployment with the specified name

```bash
kubectl create deployment <name> --image=<image> \
    -r, --replicas=1 \
    --port=<> \
    # -l, --labels=<key>=<value>,<key>=<value> \ # Not supported
    # --env=<key>=<value> --env=<key>=<value> \  # Not supported
    -n, --namespace=<namespace> \
    # -- <arg1> <arg2> ... <argN> \              # Not supported
    # --command -- <cmd> <arg1> ... <argN> \     # Not supported
    -- [COMMAND] [args...]
    --save-config
```
### Example

```bash
# Create a deployment named my-dep that runs the busybox image
kubectl create deployment my-dep --image busybox -r 3 --port 3000

# Create a deployment with a command
# kubectl create deployment NAME --image=image -- [COMMAND] [args...] [options]
kubectl create deployment my-dep --image=busybox -- date

# Create a deployment named my-dep that runs multiple containers
kubectl create deployment my-dep --image=busybox:latest --image=ubuntu:latest --image=nginx

# controlplane ~ ➜  kubectl create deployment my-dep --image=busybox:latest --image=ubuntu:latest --image=nginx -- date
error: cannot specify multiple --image options and command
```
- `--image=[]`: Image names to run. A deployment can have multiple images set for multi-container pod.
- `kubectl create deployment` treats arguments after `--` as the container’s command, replacing the image’s default ENTRYPOINT. However, `kubectl run` interprets arguments after `--` as **arguments** to the container’s Entrypoint (not the command itself, and replacing ENTRYPOINT), unless `--command` is specified.

---

## ReplicaSet & ReplicationController

- NO imperative command
- `kubectl rollout` also don't cover both of them

---

## Jobs & CronJobs
```bash
kubectl create job NAME --image=image \
	--from=cronjob/name \    	# create a job from a cron job
	-- [COMMAND] [args...]

kubectl create cronjob NAME --image=image --schedule='0/5 * * * ?' \			# schedule must be surrounded with ""
    --restart \     			# supported values: OnFailure, Never
    -- [COMMAND] [args...] [flags] [options]

k create cj nautilus --image nginx:latest --restart OnFailure --schedule "*/9 * * * *" -- "echo Welcome!" 	# wrong
k create cj nautilus --image nginx:latest --restart OnFailure --schedule "*/9 * * * *" -- echo Welcome! 	# correct
```

In commands like `kubectl create cronjob`, the format `-- [COMMAND] [args...] [flags] [options]` dictates what runs inside the container:

- **COMMAND**: The program that runs inside the container (e.g., `echo`, `sh`, `python`)
- **args...**: Arguments passed to the command (e.g., "Hello, Kubernetes!")
- **flags**: Command-specific flags inside the container (e.g., `-c` for `sh`)
- **options**: Extra settings for the command inside the container (e.g., `--verbose`)
- Like deployment, it supports only `-- <command> <arg>`, not pod like `--command -- <arg>`.

Example:
```sh
kubectl create cronjob my-cronjob --image=busybox --schedule="*/5 * * * *" -- echo "Hello, Kubernetes!"
```
Here, `echo "Hello, Kubernetes!"` runs inside the container every 5 minutes.

> error: either `--image` or `--from` must be specified

---

## ConfigMap and Secret

```bash
kubectl create configmap NAME \
    --from-file=path/to/bar \ # bar is directory, and inside dir, each file name becomes a key, and the file content becomes the value
    --from-file=path/to/bar \ # bar is file, key becomes equal to the file name (bar) and the file content becomes the value.
    --from-file=key1=/path/to/file1.txt --from-file=key2=/path/to/file2.txt \ # file content becomes the value
    --from-literal=key1=config1 --from-literal=key2=config2 \
    --from-env-file=path/to/foo.env --from-env-file=path/to/bar.env

kubectl create secret generic NAME \
    --from-file=path/to/bar \
    --from-file=ssh-privatekey=path/to/id_rsa \
    --from-literal=key1=supersecret \
    --from-env-file=path/to/bar.env

# Create a new TLS secret named tls-secret with the given key pair
kubectl create secret tls tls-secret --cert=path/to/tls.crt --key=path/to/tls.key

# If you do not already have a .dockercfg file, create a dockercfg secret directly
kubectl create secret docker-registry my-secret --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
  
# Create a new secret named my-secret from ~/.docker/config.json
kubectl create secret docker-registry my-secret --from-file=path/to/.docker/config.json
```

- **When using `--from-env-file`, the file must follow `.env` format (`KEY=VALUE` per line); YAML-style (`key: value`) is not supported. Multiple files can be specified, and later keys override earlier ones.**
- If the same key is defined in multiple env files, the value from the last file specified takes precedence.

---

## Persistent Volume (PV), Persistent Volume Claim (PVC) and StorageClass

- NO imperative command
- Adding `volumeName` into PVC will bypass `volumeBindingMode: WaitForFirstConsumer` of the StorageClass
- Set the `volumeName`, and `storageClassName: ""` in PVC, and get your PVC bound without deploying any pod.
- PVC requires some time for binding. So, be patient.
- Set the `allowVolumeExpansion: true` in StorageClass enables PVC expansion. → you cannot shrink a PVC.
- Each `volume` entry under `spec.volumes` must have a **unique name**.
- However, if you try to add two different sources (like `persistentVolumeClaim` + `emptyDir`) under the same volume, you’ll also get an error.
- Unlike `hostPath` volumes (which **can create a path automatically** if it doesn’t exist → type: `DirectoryOrCreate`), a **local PersistentVolume (PV)** in Kubernetes expects that the directory (or device) already exists on the node.
- With `hostPath`, the `nodeAffinity` is a precaution; with `local`, it’s mandatory.
- A PVC cannot be deleted while mounted; delete the Pod first, then the PVC, and the PV’s fate depends on its `ReclaimPolicy`.

---

## Namespace
```bash
kubectl create ns NAME [--dry-run=server|client|none] [options]
kubectl config view --minify --output yaml | grep namespace:

controlplane ~ ➜  k describe ns ibtisam 					# Resource Quotas & LimitRange resources are found, if applied.
Name:         ibtisam
Labels:       kubernetes.io/metadata.name=ibtisam
Annotations:  <none>
Status:       Active

Resource Quotas
  Name:           rq
  Resource        Used  Hard
  --------        ---   ---
  resourcequotas  1     1

No LimitRange resource.
```
---

## Service Account & Token
```bash
# create a service account with the specified name
kubectl create sa my-service-account -n ibtisam

# Request a service account token
kubectl create token SERVICE_ACCOUNT_NAME -n ibtisam
```
---

## Role and RoleBinding & ClusterRole and ClusterRoleBinding

```bash
# Create a role named "pod-reader" that allows user to perform "get", "watch" and "list" on pods
kubectl create role pod-reader --verb=get,list,watch --resource=pods

# Create a role that allows all verbs, and all resources
kubectl create role ibtisam -n ibtisam --verb=* --resource=*
  
# Create a role named "pod-reader" with ResourceName specified
kubectl create role pod-reader --verb=get --resource=pods --resource-name=readablepod,anotherpod
  
# Create a role named "foo" with API Group specified
kubectl create role foo --verb=get,list,watch --resource=rs.apps
  
# Create a role named "foo" with SubResource specified
kubectl create role foo --verb=get,list,watch --resource=pods,pods/status

# Create a new cluster role named “abc” that can create deployments, replicasets and daemonsets
controlplane:~$ k create clusterrole abc --verb create --resource=deploy,rs,ds
clusterrole.rbac.authorization.k8s.io/acme-corp-clusterrole created

# Create a ClusterRole named healthz-access that allows GET and POST requests to the non-resource endpoint /healthz and all subpaths
root@student-node ~ ➜  kubectl create clusterrole healthz-access \
  --verb=get,post \
  --non-resource-url=/healthz \
  --non-resource-url=/healthz/*
clusterrole.rbac.authorization.k8s.io/healthz-access created

# Update the permissions of this service account so that it can only `get` all the `namespaces`
cluster1-controlplane ~ ➜  k create clusterrole green-role-cka22-arch --verb get --resource namespaces
clusterrole.rbac.authorization.k8s.io/green-role-cka22-arch created

kubectl create role|clusterrole NAME --verb=verb --resource=resource.group [--resource-name=resourcename]
[--dry-run=server|client|none] [options]

kubectl create rolebinding|clusterrolebinding NAME --clusterrole=NAME|--role=NAME 
    [--user=username1,username2] [--group=groupname] [--serviceaccount=namespace:serviceaccountname] 
    [--dry-run=server|client|none] [options]
```

When using the `--resource` flag in `kubectl create role`, you're defining the exact API target the role will apply to. This flag can have **three components**:

- **`resource`** → The main Kubernetes object.  
  _Examples_: `pods`, `deployments`, `services`

- **`group`** → The API group the resource belongs to.  
  _Examples_: `apps`, `batch`, `rbac.authorization.k8s.io`

- **`subresource`** (optional) → A more specific part or action related to the resource.  
  _Examples_:  
  - `pods/log` – to access logs from a pod  
  - `deployments/scale` – to allow scaling of deployments  
  - `pods/status` – to read or modify the status subresource of a pod

> 📌 **Format:**  
> `--resource=resource.group/subresource`  
> All three components are not always required. For core resources (like `pods`), the `group` may be empty. And `subresource` is only used when needed.

> ✅ You can specify multiple values for flags like `--verb`, `--resource`, or `--resource-name` either by repeating the flag (`--verb=get --verb=list`) or by providing comma-separated values (`--verb=get,list`) — both approaches are functionally equivalent.

> Run `kubectl api-resources` for fetching details. 

**There are 4 different RBAC combinations and 3 valid ones:**

1. RoleBinding + Role (available in single Namespace, applied in single Namespace)
2. ClusterRoleBinding + ClusterRole (available cluster-wide, applied cluster-wide)
3. RoleBinding + ClusterRole (available cluster-wide, applied in single Namespace)
4. ClusterRoleBinding + Role (NOT POSSIBLE: available in single Namespace, applied cluster-wide)


- `list` is used by commands like `kubectl get pods`
- `watch` is used when you do `kubectl get pods -w` or clients use a watch API
- `get` is used for getting details of individual pods (`kubectl get pod <pod-name>`)

If the question is minimal, you might only need `list`, but if the exam expects broader functionality (like seeing pod details or watching pods), you include `get`, `list`, `watch`.

---

## Service

The `kubectl expose` command is used to create a Kubernetes **Service** from an existing resource such as a Pod, Deployment, ReplicaSet, or ReplicationController. This allows external or internal clients to access the workloads through a stable endpoint (ClusterIP, NodePort, or LoadBalancer).

```bash
kubectl create service clusterip|externalname|loadbalancer|nodeport NAME --tcp=port:targetPort
    --clusterip='Assign your own ClusterIP or set to 'None' for a 'headless' service (no loadbalancing)'
    --external-name='External name of service'
    --node-port=0

kubectl expose (-f FILENAME | TYPE NAME) --port=<> \ # The port that the service should serve on
    --target-port=<port> \
    --name=<name> \
    --type=<type> \
    --protocol=<protocol> \ # Sets TCP, UDP, or SCTP (default: TCP)
    -l, --labels='': Labels to apply to the service created by this call
    --selector='': A label selector to use for this service. Only equality-based selector requirements are supported.
    --cluster-ip='': ClusterIP to be assigned to the service. Leave empty to auto-allocate, or set to 'None'
    --external-ip='': Additional external IP address (not managed by Kubernetes) to accept for the service
```

### Examples
```bash
# Create a service for a replicated nginx, which serves on port 80 and connects to the containers on port 8000
kubectl expose rc nginx --port=80 --target-port=8000
  
# Create a service for a replication controller identified by type and name specified in "nginx-controller.yaml", which serves on port 80 and connects to the containers on port 8000
kubectl expose -f nginx-controller.yaml --port=80 --target-port=8000
  
# Create a service for a pod valid-pod, which serves on port 444 with the name "frontend"
kubectl expose pod valid-pod --port=444 --name=frontend
  
# Create a second service based on the above service, exposing the container port 8443 as port 443 with the name "nginx-https"
kubectl expose service nginx --port=443 --target-port=8443 --name=nginx-https
  
# Create a service for a replicated streaming application on port 4100 balancing UDP traffic and named 'video-stream'.
kubectl expose rc streamer --port=4100 --protocol=UDP --name=video-stream
  
# Create a service for a replicated nginx using replica set, which serves on port 80 and connects to the containers on port 8000
kubectl expose rs nginx --port=80 --target-port=8000
  
# Create a service for an nginx deployment, which serves on port 80 and connects to the containers on port 8000
kubectl expose deployment nginx --port=80 --target-port=8000

# Adds labels app=my-app and env=prod to the Service for grouping Services (e.g., kubectl get service -l app=my-app)
kubectl expose deployment my-app --port=80 --labels="app=my-app,env=prod"

# Routes traffic to Pods with labels app=my-app and version=v2, overriding the Deployment’s default selector
kubectl expose deployment my-app --port=80 --selector="app=my-app,version=v2"
```

**1. Syntax**

```bash
kubectl expose (TYPE NAME | -f FILENAME) [--port=port] [--target-port=port] [--type=service-type] [flags]
```

* **TYPE**: The kind of resource to expose (e.g., `pod`, `service`, `rc`, `deployment`, `rs`).
* **NAME**: The specific resource instance to expose.
* **-f, --filename**: Instead of TYPE/NAME, you can specify a file, directory, or URL containing the resource manifest.

**2. Service Port Configuration**

* **`--port=<port>`**

  * Defines the port on the Service that clients will use to connect.
  * Mandatory if the container does not already specify a `containerPort`.
  * Example: `--port=80` makes the Service available on port 80.

* **`--target-port=<port>`**

  * The port on the Pod/container that traffic should be forwarded to.
  * Can be either a numeric value or a named port from the container spec.
  * Defaults to the same value as `--port` if not provided.

**3. Service Type**

* **`--type=<ClusterIP|NodePort|LoadBalancer|ExternalName>`**

  * **ClusterIP** (default): Creates a Service with an internal IP, accessible only inside the cluster.
  * **NodePort**: Exposes the Service on a static port across all nodes (`nodeIP:nodePort`).
  * **LoadBalancer**: Creates an external load balancer (cloud provider support required).
  * **ExternalName**: Maps the Service to an external DNS name instead of a Pod.

**4. Cluster and External IPs**

* **`--cluster-ip=<IP>`**

  * Assigns a specific internal ClusterIP for the Service.
  * By default, Kubernetes auto-assigns one from the cluster’s IP range.

* **`--external-ip=<IP>`**

  * Specifies one or more external IP addresses that will accept traffic for the Service.
  * These IPs are **not managed by Kubernetes** (they must already exist in your network).
  * Commonly used in bare-metal setups where a real load balancer is not available.

**5. Label and Selector Behavior**

* Kubernetes Services route traffic to Pods using a **label selector**.
* By default, `kubectl expose` will automatically use the selector from the resource being exposed (e.g., a Deployment’s `spec.selector.matchLabels`).
* **If the Pod or resource has no labels, `kubectl expose` fails** with an error like:

  ```
  error: the pod has no labels and cannot be exposed
  ```
* Use `--selector=<key=value>` if you want to override the default selector.

**6. Behavior of Repeated Flags**

* If you pass the same flag multiple times (e.g., multiple `--port` flags), **the last one overrides all previous values**.
* Example:

  ```bash
  kubectl expose pod mypod --port=80 --port=443
  ```

  Only port `443` is used in the final Service spec.

**7. Additional Notes**

* Services always get a **ClusterIP** unless explicitly configured otherwise.
* External access is usually provided by **NodePort, LoadBalancer, or Ingress**, not by `ClusterIP`.
* Using `-f FILENAME` is often better in production because it allows you to version-control the Service definition.
* `kubectl expose` is a **shortcut for quick testing**, not a replacement for declarative manifests.

---

## Ingress Resource

- The **Ingress resource** defines how external HTTP/S traffic is routed to the services inside your Kubernetes cluster. It includes the domain, path routing rules, and TLS (SSL) configurations.

- It also contains the references to the Ingress controller (e.g., NGINX) and any specific configurations for TLS certificates (via `ClusterIssuer`).

```bash
kubectl create ingress NAME --class <> --annotation <>
    --rule ibtisam-iq.com/=svc1:8080,tls=my-cert    # TLS       # Exact
    --rule ibtisam-iq.com/=svc2:8081                # Non-TLS   # Exact
    --rule ibtisam-iq.com/*=svc3:8082               # Wildcard  # Prefix
```

## Ingress Controller (NGINX Ingress controller)

- The **Ingress controller** is the **actual component** that processes the **Ingress resources** and routes the incoming HTTP/S traffic to the backend services in your cluster.
- The **NGINX Ingress controller** is the most commonly used controller, and it can be deployed as a Kubernetes deployment or pod.
- It listens to changes in the Ingress resources and implements the routing rules specified in the resources.
- It can also handle TLS termination and load balancing.
- Run the following command to list the pods and see if there's a pod related to the Ingress controller:
```bash
kubectl get pods -n kube-system
```
Look for something like `nginx-ingress-controller` in the pod name. If you see this, then the NGINX Ingress controller is deployed.

> 📌 **Note:** If you don't see any relevant pod, you can deploy the **NGINX Ingress controller** manually using the following steps (via Helm or YAML).
```bash
# Add the NGINX ingress controller repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update the Helm repository to get the latest charts
helm repo update

# Install the NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx
```
Alternatively, you can apply the NGINX Ingress controller directly using a YAML manifest:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

### Ingress Access & Testing

**1. Ingress without `host`**

If the Ingress resource does **not** specify a host:

```bash
curl http://<node-IP>:<nodePort>/<path>
```

* `<node-IP>` can be any cluster node (including controlplane).
* `<nodePort>` is the port exposed by the ingress controller’s Service.

**2. Ingress with `host`**

If the Ingress resource **does** specify a host:

### ✅ Most Reliable Method (always works)

```bash
curl -H "Host: <host-from-ingress>" http://<node-IP>:<nodePort>/<path>
```

* Forces the `Host` header to match the Ingress rule.

### ➕ Optional (requires DNS or `/etc/hosts` entry)

```bash
curl http://<host-from-ingress>:<nodePort>/<path>
curl http://<host-from-ingress>/<path>
```

* Works only if the hostname resolves correctly (e.g., via `/etc/hosts` or DNS).

**3. Ingress via LoadBalancer (if available)**

If the ingress controller Service type is `LoadBalancer`:

```bash
curl http://<loadbalancer-IP>/<path>
```

| Ingress Mode     | Shown PORT |
| ---------------- | ---------- |
| No TLS (HTTP)    | **80**     |
| With TLS (HTTPS) | **443**    |

```bash
controlplane ~ ➜  k get ingress -n test-1
NAME   CLASS     HOSTS           ADDRESS   PORTS     AGE
abc    nginx     ibt-sam.local             80, 443   50m

controlplane ~ ➜  k get ingress -n test-2
NAME   CLASS     HOSTS             ADDRESS   PORTS   AGE
abc    traefik   ibt-sam-2.local             80      48m

controlplane ~ ➜  curl -H "Host: ibt-sam.local" http://192.168.102.145:31338
<html>
<head><title>308 Permanent Redirect</title></head>
</html>

controlplane ~ ➜  curl --resolve ibt-sam.local:31338:192.168.102.145 http://ibt-sam.local:31338
<html>
<head><title>308 Permanent Redirect</title></head>
</html>

controlplane ~ ➜  curl --resolve ibt-sam.local:30768:192.168.102.145 https://ibt-sam.local:30768 -k
love you my sweetheart, ibtisam
```

---


## ClusterIssuer

- The **ClusterIssuer** (or **Issuer**) is used to manage **SSL/TLS certificates**. In production, you usually want traffic to be **secure** using HTTPS, which means using an SSL/TLS certificate.
- The **ClusterIssuer** is usually backed by **Let's Encrypt** (or another Certificate Authority) to automatically manage the certificates.
- The **cert-manager** is the component that integrates with the **ClusterIssuer** to automate the process of obtaining, renewing, and managing SSL/TLS certificates.

---

## Horizontal Pod Autoscaler (HPA)
- Creates an autoscaler that automatically chooses and sets the number of pods that run in a Kubernetes cluster.
- Looks up a **deployment**, **replicaset**, **statefulset**, or **replicationcontroller** by name and creates an autoscaler that uses the given **resource** as a reference.
- The autoscaler will automatically scale the number of replicas up or down based on the **CPU utilization** of the pods.

```bash
kubectl autoscale (-f FILENAME | TYPE NAME | TYPE/NAME) # Three different ways to specify the target resource
    --name NAME
    [--min=MINPODS] --max=MAXPODS 
    [--cpu-percent=CPU]
    [--namespace=NAMESPACE]
```
### Examples

```bash
# Specify the path to a YAML file that defines the target resource (e.g., deployment, replicaset, etc.).
kubectl autoscale -f deployment.yaml --min=2 --max=10 --cpu-percent=80

# Specify the type and name of the target resource.
kubectl autoscale deployment my-deployment --min=2 --max=10 --cpu-percent=80
kubectl autoscale deployment/my-deployment --min=2 --max=10 --cpu-percent=80

# Specify the type and name of the target resource, and the namespace where the resource is located.
kubectl autoscale deployment my-deployment --namespace=my-namespace --min=2 --max=10 --cpu-percent=80

# Specify the type and name of the target resource, and the namespace where the resource is located, and the name of the autoscaler.
kubectl autoscale deployment my-deployment --namespace=my-namespace --min=2 --max=10 --cpu-percent=80 --name=my-autoscaler

# Specify the type and name of the target resource, and the namespace where the resource is located, and the name of the autoscaler, and the path to a YAML file that defines the target resource ( e.g., deployment, replicaset, etc.).
kubectl autoscale -f deployment.yaml --namespace=my-namespace --min=2 --max=10 --cpu-percent=80 --name=my-autoscaler
```
---

## Resource Quota Management

```bash
# Create a new resource quota named my-quota
kubectl create quota NAME --hard cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1 -n <> \
    --scopes BestEffort,Scope2
```

```bash
kubectl create quota abc --hard cpu=1,memory=512Mi,
requests.cpu=4,limits.cpu=8,requests.memory=8Gi,limits.memory=16Gi,
requests.storage=100Gi,persistentvolumeclaims=10,
pods=20,services=20,configmaps=20,secrets=20,replicationcontrollers=4,resourcequotas=1,services.nodeports=2,
count/deployments.apps=10,count/replicasets.apps=10,count/statefulsets.apps=10,count/jobs.batch=10
```

---

## PriorityClass

Create a priority class with the specified name, value, globalDefault and description.

```bash
kubectl create pc NAME --value=VALUE --global-default=BOOL --description=''					# Namespaced: false
    --preemption-policy 'PreemptLowerPriority' | 'PreemptNoPriority' | 'PreemptNoSchedule'	# default: PreemptLowerPriority
```

---

## PodDisruptionBudget

Create a pod disruption budget with the specified name, selector, and desired minimum available pods.

```bash
kubectl create poddisruptionbudget NAME --selector=SELECTOR --min-available=N [--dry-run=server|client|none] [options]
```
---

## `kubectl apply` (refer quick ref)

## `kubectl rollout`

Manage the rollout of one or many resources. 
- Valid resource types include: deployments, daemonsets, statefulsets

```bash
kubectl rollout history (TYPE NAME | TYPE/NAME) -l, --selector --revision=0
kubectl rollout pause|resume|restart (TYPE NAME | TYPE/NAME) -l, --selector
kubectl rollout status (TYPE NAME | TYPE/NAME) -l, --selector --revision=0 -w, --watch=true
kubectl rollout undo (TYPE NAME | TYPE/NAME) -l, --selector --dry-run='none' --to-revision=0
kubectl annotate deploy <> kubernetes.io/change-cause="Updated to nginx:1.29.1"
```

## `kubectl scale`

Set a new size for a deployment, replica set, replication controller, or stateful set.

```bash
kubectl scale (-f FILENAME | TYPE NAME) [--resource-version=version] [--current-replicas=count] --replicas=COUNT -l, --selector='' --dry-run='none' 
```

## `kubectl port-forward`

```bash
# Listen on port 5000 on the local machine and forward to port 6000 on my-pod
kubectl port-forward my-pod 5000:6000 
# listen on local port 5000 and forward to port 5000 on Service backend
kubectl port-forward svc/my-service 5000                  
# listen on local port 5000 and forward to Service target port with name <my-service-port>
kubectl port-forward svc/my-service 5000:my-service-port
# listen on local port 5000 and forward to port 6000 on a Pod created by <my-deployment>
kubectl port-forward deploy/my-deployment 5000:6000
```

## `kubectl taint nodes`
Update the taints on one or more nodes.

- `kubectl taint nodes` adds or updates taints on one or more nodes.
- A taint is expressed as: `key[=value]:effect`

* **Key**: required, must start with letter/number, max 253 chars.
* **Value**: optional, if present max 63 chars.
* **Effect**: required → `NoSchedule` | `PreferNoSchedule` | `NoExecute`.
* **Operator**:
  * `key=value:effect` → Equal
  * `key:effect` → Exists

👉 Taints currently apply only to **nodes**.

```bash
kubectl taint NODE NAME KEY_1=VAL_1:TAINT_EFFECT_1 ... KEY_N=VAL_N:TAINT_EFFECT_N [options]
```

#### Examples

Please see `kubectl taint nodes --help`.

## `kubectl label|annotate`
Update the labels on a resource.

- **Key & Value**: must start with letter/number, max 63 chars.
- If `--overwrite` is true, then existing labels can be overwritten, otherwise attempting to overwrite a label will result in an error.
- If `--resource-version` is specified, then updates will use this resource version, otherwise the existing resource-version will be used.

```bash
kubectl label [--overwrite] (-f FILENAME | TYPE NAME) KEY_1=VAL_1 ... KEY_N=VAL_N [--resource-version=version]
[options]

kubectl annotate [--overwrite] (-f FILENAME | TYPE NAME) KEY_1=VAL_1 ... KEY_N=VAL_N [--resource-version=version]
[options]
```

#### Examples

Please see `kubectl label --help` and `kubectl annotate --help`.

## `kubectl logs`
Print the logs for a `container` in a **pod** or **specified resource**. If the pod has only one container, the container name is optional. 

```bash
kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER] [options]
```
| Use Case | Command |
|----------|---------|
| Single Container | `kubectl logs pod-name` |
| Multi-Container | `--all-containers=true` |
| Stream Logs | `-f` |
| Previous Logs | `-p` |
| Filter by Label | `-l app=name` |
| Resource Type (Job/Deployment) | `job/name`, `deployment/name` |
| Time-based | `--since=1h`, `--since-time=` |
| TLS Skip | `--insecure-skip-tls-verify-backend` |
| Limit Output | `--limit-bytes`, `--tail` |

## `kubectl auth`
```bash
# kubectl auth can-i <verb> <resource>
kubectl auth whoami
kubectl auth can-i list pods --as <user>
kubectl auth can-i list pods --as-group <> --as <user>
# kubectl auth can-i list pods --as=system:serviceaccount:<ns name>:<sa name>
kubectl auth can-i list pods --as system:serviceaccount:ibtisam:ibtisam -n ibtisam
```

## `kubectl set`

```bash
controlplane ~ ➜  k set --help

Available Commands:
  env              Update environment variables on a pod template
  image            Update the image of a pod template
  resources        Update resource requests/limits on objects with pod templates
  selector         Set the selector on a resource
  serviceaccount   Update the service account of a resource
  subject          Update the user, group, or service account in a role binding or cluster role binding

kubectl set image (-f FILENAME | TYPE NAME) CONTAINER_NAME_1=CONTAINER_IMAGE_1 ... CONTAINER_NAME_N=CONTAINER_IMAGE_N
[options]
```

## `kubectl exec`

```bash
controlplane ~ ➜  k exec -it -n kube-system etcd-controlplane -- etcd --version
etcd Version: 3.6.4
Git SHA: 5400cdc
Go Version: go1.23.11
Go OS/Arch: linux/amd64

controlplane ~ ➜  k exec -n kube-system etcd-controlplane -- etcd --version
etcd Version: 3.6.4
Git SHA: 5400cdc
Go Version: go1.23.11
Go OS/Arch: linux/amd64

controlplane ~ ➜  k exec -it -n kube-system etcd-controlplane -- sh
sh-5.2# exit                                                                                                                                                          
exit

controlplane ~ ➜  k exec -it -n kube-system kube-apiserver-controlplane -- kube-apiserver --version
Kubernetes v1.34.0

controlplane ~ ➜  k exec -it -n kube-system kube-apiserver-controlplane -- kube-apiserver -h
Usage:
  kube-apiserver [flags]
```
