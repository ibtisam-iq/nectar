# Unit Files

A unit file is the declarative description systemd uses for a service, socket, timer, mount or target: what to run, when, after what, and how to restart it. Most service failures in practice come from a few settings in these files, such as the path in `ExecStart=`, the `Type=`, ordering and overrides that never took effect.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Unit types | `.service`, `.socket`, `.timer`, `.target`, `.mount`, `.automount`, `.path`, `.slice`, `.scope`, `.device`, `.swap` | `systemctl -t help` |
| Sections | `[Unit]` (description, dependencies), `[Service]` / `[Socket]` / ... (type-specific), `[Install]` (enable) | `systemctl cat <unit>` |
| Search order | `/etc/systemd/system` overrides `/run/systemd/system`, which overrides `/usr/lib/systemd/system` | `systemd-analyze unit-paths` |
| Vendor units | `/usr/lib/systemd/system` (packages); never edit them | `systemctl show -p FragmentPath` |
| Drop-ins | `/etc/systemd/system/<unit>.d/*.conf` change single settings | `systemctl show -p DropInPaths` |
| `systemctl edit <unit>` | Creates `override.conf` and reloads; `--full` copies the whole unit | `systemctl cat <unit>` |
| List-valued settings | `ExecStart=` with an empty value resets the list before a new value | `systemctl cat <unit>` |
| `daemon-reload` | Required after any file change; otherwise systemd warns "changed on disk" | `systemctl status <unit>` |
| `Type=` | `simple` (default), `exec`, `forking`, `oneshot`, `notify`, `dbus`, `idle` | `systemctl show -p Type <unit>` |
| `Restart=` | `no` (default), `on-failure`, `always`, `on-abnormal`; `RestartSec=` delay | `systemctl show -p NRestarts <unit>` |
| Start limit | `StartLimitBurst=5` in `StartLimitIntervalSec=10s` by default, then "Start request repeated too quickly" | `systemctl reset-failed <unit>` |
| `Wants=` / `Requires=` | Pull in another unit; `Requires=` also fails or stops with it | `systemctl list-dependencies <unit>` |
| `After=` / `Before=` | Ordering only; without them, units start in parallel | `systemctl show -p After <unit>` |
| `network-online.target` | Needs `Wants=` and `After=` to wait for configured networking | `systemctl show -p WantedBy network-online.target` |
| Check a file | `systemd-analyze verify <file>` | `systemd-analyze verify <file>` |
| Overrides report | `systemd-delta` lists overridden and extended units | `systemd-delta --type=extended` |
<!-- --8<-- [end:facts] -->

---

## Anatomy of a Unit

```bash
systemctl cat nginx.service | head -25
```

Output:

```text
# /usr/lib/systemd/system/nginx.service
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

| Setting | Meaning |
|---|---|
| `After=` / `Wants=` | Start after the network is configured, and ask for that target |
| `Type=forking` | `ExecStart=` forks a daemon and exits; `PIDFile=` tells systemd the main PID |
| `ExecStartPre=` | Commands that must succeed before the main command |
| `KillSignal=SIGQUIT` | nginx treats `QUIT` as a graceful stop |
| `KillMode=mixed` | `SIGQUIT` to the main process, `SIGKILL` to the rest after the timeout |
| `WantedBy=` | The target that `enable` links the unit into |

---

## Where Units Live

```bash
systemctl show nginx -p FragmentPath -p DropInPaths
```

Output:

```text
FragmentPath=/usr/lib/systemd/system/nginx.service
DropInPaths=
```

`systemd-analyze unit-paths` lists the full search order; earlier directories win. A file with the same name in `/etc/systemd/system` replaces the vendor unit completely; a drop-in directory changes only the settings it names. Package updates overwrite `/usr/lib/systemd/system` and never touch `/etc`; Ubuntu 24.04 uses the same paths, while older Debian releases used `/lib/systemd/system`.

---

## Overrides with Drop-ins

`systemctl edit nginx` opens an editor on `/etc/systemd/system/nginx.service.d/override.conf` and reloads on save. The same file can be written directly, followed by `daemon-reload`:

```bash
sudo mkdir -p /etc/systemd/system/nginx.service.d
printf '[Service]\nRestart=on-failure\nRestartSec=2\nLimitNOFILE=65536\n' | sudo tee /etc/systemd/system/nginx.service.d/override.conf >/dev/null
systemctl status nginx --no-pager | head -3
sudo systemctl daemon-reload; systemctl cat nginx | tail -6
systemctl show nginx -p Restart -p LimitNOFILE -p DropInPaths
```

Output:

```text
Warning: The unit file, source configuration file or drop-ins of nginx.service changed on disk. Run 'systemctl daemon-reload' to reload units.
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)

# /etc/systemd/system/nginx.service.d/override.conf
[Service]
Restart=on-failure
RestartSec=2
LimitNOFILE=65536
Restart=on-failure
LimitNOFILE=65536
DropInPaths=/etc/systemd/system/nginx.service.d/override.conf
```

Settings such as `LimitNOFILE=` apply only to processes started after the change, so the service needs a restart.

### Replacing ExecStart

`ExecStart=` is a list. A drop-in that adds a second value to a non-oneshot service makes the unit invalid; an empty assignment clears the list first.

```bash
printf '[Service]\nExecStart=/usr/sbin/nginx -g "worker_processes 1;"\n' | sudo tee /etc/systemd/system/nginx.service.d/cmd.conf >/dev/null
sudo systemctl daemon-reload; sudo systemctl restart nginx
systemctl status nginx --no-pager | head -4
journalctl -b -u nginx --no-pager -o cat | grep -i "ExecStart" | tail -2
```

Output:

```text
Failed to restart nginx.service: Unit nginx.service has a bad unit file setting.
See system logs and 'systemctl status nginx.service' for details.
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: bad-setting (Reason: Unit nginx.service has a bad unit file setting.)
    Drop-In: /etc/systemd/system/nginx.service.d
             └─cmd.conf, override.conf
nginx.service: Service has more than one ExecStart= setting, which is only allowed for Type=oneshot services. Refusing.
nginx.service: Service has more than one ExecStart= setting, which is only allowed for Type=oneshot services. Refusing.
```

The correct drop-in:

```ini
[Service]
ExecStart=
ExecStart=/usr/sbin/nginx -g "worker_processes 1;"
```

---

## Service Types

`Type=` tells systemd when a service counts as started and which process is the main one.

| `Type=` | Started when | Use for |
|---|---|---|
| `simple` | Immediately after `fork()` | Default; foreground programs |
| `exec` | After `execve()` succeeded | Foreground programs; reports a bad path as a start failure |
| `forking` | The `ExecStart=` process exits | Classic daemons that background themselves |
| `oneshot` | `ExecStart=` finished | Setup scripts; often with `RemainAfterExit=yes` |
| `notify` | The program sends `READY=1` via `sd_notify` | Programs with systemd support (`sshd` on Ubuntu, PostgreSQL) |
| `dbus` | The program takes its D-Bus name | D-Bus services |

The difference between `simple` and `exec` shows with a missing binary:

```bash
sudo systemctl start exec-simple; echo rc=$?
sudo systemctl start exec-exec; echo rc=$?
```

Output:

```text
rc=0
Job for exec-exec.service failed because the control process exited with error code.
See "systemctl status exec-exec.service" and "journalctl -xeu exec-exec.service" for details.
rc=1
```

Both units have `ExecStart=/opt/missing/bin/app`. With `Type=simple`, `systemctl start` returned success and the unit failed a moment later; deployment scripts that trust the exit code miss the failure.

A daemon that backgrounds itself needs `Type=forking`. Under `Type=simple`, systemd sees the main process exit, marks the unit finished and kills the rest of its cgroup:

```bash
sudo systemctl start fork; systemctl status fork --no-pager | sed -n "1,4p;/CGroup/,+1p"
sudo systemctl start simple-fork; sleep 1; systemctl status simple-fork --no-pager | sed -n "1,3p"; pgrep -a -f "sleep 600"
```

Output:

```text
● fork.service - Forking daemon without PIDFile
     Loaded: loaded (/etc/systemd/system/fork.service; static)
     Active: active (running) since Wed 2026-09-16 19:12:16 UTC; 8ms ago
 Invocation: d90c90e794214a319f35ae337f654710
     CGroup: /system.slice/fork.service
             └─4481 sleep 600
○ simple-fork.service - Daemon that backgrounds itself under Type=simple
     Loaded: loaded (/etc/systemd/system/simple-fork.service; static)
     Active: inactive (dead)
4481 sleep 600
```

Both units run `ExecStart=/usr/bin/bash -c 'sleep 600 & exit 0'`. Only the `sleep` of `fork.service` (PID 4481) is still running. `static` means the units have no `[Install]` section.

---

## Restart and Start Limits

`Restart=on-failure` restarts after a non-zero exit, a signal or a timeout, and the start limit stops the loop. `flaky.service` runs `ExecStart=/usr/bin/bash -c 'echo starting; exit 1'` with `Restart=on-failure` and `RestartSec=1` in `[Service]`, and `StartLimitIntervalSec=30` and `StartLimitBurst=3` in `[Unit]`:

```bash
sudo systemctl start flaky; sleep 5
systemctl status flaky --no-pager
systemctl show flaky -p NRestarts -p Result
sudo systemctl start flaky
sudo systemctl reset-failed flaky; systemctl is-failed flaky
```

Output:

```text
× flaky.service - Crashes on start
     Loaded: loaded (/etc/systemd/system/flaky.service; static)
     Active: failed (Result: exit-code) since Wed 2026-09-16 19:11:36 UTC; 1s ago
   Duration: 103ms
 Invocation: 8119cac66714457dad9afbf7e39a5618
    Process: 4061 ExecStart=/usr/bin/bash -c echo starting; exit 1 (code=exited, status=1/FAILURE)
   Main PID: 4061 (code=exited, status=1/FAILURE)

Sep 16 19:11:36 rocky-01 systemd[1]: flaky.service: Scheduled restart job, restart counter is at 3.
Sep 16 19:11:36 rocky-01 systemd[1]: flaky.service: Start request repeated too quickly.
Sep 16 19:11:36 rocky-01 systemd[1]: flaky.service: Failed with result 'exit-code'.
Sep 16 19:11:36 rocky-01 systemd[1]: Failed to start flaky.service - Crashes on start.
Result=exit-code
NRestarts=3
Job for flaky.service failed because the control process exited with error code.
See "systemctl status flaky.service" and "journalctl -xeu flaky.service" for details.
inactive
```

`StartLimit*` settings belong in `[Unit]`, not `[Service]`. After the limit is reached, `reset-failed` clears the counter.

!!! warning "Restart=always hides crash loops"
    A service that restarts every few seconds looks `active` most of the time. Check `NRestarts` and the journal, and keep the start limit so that a broken release ends in `failed`, which monitoring can alert on.

---

## Dependencies and Ordering

`Wants=` and `Requires=` decide which units start together; `After=` and `Before=` decide the order. Without ordering, both start in parallel.

`app-web.service` with only `Wants=app-db.service`:

```bash
sudo systemctl start app-web; journalctl -u app-db -u app-web --no-pager -o short-precise -n 20 | grep -E "starting|ready"
```

Output:

```text
Sep 16 19:12:18.378030 rocky-01 bash[4539]: db starting
Sep 16 19:12:18.400186 rocky-01 echo[4541]: web starting
```

The web unit started 22 ms after the database began, without waiting for it. With `After=app-db.service` added:

```bash
sudo systemctl start app-web; journalctl -u app-db -u app-web --no-pager -o short-precise -n 30 | grep -E "starting|ready" | tail -3
systemctl show app-web -p Wants -p After -p Requires
```

Output:

```text
Sep 16 19:12:19.698086 rocky-01 bash[4589]: db starting
Sep 16 19:12:21.699369 rocky-01 bash[4589]: db ready
Sep 16 19:12:21.789975 rocky-01 echo[4592]: web starting
Requires=sysinit.target system.slice
Wants=app-db.service
After=basic.target sysinit.target system.slice app-db.service systemd-journald.socket
```

| Directive | Pulls in the other unit | Fails if it fails | Stops with it | Orders |
|---|---|---|---|---|
| `Wants=` | Yes | No | No | No |
| `Requires=` | Yes | Yes (with `After=`) | Yes | No |
| `BindsTo=` | Yes | Yes | Yes, also when it disappears | No |
| `Requisite=` | No, must already be active | Yes | Yes | No |
| `After=` / `Before=` | No | No | No | Yes |
| `Conflicts=` | Stops the other unit | | | No |

!!! tip "Wait for the network with network-online.target"
    `network.target` only means the network stack is up. A service that must reach a remote host at start needs `Wants=network-online.target` and `After=network-online.target`, as the nginx unit has.

---

## Common Errors

### `Failed to restart nginx.service: Unit nginx.service has a bad unit file setting.`

**Cause:** a setting failed to parse, often a second `ExecStart=` added by a drop-in.

**Fix:** `journalctl -b -u <unit>` names the setting; add an empty `ExecStart=` before the new one, or run `systemd-analyze verify`.

### `Warning: The unit file, source configuration file or drop-ins of nginx.service changed on disk. Run 'systemctl daemon-reload' to reload units.`

**Cause:** a unit or drop-in was edited without reloading, so systemd still uses the old version.

**Fix:** `sudo systemctl daemon-reload`, then restart the unit if the change affects the running process.

### `flaky.service: Start request repeated too quickly.`

**Cause:** the unit failed more than `StartLimitBurst` times within `StartLimitIntervalSec`.

**Fix:** fix the cause in the journal, then `sudo systemctl reset-failed <unit>` and start it.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: Where do unit files live, and which location wins?"
    **Say first:** vendor units are in `/usr/lib/systemd/system`, runtime units in `/run/systemd/system`, and administrator units and drop-ins in `/etc/systemd/system`, which takes precedence.

    **Proof:** `systemd-analyze unit-paths`; `systemctl show -p FragmentPath -p DropInPaths <unit>`

    **Follow-up:** Why should the vendor file not be edited?

??? question "L1: What is the difference between Wants= and After=?"
    **Say first:** `Wants=` makes systemd start the other unit too; `After=` only orders the start. A dependency usually needs both.

    **Proof:** with only `Wants=`, the journal shows both units starting within milliseconds.

    **Follow-up:** When do you use `Requires=` instead of `Wants=`?

??? question "L1: What do Type=simple and Type=forking mean?"
    **Say first:** `simple` treats the started process as the service; `forking` expects it to fork a daemon and exit, and tracks the child.

    **Proof:** a backgrounding script under `Type=simple` ends as `inactive (dead)` and systemd kills its child.

    **Follow-up:** Why is `Type=exec` safer than `simple`?
<!-- --8<-- [end:l1] -->

??? question "L2: Raise the open-file limit of nginx without editing the vendor unit."
    **Say first:** add a drop-in and restart.

    **Proof:**

    ```bash
    sudo systemctl edit nginx      # [Service] LimitNOFILE=65536
    sudo systemctl restart nginx
    cat /proc/$(systemctl show -p MainPID --value nginx)/limits | grep 'open files'
    ```

    **Follow-up:** Why does `/etc/security/limits.conf` not apply to services?

??? question "L2: Make a service restart on failure, but give up after 3 failures in 30 seconds."
    **Say first:** set `Restart=` in `[Service]` and the start limit in `[Unit]`.

    **Proof:** `StartLimitIntervalSec=30`, `StartLimitBurst=3`, `Restart=on-failure`, `RestartSec=1`; `systemctl show -p NRestarts`.

    **Follow-up:** How do you start it again after it hit the limit?

??? question "L3: An application service fails at boot but starts fine manually a minute later."
    **Say first:** it probably starts before something it needs: the network, a mount or a database.

    **Proof:** `journalctl -b -u <unit>` shows a connection or path error; `systemd-analyze critical-chain <unit>` shows its order; add `Wants=` and `After=` for `network-online.target`, the mount (`RequiresMountsFor=`) or the database unit.

    **Follow-up:** Why is a `sleep` in `ExecStartPre=` the wrong fix?

??? question "L4: How does systemd know which processes belong to a service?"
    **Say first:** it starts every service in its own cgroup, and every child inherits the cgroup, so forked and double-forked processes are still tracked without PID files.

    **Proof:** `systemd-cgls -u nginx.service`; `cat /proc/<pid>/cgroup` shows `/system.slice/nginx.service`.

    **Don't say:** "systemd follows the PID file."

---

## Related

- [systemctl](systemctl.md): commands that act on units
- [Writing a Service](writing-a-service.md): a unit built from scratch
- [Process Lifecycle](../07-processes/process-lifecycle.md): daemons and double forks
- [Signals](../07-processes/signals.md): `KillSignal=` and the stop sequence

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
