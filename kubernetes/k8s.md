# Kubernetes Documentation 

## Kubernetes Architecture 

### Control Plane (Master Node): 
- **API Server** (kube-apiserver)
- **etcd**
- **Scheduler** (kube-scheduler)
- **Controller Manager**

### Worker Nodes:
- **Kubelet**
- **Kube-proxy**
- **Container Runtime**

Useful links:
- [Play with Kubernetes](https://labs.play-with-k8s.com/)
- [KillerCoda](https://killercoda.com/)

---

## Kubernetes Cluster Setup Tools

### Kind
- [Kind Documentation](https://kind.sigs.k8s.io/)

#### Commands:
```bash
kind create/delete cluster [flags]

--config string           path to a kind config file

-h, --help                help for cluster

--image string            node docker image to use for booting the cluster

-n, --name string         cluster name, overrides KIND_CLUSTER_NAME (default kind)

--retain                  retain nodes for debugging when cluster creation fails

--wait duration           wait for control plane node to be ready (default 0s)

kind create cluster --name <ibtisam>            # Ensuring node image (kindest/node:v1.30.0)
kind create cluster --name <ibtisam> --image <abc>
kind create cluster --config /path/to/file
kind get clusters/nodes/kubeconfig
kind delete cluster --name ibtisam  # Delete to recreate; no restart command.
```

### Minikube
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/start/)

```bash
systemctl stop docker; systemctl stop docker.socket; systemctl --user stop docker-desktop
lsmod | grep kvm; sudo modprobe -r kvm kvm_intel; sudo reboot

minikube start --driver virtualbox
minikube start --driver docker

minikube status/start/stop/delete/dashboard/pause/unpause

minikube addons enable metrics-server 	# for minikube	
# only one Metrics Server for one cluster whether minikube or other.
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml # install Metrics-server	
kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```
#### Minikube Context Setup
```bash
kubectl config get-contexts # to get all available clusters
kubectl config get-clusters		
kubectl cluster-info
kubectl config use-context <minikube>	# use, not set			
kubectl config use-context <kind-ibtisam>
kubectl config current-context					            
kubectl cluster-info --context $(kubectl config current-context)
kubectl config view
kubectl config delete-context kind-ibtisam		            
kubectl config delete-cluster kind-ibtisam
kubectl config set-context <context-name> --cluster=<cluster-name> --user=<user-name> --namespace=<namespace>
```

#### Notes:
- Minikube requires a container or virtual machine manager (Docker, QEMU, VirtualBox, etc.)
- **Steps:**
  1. `get-clusters`
  2. `use-context minikube`
  3. `current-context`
  4. `minikube start --driver virtualbox`

Kubectl will be configured to use the "minikube" cluster and "default" namespace by default.

---

## Kubernetes CLI Tools

### Kubectl
- [Install Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
kubectl version
kubectl version --client false -o yaml
```

#### Basic Commands:
```bash
Beginner:
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects
Intermediate:
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and label selector
Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller		--replicas=0
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller
Cluster Management Commands:
  certificate     Modify certificate resources
  cluster-info    Display cluster information
  top             Display resource (CPU/memory) usage
  cordon          Mark node as unschedulable
  uncordon        Mark node as schedulable
  drain           Drain node in preparation for maintenance
  taint           Update the taints on one or more nodes
Troubleshooting and Debugging Commands:
  describe        Show details of a specific resource or group of resources
  logs            Print the logs for a container in a pod
  attach          Attach to a running container
  exec            Execute a command in a container
  port-forward    Forward one or more local ports to a pod
  proxy           Run a proxy to the Kubernetes API server
  cp              Copy files and directories to and from containers
  auth            Inspect authorization
  debug           Create debugging sessions for troubleshooting workloads and nodes
  events          List events
Advanced Commands:
  diff            Diff the live version against a would-be applied version
  apply           Apply a configuration to a resource by file name or stdin
  patch           Update fields of a resource
  replace         Replace a resource by file name or stdin
  wait            Experimental: Wait for a specific condition on one or many resources
  kustomize       Build a kustomization target from a directory or URL
Settings Commands:
  label           Update the labels on a resource
  annotate        Update the annotations on a resource
  completion      Output shell completion code for the specified shell (bash, zsh, fish, or powershell)
Other Commands:
  api-resources   Print the supported API resources on the server
  api-versions    Print the supported API versions on the server, in the form of "group/version"
  config          Modify kubeconfig files
  plugin          Provides utilities for interacting with plugins
  version         Print the client and server version information
```
---

### Resources:
- Cluster
- Pod (po)
- Deployment (deploy)
- Service (svc)
- Namespace (ns)
- ConfigMap (cm)
- Secret


**kubectl commands**
```bash
Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller		--replicas=0
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller

Cluster Management Commands:
  certificate     Modify certificate resources
  cluster-info    Display cluster information
  top             Display resource (CPU/memory) usage
  cordon          Mark node as unschedulable
  uncordon        Mark node as schedulable
  drain           Drain node in preparation for maintenance
  taint           Update the taints on one or more nodes

Troubleshooting and Debugging Commands:
  describe        Show details of a specific resource or group of resources
  logs            Print the logs for a container in a pod
  attach          Attach to a running container
  exec            Execute a command in a container
  port-forward    Forward one or more local ports to a pod
  proxy           Run a proxy to the Kubernetes API server
  cp              Copy files and directories to and from containers
  auth            Inspect authorization
  debug           Create debugging sessions for troubleshooting workloads and nodes
  events          List events

Advanced Commands:
  diff            Diff the live version against a would-be applied version
  apply           Apply a configuration to a resource by file name or stdin
  patch           Update fields of a resource
  replace         Replace a resource by file name or stdin
  wait            Experimental: Wait for a specific condition on one or many resources
  kustomize       Build a kustomization target from a directory or URL

Settings Commands:
  label           Update the labels on a resource
  annotate        Update the annotations on a resource
  completion      Output shell completion code for the specified shell (bash, zsh, fish, or powershell)

Other Commands:
  api-resources   Print the supported API resources on the server
  api-versions    Print the supported API versions on the server, in the form of "group/version"
  config          Modify kubeconfig files
  plugin          Provides utilities for interacting with plugins
  version         Print the client and server version information
```
**kubectl config commands**
```bash
current-context   Display the current-context
delete-cluster    Delete the specified cluster from the kubeconfig
delete-context    Delete the specified context from the kubeconfig
delete-user       Delete the specified user from the kubeconfig
get-clusters      Display clusters defined in the kubeconfig
get-contexts      Describe one or many contexts
get-users         Display users defined in the kubeconfig
rename-context    Rename a context from the kubeconfig file
set               Set an individual value in a kubeconfig file
set-cluster       Set a cluster entry in kubeconfig
set-context       Set a context entry in kubeconfig
set-credentials   Set a user entry in kubeconfig
unset             Unset an individual value in a kubeconfig file
use-context       Set the current-context in a kubeconfig file
view              Display merged kubeconfig settings or a specified kubeconfig file
```

**kubectl create/apply/replace/run/expose/rollout/port-forward/config/taint/label/patch**
```bash
-f, --filename=[]                # Filename, directory, or URL to files identifying the resource to manage.
--force                          # Force the operation.
--dry-run=''                     # Must be "none", "server", or "client". Use to preview the operation without making changes.
-o, --output=''                  # Output format. Options: 'yaml' or 'json'.
-w, --watch=false                # Watch for changes after the operation.
-n, --namespace=[]               # Namespace to use for the operation.
-l, --labels=''                  # Comma-separated labels to apply to the resource. Will override previous values.
#                      Create
--edit=false                     # Edit the API resource before creating it.

--save-config                    # Save the configuration of the current object in its annotation. Useful for future kubectl apply operations.
#                      Run
--annotations=[]                 # Annotations to apply to the pod.

--attach=false                   # Wait for the Pod to start running, then attach to it. Default is false unless '-i/--stdin' is set.

--command=false                  # Use extra arguments as the 'command' field in the container, rather than the 'args' field.

--env=[]                         # Environment variables to set in the container.

--expose=false                   # Create a ClusterIP service associated with the pod. Requires `--port`.

--image=''                       # The image for the container to run.

--port=''                        # The port that this container exposes.

--privileged=false               # Run the container in privileged mode.

-q, --quiet=false                # Suppress prompt messages.

--restart='Always'               # The restart policy for this Pod. Legal values: [Always, OnFailure, Never].

--rm=false                       # Delete the pod after it exits. Only valid when attaching to the container.

-i, --stdin=false                # Keep stdin open on the container in the pod, even if nothing is attached.

-t, --tty=false                  # Allocate a TTY for the container in the pod.
#                       Expose    
--cluster-ip=''                  # ClusterIP to be assigned to the service. Leave empty to auto-allocate, or set to 'None' to create a headless service.

--external-ip=''                 # Additional external IP address (not managed by Kubernetes) to accept for the service.

--load-balancer-ip=''            # IP to assign to the LoadBalancer. If empty, an ephemeral IP will be created and used (cloud-provider specific).

--name=''                        # The name for the newly created object.

--protocol=''                    # The network protocol for the service to be created. Default is 'TCP'.

--selector=''                    # A label selector to use for this service. Only equality-based selector requirements are supported.

--target-port=''                 # Name or number for the port on the container that the service should direct traffic to. Optional.

--type=''                        # Type for this service: ClusterIP, NodePort, LoadBalancer, or ExternalName. Default is 'ClusterIP'.
```
**kubectl get/describe/delete/edit/exec/logs/set**
```bash
-A, --all-namespaces=false       # List the requested object(s) across all namespaces.

-n, --namespace=[]               # Namespace to use for the operation.

-f, --filename=[]                # Filename, directory, or URL to files identifying the resource to get from a server.

--no-headers=false               # When using the default or custom-column output format, don't print headers.

-o, --output=''                  # Output format. Options: 'wide'.

-l, --selector=''                # Selector (label query) to filter on, supports '=', '==', and '!='.

--show-kind=false                # List the resource type for the requested object(s).

--show-labels=false              # Show all labels as the last column when printing.
#                       Get
-w, --watch=false                # Watch for changes after listing/getting the requested object.

--watch-only=false               # Watch for changes to the requested object(s), without listing/getting first.

--all=false                      # Delete all resources, in the namespace of the specified resource types.

--force=false                    # Immediately remove resources from API and bypass graceful deletion.

--grace-period=-1                # Period of time in seconds given to the resource to terminate gracefully. Ignored if negative.

--ignore-not-found=false         # Treat "resource not found" as a successful delete. Defaults to "true" when --all is specified.

-i, --interactive=false          # Delete resource only when the user confirms.

--now=false                      # Signal resources for immediate shutdown.

--timeout=0s                     # The length of time to wait before giving up on a delete.

--wait=true                      # Wait for resources to be gone before returning. This waits for finalizers.
#                       Edit
--save-config=false              # Save the configuration of the current object in its annotation.
#                       Exec
-c, --container=''               # Container name. If omitted, use the default container or the first container in the pod.

-q, --quiet=false                # Only print output from the remote session.

-i, --stdin=false                # Pass stdin to the container.

-t, --tty=false                  # Stdin is a TTY.
#                       logs
--all-containers=false           # Get all containers' logs in the pod(s).

-c, --container=''               # Print the logs of this container.

-f, --follow=false               # Specify if the logs should be streamed.

--max-log-requests=5             # Specify maximum number of concurrent logs to follow when using by a selector. Defaults to 5.

--pod-running-timeout=20s        # The length of time to wait until at least one pod is running.

--prefix=false                   # Prefix each log line with the log source (pod name and container name).

-p, --previous=false             # Print the logs for the previous instance of the container in a pod if it exists.

--timestamps=false               # Include timestamps on each line in the log output.

--record=true                    # Record the current kubectl command in the resource annotation.

--selector app=frontend,env=dev --no-headers | wc -l  # Example of using a selector to filter resources and count them.
```
**above is done**

**Declarative Commands**

resources: Cluster, Pod (po), ReplicationController (rc), ReplicaSet (rs), Deployment (Deploy), Service (svc), Namespace (ns),	ResourceQuota (quota),	Job, ConfigMap (cm), Secret, ServiceAccount (sa), Role, RoleBinding, NetworkPolicy (netpol)

```bash
kubectl apply/create -f /filepath
kubectl replace -f /filepath --force		
kubectl get po --watch		
kubectl get po -o wide (internal IP & Node)	kubectl get po -A		
kubectl delete po --all
kubectl get/describe/edit/delete <object> <object name>	| grep -i label -7		| grep -i -A 1 -B 1 args		 after -B before
kubectl logs -f <pod name> -c <container name>
kubectl get/describe/edit/delete all,clusters,nodes,po,rc,rs,deploy,quota,cm,secret,svc,job,cronjob,sa,token,role,rolebinding
kubectl exec <pod name> -c <cont name> -- whoami    
kubectl exec -it <my-pod> -- sh	
docker exec -it <node name> /bin/sh
kubectl edit deploy/svc/job <name> --record
```
**kubectl create Available Commands:**

clusterrole, clusterrolebinding, configmap, cronjob, deployment, ingress, job, namespace, poddisruptionbudget, priorityclass, quota, role, rolebinding, secret, service, serviceaccount, token

**Imperative Commands**

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands  

**Pods**
```bash
kubectl run <pod name> --image <image name> # only if resource quota isn’t set

kubectl run my-pod --image=nginx --restart=Never --port=80 --labels="app=my-pod,env=production" --env="ENVIRONMENT=production" --namespace default --dry-run=client -o yaml > filename

kubectl replace -f <path-to-file.yaml> --force			
```
**Labels, Selectors & Annotations**

**Commands & Arguments**
- ENTRYPOINT [ "executable" ] = command, CMD = args
```bash				
kubectl run <> --image kodekloud/webapp-color --dry-run=client -o yaml -- --color red # command: python run main.py
kubectl run <> --image kodekloud/webapp-color --dry-run=client -o yaml --command -- color red
kubectl run <> --image=busybox --dry-run=client -o yaml --command -- sleep 3600
```
- Each container image may have a default command or script it runs when started. The command field lets you override that default behavior.

**Resource Quota & Management**
```bash
kubectl create quota <> --hard=cpu=4,memory=8Gi,pods=10,services=5,persistentvolumeclaims=2 --namespace=<> --dry-run=client
kubectl set resources pod <> --limits="cpu=500m,memory=128Mi" --requests="cpu=250m,memory=64Mi" --dry-run=client
```
- (1 core = 1000m), bytes (Ki, Mi, Gi for kilobytes, megabytes, and gigabytes)
- The kubectl run command no longer supports setting resource requests and limits directly. To achieve this, you can create a YAML manifest and apply it using kubectl apply, or you can modify the resource after the Pod has been created using kubectl set resources.

**Environment Variables, ConfigMaps & Secrets**
```bash
kubectl create cm abc --from-literal key=value --from-literal APP_COLOR=green --dry-run=client -o yaml	# From key-value pairs
kubectl create cm abc --from-file /home/ibtisam/k8s/10-1/cm.yaml --dry-run=client -o yaml			# From a file
kubectl create secret generic <> --from-literal	DB_Host=sq101 --from-literal DB_User=root --from-literal DB_Password=password123
echo -n 'value' | base64					
echo -n 'sq101' | base64					# Base64 encoded
echo 'base64_encoded_value' | base64 --decode		
echo 'c3ExMDE=' | base64 --decode
```
**Taints, Toleration, Node Selector, Node Affinity**
```bash
kubectl taint node <ibtisam-worker> flower=rose:NoSchedule		# associated with pod tolerations
kubectl taint node <ibtisam-worker> flower=rose:NoSchedule-	key=value:tainteffect					# remove the taint
kubectl describe node <ibtisam-control-plane> | grep -i taint -5
kubectl label node <ibtisam-worker2> cpu=large		# key=value	associated with nodeSelector & nodeAffinity 	cpu-
```

- A taint is a key-value pair applied to a node that instructs Kubernetes not to schedule pods on that node unless they tolerate the taint. A toleration is applied to a pod, allowing it to tolerate a specific taint. Tolerations only matter if the node is tainted. 
- If the node doesn't have any taints, the tolerations don't play a role, and the Pod will be scheduled normally.
- If a node is not tainted, and the Pod has tolerations, the Pod can still be scheduled on that node without any issue.
- If the node is tainted and the Pod doesn’t have matching tolerations the Pod will not be scheduled on that node.

Effect: The taint's behavior, which is one of:

- **NoSchedule:** Pods that don't tolerate the taint will not be scheduled on the node. 
- **PreferNoSchedule:** The scheduler will avoid placing pods that don't tolerate the taint on the node, but it's not guaranteed.
- **NoExecute:** Pods that don't tolerate the taint will be evicted from the node if they're already running.

**Node affinity** is a way to influence the scheduling of Pods onto specific nodes based on the node's labels. Node affinity is a more flexible and expressive version of nodeSelector, providing operators like In, NotIn, Exists, etc., for more complex scheduling rules. Pod won't be scheduled unless a node matches the label/affinity criteria. If no nodes have matching labels, the Pod stays pending.

**Types of Node Affinity**

**RequiredDuringSchedulingIgnoredDuringExecution (Hard Affinity):**
Pods must be scheduled onto nodes that satisfy the given node affinity rules. If no matching node is found, the Pod remains unscheduled.

**PreferredDuringSchedulingIgnoredDuringExecution (Soft Affinity):**
Kubernetes tries to place the Pod on a node that satisfies the preferred affinity rules, but if no matching node is found, the Pod is scheduled on any available node.

**RequiredDuringSchedulingRequiredDuringExecution (Future Proposal):**
This enforces the constraint that Pods should only be allowed to execute on nodes that continue to meet the specified rules (not implemented in Kubernetes as of now).

**Node Affinity Operators**

- In: The value of the node label must be one of the specified values.
- NotIn: The value of the node label must not be one of the specified values.
- Exists: The node must have the specified label, regardless of its value.
- DoesNotExist: The node must not have the specified label.
- Gt: The node's label value must be greater than a given value.
- Lt: The node's label value must be less than a given value.

**Readiness & Liveness**

Problem: The container is not running, traffic is not served, but the pod is marked as "Ready & Running" by K8s.

Use readiness probe to check if container becomes ready (starts running) to serve traffic.	If --, service point is removed.

Problem: Both pods are still marked as "Ready & Running" even though one of them is not serving traffic, the container crashed.

Use liveness probe to check if container is alive (running perfectly) to serve traffic.		If failed, the pod is restarted.

**Pod Status and Conditions**

Pods have statuses like Pending, Running, Completed, Failed, and Unknown, which represent the overall state of the pod.

Additionally, each pod has conditions that offer more detailed information about its state:

- PodScheduled: The Pod has been scheduled to a node.
- Initialized: All init containers have completed.
- Ready: The Pod is able to serve requests (readiness probe passed).
- ContainersReady: All containers in the Pod are ready.
- Unschedulable: The Pod could not be scheduled on any node.

**Container Logs**
```bash
kubectl logs -f <pod name> -c <container name>		
kubectl logs <pod> <con>
```
- logs are of the container(s), not a pod.

**Service**
```bash 
kubectl create service <type, small let> <name> --tcp=<port>:<targetPort> # <type>: ClusterIP, NodePort, LoadBalancer (avoid this command)
kubectl expose <resource> <name> --name <> --port=<> --target-port=<> --type=<service-type>	# <resource>: <deployment/replicaset/pod>
kubectl expose po <pod name> --name <svc name> --port=<> --target-port=<> --type <> --dry-run=client # (no pod labels, no expose)
```
- If the pod doesn’t have a label, ‘kubectl expose’ command wouldn’t work. error: the pod has no labels and cannot be exposed.

**SSH**
```bash
minikube ssh	
ssh username@ip		
docker exec -it <node name> </bin/bash> or <bash> or </bin/sh> or <sh>	jump into node
curl <pod_IP:service_port / service IP:servive_port>				# inside the node, whether ClusterIP or NodePort
kubectl port-forward svc/c-ip-svc host:svc_port > /dev/null 2>&1 &	# from outside, whether ClusterIP or NodePort, Port-forwarding, if different network
curl <node_ip:NordPort>	# from outside, NodePort, if Node_IP & localhost_IP (ip r l) share the same network.
host=svc	<service name>.<namespace>.svc.cluster.local (if diff namespace), connecting one pod to another within same/diff ns

# wlp6s0: 192.168.100.10		minikube: 192.168.59.100		ibtisam-worker: 172.18.0.3	docker0: 172.17.0.1	lo: 127.0.0.1 pod: 10.244.1.2			My IP Address is: IPv4: 439.195.86.299
```
**Deployment**
```bash
kubectl create deployment my-deployment --image=nginx:1.19.2 --replicas=3 --port=80 --labels="app=my-deployment,env=production" --env="ENVIRONMENT=production" --dry-run=client -o yaml | kubectl apply --record=true -f-  # <or --record>

kubectl create deploy <name> --image <name> -r 3 --port 3741 --record --dry-run=client -o yaml > filename

# REVISION: Each time you update the Deployment (e.g., by changing the image, replicas, or configuration), K8s creates a new revision.

kubectl edit deploy dp7xyz		# (change the image)	
kubectl scale deploy dp7xyz --replicas 6				# scale up/down
kubectl edit deploy dp7xyz --record	# (change the image) 	
kubectl set image deploy <> <ContainerName>=nginx:1.22-alpine --record
kubectl rollout status deploy dp7xyz				# real-time status; Successful rollout, Rolling updates, Error messages
kubectl rollout history deploy dp7xyz --revision <n>		# track the history of changes to your Deployment
kubectl rollout undo deploy dp7xyz --to-revision <n>
```
#### Namespace
```bash
kubectl get ns		# default 	kube-node-lease 	kube-public 		kube-system 		local-path-storage
kubectl create ns <ibtisam> --dry-run=client -o yaml
kubectl apply/delete <object> <object name> -n <namespace>		
kubectl get all -n <>			# 	specify -n <>
kubectl config get-contexts		
kubectl config view --minify --output yaml | grep namespace:		# current/verify
kubectl config set-context --current --namespace <>					# to modify
```
#### Jobs & CronJobs
```bash
kubectl create job <> --image=busybox --dry-run=client -o yaml -- sh -c "echo Hello from Kubernetes Job! && sleep 30"

kubectl create cronjob <> --schedule="*/5 * * * *" --image=<> --dry-run=client -o yaml -- sh -c "echo Hello CronJob! && sleep 30"

kubectl logs <pod name> -c <container name>							# logs, not log. No object, only object name
```
#### Service Account, Role, Rolebinding
```bash
kubectl create sa dashboard-sa --dry-run=client -o yaml
kubectl create token <sa name>
kubectl create role <pod-reader> --verb=get,list,watch --resource=pods --namespace=default 		# resource:pods/deployments
kubectl create rolebinding <pod-reader-binding> --role=pod-reader --serviceaccount=default:dashboard-sa --namespace=default
```
- The ServiceAccount does not have any inherent permissions. It must be bound to a Role (or ClusterRole) using a RoleBinding (or ClusterRoleBinding) to allow it to perform actions.

#### Ingress
An Ingress is an API object in Kubernetes that manages external access to services within a cluster. It allows you to define rules for how external traffic reaches the services inside your Kubernetes cluster, typically through HTTP/HTTPS requests.

Without an Ingress, you would need to expose your services using a Service of type NodePort or LoadBalancer, which directly maps a service to external ports. However, using an Ingress is more efficient and flexible, as it provides load balancing, SSL termination, and name-based virtual hosting features. It contains two components:

- Ingress Controller: A specific implementation that interprets the Ingress rules and carries out the necessary routing. Examples include NGINX, HAProxy, or Traefik. github.com/kubernetes/ingress-nginx	 kubernetes.github.io/ingress-nginx/deploy/

- Ingress Resource: A Kubernetes object that defines rules for routing traffic to services. The Ingress Controller reads and implements these rules.

```bash
kubectl create ingress <> --rule="myapp.example.com/*=myapp-service:80" --rule=<> --dry-run=client -o yaml		# pathType: Prefix
kubectl create ingress <> --rule="myapp.example.com/=myapp-service:80" --rule=<> --dry-run=client -o yaml		# pathType: Exact
```
https://letsencrypt.org/docs/challenge-types/
https://cert-manager.io/docs/configuration/acme/
### Network Policy
Kubernetes does not have an imperative command for creating Network Policies directly.

#### Debugging & Monitoring
- kubectl get	
- kubectl describe	
- kubectl edit		
- kubectl logs

```bash
kubectl top pod/node
kind get clusters 						OR 	kubectl config get-clusters
kubectl config get-contexts
kubectl config view
docker ps; docker ps -a
kind delete cluster --name <your-cluster-name>		 	kubectl config delete-cluster kind-ibtisam		both aren't the same.
kind create cluster --name <your-cluster-name>
docker inspect/logs <ibtisam-control-plane>
docker logs ibtisam-external-load-balancer
kind get clusters; kubectl config get-clusters; kubectl config get-contexts; kubectl config view; docker ps
```

The issue arises because your worker nodes are in the 172.x.x.x range, while your local network is in the 192.x.x.x range, causing the service to be inaccessible directly from your local network. This is common when Kubernetes is running in a virtualized or containerized environment like Docker or Minikube.

Here are a few alternatives you can try:
1. Use Port Forwarding
Kubernetes provides a port forwarding mechanism that allows you to forward traffic from your local machine to a specific pod or service.

kubectl port-forward svc/test-svc 7070(localhost port):3741(services’s Port)

This will forward the service port 3741 from the Kubernetes cluster to port 7070 on your local machine. You can then access the service in your browser using:
http://localhost:7070

Check if the Application is Listening on Port 8000

First, verify that the application inside the test pod is actually running and listening on port 8000. You can do this by executing a shell inside the pod and checking the listening ports:

kubectl exec -it <pod name> -c <containerID -- netstat -tuln
Look for a line that indicates the application is listening on 0.0.0.0:8000 or 127.0.0.1:8000.

ibtisam@mint-dell:~/k8s/imp-co$ kubectl exec -it test -- netstat -tuln
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN 

Pod status: pending, ContainerCreating, Running

Pod Condition: PodScheduled, Initialized, ContainersReady, Ready

