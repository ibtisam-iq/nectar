## Q1

```bash
controlplane:~$ k logs goapp-deployment-77549cf8d6-rr5q4
Error: PORT environment variable not set
controlplane:~$ k edit deployments.apps goapp-deployment 
deployment.apps/goapp-deployment edited
controlplane:~$ k get po
NAME                              READY   STATUS    RESTARTS   AGE
goapp-deployment-9d4fb95f-rq2fc   1/1     Running   0          7s
controlplane:~$ k get svc
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
goapp-service   ClusterIP   10.111.109.109   <none>        8080/TCP   11m
kubernetes      ClusterIP   10.96.0.1        <none>        443/TCP    5d
controlplane:~$ curl http://10.111.109.109:8080
Hello, Kubernetes! Here is a UUID: f3f5e0f0-7786-4f2d-90a2-2510b737aec3
controlplane:~$ 

      env:
        - name: PORT
          value: "8080"         # MUST match the port your app expects
```

---

## Q2

`postgres-deployment` deployment pods are not running, fix that issue

```bash
  Warning  Failed     12s (x2 over 13s)  kubelet            Error: configmap "postgres-db-config" not found
  Normal   Pulled     12s                kubelet            Successfully pulled image "postgres:latest" in 759ms (759ms including waiting). Image size: 161430709 bytes.

controlplane:~$ k get cm
NAME               DATA   AGE
kube-root-ca.crt   1      8d
postgres-config    2      52s
controlplane:~$ k edit deploy postgres-deployment 
deployment.apps/postgres-deployment edited

Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Warning  BackOff    10s (x3 over 24s)  kubelet            Back-off restarting failed container postgres-container in pod postgres-deployment-558f7db69-ht8mc_default(2973d420-da17-4e8a-81b3-536b16d6abc8)

controlplane:~$ crictl ps -a                 # nothing found, just core components
controlplane:~$ ls /var/log/pods/            # nothing found, just core components
controlplane:~$ ls /var/log/containers/      # nothing found, just core components
controlplane:~$ k get events                 # nothing new, just the same as mentions in pod's Events

controlplane:~$ kubectl logs postgres-deployment-558f7db69-ht8mc
Error: Database is uninitialized and superuser password is not specified.
       You must specify POSTGRES_PASSWORD to a non-empty value for the
       superuser. For example, "-e POSTGRES_PASSWORD=password" on "docker run".

controlplane:~$ k edit deployments.apps postgres-deployment       # add  --env=POSTGRES_PASSWORD=<any-value>
deployment.apps/postgres-deployment edited
controlplane:~$ k get po
NAME                                   READY   STATUS    RESTARTS   AGE
postgres-deployment-846744d649-lhpcm   1/1     Running   0          4s
controlplane:~$
```

Sweetheart, this Postgres pod is in **CrashLoopBackOff**, which means the container starts, fails immediately, and kubelet keeps retrying. Let’s debug step by step:

### 🔑 Key Observations

1. **Exit Code: 1**

   ```
   Last State: Terminated
   Reason:     Error
   Exit Code:  1
   ```

   → Postgres process is failing during startup (not killed by kubelet like your apiserver earlier).

2. **Environment Variables**

   ```yaml
   POSTGRES_DB:    <set to the key 'POSTGRES_DB' of config map 'postgres-config'>
   POSTGRES_USER:  <set to the key 'POSTGRES_USER' of config map 'postgres-config'>
   ```

   * You’re passing DB name and user from a **ConfigMap** called `postgres-config`.
   * But there is **no `POSTGRES_PASSWORD` set** — which is **mandatory** for the `postgres` image.
     Without it, the container exits with error.

3. **Events**

   * No image pull error (image is pulled fine).
   * No scheduling issue.
   * Just keeps restarting because of **Postgres startup failure**.

### 🎯 Root Cause

The official `postgres` image requires a password for the database superuser unless you enable passwordless mode.
At minimum, one of these must be provided:

* `POSTGRES_PASSWORD`
* `POSTGRES_PASSWORD_FILE`
* `POSTGRES_HOST_AUTH_METHOD=trust` (for testing only, insecure)

Since none are set → container fails instantly.

✅ After adding `POSTGRES_PASSWORD`, the pod should start properly and stay in `Running` state.

---

```bash
# Correct DB_USER, it is provided .. root
Environment Variables: DB_Host=mysql-service; DB_Database=Not Set; DB_User=sql-user; DB_Password=paswrd; 1045 (28000): Access denied for user 'sql-user'@'10.22.0.1' (using password: YES)

# DB_USER in webapp deployment is corrected, and now also fix MYSQL_ROOT_PASSWORD in myqsl pod/deploy.
Environment Variables: DB_Host=mysql-service; DB_Database=Not Set; DB_User=root; DB_Password=paswrd; 1045 (28000): Access denied for user 'root'@'10.22.0.1' (using password: YES)

# MYSQL_ROOT_PASSWORD is fixed now.
Environment Variables: DB_Host=mysql-service; DB_Database=Not Set; DB_User=root; DB_Password=paswrd;
                  From webapp-mysql-5c4c675768-r7bfh!
```

Good “why” ❤️ — let’s unwrap this carefully.

When you run the **MySQL container** (from the official image), it bootstraps itself with a **root password**. That’s controlled by the environment variable:

```yaml
- name: MYSQL_ROOT_PASSWORD
  value: paswrd
```

👉 This is not just a “hint” — the container actually runs an initialization script that sets the **root account’s password inside MySQL** to whatever you pass here.

### Why must it match `DB_Password` in your webapp?

* Your **webapp** tries to log in using the credentials you provide:

  ```yaml
  DB_User = root
  DB_Password = paswrd
  ```
* MySQL checks if this user/password matches what was set during initialization.
* If the `DB_Password` in the webapp ≠ `MYSQL_ROOT_PASSWORD` in the MySQL Pod, MySQL rejects with:

  ```
  1045 (28000): Access denied for user 'root'@'10.22.0.1'
  ```

So both sides must “speak the same secret.”

* On **MySQL side**: `MYSQL_ROOT_PASSWORD=paswrd` → root password stored as `paswrd`.
* On **App side**: `DB_Password=paswrd` → app uses same password to log in.

### 🔑 Think of it like a lock & key analogy

* `MYSQL_ROOT_PASSWORD` = the locksmith setting the lock’s key code.
* `DB_Password` in the app = the physical key you’re trying to use.
* If the locksmith set the lock to `1234`, but your key is cut for `5678`, the lock won’t open.

--

Exactly sweetheart ✅ you’ve nailed it.

Let me break it cleanly:

### 🔑 Case 1: Using `root`

* If your **DB_USER = root**,
* then your **DB_Password must match the value of `MYSQL_ROOT_PASSWORD`** inside the MySQL Pod.
* Because that’s the password the container **sets for root** when it starts.

### 🔑 Case 2: Using a Different User (e.g., `sql-user`, `webuser`)

* `MYSQL_ROOT_PASSWORD` has nothing to do with this.
* Each user has **its own password** set inside MySQL. Example:

  ```sql
  CREATE USER 'sql-user'@'%' IDENTIFIED BY 'paswrd123';
  GRANT ALL PRIVILEGES ON mydb.* TO 'sql-user'@'%';
  FLUSH PRIVILEGES;
  ```
* In this case:

  * `DB_User = sql-user`
  * `DB_Password = paswrd123` (not equal to root password, unless you deliberately made it the same).

### 📌 Why the Confusion Happens

* The **MySQL image requires `MYSQL_ROOT_PASSWORD`** at first run → so people often think *every* user must use it.
* But really:

  * `MYSQL_ROOT_PASSWORD` = only for the **root account**.
  * Other users = you create them manually and set their own passwords.

⚡ So summary:

* **Root user** → must match `MYSQL_ROOT_PASSWORD`.
* **Non-root user** → password must match the one you explicitly set with `CREATE USER ... IDENTIFIED BY ...`.

---

