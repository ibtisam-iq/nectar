# AppArmor

AppArmor is the mandatory access control system of Ubuntu, Debian and SUSE: per-program profiles list the paths, capabilities and network access a program may use. It is path-based where SELinux is label-based, and Docker applies its `docker-default` profile to containers on AppArmor hosts.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Model | Profiles attach to executables by path; rules name files (`r`, `w`, `ix`, ...), capabilities and network types | `ls /etc/apparmor.d` |
| Modes | `enforce` (deny and log `apparmor="DENIED"`) or `complain` (log only), per profile; the kernel must run AppArmor as its active LSM | `sudo aa-status` |
| Tools | `aa-enforce`, `aa-complain`, `aa-disable`, `apparmor_parser -r` (reload), `aa-genprof` and `aa-logprof` (build from logs) | `sudo journalctl -k -g apparmor` |
| Containers | Docker and containerd apply `docker-default`; `--security-opt apparmor=unconfined` removes it | `docker inspect -f '{{.AppArmorProfile}}' ID` |
<!-- --8<-- [end:facts] -->

---

## Status and Profiles

The iximiuz Labs kernel activates SELinux as its major security module, so on `client` (Ubuntu 24.04) the AppArmor tools are installed but the kernel does not enforce profiles. A stock Ubuntu kernel prints the list of loaded profiles and their modes here instead.

```bash
sudo aa-status; echo "exit=$?"
cat /sys/kernel/security/lsm; echo
sudo systemctl start apparmor
systemctl status apparmor --no-pager | sed -n '3,4p'
```

Output:

```text
apparmor filesystem is not mounted.
apparmor module is loaded.
exit=3
capability,selinux
     Active: inactive (dead)
  Condition: start condition unmet at Thu 2026-09-17 16:32:26 UTC; 4ms ago
```

!!! note "Why no enforcement output is shown"
    The kernel option that selects the active LSM cannot be changed on these playgrounds, and SELinux is compiled in first. Profile syntax and tooling are captured below; denials and `aa-status` profile lists are described, not captured.

Ubuntu ships profiles such as the one for `tcpdump` (comment and include lines removed by the `grep`):

```bash
grep -v '^ *#' /etc/apparmor.d/usr.bin.tcpdump | grep . | head -8
```

Output:

```text
profile tcpdump /usr/bin/tcpdump {
  capability net_raw,
  capability setuid,
  capability setgid,
  capability dac_override,
  capability chown,
  network raw,
  network packet,
```

A small profile for a script, `/usr/local/bin/labreader`, allows `/etc/hostname` and denies `/etc/shadow`. `apparmor_parser -Q -K` checks the syntax without loading it into the kernel; the first version missed a comma.

```bash
sudo tee /etc/apparmor.d/usr.local.bin.labreader >/dev/null <<'EOF'
abi <abi/4.0>,
include <tunables/global>

profile labreader /usr/local/bin/labreader {
  include <abstractions/base>
  /usr/local/bin/labreader r,
  /usr/bin/dash ix,
  /usr/bin/cat ix,
  /etc/hostname r,
  deny /etc/shadow r
}
EOF
sudo apparmor_parser -Q -K /etc/apparmor.d/usr.local.bin.labreader; echo "exit=$?"
```

Output:

```text
Cache read/write disabled: interface file missing. (Kernel needs AppArmor 2.4 compatibility patch.)
AppArmor parser error for /etc/apparmor.d/usr.local.bin.labreader in profile /etc/apparmor.d/usr.local.bin.labreader at line 11: syntax error, unexpected TOK_CLOSE, expecting TOK_END_OF_RULE
exit=1
```

!!! tip "Complain mode first, then logprof"
    After adding the comma, the check returned `exit=0`; `sudo apparmor_parser -r` then failed here with `unable to find a suitable fs in /proc/mounts`, while a stock Ubuntu kernel loads the profile. Tune new profiles in complain mode (`sudo aa-complain`), let `sudo aa-logprof` propose rules from the log, and switch with `sudo aa-enforce` once the log is quiet.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How does AppArmor differ from SELinux?"
    **Say first:** AppArmor confines programs by file paths in per-program profiles; SELinux labels every file and process and decides by type.

    **Proof:** `/etc/apparmor.d/usr.bin.tcpdump` lists paths; `ls -Z` on RHEL shows labels.

    **Follow-up:** Which one does Docker use on Ubuntu, and on RHEL?
<!-- --8<-- [end:l1] -->

??? question "L2: A service on Ubuntu gets permission denied although file modes allow the access. Check AppArmor."
    **Say first:** look for `apparmor="DENIED"` messages and the profile's mode.

    **Proof:** `sudo journalctl -k -g apparmor`; `sudo aa-status`; `sudo aa-complain /path/to/binary` to confirm, then add the rule and `sudo apparmor_parser -r` the profile.

    **Follow-up:** Why is `aa-disable` the wrong permanent fix?

??? question "L2: Validate a profile edit before reloading it."
    **Say first:** parse it without loading.

    **Proof:** `sudo apparmor_parser -Q -K /etc/apparmor.d/usr.local.bin.labreader` printed the line and the syntax error.

    **Follow-up:** What does `-r` do differently?

??? question "L2: A container needs to mount a filesystem and fails with permission denied despite CAP_SYS_ADMIN. What is involved?"
    **Say first:** the `docker-default` AppArmor profile denies `mount` even with the capability.

    **Proof:** `docker inspect -f '{{.AppArmorProfile}}'`; the kernel log shows the denial; a custom profile or `--security-opt apparmor=...` changes it.

    **Follow-up:** Why is `apparmor=unconfined` risky?

??? question "L2: Show which security module a Linux kernel enforces."
    **Say first:** read the LSM list from securityfs.

    **Proof:** `cat /sys/kernel/security/lsm` printed `capability,selinux` on the playground; Ubuntu kernels list `apparmor`.

    **Follow-up:** Can two major LSMs be active at once?

??? question "L3: After moving an application from /opt/app to /srv/app, it starts failing on one Ubuntu host only. Why could that be?"
    **Say first:** an AppArmor profile attaches by path, so the new path either has no profile or lacks rules for its files.

    **Proof:** `sudo aa-status` (profile names and paths); `sudo journalctl -k -g apparmor`; update the profile paths and reload.

    **Follow-up:** How would the same move behave under SELinux?

---

## Related

- [SELinux](selinux.md) and [Capabilities](capabilities.md): labels on RHEL, and the capability rules used in profiles

Captured on Ubuntu 24.04.4 (apparmor 4.0.1) on an iximiuz Labs FlexBox microVM, kernel 6.1.167 with SELinux as the active LSM, 2026-09.
