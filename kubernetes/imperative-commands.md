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
### Example
```bash
# Create two objects in YAML: pod named "my-pod" and generate service (ClusterIP type)

kubectl run my-nginx --image=nginx:1.14.2 --port=80 --expose \
  --labels=app=my-nginx,type=sam --env=MY_VAR=hello --env=flower=lily \
  --namespace=default --restart=Never --dry-run=client -o yaml > my-nginx.yaml

kubectl run my-nginx --image nginx:1.14.2 --port 80 --expose \
  --labels app=my-nginx,type=sam --env MY_VAR=hello --env flower=lily \
  --namespace default --restart Never --dry-run client -o yaml > my-nginx.yaml
```

```bash
kubectl get pods --all-namespacescammand