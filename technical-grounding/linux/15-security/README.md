# Security

How a Linux host limits what reaches it and what runs on it: host firewalls and netfilter, mandatory access control (SELinux and AppArmor), capabilities, auditing, package and file integrity, certificates and the trust store, and a hardening checklist that ties them together. Security monitoring and scanners for fleets live under [Observability and Security](../../../observability-security/index.md).

---

## Revision Card

| Fact | Value |
|---|---|
| Firewalls | RHEL: firewalld (zones, `--permanent` + `--reload`); Ubuntu: ufw (inactive by default); both write nftables rules |
| Reject vs drop | firewalld rejects (refused, unreachable); ufw and `drop` rules time out |
| firewalld order | Deny rich rules run before allow rules unless `priority` is set |
| netfilter | `input` for this host, `forward` for routed traffic, `prerouting` DNAT, `postrouting` SNAT/masquerade |
| iptables view | `iptables -S` hides nftables tables; read `nft list ruleset` |
| SELinux | `getenforce`; labels with `ls -Z`; fix with `semanage fcontext` + `restorecon`, `semanage port`, `setsebool -P` |
| SELinux logs | `ausearch -m AVC -ts recent`, `audit2why`; never load `audit2allow` output unread |
| AppArmor | Path-based profiles in `/etc/apparmor.d`; `aa-status`, `aa-complain`, `aa-enforce` |
| Capabilities | `getcap`/`setcap`, `/proc/PID/status` + `capsh --decode`; systemd `AmbientCapabilities=` |
| auditd | Watch `-w PATH -p wa -k KEY`; `ausearch -k KEY`; login UID survives `sudo` |
| GPG | `rpm -K`, `gpg --verify`; APT keys per repository with `Signed-By` |
| Certificates | Names from SAN; `openssl s_client -servername`; `-checkend` for expiry |
| Trust store | RHEL `/etc/pki/ca-trust/source/anchors` + `update-ca-trust`; Ubuntu `/usr/local/share/ca-certificates/*.crt` + `update-ca-certificates` |
| Integrity | `rpm -Va`, `debsums -s`, AIDE baseline off the host |
| Backports | Distribution packages fix CVEs without changing the upstream version |

| Task | Command |
|---|---|
| Open a port on RHEL | `sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload` |
| Open a port on Ubuntu | `sudo ufw allow from 10.0.0.0/8 to any port 8080 proto tcp` |
| Everything netfilter does | `sudo nft list ruleset` |
| Label web content | `sudo semanage fcontext -a -t httpd_sys_content_t '/data/www(/.*)?' && sudo restorecon -Rv /data/www` |
| Let nginx proxy | `sudo setsebool -P httpd_can_network_connect on` |
| Low port without root | `AmbientCapabilities=CAP_NET_BIND_SERVICE` in the unit |
| Who changed a file | `sudo ausearch -k identity --format text` |
| Certificate dates and names | `openssl x509 -in cert.pem -noout -dates -ext subjectAltName` |
| Test a TLS server | `openssl s_client -connect host:443 -servername host -brief </dev/null` |
| Verify packages | `sudo rpm -Va`, `sudo debsums -s` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [firewalld and ufw](firewalld-and-ufw.md) | Zones, runtime and permanent rules, services, rich rules, ufw rules and logs | Core | Med |
| [nftables and iptables](nftables-and-iptables.md) | Hooks, stateful filtering, NAT and port forwarding, sets, persistence | Core | Med |
| [SELinux](selinux.md) | Modes, contexts, file and port labels, booleans, AVC tools, the LSM decision | RHCSA | Med |
| [AppArmor](apparmor.md) | Profiles, modes, syntax checks, container profiles | Core | Low |
| [Capabilities](capabilities.md) | Capability sets, file capabilities, systemd grants, `ping` on both distributions | Advanced | Med |
| [auditd](auditd.md) | Watch and syscall rules, `ausearch`, `aureport`, the login UID | Advanced | Low |
| [GPG](gpg.md) | Signing and verifying, RPM and APT keys | Core | Low |
| [OpenSSL and Trust Store](openssl-and-trust-store.md) | CA and CSR, inspecting and testing certificates, system trust stores | Core | Med |
| [Compliance and Integrity](compliance-and-integrity.md) | `rpm -Va`, `debsums`, AIDE, OpenSCAP, backported CVE fixes | Advanced | Low |
| [Hardening Checklist](hardening-checklist.md) | Accounts, setuid, services, kernel settings, SSH, fail2ban, updates, Lynis | Core | Med |

---

## Scenarios and Labs

- [Service Unreachable](../interview/scenarios/service-unreachable.md): works on localhost, fails for clients: bind address, firewall, SELinux port
- [Cannot Reach Host](../interview/scenarios/cannot-reach-host.md): routes, forwarding, a filtering router and MTU
- [TLS Certificate Errors](../interview/scenarios/tls-certificate-errors.md): unknown CA, name mismatch, expiry, clock skew, missing intermediate
- [Permission Denied](../interview/scenarios/permission-denied.md): modes, ACLs, attributes, SELinux, `noexec` and read-only mounts
- [Suspected Compromise](../interview/scenarios/suspected-compromise.md): triage of processes, connections, accounts and persistence
- [Cannot SSH](../interview/scenarios/cannot-ssh.md): SSH failures, including SELinux labels
- [Security Lab](../labs/security-lab.md): the hands-on version of this module

SELinux runs in enforcing mode on both Rocky hosts (`gw`, `web`) of the lab network; the playground kernel activates SELinux as its security module, so AppArmor is not enforced on `client`.
