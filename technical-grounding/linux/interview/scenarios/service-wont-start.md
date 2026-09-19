# Service Won't Start

A systemd service fails to start, or starts and dies within seconds. The interviewer expects the candidate to read `systemctl status` and the journal before changing anything, and to recognize the common failure classes from their exit codes.

---

## Symptom

> "We deployed the new orders API and systemctl start fails. Restarting it a few times did not help. Walk me through it."

---

## Clarifying Questions

- **What exactly does `systemctl start` print?** "Unavailable resources", "control process exited" and "dependency" point to different causes.
- **Did it ever run on this host?** A first deployment fails on setup (files, users, permissions); a previously working service fails on a change.
- **What changed?** A package update, a config edit, a new drop-in, a port taken by another service, a failed dependency.
- **Does the program start by hand as the service user?** That separates the unit from the application.

---

## Diagnostic Path

The unit, as deployed on Rocky Linux 10.2:

```ini
# /etc/systemd/system/orders-api.service
[Unit]
Description=Orders API
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=orders
EnvironmentFile=/etc/orders/orders.env
ExecStart=/opt/orders/run.sh
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

`run.sh` runs `exec /usr/bin/python3 /opt/orders/server.py`, which writes a marker to `/var/lib/orders/` and listens on `$ORDERS_PORT`. All commands below ran as root.

### 1. Read the Status and the Journal

```bash
systemctl start orders-api; echo rc=$?
systemctl status orders-api --no-pager
journalctl -u orders-api -b -o cat --no-pager | tail -4
```

Output:

```text
Job for orders-api.service failed because of unavailable resources or another system error.
See "systemctl status orders-api.service" and "journalctl -xeu orders-api.service" for details.
rc=1
● orders-api.service - Orders API
     Loaded: loaded (/etc/systemd/system/orders-api.service; disabled; preset: disabled)
     Active: activating (auto-restart) (Result: resources) since Thu 2026-09-17 05:58:26 UTC; 14ms ago
 Invocation: 7e2ad68f1b3341b1b6ace55cc1c42747
   Mem peak: 0B
        CPU: 0
orders-api.service: Failed to load environment files: No such file or directory
orders-api.service: Failed to spawn 'start' task: No such file or directory
orders-api.service: Failed with result 'resources'.
Failed to start orders-api.service - Orders API.
```

`Result: resources` means systemd could not even prepare the process: the `EnvironmentFile=` does not exist. `Mem peak: 0B` confirms that nothing ran.

### 2. Check What systemd Tried to Execute

After creating `/etc/orders/orders.env` with `ORDERS_PORT=8080`:

```bash
systemctl reset-failed orders-api; systemctl start orders-api; echo rc=$?
journalctl -u orders-api -b -o cat --no-pager | grep -m1 -B1 -A1 "203/EXEC"
namei -l /opt/orders/run.sh
```

Output:

```text
Job for orders-api.service failed because the control process exited with error code.
See "systemctl status orders-api.service" and "journalctl -xeu orders-api.service" for details.
rc=1
orders-api.service: Failed at step EXEC spawning /opt/orders/run.sh: Permission denied
orders-api.service: Main process exited, code=exited, status=203/EXEC
orders-api.service: Failed with result 'exit-code'.
f: /opt/orders/run.sh
drwxr-xr-x root root /
drwxr-xr-x root root opt
drwxr-xr-x root root orders
-rw-r--r-- root root run.sh
```

`203/EXEC` means the program could not be executed; the line before it gives the reason. `namei -l` checks every directory on the path as well as the file, and here the file lacks the execute bit.

### 3. Run the Program as the Service User

After `chmod 755 /opt/orders/run.sh`, `systemctl start` returns 0 (with `Type=exec`, success means the program was executed), but the service keeps restarting:

```bash
systemctl start orders-api; echo rc=$?; sleep 1; systemctl status orders-api --no-pager | sed -n "3,4p"
journalctl -u orders-api -b -o cat --no-pager | tail -8
sudo mkdir -p /var/lib/orders; sudo -u orders ORDERS_PORT=8081 timeout 2 /opt/orders/run.sh; echo rc=$?
ls -ld /var/lib/orders
```

Output:

```text
rc=0
     Active: activating (auto-restart) (Result: exit-code) since Thu 2026-09-17 05:58:26 UTC; 973ms ago
 Invocation: 1ed7c023168849b396b490c5bbd5fff3
Started orders-api.service - Orders API.
Traceback (most recent call last):
  File "/opt/orders/server.py", line 3, in <module>
    open("/var/lib/orders/started", "w").write("ok\n")
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
FileNotFoundError: [Errno 2] No such file or directory: '/var/lib/orders/started'
orders-api.service: Main process exited, code=exited, status=1/FAILURE
orders-api.service: Failed with result 'exit-code'.
Traceback (most recent call last):
  File "/opt/orders/server.py", line 3, in <module>
    open("/var/lib/orders/started", "w").write("ok\n")
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
PermissionError: [Errno 13] Permission denied: '/var/lib/orders/started'
rc=1
drwxr-xr-x 2 root root 4096 Sep 17 05:58 /var/lib/orders
```

The application's own error is in the journal because systemd captures its stderr. Creating the directory as root is not enough: it must belong to the service user. `StateDirectory=orders` makes systemd create and own it:

```bash
rmdir /var/lib/orders; mkdir -p /etc/systemd/system/orders-api.service.d; printf '[Service]\nStateDirectory=orders\n' > /etc/systemd/system/orders-api.service.d/10-state.conf
systemctl daemon-reload; systemctl reset-failed orders-api; systemctl restart orders-api; sleep 3; systemctl status orders-api --no-pager | sed -n "3p"; journalctl -u orders-api -o cat --no-pager | grep -m1 OSError
ls -ld /var/lib/orders
```

Output:

```text
    Drop-In: /etc/systemd/system/orders-api.service.d
OSError: [Errno 98] Address already in use
drwxr-xr-x 2 orders orders 4096 Sep 17 05:58 /var/lib/orders
```

### 4. Check the Port

```bash
ss -tlnp "sport = :8080"
```

Output:

```text
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      511          0.0.0.0:8080      0.0.0.0:*    users:(("nginx",pid=2098,fd=19),("nginx",pid=2097,fd=19),("nginx",pid=2096,fd=19),("nginx",pid=2095,fd=19),("nginx",pid=954,fd=19))
```

nginx already listens on 8080. With `ORDERS_PORT=8081` in the environment file, the service starts:

```bash
systemctl reset-failed orders-api; systemctl start orders-api; sleep 1; systemctl is-active orders-api; ss -tlnp "sport = :8081"; curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/
```

Output:

```text
active
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5            0.0.0.0:8081      0.0.0.0:*    users:(("python3",pid=5531,fd=3))
200
```

### 5. Recognize the Other Failure Classes

A typo in `User=` (a drop-in set `User=order`) fails before the program runs:

```bash
systemctl daemon-reload; systemctl restart orders-api; sleep 0.5; journalctl -u orders-api -o cat -n 3 --no-pager
journalctl -u orders-api -o cat --no-pager | grep -B2 "217/USER"
```

Output:

```text
Job for orders-api.service failed because the control process exited with error code.
See "systemctl status orders-api.service" and "journalctl -xeu orders-api.service" for details.
orders-api.service: Main process exited, code=exited, status=217/USER
orders-api.service: Failed with result 'exit-code'.
Failed to start orders-api.service - Orders API.
orders-api.service: Failed to determine user credentials: No such process
orders-api.service: Failed at step USER spawning /opt/orders/run.sh: No such process
orders-api.service: Main process exited, code=exited, status=217/USER
```

A worker that `Requires=` a failing database unit never starts itself:

```bash
systemctl daemon-reload; systemctl reset-failed; systemctl start orders-worker
systemctl list-dependencies orders-worker --no-pager | head -4
systemctl --failed --no-pager
systemd-analyze verify /etc/systemd/system/orders-db.service
```

Output:

```text
A dependency job for orders-worker.service failed. See 'journalctl -xe' for details.
orders-worker.service
× ├─orders-db.service
● ├─system.slice
● └─sysinit.target
  UNIT              LOAD   ACTIVE SUB    DESCRIPTION
● orders-db.service loaded failed failed Orders database

Legend: LOAD   → Reflects whether the unit definition was properly loaded.
        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.
        SUB    → The low-level unit activation state, values depend on unit type.

1 loaded units listed.
orders-db.service: Command /usr/local/bin/orders-db is not executable: No such file or directory
```

A masked unit refuses every start, and a service whose `ExecStartPre=` validates its configuration fails on a syntax error:

```bash
systemctl stop memcached 2>/dev/null; systemctl mask memcached; systemctl start memcached
cp /etc/nginx/nginx.conf /root/c/nginx.conf.bak; sed -i "s/worker_connections 1024;/worker_connections 1024/" /etc/nginx/nginx.conf; systemctl restart nginx
journalctl -u nginx -o cat -n 4 --no-pager
nginx -t
```

Output:

```text
Created symlink '/etc/systemd/system/memcached.service' → '/dev/null'.
Failed to start memcached.service: Unit memcached.service is masked.
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
nginx: configuration file /etc/nginx/nginx.conf test failed
nginx.service: Control process exited, code=exited, status=1/FAILURE
nginx.service: Failed with result 'exit-code'.
Failed to start nginx.service - The nginx HTTP and reverse proxy server.
nginx: [emerg] unexpected "}" in /etc/nginx/nginx.conf:15
nginx: configuration file /etc/nginx/nginx.conf test failed
```

Both were reverted afterwards (`systemctl unmask memcached`, the saved `nginx.conf` restored). `systemctl mask` on a unit that lives in `/etc/systemd/system` fails with `Failed to mask unit: File '/etc/systemd/system/orders-api.service' already exists`, because masking works by placing a link there.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| Missing environment file | `Result: resources`, `Failed to load environment files` | Create it, or `EnvironmentFile=-/path` if optional |
| Program not executable | `status=203/EXEC`, `Failed at step EXEC ... Permission denied` or `No such file` | Path, mode, shebang, `noexec` mount |
| Unknown user or group | `status=217/USER`, `Failed to determine user credentials` | Create the user or fix `User=` |
| Application error | `status=1/FAILURE` with the app's traceback in the journal | Fix the application or its prerequisites |
| Missing or wrong-owner directories | `No such file or directory`, `Permission denied` under `/var/lib` | `StateDirectory=`, `LogsDirectory=`, `RuntimeDirectory=` |
| Port in use | `Address already in use`; `ss -tlnp` shows another owner | Change the port or stop the other service |
| Dependency failed | `A dependency job ... failed`; `list-dependencies` shows `×` | Fix the required unit |
| Masked | `Unit ... is masked`; `is-enabled` prints `masked` | `systemctl unmask` |
| Invalid configuration | `ExecStartPre=` check fails; `nginx -t`, `sshd -t`, `named-checkconf` show the line | Correct the config |
| Crash loop | `activating (auto-restart)`, rising `NRestarts`, then `Start request repeated too quickly` | Fix the cause, then `systemctl reset-failed` |
| SELinux denial (RHEL) | `Permission denied` although modes are correct; AVC in `ausearch -m avc` | `restorecon`, `semanage port`, booleans (see the security module) |

---

## Fix

Change one thing at a time and confirm each with `systemctl status` and `journalctl -u`: here the environment file, the execute bit, `StateDirectory=` and the port. `systemctl reset-failed` clears the failed state and the start-limit counter before each retry.

---

## Prevention

- Run `systemd-analyze verify` on new units and the application's own config test (`nginx -t`) in the deployment pipeline.
- Let systemd create directories and users (`StateDirectory=`, `DynamicUser=` or a `sysusers.d` file) instead of manual steps.
- Use `Type=exec` or `Type=notify` so `systemctl start` reports failures that `Type=simple` hides.
- Alert on units in the failed state and on rising `NRestarts`.

---

## Related

- [systemctl](../../08-systemd-and-services/systemctl.md): reading `status`
- [Unit Files](../../08-systemd-and-services/unit-files.md): `Type=`, dependencies and restarts
- [Writing a Service](../../08-systemd-and-services/writing-a-service.md): directories and hardening
- [journalctl](../../09-logging/journalctl.md): filtering the unit's messages
- [Process Won't Die](process-wont-die.md): the opposite problem

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
