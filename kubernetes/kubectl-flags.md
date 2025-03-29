# kubectl Flags

**kubectl create|apply|replace|run|expose|rollout|port-forward|config|taint|label|patch**
=====================================
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
---

**kubectl get|describe|delete|edit|exec|logs|set**

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
---

## Understanding `kubectl run` Flags: Labels and Environment Variables

## 1. `--labels="key1=value1,key2=value2"` (Comma-Separated String)
- **What is it?** Labels are key-value pairs used to categorize and identify Kubernetes objects.
- **How does Kubernetes expect it?** Kubernetes expects labels as a **single string**, where key-value pairs are separated by commas (,).
- **Example:**
  ```sh
  --labels="app=nginx,env=production"
  ```
- **Why this format?**  
  - Labels are lightweight metadata used for selection (e.g., `kubectl get pods -l app=nginx`).
  - They need to be easy to pass in commands without requiring structured input.
  - Since labels are frequently used for filtering, a **compact format** is preferred.
  - Equivalent shorter flag:
    ```sh
    -l "app=nginx,env=prod"
    ```
  - Kubernetes treats labels as a **dictionary (map)** behind the scenes.

---

## 2. `--env=[]` (Environment Variables)
- **What is it?** Environment variables are key-value pairs that are passed to the container at runtime.
- **How does Kubernetes expect it?** Kubernetes expects environment variables as a **list**, meaning you must specify `--env` multiple times for each variable.
- **Example:**
  ```sh
  --env="DNS_DOMAIN=cluster" --env="POD_NAMESPACE=default"
  ```
- **Why this format?**
  - Kubernetes treats environment variables as a **list of key-value pairs**, not a dictionary.
  - This format makes it flexible to pass multiple environment variables dynamically.
  - If Kubernetes used a comma-separated format (like labels), handling values with spaces or special characters would be harder.
  - Each `--env` flag adds another entry to the list.

---

## 3. Key Differences Between Labels and Environment Variables
| Feature         | Labels (`--labels=""`)  | Environment Variables (`--env=[]`) |
|---------------|------------------------|----------------------------------|
| **Structure**  | Dictionary (key-value)  | List of key-value pairs |
| **Format in CLI** | Single string with `,` | Repeated flag (list) |
| **Example**   | `--labels="app=nginx,env=prod"` | `--env="VAR1=value1" --env="VAR2=value2"` |
| **Purpose**  | Used for **selection & filtering** | Used to **pass environment variables to containers** |
| **Common Values** | Short identifiers | Key-value pairs for configurations |

---

## 4. Analogy
- **Labels (`--labels` as comma-separated values)**  
  → Like assigning short tags to an object (e.g., sticky notes).
- **Environment Variables (`--env` as a list)**  
  → Like setting **configuration parameters** for an application at runtime.

---

## 5. Why Kubernetes Uses Different Formats?
1. **Labels** are simple and frequently used in filtering, so a **compact format** (comma-separated) is preferred.
2. **Environment Variables** are naturally structured as a list, allowing them to be repeated multiple times for better flexibility.

---

## 6. How Kubernetes Expects These Flags Imperatively
### **Labels (`--labels`)**
- **Kubernetes expects labels as a single string.**
- **Usage Example:**
  ```sh
  kubectl run my-pod --image=nginx --labels="app=myapp,env=prod"
  ```
- **What happens internally?** Kubernetes stores it as:
  ```yaml
  metadata:
    labels:
      app: myapp
      env: prod
  ```

### **Environment Variables (`--env`)**
- **Kubernetes expects environment variables as a list.**
- **Usage Example:**
  ```sh
  kubectl run my-pod --image=nginx --env="DB_HOST=database" --env="DB_USER=admin"
  ```
- **What happens internally?** Kubernetes stores it as:
  ```yaml
  spec:
    containers:
      - name: my-container
        image: nginx
        env:
          - name: DB_HOST
            value: database
          - name: DB_USER
            value: admin
  ```

---

## 7. Conclusion
- **Use `--labels="key1=value1,key2=value2"` for tagging and selection.**
- **Use `--env=[]` for defining environment variables in a structured way.**
- **Labels are stored as a dictionary, while environment variables are stored as a list.**

---


