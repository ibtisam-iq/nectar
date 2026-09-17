# SELinux

SELinux is mandatory access control in the RHEL family: every process and file carries a label, and the loaded policy decides which labels may interact, even for root. Most "permission denied with correct permissions" incidents on RHEL are a wrong file label, a missing port label or a boolean that is off.

**Track:** RHCSA · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Modes | `enforcing` (deny and log), `permissive` (log only, a diagnostic step), `disabled`; `setenforce 0/1` switches until reboot | `getenforce` |
| Config | `/etc/selinux/config`: `SELINUX=` and `SELINUXTYPE=targeted`; full disable needs the kernel option `selinux=0` | `sestatus` |
| Context | `user:role:type:level`; the type decides almost everything in the targeted policy | `ls -Z`, `ps -Z`, `id -Z` |
| Type enforcement | A process type (domain, nginx: `httpd_t`) may access a file type (web content: `httpd_sys_content_t`, writable: `httpd_sys_rw_content_t`) only if an `allow` rule exists | `sesearch --allow -s httpd_t` |
| Labels | New files inherit the parent directory's type; `mv` keeps the old label, `cp` takes the new one; `touch /.autorelabel` and a reboot relabel everything | `ls -Z` |
| Fix a label | `semanage fcontext -a -t TYPE 'PATH(/.*)?'` then `restorecon -Rv PATH`; `chcon` is temporary | `matchpathcon PATH` |
| Ports | Daemons may bind only ports with their type; `semanage port -a -t http_port_t -p tcp 8090` | `semanage port -l` |
| Booleans | Policy switches such as `httpd_can_network_connect`; `-P` makes them persistent | `getsebool -a` |
| Logs | AVC denials in `/var/log/audit/audit.log`; `ausearch -m AVC -ts recent`, `audit2why`, `sealert` | `sudo ausearch -m AVC` |
<!-- --8<-- [end:facts] -->

---

## Modes, Status and Contexts

`web` runs Rocky Linux 10.2 with the targeted policy in enforcing mode. The kernel lists SELinux as its active Linux Security Module.

```bash
getenforce
sestatus
cat /sys/kernel/security/lsm; echo
ls -Z /etc/shadow /usr/sbin/nginx /usr/share/nginx/html/index.html
ps -eZ | grep -E ' (nginx|named|sshd|chronyd)$' | sort -u -k4 | head -6
ssh deploy@172.16.1.3 'id -Z'    # from client
```

Output:

```text
Enforcing
SELinux status:                 enabled
# ... (trimmed)
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
# ... (trimmed)
capability,selinux
           system_u:object_r:shadow_t:s0 /etc/shadow
       system_u:object_r:httpd_exec_t:s0 /usr/sbin/nginx
system_u:object_r:httpd_sys_content_t:s0 /usr/share/nginx/html/index.html
system_u:system_r:chronyd_t:s0      850 ?        00:00:00 chronyd
system_u:system_r:httpd_t:s0        941 ?        00:00:00 nginx
system_u:system_r:named_t:s0        906 ?        00:00:01 named
system_u:system_r:sshd_t:s0-s0:c0.c1023 90394 ?  00:00:00 sshd
unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

systemd starts `/usr/sbin/nginx` (type `httpd_exec_t`), and a policy transition puts the process into the `httpd_t` domain. Logged-in users run as `unconfined_t`, which the targeted policy barely restricts; the confinement applies to services.

---

## A Denied File

nginx on `web` serves `/static/` from a new directory with `location /static/ { alias /data/www/; }`. File modes allow reading, but the new files inherited `root_t` from `/`.

```bash
sudo mkdir -p /data/www
echo 'static file from /data/www' | sudo tee /data/www/index.html >/dev/null
ls -Zd /data /data/www /data/www/index.html
sudo systemctl reload nginx
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/static/index.html
sudo tail -1 /var/log/nginx/error.log
sudo ausearch -m AVC -ts recent | grep -o 'avc: .*'
matchpathcon /data/www/index.html
```

Output:

```text
system_u:object_r:root_t:s0 /data
system_u:object_r:root_t:s0 /data/www
system_u:object_r:root_t:s0 /data/www/index.html
403
2026/09/17 16:26:54 [error] 92269#92269: *257 open() "/data/www/index.html" failed (13: Permission denied), client: 127.0.0.1, server: api.shop.internal, request: "GET /static/index.html HTTP/1.1", host: "127.0.0.1:8080"
# ... (trimmed: an earlier denial)
avc:  denied  { read } for  pid=92269 comm="nginx" name="index.html" dev="vda" ino=509955 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:root_t:s0 tclass=file permissive=0
/data/www/index.html	system_u:object_r:default_t:s0
```

The AVC names the source domain (`httpd_t`), the target type (`root_t`), the class and the permission. `matchpathcon` shows what `restorecon` would set: `default_t`, which nginx cannot read either.

### chcon, restorecon and semanage fcontext

`chcon` changes the label on disk but not the policy's file-context rules, so the next `restorecon` or relabel undoes it:

```bash
sudo chcon -R -t httpd_sys_content_t /data/www
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/static/index.html
sudo restorecon -Rv /data/www
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/static/index.html
```

Output:

```text
200
Relabeled /data/www from system_u:object_r:httpd_sys_content_t:s0 to system_u:object_r:default_t:s0
Relabeled /data/www/index.html from system_u:object_r:httpd_sys_content_t:s0 to system_u:object_r:default_t:s0
403
```

The lasting fix adds a local file-context rule (listed by `sudo semanage fcontext -l -C`) and applies it:

```bash
sudo semanage fcontext -a -t httpd_sys_content_t '/data/www(/.*)?'
sudo restorecon -Rv /data/www
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8080/static/index.html
matchpathcon /data/www/new.html
```

Output:

```text
Relabeled /data/www from system_u:object_r:default_t:s0 to system_u:object_r:httpd_sys_content_t:s0
Relabeled /data/www/index.html from system_u:object_r:default_t:s0 to system_u:object_r:httpd_sys_content_t:s0
200
/data/www/new.html	system_u:object_r:httpd_sys_content_t:s0
```

!!! tip "Check the policy's own rules first"
    The policy already maps `/srv/([^/]*/)?www(/.*)?` to `httpd_sys_content_t` (`semanage fcontext -l | grep ^/srv`). A first attempt with `/srv/www` failed only because the new directory inherited `var_t` from `/srv`; a plain `restorecon -Rv /srv/www` would have fixed it.

---

## Port Labels

nginx may bind only ports of type `http_port_t` (and a few related types). Port 8090 had no label.

```bash
printf 'server {\n    listen 8090;\n    root /data/www;\n}\n' | sudo tee /etc/nginx/conf.d/static.conf >/dev/null
sudo nginx -t
sudo systemctl restart nginx; echo "exit=$?"
sudo journalctl -u nginx --since -30s | grep -E 'bind|failed' | head -3
sudo semanage port -a -t http_port_t -p tcp 8090
sudo systemctl restart nginx; echo "exit=$?"
curl -s http://127.0.0.1:8090/
```

Output:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# ... (trimmed)
Job for nginx.service failed because the control process exited with error code.
# ... (trimmed)
exit=1
Sep 17 16:27:11 web nginx[92382]: nginx: [emerg] bind() to 0.0.0.0:8090 failed (13: Permission denied)
Sep 17 16:27:11 web nginx[92382]: nginx: configuration file /etc/nginx/nginx.conf test failed
exit=0
static file from /data/www
```

`nginx -t` passed when root ran it from a shell, and failed inside the service, where it runs as `httpd_t`.

---

## Booleans

On `gw`, the nginx reverse proxy returned 502 and HAProxy did not start after SELinux was switched to enforcing. Both are policy switches, not labels.

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1/
sudo ausearch -m AVC -c nginx -ts recent | grep -o 'avc: .*' | tail -1
sudo ausearch -m AVC -c nginx -ts recent | audit2why | grep -A4 'Was caused by' | head -6
sudo setsebool -P httpd_can_network_connect on
curl -s http://127.0.0.1/
sudo ausearch -m AVC -c haproxy -ts recent | grep -o 'avc: .*' | tail -1
sudo semanage port -l | grep -w 8081
sudo setsebool -P haproxy_connect_any on
sudo systemctl restart haproxy; echo "exit=$?"
```

Output:

```text
502
avc:  denied  { name_connect } for  pid=945 comm="nginx" dest=8080 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:http_cache_port_t:s0 tclass=tcp_socket permissive=0
	Was caused by:
	One of the following booleans was set incorrectly.
	Description:
	Allow httpd to can network connect

--
shop-api on client (172.16.0.2:8080) client=172.16.0.3 xff=127.0.0.1
avc:  denied  { name_bind } for  pid=6683 comm="haproxy" src=8081 scontext=system_u:system_r:haproxy_t:s0 tcontext=system_u:object_r:transproxy_port_t:s0 tclass=tcp_socket permissive=0
transproxy_port_t              tcp      8081
exit=0
```

nginx's own log said `connect() to 172.16.0.2:8080 failed (13: Permission denied)`, and HAProxy's said `cannot bind socket (Permission denied) for [0.0.0.0:8081]`. Port 8081 already belongs to `transproxy_port_t`, so relabeling it would need `semanage port -m`; `haproxy_connect_any` lets HAProxy use any port.

### Tools That Suggest Wrong Fixes

`audit2allow` turns denials into allow rules, and `sealert` ranks possible fixes. For the `root_t` denial above, both pointed away from the real fix, a file label:

```bash
sudo ausearch -m AVC -ts today -c nginx | audit2allow
```

Output:

```text
#============= httpd_t ==============
allow httpd_t default_t:file read;

#!!!! This avc can be allowed using the boolean 'daemons_dump_core'
allow httpd_t root_t:file read;

#!!!! This avc can be allowed using the boolean 'nis_enabled'
allow httpd_t unreserved_port_t:tcp_socket name_bind;
allow httpd_t var_t:file read;
```

`sudo sealert -a` on the single `root_t` record ranked `setsebool -P daemons_dump_core 1` first, with `89.3 confidence`. A module with `allow httpd_t root_t:file read` would let nginx read most of the filesystem.

!!! danger "Never load audit2allow output without reading it"
    Every suggestion above widens what a network-facing daemon can read or bind. Fix labels with `semanage fcontext` and `restorecon`, ports with `semanage port`, and use documented booleans; a custom module is the last resort.

---

## How the Kernel Decides

SELinux is a Linux Security Module: the kernel calls its hooks at points such as `open()`, `bind()` and `connect()`, after the normal permission checks pass. The hook looks up the decision for (source type, target type, class) in the Access Vector Cache and asks the loaded policy on a miss.

The policy on `web` has 4669 types and 57482 allow rules (`seinfo`), and none lets `httpd_t` read `default_t` files: `sesearch --allow -s httpd_t -t default_t -c file -p read` printed nothing, so the read was denied. `/sys/fs/selinux/avc/cache_stats` reported 12283014 lookups and 12266820 cache hits on the first CPU, more than 99%.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between chcon and semanage fcontext?"
    **Say first:** `chcon` changes a label on disk only; `semanage fcontext` changes the policy's labeling rules, which `restorecon` and relabels apply.

    **Proof:** after `chcon`, `restorecon -Rv /data/www` put `default_t` back and the page returned 403.

    **Follow-up:** Why does `mv` from `/tmp` cause SELinux denials?
<!-- --8<-- [end:l1] -->

??? question "L2: Serve a website from /data/www with nginx on RHEL."
    **Say first:** point nginx at the path, add a file-context rule and relabel.

    **Proof:** `sudo semanage fcontext -a -t httpd_sys_content_t '/data/www(/.*)?'`; `sudo restorecon -Rv /data/www`; `curl` returns 200.

    **Follow-up:** The application also writes uploads there. Which type do you use?

??? question "L2: nginx must listen on 8090 and proxy to a backend on another host."
    **Say first:** label the port and enable the network-connect boolean.

    **Proof:** `sudo semanage port -a -t http_port_t -p tcp 8090`; `sudo setsebool -P httpd_can_network_connect on`.

    **Follow-up:** How do you find which boolean a denial needs?

??? question "L3: After a server migration, the site returns 403 and the error log says Permission denied, but the modes are fine. How do you proceed?"
    **Say first:** confirm SELinux denials in the audit log, then compare the actual label with the expected one.

    **Proof:** `sudo ausearch -m AVC -ts recent`; `ls -Z` against `matchpathcon`; fix with `semanage fcontext` and `restorecon`, not `setenforce 0`.

    **Follow-up:** How would `sudo setenforce 0` help confirm the cause without leaving the server exposed?

??? question "L4: What happens inside the kernel when nginx opens a file on an SELinux system?"
    **Say first:** after the normal permission check, the `open` path calls the SELinux LSM hook, which checks (httpd_t, file type, file, read open) in the AVC and denies unless an allow rule exists.

    **Proof:** the AVC record names `scontext`, `tcontext`, `tclass` and the permission; `/sys/fs/selinux/avc/cache_stats` shows the cache; `sesearch --allow` shows the rules.

    **Don't say:** SELinux replaces file permissions; both checks must pass.

??? question "L4: How does a service end up in its own SELinux domain?"
    **Say first:** a type transition rule says that when `init_t` executes a file labeled `httpd_exec_t`, the new process runs as `httpd_t`.

    **Proof:** `ls -Z /usr/sbin/nginx` shows `httpd_exec_t`; `ps -eZ` shows `httpd_t`; a binary with the wrong label runs in the wrong domain or fails to start.

    **Don't say:** the label comes from the unit file.

---

## Related

- [AppArmor](apparmor.md): the path-based equivalent on Ubuntu
- [sshd Server](../14-ssh-and-remote-access/sshd-server.md) and [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md): `ssh_port_t` and `ssh_home_t` in practice
- [auditd](auditd.md): where AVC records are stored and searched

Captured on Rocky Linux 10.2 (selinux-policy-targeted 42.1.18, SELinux enforcing on the iximiuz Labs kernel 6.1.167) on FlexBox microVMs, 2026-09.
