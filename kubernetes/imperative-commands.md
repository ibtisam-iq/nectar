# Managing Kubernetes Objects Using Imperative Commands

### Official Documentation

- https://kubernetes.io/docs/reference/kubectl/kubectl/
- https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/imperative-command/

### Important Points

- Kubernetes supports both `--flag=value` and `--flag value` formats.

## Pod
Create and run a particular image.

```bash
kubectl run <name> --image=<image> \
    --port=<port> \
    --expose =<expose> \
    --labels=<key>=<value>,<key>=<value> \
    --env=<key>=<value> --env=<key>=<value> \
    --namespace=<namespace> \
    -- <arg1> <arg2> ... <argN> \   # use default command, but use custom arguments (arg1 .. argN) for that command
    --command -- <cmd> <arg1> ... <argN> \  # use a different command and custom arguments
    --restart=Never \
    --dry-run=client \
    --output=yaml > <output file>
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

