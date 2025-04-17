# Creating ConfigMaps Imperatively
Kubernetes provides multiple ways to create ConfigMaps using the `kubectl create configmap` command.

---

## **1️⃣ Creating a ConfigMap from a Directory**
```sh
kubectl create configmap my-config --from-file=path/to/bar
```

### **Effect:**
- If `path/to/bar` is a **directory**, all files inside that directory are added as keys in the ConfigMap.
- Each **file name** becomes a key, and the **file content** becomes the value.

### **Example:**
If `bar/` contains:
```
bar/
├── file1.txt (contains "hello")
├── file2.txt (contains "world")
```
The ConfigMap will be:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  file1.txt: "hello"
  file2.txt: "world"
```

### **Use Case:**
Use this method when you have multiple configuration files that you want to bundle into a single ConfigMap.

---

## **2️⃣ Creating a ConfigMap from a Single File**
```sh
kubectl create configmap my-config --from-file=path/to/bar
```

### **Effect:**
- If `path/to/bar` is a **single file**, Kubernetes creates a ConfigMap with a key equal to the file name (`bar`) and a value containing the file’s contents.

### **Example:**
If `bar` is a file with contents:
```
hello world
```
The ConfigMap will be:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  bar: "hello world"
```

### **Use Case:**
Use this method when you want to store a single configuration file inside a ConfigMap.

---

## **3️⃣ Creating a ConfigMap with Custom Keys from Files**
```sh
kubectl create configmap my-config --from-file=key1=/path/to/file1.txt --from-file=key2=/path/to/file2.txt
```

### **Effect:**
- Allows **custom key names** instead of using file names.
- Each specified key gets assigned the content of the corresponding file.

### **Example:**
If `file1.txt` contains `hello` and `file2.txt` contains `world`, the ConfigMap will be:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  key1: "hello"
  key2: "world"
```

### **Use Case:**
Use this method when you want to **rename keys** while creating the ConfigMap.

---

## **4️⃣ Creating a ConfigMap with Key-Value Pairs (Literals)**
```sh
kubectl create configmap my-config --from-literal=key1=config1 --from-literal=key2=config2
```

### **Effect:**
- Directly specifies key-value pairs inside the ConfigMap without using any files.

### **Example:**
The resulting ConfigMap will be:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  key1: "config1"
  key2: "config2"
```

### **Use Case:**
Use this method when you need to quickly create a small set of key-value pairs without using files.

---

## **5️⃣ Creating a ConfigMap from an Environment File**
```sh
kubectl create configmap my-config --from-env-file=path/to/foo.env --from-env-file=path/to/bar.env
```

### **Effect:**
- Reads environment variables from an `.env` file and converts them into a ConfigMap.

### **Example:**
If `foo.env` contains:
```
DB_USER=root
DB_PASS=secret
```
The ConfigMap will be:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  DB_USER: "root"
  DB_PASS: "secret"
```

### **Use Case:**
Use this method when you want to **load multiple environment variables at once** from a `.env` file.

---

## **Summary**
| Method | Command | Best Use Case |
|--------|---------|--------------|
| From a Directory | `--from-file=path/to/bar/` | Store multiple config files as keys |
| From a Single File | `--from-file=path/to/bar` | Store a single file as a key |
| Custom Keys from Files | `--from-file=key1=file1 --from-file=key2=file2` | Rename keys manually |
| Key-Value Pairs | `--from-literal=key=value` | Quick inline creation |
| From an Env File | `--from-env-file=path/to/foo.env` | Load environment variables |

Understanding these methods allows you to **choose the best approach based on your use case** and **effectively manage configurations in Kubernetes**.

