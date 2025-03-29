# Managing Kubernetes Objects Using Imperative Commands

### Official Documentation

- https://kubernetes.io/docs/reference/kubectl/kubectl/
- https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/imperative-command/

## kubectl run
Create and run a particular image.
```bash
kubectl run <name> --image=<image> \
        --port=<port> \
        --labels=<key>=<value>,<key>=<value> \
        --env=<key>=<value> \
```  