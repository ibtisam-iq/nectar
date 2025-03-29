## 7. Running Pods with Custom Commands and Arguments
### **1. Understanding Default Command and Arguments**
- Every container image has a **default command** (defined as `ENTRYPOINT` in Docker) and **default arguments** (defined as `CMD` in Docker).
- When running a pod using `kubectl run`, if no command or arguments are specified, Kubernetes will use the **default command and arguments** defined in the container image.
- For example, the `nginx` image has a default command of `nginx` and default arguments to start the web server.

### **2. Overriding Only Arguments (Keeping Default Command)**
```sh
kubectl run nginx --image=nginx -- <arg1> <arg2> ... <argN>
```
**Example:**
```sh
kubectl run nginx --image=nginx -- -g "daemon off;"
```
- **What happens?** The default command (`nginx`) is kept, but arguments are overridden with `-g "daemon off;"`.
- **Equivalent YAML:**
  ```yaml
  spec:
    containers:
      - name: nginx
        image: nginx
        args: ["-g", "daemon off;"]
  ```

### **3. Overriding the Command and Arguments**
```sh
kubectl run nginx --image=nginx --command -- <cmd> <arg1> ... <argN>
```
**Example:**
```sh
kubectl run nginx --image=nginx --command -- /bin/sh -c "echo Hello Kubernetes"
```
- **What happens?** The command (`/bin/sh`) and arguments (`-c "echo Hello Kubernetes"`) fully replace the default command.
- **Equivalent YAML:**
  ```yaml
  spec:
    containers:
      - name: nginx
        image: nginx
        command: ["/bin/sh"]
        args: ["-c", "echo Hello Kubernetes"]
  ```

### **4. Running a Pod with Multiple Arguments**
```sh
kubectl run myapp --image=alpine --command -- /bin/sh -c "echo arg1; echo arg2; echo arg3"
```
- **What happens?** The Alpine container runs `/bin/sh` and executes the given commands.
- **Equivalent YAML:**
  ```yaml
  spec:
    containers:
      - name: myapp
        image: alpine
        command: ["/bin/sh"]
        args: ["-c", "echo arg1; echo arg2; echo arg3"]
  ```

---

## 8. Conclusion
- **Use `--labels="key1=value1,key2=value2"` for tagging and selection.**
- **Use `--env=[]` for defining environment variables in a structured way.**
- **Labels are stored as a dictionary, while environment variables are stored as a list.**
- **Use `--command --` to define custom commands in containers.**
- **When using `--command`, both command and arguments must be explicitly defined.**
