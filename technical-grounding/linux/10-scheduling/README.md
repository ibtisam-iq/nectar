# Scheduling

Running jobs on a schedule with cron, once with `at`, and with systemd timers, and why jobs that work in a terminal fail when scheduled.

---

## Revision Card

| Fact | Value |
|---|---|
| Crontab fields | minute, hour, day of month, month, day of week |
| Day fields in cron | Day of month **or** day of week; systemd requires both |
| `%` in a crontab | Newline; escape as `\%` |
| cron `PATH` on RHEL | `/usr/bin:/bin:/usr/sbin:/sbin`, no `/usr/local/bin` |
| cron `PATH` on Ubuntu | From `/etc/environment` through `pam_env` |
| `/etc/cron.d` lines | Need a user field; without it: `bad command` (RHEL), `bad username` (Ubuntu) |
| Dot in a file name | Ignored by Debian's `run-parts` and cron in `cron.daily` and `cron.d` |
| Periodic directories | Scripts must be executable |
| Output without an MTA | RHEL logs it as `CMDOUT`; Ubuntu discards it |
| Access | `cron.allow` wins; otherwise `cron.deny`; same for `at` |
| anacron | Catches up missed daily, weekly and monthly jobs |
| Timer pair | `name.timer` starts `name.service`; enable the timer |
| `Persistent=true` | Runs a missed calendar job after boot |
| Missing service | "Refusing to start, unit ... to trigger not loaded" |

| Task | Command |
|---|---|
| Edit or list a crontab | `crontab -e`, `crontab -l`, `sudo crontab -u alice -l` |
| See cron's environment | `* * * * * env > /tmp/cron-env.txt` |
| Cron logs | `journalctl -u crond` (RHEL), `journalctl -u cron` (Ubuntu) |
| Which periodic scripts run | `run-parts --test /etc/cron.daily` (Ubuntu) |
| One-off job | `at 23:00` (commands on standard input), `atq`, `atrm 4` |
| Check a calendar expression | `systemd-analyze calendar "Mon..Fri 09:00"` |
| Enable a timer | `sudo systemctl enable --now name.timer` |
| Next and last runs | `systemctl list-timers --all` |
| Transient timer | `sudo systemd-run --on-active=10min --unit=name cmd` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [cron and at](cron-and-at.md) | Syntax, user and system crontabs, anacron, the cron environment, `run-parts`, access control, `at` | Core | High |
| [Systemd Timers](systemd-timers.md) | Timer and service pairs, calendar expressions, transient timers, timers vs cron | Core | Med |

---

## Scenarios and Labs

- [Cron Job Not Running](../interview/scenarios/cron-job-not-running.md): environment, syntax, permissions and daemon checks
