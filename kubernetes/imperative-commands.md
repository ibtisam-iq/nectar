# Managing Kubernetes Objects Using Imperative Commands

### Official Documentation

- https://kubernetes.io/docs/reference/kubectl/kubectl/ # this one
- https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/imperative-command/

### Important Points

- Kubernetes supports both `--flag=value` and `--flag value` formats.

---

## Pod
Create and run a particular image.

```bash
kubectl run <name> --image=<image> \
    --port=<port> \
    --expose =<expose> \
    -l, --labels=<key>=<value>,<key>=<value> \
    --env=<key>=<value> --env=<key>=<value> \
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
kubectl run <> --image kodekloud/webapp-color --dry-run=client -o yaml -- --color red

# Override the Command and Arguments
kubectl run nginx --image=nginx --command -- /bin/sh -c "echo Hello Sweetheart, Ibtisam"
kubectl run <> --image kodekloud/webapp-color --dry-run client -o yaml --command -- color red
kubectl run <> --image busybox --dry-run client -o yaml --command -- sleep 3600

# Start a busybox pod and keep it in the foreground, don't restart it if it exits
kubectl run -i -t busybox --image=busybox --restart=Never
```

- `--expose` **is valid** in `kubectl run`, but **only creates a ClusterIP service**.
- Requires `--port`, otherwise, Kubernetes won't know what port to expose.
- Useful for **quick testing** but not flexible for customizing the Service.
- For external access, manually expose the Pod using `kubectl expose` and change `--type` to `NodePort` or `LoadBalancer`.
- **Use `--command --` to define custom commands in containers.**
- **When using `--command`, both command and arguments must be explicitly defined.**

---

## Deployment
Create a deployment with the specified name

```bash
kubectl create deployment <name> --image=<image> \
    -r, --replicas=1 \
    --port=80 \
    -l, --labels=<key>=<value>,<key>=<value> \
    --env=<key>=<value> --env=<key>=<value> \
    -n, --namespace=<namespace> \
    -- <arg1> <arg2> ... <argN> \   
    --command -- <cmd> <arg1> ... <argN> \
    --save-config
```
### Example

```bash
# Create a deployment named my-dep that runs the busybox image
kubectl create deployment my-dep --image busybox -r 3 --port 3000

# Create a deployment with a command
kubectl create deployment my-dep --image=busybox -- date

# Create a deployment named my-dep that runs multiple containers
kubectl create deployment my-dep --image=busybox:latest --image=ubuntu:latest --image=nginx
```
- `--image=[]`: Image names to run. A deployment can have multiple images set for multi-container pod.

---

## Service

```bash
kubectl create service clusterip|externalname|loadbalancer|nodeport NAME --tcp=port:targetPort

kubectl expose (-f FILENAME | TYPE NAME) --port=<> \
    --target-port=<port> \
    --name=<name> \
    --type=<type> \
    --protocol=<protocol> \ # Sets TCP, UDP, or SCTP (default: TCP)
    --external-ip=<IP>
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
---

## ConfigMap and Secret

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

## Jobs & CronJobs
```bash
kubectl create job NAME --image=image \
    -- [COMMAND] [args...] \
    --from=cronjob/name     # create a job from a cron job named "a-cronjob" 

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

---

## Resource Quota Management

```bash
# Create a new resource quota named my-quota
kubectl create quota NAME --hard cpu=1,memory=1G,pods=2,services=3,replicationcontrollers=2,resourcequotas=1,secrets=5,persistentvolumeclaims=10 --namespace <> \
    --scopes BestEffort,Scope2
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

## Role and RoleBinding
## ClusterRole and ClusterRoleBinding

```bash
# Create a role named "pod-reader" that allows user to perform "get", "watch" and "list" on pods
kubectl create role pod-reader --verb=get,list,watch --resource=pods
  
# Create a role named "pod-reader" with ResourceName specified
kubectl create role pod-reader --verb=get --resource=pods --resource-name=readablepod,anotherpod
  
# Create a role named "foo" with API Group specified
kubectl create role foo --verb=get,list,watch --resource=rs.apps
  
# Create a role named "foo" with SubResource specified
kubectl create role foo --verb=get,list,watch --resource=pods,pods/status

kubectl create role NAME --verb=verb --resource=resource.group [--resource-name=resourcename]
[--dry-run=server|client|none] [options]

kubectl create clusterrole NAME --verb=verb --resource=resource.group [--resource-name=resourcename]
[--dry-run=server|client|none] [options]

kubectl create rolebinding|clusterrolebinding NAME --clusterrole=NAME|--role=NAME [--user=username1,username2] [--group=groupname] [--serviceaccount=namespace:serviceaccountname] [--dry-run=server|client|none] [options]
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

---

## Namespace

## Taints, Toleration, Node Selector, Node Affinity

## Ingress
```bash
kubectl create ingress NAME --class <> --annotations <>
    --rule ibtisam-iq.com/=svc1:8080,tls=my-cert    # TLS       # Exact
    --rule ibtisam-iq.com/=svc2:8081                # Non-TLS   # Exact
    --rule ibtisam-iq.com/*=svc3:8082               # Wildcard  # Prefix
```
## Frequently Used Flags

--dry-run='none':
	Must be "none", "server", or "client".
-o, --output='':
	Output format. One of: (json, yaml).
--save-config=false:
	If true, the configuration of current object will be saved in its annotation.


## kubectl apply (should add in quick ref)