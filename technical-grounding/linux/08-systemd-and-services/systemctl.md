# systemctl

`systemctl` is the command-line client of systemd: it starts, stops, enables and inspects units, and its `status` output is the first thing to read when a service misbehaves. Knowing the difference between active and enabled, and reading a failed status line such as `status=203/EXEC`, covers most service questions in interviews.

**Track:** Core · **Interview weight:** High

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `start` / `stop` / `restart` | Change the running state now | `systemctl is-active <unit>` |
| `reload` | Ask the service to reread its configuration (`ExecReload=`); the main PID stays | `systemctl show -p MainPID` |
| `enable` / `disable` | Create or remove `[Install]` symlinks; affects the next boot only | `systemctl is-enabled <unit>` |
| `enable --now` | Enable and start in one command | `systemctl status <unit>` |
| `mask` / `unmask` | Link the unit to `/dev/null` so nothing can start it | `systemctl is-enabled` shows `masked` |
| `is-active` exit codes | 0 active, 3 inactive or failed | `systemctl is-active <unit>; echo $?` |
| `status` exit codes | 0 active, 3 not running, 4 no such unit | `systemctl status <unit>; echo $?` |
| Enablement states | `enabled`, `disabled`, `static` (no `[Install]`), `masked`, `alias`, `indirect` | `systemctl list-unit-files` |
| Preset | Vendor default for `enable`: RHEL disables most new services, Ubuntu enables and starts them on install | `systemctl list-unit-files <unit>` |
| Failed units | `systemctl --failed`; clear with `systemctl reset-failed` | `systemctl is-failed <unit>` |
| Reading config | `systemctl cat <unit>` prints the unit and its drop-ins | `systemctl cat sshd` |
| Properties | `systemctl show <unit> -p MainPID -p Restart -p NRestarts` | `systemctl show <unit>` |
| After editing units | `systemctl daemon-reload` | Warning "changed on disk" |
| Without root | Read commands work; changes need `sudo` ("Interactive authentication required") | `systemctl start <unit>` as a user |
| User units | `systemctl --user` manages the per-user manager | `systemctl --user status` |
<!-- --8<-- [end:facts] -->

---

## Start, Enable, Status

`start` affects the running system and `enable` affects the next boot; the two are independent. `enable --now` does both.

```bash
sudo systemctl stop nginx; sudo systemctl disable nginx
systemctl is-active nginx; echo rc=$?; systemctl is-enabled nginx; echo rc=$?
systemctl start nginx
sudo systemctl enable --now nginx
```

Output:

```text
inactive
rc=3
disabled
rc=1
Failed to start nginx.service: Interactive authentication required.
See system logs and 'systemctl status nginx.service' for details.
Created symlink '/etc/systemd/system/multi-user.target.wants/nginx.service' → '/usr/lib/systemd/system/nginx.service'.
```

The symlink is what `enable` does: `WantedBy=multi-user.target` in the unit's `[Install]` section becomes a link in `multi-user.target.wants/`.

### Reading status

```bash
systemctl status nginx --no-pager -n 3
```

Output:

```text
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: active (running) since Wed 2026-09-16 19:10:57 UTC; 7ms ago
 Invocation: 22117ace13564a3a838c4206f09ea275
    Process: 3609 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 3611 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 3615 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 3616 (nginx)
      Tasks: 5 (limit: 51276)
     Memory: 4.7M (peak: 4.7M)
        CPU: 23ms
     CGroup: /system.slice/nginx.service
             ├─3616 "nginx: master process /usr/sbin/nginx"
             ├─3617 "nginx: worker process"
             ├─3618 "nginx: worker process"
             ├─3620 "nginx: worker process"
             └─3621 "nginx: worker process"

Sep 16 19:10:56 rocky-01 nginx[3611]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Sep 16 19:10:56 rocky-01 nginx[3611]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Sep 16 19:10:57 rocky-01 systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
```

| Line | Meaning |
|---|---|
| `●` / `○` / `×` | Active / inactive / failed |
| `Loaded:` | Unit file path; enablement; vendor preset |
| `Active:` | State (sub-state) and since when |
| `Process:` | Helper commands (`ExecStartPre=`, `ExecStart=` of a forking service) and their exit status |
| `Main PID:` | The process systemd tracks as the service |
| `Tasks:` / `Memory:` / `CPU:` | cgroup accounting, with limits in parentheses |
| `CGroup:` | Every process of the service |
| Last lines | Recent journal entries for the unit (`-n` sets how many) |

### Scriptable checks

```bash
systemctl is-active nginx; systemctl is-enabled nginx; systemctl is-failed nginx; echo rc=$?
systemctl status nosuch.service; echo rc=$?
systemctl show nginx -p MainPID -p ActiveState -p SubState -p ExecMainStartTimestamp -p NRestarts -p UnitFileState
```

Output:

```text
active
enabled
active
rc=1
Unit nosuch.service could not be found.
rc=4
MainPID=3616
NRestarts=0
ExecMainStartTimestamp=Wed 2026-09-16 19:10:57 UTC
ActiveState=active
SubState=running
UnitFileState=enabled
```

`is-failed` returns 0 only for a failed unit, so its exit status was 1 here. `systemctl show` prints the properties in its own order, not in the order requested.

---

## Reload vs Restart

`reload` runs `ExecReload=` and keeps the process; `restart` stops and starts it, which drops connections and gives it a new PID.

```bash
sudo systemctl reload nginx; systemctl show nginx -p MainPID
sudo systemctl restart nginx; systemctl show nginx -p MainPID
```

Output:

```text
MainPID=3616
MainPID=3650
```

| | `reload` | `restart` | `try-restart` | `reload-or-restart` |
|---|---|---|---|---|
| **Process** | Kept | Replaced | Replaced if running | Kept if reload is supported |
| **Connections** | Kept | Dropped | Dropped | Depends |
| **Stopped unit** | Error | Started | Left stopped | Started |

!!! tip "Validate configuration before a reload"
    A reload with a broken configuration can leave a service on the old settings or stop it. Run the service's own check first (`nginx -t`, `sshd -t`, `apachectl configtest`, `named-checkconf`), as the nginx unit does in `ExecStartPre=`.

---

## Mask

`mask` links the unit name to `/dev/null` in `/etc/systemd/system`, which blocks manual starts and dependencies alike. It keeps a conflicting service (for example `firewalld` when `nftables` is managed directly) from coming back.

```bash
sudo systemctl mask nginx
sudo systemctl start nginx
systemctl is-enabled nginx; systemctl status nginx --no-pager | head -3
sudo systemctl unmask nginx; systemctl is-enabled nginx
```

Output:

```text
Created symlink '/etc/systemd/system/nginx.service' → '/dev/null'.
Failed to start nginx.service: Unit nginx.service is masked.
masked
● nginx.service
     Loaded: masked (Reason: Unit nginx.service is masked.)
     Active: active (running) since Wed 2026-09-16 19:10:57 UTC; 195ms ago
Removed '/etc/systemd/system/nginx.service'.
enabled
```

!!! warning "mask does not stop a running service"
    The status above still shows `active (running)`. `systemctl mask --now` masks the unit and stops it in one step.

---

## Listing Units

```bash
systemctl list-unit-files nginx.service crond.service sshd.service
systemctl list-units --type=service --state=failed --no-legend
systemctl list-units "sys*" --type=service --no-legend | head -4
```

Output:

```text
UNIT FILE     STATE    PRESET
crond.service enabled  enabled
nginx.service enabled  disabled
sshd.service  disabled enabled

3 unit files listed.
● systemd-network-generator.service loaded failed failed Generate network units from Kernel command line
  systemd-hostnamed.service                loaded active running Hostname Service
  systemd-journal-flush.service            loaded active exited  Flush Journal to Persistent Storage
  systemd-journald.service                 loaded active running Journal Service
  systemd-logind.service                   loaded active running User Login Management
```

| Command | Lists |
|---|---|
| `systemctl list-units` | Units loaded in memory (active by default; `--all` for all) |
| `systemctl list-unit-files` | Unit files on disk with their enablement and preset |
| `systemctl --failed` | Failed units |
| `systemctl list-dependencies <unit>` | What a unit pulls in; `--reverse` for what pulls it in |
| `systemctl list-jobs` | Queued start and stop jobs, useful when boot hangs |
| `systemctl list-timers` | Timers and their next run |

`sshd.service` shows `disabled` with preset `enabled` because this playground starts SSH through `sshd.socket`; a default RHEL install enables `sshd.service`.

---

## Distribution Differences

The unit commands are identical; package defaults and service names differ.

=== "RHEL / Rocky"

    ```bash
    sudo dnf install -y memcached >/dev/null 2>&1
    systemctl is-enabled memcached; systemctl is-active memcached
    ```

    Output:

    ```text
    disabled
    inactive
    ```

    RHEL's preset (`/usr/lib/systemd/system-preset/99-default-disable.preset` contains `disable *`) leaves new services disabled and stopped; the administrator enables them.

=== "Ubuntu / Debian"

    ```bash
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y memcached 2>&1 | grep -iE 'symlink|memcached.service'
    systemctl is-enabled memcached; systemctl is-active memcached
    ss -tlnp | grep 11211
    ```

    Output:

    ```text
    Created symlink /etc/systemd/system/multi-user.target.wants/memcached.service → /usr/lib/systemd/system/memcached.service.
    enabled
    active
    LISTEN 0      1024       127.0.0.1:11211      0.0.0.0:*          
    LISTEN 0      1024           [::1]:11211         [::]:*          
    ```

    Debian packages enable and start their services during installation, so a new daemon listens before it is configured. `/usr/sbin/policy-rc.d` returning 101 blocks this in images and chroots.

| Service | RHEL / Rocky | Ubuntu / Debian |
|---|---|---|
| SSH server | `sshd.service` | `ssh.service`, `ssh.socket` (socket-activated since 22.10) |
| Cron | `crond.service` | `cron.service` |
| Apache | `httpd.service` | `apache2.service` |
| Firewall | `firewalld.service` | `ufw.service` |
| Network | `NetworkManager.service` | `systemd-networkd.service` (server), `NetworkManager` (desktop) |
| Time sync | `chronyd.service` | `systemd-timesyncd.service` or `chrony.service` |

On Ubuntu 24.04:

```bash
systemctl status sshd --no-pager | head -3
```

Output:

```text
Unit sshd.service could not be found.
```

On Ubuntu 24.04 the `sshd` alias exists only while `ssh.service` is enabled; with socket activation it is not created, so use the real name `ssh`.

---

## Common Errors

### `Failed to start nginx.service: Unit nginx.service is masked.`

**Cause:** the unit is linked to `/dev/null`.

**Fix:** `sudo systemctl unmask nginx`, then start it; check why it was masked first.

### `Failed to start nginx.service: Interactive authentication required.`

**Cause:** a state change ran without root and no polkit agent could ask for a password.

**Fix:** `sudo systemctl start nginx`.

### `Unit nosuch.service could not be found.`

**Cause:** wrong name, the package is not installed, or a new unit file was added without `daemon-reload`.

**Fix:** `systemctl list-unit-files | grep <name>`, then `sudo systemctl daemon-reload`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between systemctl enable and systemctl start?"
    **Say first:** `start` runs the service now; `enable` creates the symlinks that start it at boot. Neither implies the other; `enable --now` does both.

    **Proof:** after `enable`, `is-enabled` says `enabled` while `is-active` can still say `inactive`.

    **Follow-up:** What does `enable` create on disk?

??? question "L1: What is the difference between reload and restart?"
    **Say first:** `reload` tells the running process to reread its configuration and keeps its PID and connections; `restart` stops and starts it.

    **Proof:** `systemctl show -p MainPID nginx` stays the same after `reload` and changes after `restart`.

    **Follow-up:** What happens on `reload` for a unit without `ExecReload=`?

??? question "L1: What does mask do, and how is it different from disable?"
    **Say first:** `disable` removes boot links, but the unit can still be started manually or as a dependency; `mask` links it to `/dev/null` so nothing can start it.

    **Proof:** `systemctl start` on a masked unit fails with `Unit ... is masked.`

    **Follow-up:** Give a case where masking is the right choice.
<!-- --8<-- [end:l1] -->

??? question "L2: Make nginx start at boot and start it now, then confirm both."
    **Say first:** enable with `--now` and check both states.

    **Proof:** `sudo systemctl enable --now nginx && systemctl is-enabled nginx && systemctl is-active nginx`

    **Follow-up:** What exit code does `is-active` return for a stopped unit?

??? question "L2: List every failed unit and clear the list after fixing them."
    **Say first:** use `--failed`, then `reset-failed`.

    **Proof:** `systemctl --failed`, `systemctl status <unit>`, `sudo systemctl reset-failed`

    **Follow-up:** Why does a unit stay in the failed list after the underlying problem is fixed?

??? question "L2: Print the main PID and restart count of a service for a monitoring script."
    **Say first:** use `systemctl show` with `--value`.

    **Proof:** `systemctl show -p MainPID --value nginx; systemctl show -p NRestarts --value nginx`

    **Follow-up:** Why is `show` better than parsing `status`?

??? question "L3: A package was installed on Ubuntu and a new port is already listening before configuration."
    **Say first:** Debian packages enable and start services on install; check the unit and decide whether to stop and disable it until it is configured.

    **Proof:** `ss -tlnp`, `systemctl status <unit>`, then `sudo systemctl disable --now <unit>`

    **Follow-up:** How do you prevent it in a Docker build or golden image? (`policy-rc.d`.)

??? question "L3: systemctl status shows active (running), but the application does not respond."
    **Say first:** systemd only knows the process exists; check what it is doing and what it logs.

    **Proof:** `journalctl -u <unit> -n 50`, `ss -tlnp` for the listening port, `ps -o stat,wchan -p <MainPID>` for a blocked or stopped process, then the application's own health endpoint.

    **Follow-up:** Which unit type lets systemd know the application is ready? (`Type=notify`.)

---

## Related

- [Unit Files](unit-files.md): what `enable` and `status` read
- [Writing a Service](writing-a-service.md): a complete unit from scratch
- [Init and Targets](init-and-targets.md): `WantedBy=` targets
- [Signals](../07-processes/signals.md): what `stop` sends

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
