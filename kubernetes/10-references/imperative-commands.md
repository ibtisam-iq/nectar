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
    curl -sL https://raw.githubusercontent.com/ibtisam-iq/SilverInit/main/k8s-kind-calico.sh | sudo bash
    ```

**3. `kubeadm`**

- First control-plane initialization
    ```bash
    curl -sL https://raw.githubusercontent.com/ibtisam-iq/SilverInit/main/K8s-Control-Plane-Init.sh | sudo bash
    ```

- Worker node initialization
    ```bash
    curl -sL https://raw.githubusercontent.com/ibtisam-iq/SilverInit/main/K8s-Node-Init.sh | sudo bash
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
kubectl run <> --image kodekloud/webapp-color --dry-run=client -o yaml -- --color red # Parsed as two args: ["--color", "red"]

# Override the Command and Arguments
kubectl run nginx --image=nginx --restart=Never --command -- /bin/sh -c "echo Hello Sweetheart, Ibtisam; sleep 10"
kubectl run <> --image kodekloud/webapp-color --dry-run=client -o yaml --command -- color red
kubectl run <> --image busybox --dry-run client -o yaml --command -- sleep 1000			# wrong
kubectl run <> --image busybox --dry-run=client -o yaml --command -- sleep 1000			# right

# Start a busybox pod and keep it in the foreground, don't restart it if it exits
kubectl run -i -t busybox --image=busybox --restart=Never
```

- `--expose` **is valid** in `kubectl run`, but **only creates a ClusterIP service**.
- Requires `--port`, otherwise, Kubernetes won't know what port to expose.
- Useful for **quick testing** but not flexible for customizing the Service.
- For external access, manually expose the Pod using `kubectl expose` and change `--type` to `NodePort` or `LoadBalancer`.
- If more than one `--port` or `--image` flag is mentioned, the last `--port` or `--image` flag overrides all first mentioned `--port` and `--image` flags.
- The `--` separator indicates that everything after it (`-- sleep 1000`) is passed as arguments to the container. `-- sleep 1000` is interpreted as two separate arguments: `sleep` and `1000`. To pass a single argument, use quotes: `-- "sleep 1000"`.
- Use `--command --` to define custom commands in containers.
- The `command` field overrides the container image’s default **entrypoint**.
- When using `--command`, both command and arguments must be explicitly defined.

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

# controlplane ~ ➜  kubectl create deployment my-dep --image=busybox:latest --image=ubuntu:latest --image=nginx --dry-run=client -o yaml -- date
error: cannot specify multiple --image options and command
```
- `--image=[]`: Image names to run. A deployment can have multiple images set for multi-container pod.
- `kubectl create deployment` treats arguments after `--` as the container’s command, replacing the image’s default ENTRYPOINT. However, `kubectl run` interprets arguments after `--` as **arguments** to the container’s Entrypoint (not the command itself, and replacing ENTRYPOINT), unless `--command` is specified.

---

## kubectl scale

Manage the rollout of one or many resources. Valid resource types include: deployments, daemonsets, statefulsets

```bash
kubectl rollout history (TYPE NAME | TYPE/NAME) -l, --selector --revision=0
kubectl rollout pause|resume|restart (TYPE NAME | TYPE/NAME) -l, --selector
kubectl rollout status (TYPE NAME | TYPE/NAME) -l, --selector --revision=0 -w, --watch=true
kubectl rollout undo (TYPE NAME | TYPE/NAME) -l, --selector --dry-run='none' --to-revision=0
```

## kubectl scale

Set a new size for a deployment, replica set, replication controller, or stateful set.

```bash
kubectl scale [--resource-version=version] [--current-replicas=count] --replicas=COUNT -l, --selector='' --dry-run='none' (-f FILENAME | TYPE NAME)
```

## kubectl autoscale

Creates an autoscaler that automatically chooses and sets the number of pods that run in a Kubernetes cluster.

```bash
kubectl autoscale (-f FILENAME | TYPE NAME | TYPE/NAME) [--min=MINPODS] --max=MAXPODS [--cpu-percent=CPU] --name='' --dry-run='none'
```

---

## Jobs & CronJobs
```bash
kubectl create job NAME --image=image \
    -- [COMMAND] [args...] \
    --from=cronjob/name     # create a job from a cron job

kubectl create cronjob NAME --image=image --schedule='0/5 * * * ?' \
    --restart \     # supported values: OnFailure, Never
    -- [COMMAND] [args...] [flags] [options] 
```

In commands like `kubectl create cronjob`, the format `-- [COMMAND] [args...] [flags] [options]` dictates what runs inside the container:

- **COMMAND**: The program that runs inside the container (e.g., `echo`, `sh`, `python`)
- **args...**: Arguments passed to the command (e.g., "Hello, Kubernetes!")
- **flags**: Command-specific flags inside the container (e.g., `-c` for `sh`)
- **options**: Extra settings for the command inside the container (e.g., `--verbose`)

Example:
```sh
kubectl create cronjob my-cronjob --image=busybox --schedule="*/5 * * * *" -- echo "Hello, Kubernetes!"
```
Here, `echo "Hello, Kubernetes!"` runs inside the container every 5 minutes.

> error: either `--image` or `--from` must be specified
---

## [ConfigMap]() and Secret

```bash
kubectl create configmap NAME \
    --from-file=path/to/bar \ # bar is directory
    --from-file=path/to/bar \ # bar is file
    --from-file=key1=/path/to/file1.txt --from-file=key2=/path/to/file2.txt \
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
---

## Persistent Volume (PV), Persistent Volume Claim (PVC) and StorageClass

---

## Namespace
```bash
kubectl create ns NAME [--dry-run=server|client|none] [options]
kubectl config view --minify --output yaml | grep namespace:
```
---

## Service Account & Token
```bash
# create a service account with the specified name
kubectl create sa my-service-account

# Request a service account token
kubectl create token SERVICE_ACCOUNT_NAME
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

---

## Service

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
- `-f, --filename=[]`: Filename, directory, or URL to files identifying the resource to expose a service
- `TYPE` → The type of the resource you want to expose e.g. `pod (po)`, `service (svc)`, `replicationcontroller (rc)`, `deployment (deploy)`, `replicaset (rs)`.
- `NAME` → The specific name of the resource instance.
- `--port=<port>` defines the port on the Service that clients will use to access it. This port is exposed by the Service and directs traffic to the underlying Pods. Mandatory!
- `--target-port=''`: Name or number for the port on the container that the service should direct traffic to. (default: same as `--port`)
- `--type=''`: ClusterIP, NodePort, LoadBalancer, or ExternalName. Default is 'ClusterIP'.
- Kubernetes assigns an **internal cluster IP** to Services. However, if you want a specific external IP (e.g., a public IP from your cloud provider or a static IP in your network), you can set it manually using `--external-ip`.
- Use `-f FILENAME` to specify a resource definition file instead of `TYPE NAME`.
- If the pod doesn’t have a label, `kubectl expose` command wouldn’t work. `error: the pod has no labels and cannot be exposed.`
- If omitted, `kubectl expose` automatically derives the selector from the exposed resource (e.g., a Deployment’s `spec.selector.matchLabels`). It’s only needed when you want to override the default selector.
- `--cluster-ip=''` specifies the internal IP address for a **ClusterIP** Service. The Service’s `spec.clusterIP` field is set to this value, determining how it’s addressed within the cluster.
- `--external-ip=''` specifies an additional external IP address (not managed by Kubernetes) that can accept traffic for the Service. This is added to the `spec.externalIPs` field.
    - **Default:** No external IPs are assigned by default. External access is typically handled by Service types like **NodePort** or **LoadBalancer**, or by Ingress.

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
## ClusterIssuer

- The **ClusterIssuer** (or **Issuer**) is used to manage **SSL/TLS certificates**. In production, you usually want traffic to be **secure** using HTTPS, which means using an SSL/TLS certificate.
- The **ClusterIssuer** is usually backed by **Let's Encrypt** (or another Certificate Authority) to automatically manage the certificates.
- The **cert-manager** is the component that integrates with the **ClusterIssuer** to automate the process of obtaining, renewing, and managing SSL/TLS certificates.

```bash

```

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
kubectl create quota NAME --hard cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10 --namespace <> \
    --scopes BestEffort,Scope2
```

```bash
kubectl create quota abc --hard cpu=1,memory=512Mi,
requests.cpu=4,limits.cpu=8,requests.memory=8Gi,limits.memory=16Gi,
requests.storage=100Gi,persistentvolumeclaims=10,
pods=20,services=20,configmaps=20,secrets=20,replicationcontrollers=4,services.nodeports=2,
count/deployments.apps=10,count/replicasets.apps=10,count/statefulsets.apps=10,count/jobs.batch=10
```

---

## PriorityClass

Create a priority class with the specified name, value, globalDefault and description.

```bash
kubectl create priorityclass NAME --value=VALUE --global-default=BOOL --description=''
    --preemption-policy 'PreemptLowerPriority' | 'PreemptNoPriority' | 'PreemptNoSchedule'
```

---

## PodDisruptionBudget

Create a pod disruption budget with the specified name, selector, and desired minimum available pods.

```bash
kubectl create poddisruptionbudget NAME --selector=SELECTOR --min-available=N [--dry-run=server|client|none] [options]
```
---

## kubectl taint nodes
Update the taints on one or more nodes.

- A taint consists of a key, value, and effect. As an argument here, it is expressed as key=value:effect.
- The key must begin with a letter or number, and may contain letters, numbers, hyphens, dots, and underscores, up to
253 characters.
- Optionally, the key can begin with a DNS subdomain prefix and a single '/', like example.com/my-app.
- The value is optional. If given, it must begin with a letter or number, and may contain letters, numbers, hyphens,
dots, and underscores, up to 63 characters.
- The effect must be NoSchedule, PreferNoSchedule or NoExecute.
- Currently taint can only apply to node.

```bash
kubectl taint NODE NAME KEY_1=VAL_1:TAINT_EFFECT_1 ... KEY_N=VAL_N:TAINT_EFFECT_N [options]
```

### Examples

Please see `kubectl taint nodes --help`.

---

## kubectl label|annotate
Update the labels on a resource.

- A label key and value must begin with a letter or number, and may contain letters, numbers, hyphens, dots, and
underscores, up to 63 characters each.
- Optionally, the key can begin with a DNS subdomain prefix and a single '/', like example.com/my-app.
- If `--overwrite` is true, then existing labels can be overwritten, otherwise attempting to overwrite a label will
result in an error.
- If `--resource-version` is specified, then updates will use this resource version, otherwise the existing
resource-version will be used.

```bash
kubectl label [--overwrite] (-f FILENAME | TYPE NAME) KEY_1=VAL_1 ... KEY_N=VAL_N [--resource-version=version]
[options]

kubectl annotate [--overwrite] (-f FILENAME | TYPE NAME) KEY_1=VAL_1 ... KEY_N=VAL_N [--resource-version=version]
[options]
```

### Examples

Please see `kubectl label --help` and `kubectl annotate --help`.

---

## kubectl logs
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

---


## Frequently Used Flags

--dry-run='none':
	Must be "none", "server", or "client".
-o, --output='':
	Output format. One of: (json, yaml).
--save-config=false:
	If true, the configuration of current object will be saved in its annotation.


## kubectl apply (should add in quick ref)

## kubectl port-forward

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

## kubectl auth
```bash
# kubectl auth can-i <verb> <resource>
kubectl auth whoami
kubectl auth can-i list pods --as <user>
kubectl auth can-i list pods --as-group <> --as <user>
# kubectl auth can-i list pods --as=system:serviceaccount:<ns name>:<sa name>
kubectl auth can-i list pods --as system:serviceaccount:ibtisam:ibtisam -n ibtisam
```
