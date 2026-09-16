# Systemd and Services

How systemd boots the system into a target, and how services are managed, defined, overridden, hardened and inspected.

---

## Revision Card

| Fact | Value |
|---|---|
| PID 1 | systemd (257 on Rocky 10.2, 255 on Ubuntu 24.04) |
| Server target | `multi-user.target` (runlevel 3); `graphical.target` is runlevel 5 |
| `start` vs `enable` | Now vs next boot; `enable --now` does both |
| `mask` | Links the unit to `/dev/null`; nothing can start it |
| `reload` vs `restart` | Same PID and connections vs new process |
| Unit precedence | `/etc/systemd/system` over `/run` over `/usr/lib/systemd/system` |
| Drop-ins | `<unit>.d/*.conf`; `ExecStart=` needs an empty line to reset |
| After editing | `systemctl daemon-reload` |
| `Type=simple` | `start` succeeds even if the binary is missing; `Type=exec` reports it |
| Backgrounding daemon | Needs `Type=forking`, or systemd kills the children |
| `Wants=` vs `After=` | Pull in vs order; usually both |
| Start limit | 5 starts in 10 s by default, then "Start request repeated too quickly" |
| `status=203/EXEC` | `ExecStart=` could not be executed |
| Stop sequence | `SIGTERM`, then `SIGKILL` after `TimeoutStopSec=` (90 s) |
| Package install | RHEL leaves services disabled; Ubuntu enables and starts them |

| Task | Command |
|---|---|
| Default target | `systemctl get-default`, `sudo systemctl set-default multi-user.target` |
| Enable and start | `sudo systemctl enable --now <unit>` |
| Why did it fail | `systemctl status <unit>`, `journalctl -u <unit> -b` |
| Failed units | `systemctl --failed`, `sudo systemctl reset-failed` |
| Show the unit and overrides | `systemctl cat <unit>` |
| Override a setting | `sudo systemctl edit <unit>` |
| One property | `systemctl show -p MainPID --value <unit>` |
| Check a unit file | `systemd-analyze verify <file>` |
| Security score | `systemd-analyze security <unit>` |
| Slow boot | `systemd-analyze blame`, `systemd-analyze critical-chain` |
| One-off job with limits | `sudo systemd-run --unit=<name> -p MemoryMax=1G <cmd>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Init and Targets](init-and-targets.md) | SysV vs systemd, targets and runlevels, default target, isolate, shutdown | Core | Med |
| [systemctl](systemctl.md) | Start, enable, status, reload, mask, listing, distribution differences | Core | High |
| [Unit Files](unit-files.md) | Sections, paths, drop-ins, `Type=`, restarts, dependencies | Core | High |
| [Writing a Service](writing-a-service.md) | A hardened service from a script, environment files, sandbox tests | Core | Med |
| [Systemd Toolbox](systemd-toolbox.md) | `systemd-analyze`, `systemd-run`, `loginctl`, `tmpfiles.d` | Core | Low |

---

## Scenarios and Labs

- [Process Won't Die](../interview/scenarios/process-wont-die.md): a service that systemd keeps restarting
- [Processes and Services Lab](../labs/processes-and-services-lab.md): write, break and fix a service
