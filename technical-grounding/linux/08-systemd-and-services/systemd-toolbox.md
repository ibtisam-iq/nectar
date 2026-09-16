# Systemd Toolbox

systemd ships helper commands beyond `systemctl`: boot analysis, login sessions, transient units, cgroup views and temporary-file rules. Each replaces an older tool or a hand-written script.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Boot time | `systemd-analyze`, `blame`, `critical-chain <unit>` | `systemd-analyze blame` |
| Calendar syntax check | `systemd-analyze calendar "<expr>"` | `systemd-analyze calendar daily` |
| Sessions and users | `loginctl list-sessions`, `show-user`, `terminate-session` | `loginctl list-users` |
| Lingering | `loginctl enable-linger <user>` keeps user services running without a login | `ls /var/lib/systemd/linger` |
| Transient units | `systemd-run` runs a command as a service, scope or timer | `systemd-run --unit=<name> <cmd>` |
| cgroup tree | `systemd-cgls`; live usage with `systemd-cgtop` | `systemd-cgls -u <unit>` |
| Temporary files | `tmpfiles.d` rules create and clean paths; `systemd-tmpfiles --create` / `--clean` | `cat /usr/lib/tmpfiles.d/tmp.conf` |
| Escaping names | `systemd-escape --path` turns a path into a unit name | `systemd-escape --path /mnt/backup` |
| Logging from scripts | `systemd-cat -t <tag>` sends output to the journal | `journalctl -t <tag>` |
| Other tools | `hostnamectl`, `timedatectl`, `localectl`, `resolvectl`, `networkctl` | `hostnamectl` |
<!-- --8<-- [end:facts] -->

---

## Boot Analysis

```bash
systemd-analyze blame --no-pager | head -5
```

Output:

```text
1.819s healthcheck.service
1.290s nginx.service
1.207s dnf-makecache.service
 525ms dev-vda.device
 459ms systemd-tmpfiles-setup.service
```

!!! note "blame times overlap"
    `blame` lists start durations, which overlap because units start in parallel; `systemd-analyze critical-chain <unit>` shows the chain that delayed a unit, and `systemd-analyze plot > boot.svg` draws the whole boot.

---

## Transient Units with systemd-run

`systemd-run` gives a one-off command the same logging, limits and status as a service: `--unit=x` runs it in the background, `-P` returns its output to the terminal, `--scope` keeps it in the terminal inside a new cgroup, and `--on-active=` or `--on-calendar=` wrap it in a timer.

```bash
sudo systemd-run --unit=backup-once --on-active=10min /usr/bin/true; systemctl list-timers backup-once.timer --no-pager
```

Output:

```text
Running timer as unit: backup-once.timer
Will run service as unit: backup-once.service
NEXT                        LEFT LAST PASSED UNIT              ACTIVATES
Wed 2026-09-16 19:23:55 UTC 9min -         - backup-once.timer backup-once.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
```

---

## Temporary Files

`tmpfiles.d` rules create directories at boot and clean old files on a timer (`systemd-tmpfiles-clean.timer`, daily). A `d` line creates a directory with an owner and mode, and the last field is the cleanup age.

```bash
cat /usr/lib/tmpfiles.d/tmp.conf | grep -v "^#" | grep -v "^$"
printf 'd /run/healthcheck 0750 healthcheck healthcheck -\nd /var/tmp/reports 0755 root root 7d\n' | sudo tee /etc/tmpfiles.d/demo.conf >/dev/null
sudo systemd-tmpfiles --create /etc/tmpfiles.d/demo.conf; ls -ld /run/healthcheck /var/tmp/reports
```

Output:

```text
q /tmp 1777 root root 10d
q /var/tmp 1777 root root 30d
drwxr-x--- 2 healthcheck healthcheck   40 Sep 16 19:14 /run/healthcheck
drwxr-xr-x 2 root        root        4096 Sep 16 19:14 /var/tmp/reports
```

!!! warning "Files in /tmp and /var/tmp are deleted by age"
    Rocky 10.2 removes files in `/tmp` after 10 days and in `/var/tmp` after 30. `/run` is a tmpfs, so directories there disappear at reboot unless a `tmpfiles.d` rule or `RuntimeDirectory=` recreates them.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does systemd-analyze blame show, and what can mislead?"
    **Say first:** how long each unit took to start; units start in parallel, so the times overlap and a slow unit may not delay boot.

    **Proof:** `systemd-analyze critical-chain` shows the path that actually delayed a target.

    **Follow-up:** How do you make a slow unit stop blocking boot?
<!-- --8<-- [end:l1] -->

??? question "L2: Run a long command in the background with logging and a memory limit, without writing a unit file."
    **Say first:** start it as a transient service.

    **Proof:** `sudo systemd-run --unit=reindex -p MemoryMax=1G /opt/app/bin/reindex`, then `journalctl -u reindex -f`.

    **Follow-up:** How do you stop it? (`systemctl stop reindex`.)

??? question "L2: Keep a user's systemd services running after the user logs out."
    **Say first:** enable lingering.

    **Proof:** `sudo loginctl enable-linger <user>`; `loginctl show-user <user> -p Linger`

    **Follow-up:** Which rootless container setup depends on this? (Podman with Quadlet.)

??? question "L2: Create a directory under /run at every boot for a service user."
    **Say first:** add a `tmpfiles.d` rule, or `RuntimeDirectory=` in the unit.

    **Proof:** `d /run/app 0750 app app -` in `/etc/tmpfiles.d/app.conf`, then `systemd-tmpfiles --create`.

    **Follow-up:** Why does a directory created by hand in `/run` vanish?

??? question "L2: List every process that belongs to the nginx service."
    **Say first:** print the unit's cgroup.

    **Proof:** `systemd-cgls -u nginx.service` lists the master and each worker; `systemd-cgtop` shows their live CPU and memory.

    **Follow-up:** Why is this more reliable than `pgrep nginx`?

??? question "L3: Files a service writes to /tmp disappear after some days."
    **Say first:** `systemd-tmpfiles-clean` removes old files in `/tmp` and `/var/tmp` by age.

    **Proof:** `cat /usr/lib/tmpfiles.d/tmp.conf` shows `10d` and `30d`; `systemctl list-timers systemd-tmpfiles-clean.timer`.

    **Follow-up:** Where should the service keep data instead? (`StateDirectory=`.)

---

## Related

- [Unit Files](unit-files.md): settings `systemd-run -p` accepts
- [Writing a Service](writing-a-service.md): `StateDirectory=` and `RuntimeDirectory=`
- [Job Control](../07-processes/job-control.md): terminal-bound alternatives

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
