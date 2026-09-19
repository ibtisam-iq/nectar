# Permissions

Who can read, write and run a file: mode bits, the umask, special bits, ACLs and filesystem attributes.

---

## Revision Card

| Fact | Value |
|---|---|
| Octal values | `r` 4, `w` 2, `x` 1; `640` = `rw-r-----` |
| Directory `x` | Needed to reach anything inside; `r` alone lists names only |
| Deleting a file | Needs `w` and `x` on the directory |
| Permission class | Owner, else group, else other; only the first match applies |
| `chown` | Root only; clears SUID and SGID |
| umask | Bits removed from new files (`666`) and directories (`777`) |
| Default umask | Rocky 10.2: `0022` for everyone; Ubuntu 24.04: `0002` for regular users |
| SUID / SGID / sticky | `4000` / `2000` / `1000`; `s`, `s`, `t` in `ls -l` |
| Capital `S` or `T` | Special bit without the execute bit under it |
| SGID directory | New files inherit the directory's group |
| Scripts | SUID and SGID are ignored |
| ACL mask | Caps named entries; `chmod` on group bits changes it |
| Default ACL | Inherited by new files; overrides the umask for group access |
| `chattr +i` | Blocks every change, even by root (`Operation not permitted`) |

| Task | Command |
|---|---|
| Find the blocking directory | `namei -l <path>` |
| Fix `chmod -R 644` damage | `find <dir> -type d -exec chmod 755 {} +` |
| Shared team directory | `chgrp team dir; chmod 3770 dir` |
| Give one user read access | `setfacl -m u:<user>:r <file>` |
| Group-writable new files | `setfacl -d -m g:<group>:rwX <dir>` |
| Private file from creation | `(umask 077; touch <file>)` |
| Audit SUID and SGID | `find / -xdev -type f -perm /6000` |
| Show attributes | `lsattr <file>` |
| Remove immutability | `chattr -i <file>` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Basic Permissions](basic-permissions.md) | `rwx` on files and directories, `chmod`, `chown`, class order, recursive changes | Core | High |
| [umask](umask.md) | Bitwise rule, distribution defaults, `pam_umask`, service umask | Core | Med |
| [Special Permissions](special-permissions.md) | SUID and effective UID, SGID directories, sticky bit, `nosuid`, audits | Core | High |
| [ACL](acl.md) | `getfacl`, `setfacl`, the mask, default ACLs, backups | RHCSA | Med |
| [File Attributes](file-attributes.md) | `chattr`, `lsattr`, immutable and append-only files | Core | Med |

---

## Scenarios and Labs

- [Users and Permissions Lab](../labs/users-and-permissions-lab.md): tasks 11 to 16 cover this module
- [Binary Won't Execute](../interview/scenarios/binary-wont-execute.md): the execute bit and `noexec` branches
- [Round 4: Internals](../interview/round-4-internals.md): how `passwd` updates `/etc/shadow`
