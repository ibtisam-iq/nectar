# Writing a Service

Turning a script or binary into a systemd service gives it boot start, restart on failure, logging, a dedicated user and sandboxing with a dozen lines of configuration. The example on this page wraps a small health-check script and hardens it.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Location | `/etc/systemd/system/<name>.service` | `systemctl cat <name>` |
| Minimum | `[Service]` with `ExecStart=` and an absolute path; `[Install]` to enable it | `systemd-analyze verify <file>` |
| Foreground | The program must not daemonize under `Type=exec` or `simple` | `systemctl status` |
| Logging | stdout and stderr go to the journal | `journalctl -u <name>` |
| Identity | `User=`, `Group=`; `DynamicUser=yes` creates a transient user | `ps -o user -p <pid>` |
| Configuration | `Environment=KEY=value`, `EnvironmentFile=/etc/<name>/<name>.env` (`-` prefix makes it optional) | `systemctl show -p Environment` |
| Writable state | `StateDirectory=`, `RuntimeDirectory=`, `LogsDirectory=`, created and owned for the service user | `ls -l /var/lib/<name>` |
| Sandboxing | `ProtectSystem=strict`, `ProtectHome=yes`, `PrivateTmp=yes`, `NoNewPrivileges=yes` | `systemd-analyze security <name>` |
| Resource limits | `MemoryMax=`, `CPUQuota=`, `TasksMax=`, `LimitNOFILE=` | `systemctl show -p MemoryMax` |
| Exposure score | 0 (sandboxed) to 10 (unrestricted) | `systemd-analyze security` |
| Exit code 203 | `EXEC`: the binary could not be executed | `systemctl status` |
| Test a setting | `systemd-run -P -p <Setting>=<value> <cmd>` runs a command as a transient unit | `systemd-run -P -q true` |
<!-- --8<-- [end:facts] -->

---

## 1. The Program

The script runs in the foreground, reads its settings from the environment, writes to stdout and exits cleanly on `SIGTERM`. `sleep & wait` lets the trap run as soon as `SIGTERM` arrives.

```bash
sudo useradd -r -s /usr/sbin/nologin -d /var/lib/healthcheck healthcheck
sudo install -d -o root -g root -m 0755 /opt/healthcheck
sudo tee /opt/healthcheck/healthcheck.sh >/dev/null <<'EOF'
#!/bin/bash
# Poll a URL and log the status code every INTERVAL seconds.
set -u
: "${TARGET_URL:?TARGET_URL is not set}"
INTERVAL="${INTERVAL:-10}"
trap 'echo "stopping"; exit 0' TERM
echo "checking ${TARGET_URL} every ${INTERVAL}s as $(id -un)"
while true; do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$TARGET_URL")
    echo "status=${code}" >> "${STATE_DIRECTORY}/history.log"
    echo "status=${code}"
    sleep "$INTERVAL" &
    wait $!
done
EOF
sudo chmod 0755 /opt/healthcheck/healthcheck.sh
sudo install -d /etc/healthcheck
printf 'TARGET_URL=http://127.0.0.1/\nINTERVAL=5\n' | sudo tee /etc/healthcheck/healthcheck.env >/dev/null
```

!!! tip "Keep the program read-only for the service user"
    The script is owned by root and not writable by `healthcheck`, so a compromised service cannot replace its own code.

---

## 2. The Unit

```ini
[Unit]
Description=HTTP health checker
Documentation=https://nectar.ibtisam-iq.com/technical-grounding/linux/08-systemd-and-services/writing-a-service/
Wants=network-online.target
After=network-online.target nginx.service

[Service]
Type=exec
User=healthcheck
Group=healthcheck
EnvironmentFile=/etc/healthcheck/healthcheck.env
ExecStart=/opt/healthcheck/healthcheck.sh
Restart=on-failure
RestartSec=5
StateDirectory=healthcheck
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
MemoryMax=64M

[Install]
WantedBy=multi-user.target
```

| Setting | Why |
|---|---|
| `Type=exec` | `systemctl start` fails if the script cannot be executed |
| `User=`, `Group=` | Runs without root |
| `EnvironmentFile=` | Settings change without editing the unit |
| `StateDirectory=` | Creates `/var/lib/healthcheck` owned by the service user and sets `$STATE_DIRECTORY` |
| `ProtectSystem=strict` | The whole filesystem is read-only except the state directory |
| `ProtectHome=yes` | `/home`, `/root` and `/run/user` are hidden |
| `NoNewPrivileges=yes` | `sudo` and setuid binaries cannot raise privileges |
| `MemoryMax=` | The kernel kills the service above 64 MiB |

---

## 3. Verify, Enable, Observe

```bash
systemd-analyze verify /etc/systemd/system/healthcheck.service; echo rc=$?
sudo systemctl daemon-reload; sudo systemctl enable --now healthcheck
systemctl status healthcheck --no-pager -n 3
```

Output:

```text
rc=0
Created symlink '/etc/systemd/system/multi-user.target.wants/healthcheck.service' → '/etc/systemd/system/healthcheck.service'.
● healthcheck.service - HTTP health checker
     Loaded: loaded (/etc/systemd/system/healthcheck.service; enabled; preset: disabled)
     Active: active (running) since Wed 2026-09-16 19:13:05 UTC; 6s ago
 Invocation: 2c1a5d50aac142a5866b997d62340737
       Docs: https://nectar.ibtisam-iq.com/technical-grounding/linux/08-systemd-and-services/writing-a-service/
   Main PID: 4831 (healthcheck.sh)
      Tasks: 2 (limit: 51276)
     Memory: 1.2M (max: 64M, available: 62.7M, peak: 2.7M)
        CPU: 26ms
     CGroup: /system.slice/healthcheck.service
             ├─4831 /bin/bash /opt/healthcheck/healthcheck.sh
             └─4838 sleep 5

Sep 16 19:13:05 rocky-01 healthcheck.sh[4831]: checking http://127.0.0.1/ every 5s as healthcheck
Sep 16 19:13:05 rocky-01 healthcheck.sh[4831]: status=200
Sep 16 19:13:10 rocky-01 healthcheck.sh[4831]: status=200
```

```bash
sudo ls -l /var/lib/healthcheck; sudo tail -2 /var/lib/healthcheck/history.log
ps -o user,pid,cmd -u healthcheck
sudo systemctl stop healthcheck; journalctl -u healthcheck --no-pager -o cat -n 3
```

Output:

```text
total 4
-rw-r--r-- 1 healthcheck healthcheck 22 Sep 16 19:13 history.log
status=200
status=200
USER         PID CMD
healthc+    4831 /bin/bash /opt/healthcheck/healthcheck.sh
healthc+    4838 sleep 5
Stopping healthcheck.service - HTTP health checker...
healthcheck.service: Deactivated successfully.
Stopped healthcheck.service - HTTP health checker.
```

The trap ran as soon as `SIGTERM` arrived, and the script's `stopping` line is in the journal immediately before the three lines shown.

---

## 4. Measure the Hardening

```bash
systemd-analyze security healthcheck.service --no-pager | tail -1; systemd-analyze security nginx.service --no-pager | tail -1
```

Output:

```text
→ Overall exposure level for healthcheck.service: 6.9 MEDIUM :-|
→ Overall exposure level for nginx.service: 9.2 UNSAFE :-{
```

`systemd-analyze security` scores each service by the protections it lacks, and the full report lists each missing setting with its weight; `ProtectClock=`, `CapabilityBoundingSet=` and `SystemCallFilter=` would lower the score further. Each sandbox setting can be tested with a transient unit before it goes into the file:

```bash
sudo systemd-run -P -q -p ProtectSystem=strict touch /etc/should-fail; echo rc=$?
sudo systemd-run -P -q -p ProtectHome=yes ls -la /home/laborant; echo rc=$?
sudo systemd-run -P -q -p User=healthcheck -p NoNewPrivileges=yes sudo -n true; echo rc=$?
sudo systemd-run -P -q -p MemoryMax=50M python3 -c 'b = bytearray(200 * 1024 * 1024)'; echo rc=$?
```

Output:

```text
/bin/touch: cannot touch '/etc/should-fail': Read-only file system
rc=1
/bin/ls: cannot access '/home/laborant': No such file or directory
rc=2
sudo: The "no new privileges" flag is set, which prevents sudo from running as root.
sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
rc=1
rc=1
```

The Python process passed 50 MiB and the kernel killed it; the journal records the unit as `Failed with result 'oom-kill'`.

!!! warning "ProtectSystem=strict needs every write path declared"
    A service that writes outside its `StateDirectory=`, `LogsDirectory=` or `RuntimeDirectory=` fails with `Read-only file system`. Add `ReadWritePaths=/srv/data` for other locations instead of removing the protection.

---

## Common Errors

### `healthcheck.service: Failed to spawn 'start' task: No such file or directory`

**Cause:** the file in `EnvironmentFile=` does not exist; the unit fails with result `resources` before the program starts.

**Fix:** create the file, or write `EnvironmentFile=-/etc/healthcheck/healthcheck.env` to make it optional.

### `/opt/healthcheck/healthcheck.sh: line 4: TARGET_URL: TARGET_URL is not set`

**Cause:** the environment file exists but does not define a required variable; the script exits 1.

**Fix:** add the variable; check what the unit passes with `systemctl show -p EnvironmentFiles <unit>`.

### `report.service: Failed at step EXEC spawning /opt/report/bin/report: No such file or directory`

**Cause:** `ExecStart=` points to a missing or non-executable file, so the unit fails with `status=203/EXEC`.

**Fix:** `ls -l` the path, check the execute bit, the shebang and the mount's `noexec` option, then `daemon-reload` and start again.

```bash
systemctl status report --no-pager | sed -n '6,7p'
journalctl -u report --no-pager -n 4 -o cat
```

Output:

```text
    Process: 6635 ExecStart=/opt/report/bin/report --daily (code=exited, status=203/EXEC)
   Main PID: 6635 (code=exited, status=203/EXEC)
report.service: Unable to locate executable '/opt/report/bin/report': No such file or directory
report.service: Failed at step EXEC spawning /opt/report/bin/report: No such file or directory
report.service: Main process exited, code=exited, status=203/EXEC
report.service: Failed with result 'exit-code'.
```

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does a minimal systemd service need?"
    **Say first:** a `[Service]` section with `ExecStart=` and an absolute path to a program that stays in the foreground, plus `[Install]` with `WantedBy=` if it should start at boot.

    **Proof:** `systemd-analyze verify /etc/systemd/system/<name>.service`, then `systemctl enable --now <name>`.

    **Follow-up:** What changes if the program forks into the background?

??? question "L1: What does status=203/EXEC mean?"
    **Say first:** systemd could not execute the program in `ExecStart=`: the path is wrong, the file is not executable, or its interpreter is missing.

    **Proof:** `journalctl -u <unit>` shows `Failed at step EXEC spawning <path>`.

    **Follow-up:** Which other step names appear in such messages? (`USER`, `CHDIR`, `NAMESPACE`.)
<!-- --8<-- [end:l1] -->

??? question "L2: Run a script as a service under a non-root user with its own writable directory."
    **Say first:** create a system user and let systemd create the directory.

    **Proof:** `useradd -r -s /usr/sbin/nologin <user>`; `User=<user>`, `StateDirectory=<name>` in the unit; `ls -l /var/lib/<name>`.

    **Follow-up:** What does `DynamicUser=yes` change?

??? question "L2: Limit a service to 256 MiB of memory and 50% of one CPU."
    **Say first:** set cgroup limits in the unit.

    **Proof:** `MemoryMax=256M` and `CPUQuota=50%`, then `systemctl show -p MemoryMax -p CPUQuotaPerSecUSec <unit>`.

    **Follow-up:** What happens when the memory limit is reached?

??? question "L2: Keep secrets out of the unit file."
    **Say first:** load them from a root-only environment file or a credential.

    **Proof:** `EnvironmentFile=/etc/<name>/<name>.env` with mode `0600`, or `LoadCredential=token:/etc/<name>/token` read from `$CREDENTIALS_DIRECTORY`.

    **Follow-up:** Why can other users read `Environment=` values? (`systemctl show` is not restricted.)

??? question "L3: A new service works when run by hand but fails under systemd with Permission denied or Read-only file system."
    **Say first:** the unit runs with a different user, environment and sandbox than an interactive shell.

    **Proof:** `journalctl -u <unit>` names the path; `systemctl show -p User -p ProtectSystem -p ReadWritePaths <unit>`; reproduce with `systemd-run -P -p User=<user> -p ProtectSystem=strict <cmd>`.

    **Follow-up:** Which other differences commonly break scripts? (`PATH`, working directory, no terminal.)

---

## Related

- [Unit Files](unit-files.md): settings reference, types and dependencies
- [systemctl](systemctl.md): managing the new service
- [Signals](../07-processes/signals.md): why the script traps `SIGTERM`
- [Users](../04-users-and-access/users.md): system accounts for services

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
