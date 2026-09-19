# rsyslog

rsyslog is the syslog daemon on RHEL and Ubuntu: it takes messages from the journal and writes them to files or remote servers by facility, priority and content. Its rules explain why a message lands in a given file, and its forwarding is the simplest way to centralize logs.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Config | `/etc/rsyslog.conf`, then `/etc/rsyslog.d/*.conf` | `grep include /etc/rsyslog.conf` |
| Selector | `facility.priority` means that priority and higher; `.=` exactly; `.none` excludes | `grep authpriv /etc/rsyslog.conf` |
| Facilities | `kern`, `user`, `mail`, `daemon`, `auth`, `authpriv`, `cron`, `local0` to `local7` | `man 3 syslog` |
| Stop processing | `& stop` after a rule, or `stop` inside `if` | `cat /etc/rsyslog.d/*.conf` |
| Validate | `rsyslogd -N1` (exit 1 on errors) | `rsyslogd -N1` |
| Forward over UDP / TCP | `*.* @host:514` / `*.* @@host:514` | Rule in `/etc/rsyslog.d/` |
| Receive | `module(load="imtcp")` and `input(type="imtcp" port="514")` | `ss -tlnp "sport = :514"` |
| Property filters | `:msg, contains, "segfault" /var/log/crashes.log` matches text instead of facility | `logger -t test segfault` |
| Test messages | `logger -p local3.err -t app "text"`; remote: `logger -n host -P 514 -T` | `tail /var/log/messages` |
| Leading `-` on a file | Ubuntu syntax for "do not sync after each line" | `/etc/rsyslog.d/50-default.conf` |
<!-- --8<-- [end:facts] -->

---

## Rules and Validation

A rule is a selector followed by an action. Files in `/etc/rsyslog.d/` are included before the main rules on RHEL, so `& stop` there keeps a message out of `/var/log/messages`. As root on Rocky:

```bash
printf "local3.*    /var/log/payments.log\n& stop\n" > /etc/rsyslog.d/30-payments.conf; rsyslogd -N1
logger -p local3.err -t payments "card gateway timeout after 30s"; sleep 2; cat /var/log/payments.log; grep -c "payments\[" /var/log/messages
```

Output:

```text
rsyslogd: version 8.2510.0-5.el10_2.1, config validation run (level 1), master config /etc/rsyslog.conf
rsyslogd: End of config validation run. Bye.
Sep 17 06:01:40 rocky-01 payments[1320]: card gateway timeout after 30s
0
```

!!! warning "A restart can drop messages logged during the restart"
    A test message sent immediately after `systemctl restart rsyslog` never reached the new file; the same message sent two seconds later did. Wait for the service to settle before testing a rule.

---

## Central Logging

A receiver loads `imtcp` and writes each sender to its own directory with a template. Senders add one forwarding rule.

```bash
cat /etc/rsyslog.d/10-receive.conf
rsyslogd -N1 2>&1 | tail -1; systemctl restart rsyslog; ss -tlnp | grep 514
logger -n 127.0.0.1 -P 514 -T --rfc3164 -t billing "invoice run finished" ; sleep 1; find /var/log/remote -type f; cat /var/log/remote/*/billing.log
```

Output:

```text
module(load="imtcp")
input(type="imtcp" port="514" ruleset="remote")
template(name="PerHost" type="string" string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")
ruleset(name="remote") {
    action(type="omfile" dynaFile="PerHost")
}
rsyslogd: End of config validation run. Bye.
LISTEN 0      25           0.0.0.0:514        0.0.0.0:*    users:(("rsyslogd",pid=4048,fd=4))
LISTEN 0      25              [::]:514           [::]:*    users:(("rsyslogd",pid=4048,fd=5))
/var/log/remote/rocky-01/billing.log
Sep 17 05:54:32 rocky-01 billing: invoice run finished
```

The sender side is one line in `/etc/rsyslog.d/90-forward.conf`: `*.* @@logs.example.test:514` (`@@` is TCP, `@` is UDP). A receiver also needs the port open in the firewall and, with SELinux enforcing, a port that `semanage port -l | grep syslog` lists as `syslogd_port_t` (not captured here; see the security module).

!!! note "Plain syslog forwarding is unencrypted"
    Production setups use TLS (`omfwd` with `StreamDriver="gtls"`) or ship logs with an agent such as Fluent Bit or Vector.

---

## Common Errors

### `rsyslogd: error during parsing file /etc/rsyslog.d/30-payments.conf, on or before line 2`

**Cause:** A syntax error in the named file; the captured case was `& stpo` instead of `& stop`, and `rsyslogd -N1` exited with 1.

**Fix:** Correct the line, confirm with `rsyslogd -N1`, then restart rsyslog.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does the selector authpriv.* mean, and why does messages exclude it?"
    **Say first:** All priorities of the `authpriv` facility; `messages` excludes it with `authpriv.none` because those lines are sensitive and go to the root-only `secure` file.

    **Proof:** `grep authpriv /etc/rsyslog.conf`

    **Follow-up:** Which facilities can applications use freely? (`local0` to `local7`.)

??? question "L1: What is the difference between @ and @@ in a forwarding rule?"
    **Say first:** `@` sends over UDP, which can lose messages silently; `@@` sends over TCP.

    **Proof:** `*.* @@logs.example.test:514`

    **Follow-up:** What does TCP still not give you? (Encryption.)
<!-- --8<-- [end:l1] -->

??? question "L2: Send all messages of the local3 facility to their own file and nowhere else."
    **Say first:** A rule with `& stop` in `/etc/rsyslog.d/`.

    **Proof:** `local3.* /var/log/payments.log` and `& stop`; `rsyslogd -N1`; `logger -p local3.err test`.

    **Follow-up:** Which new file also needs a `logrotate` rule?

??? question "L2: Forward all logs to a central server over TCP."
    **Say first:** One `@@` rule on the sender, `imtcp` on the receiver.

    **Proof:** `*.* @@logs.example.test:514`; on the receiver `ss -tlnp | grep 514`.

    **Follow-up:** What is lost if the receiver is down? (Messages, unless a disk-assisted queue is configured.)

??? question "L2: Check an rsyslog change before restarting the service."
    **Say first:** Run the validator.

    **Proof:** `rsyslogd -N1; echo $?`

    **Follow-up:** What happens to logging if rsyslog fails to start? (The journal still records everything.)

??? question "L3: An application's log lines stopped appearing in the central log server. How do you check each hop?"
    **Say first:** Local journal first, then the local rsyslog, then the network path, then the receiver.

    **Proof:** `journalctl -t app -n 5`; `rsyslogd -N1`; `logger -n logs -P 514 -T test`; `ss -tn dst :514`; on the receiver, `tail` the per-host file.

    **Follow-up:** Which firewall and SELinux checks apply on the receiver?

---

## Related

- [Log Locations](log-locations.md): the default rules on each family
- [journalctl](journalctl.md): the source rsyslog reads from
- [logrotate](logrotate.md): rotating new rsyslog files

Captured on Rocky Linux 10.2 (iximiuz Labs microVM, kernel 6.1.167), 2026-09.
