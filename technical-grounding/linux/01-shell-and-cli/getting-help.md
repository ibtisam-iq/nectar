# Getting Help

Man pages, `--help` and `help` answer most "which flag" questions faster than a web search, and they match the version installed on the machine. Exams such as RHCSA allow only these sources.

**Track:** Core · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Man sections | 1 commands, 5 file formats, 8 admin commands, 2 system calls, 3 library calls, 7 overviews | `man -f intro` |
| Page in a section | `man 5 passwd` for the file, `man passwd` for the command | `man -f passwd` |
| Search descriptions | `man -k` or `apropos`; needs an index built by `mandb` | `apropos -s 8 'user account'` |
| Builtin help | `help <builtin>`; builtins have no man page of their own | `help cd` |
| Quick usage | `<command> --help` | `ls --help` |
| Package docs | `/usr/share/doc/<package>` | `rpm -qd sudo` |
| Container images | Often ship without docs (`tsflags=nodocs`, dpkg excludes) | `grep tsflags /etc/dnf/dnf.conf` |
<!-- --8<-- [end:facts] -->

---

## Man Sections

```bash
man -f passwd
man -k '^crontab'
apropos -s 8 'user account'
man -w 5 crontab
```

Output:

```text
passwd (1)           - change user password
passwd (5)           - password file
crontab (1)          - maintains crontab files for individual users
crontab (5)          - files used to schedule the execution of programs
crontabs (4)         - configuration and scripts for running periodical jobs
userdel (8)          - delete a user account and related files
usermod (8)          - modify a user account
/usr/share/man/man5/crontab.5.gz
```

---

## Builtins, --help and Package Docs

```bash
type cd
help cd | head -3
ls --help | grep -E -- '-h, --human|-t  '
```

Output:

```text
cd is a shell builtin
cd: cd [-L|[-P [-e]] [-@]] [dir]
    Change the shell working directory.
    
  -h, --human-readable       with -l and -s, print sizes like 1K 234M 2G etc.
  -t                         sort by time, newest first; see --time
```

`man cd` returns `No manual entry for cd`: builtins are documented in `help` and in `man bash`.

Package documentation lives in `/usr/share/doc/<package>` (`rpm -qd <package>` lists it), `info coreutils` holds the full GNU manuals, and `tldr` shows example-first summaries.

---

## Common Errors

### `No manual entry for bash`

**Cause:** the image was installed without documentation. RHEL-family container and cloud images set `tsflags=nodocs` in `/etc/dnf/dnf.conf`; minimal Ubuntu images exclude `/usr/share/man` in `/etc/dpkg/dpkg.cfg.d/`.

**Fix:** remove the exclusion, reinstall the packages and rebuild the index (`sudo unminimize` on Ubuntu):

```bash
sudo sed -i 's/^tsflags=nodocs/#tsflags=nodocs/' /etc/dnf/dnf.conf
sudo dnf reinstall -y bash man-pages coreutils-single
sudo mandb -q
man -w bash    # prints /usr/share/man/man1/bash.1.gz once the page is back
```

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between man passwd and man 5 passwd?"
    **Say first:** section 1 documents the `passwd` command; section 5 documents the `/etc/passwd` file format.

    **Proof:** `man -f passwd` lists both sections.

    **Follow-up:** Which sections hold system calls and admin commands?
<!-- --8<-- [end:l1] -->

??? question "L2: Find the command that changes password aging without knowing its name."
    **Say first:** search the man page descriptions.

    **Proof:** `man -k 'password expiry'` or `apropos -s 1,8 password`; `chage` appears.

    **Follow-up:** Why can `apropos` return nothing on a fresh install?

??? question "L2: Show the help for a shell builtin."
    **Say first:** builtins use `help`, not `man`.

    **Proof:** `type cd; help cd`

    **Follow-up:** How do you list every builtin? (`help` with no arguments, or `enable`.)

??? question "L2: List the documentation files a package installed."
    **Say first:** query the package database.

    **Proof:** `rpm -qd sudo` or `dpkg -L sudo | grep /usr/share/doc`

    **Follow-up:** Where are example configuration files usually kept? (`/usr/share/doc/<package>/examples`.)

??? question "L3: man returns No manual entry for commands that are clearly installed."
    **Say first:** check whether documentation was excluded when packages were installed.

    **Proof:** `grep tsflags /etc/dnf/dnf.conf` shows `nodocs`; `rpm -qd bash` lists files that are missing on disk.

    **Follow-up:** Why do container images exclude documentation?

??? question "L3: An exam or air-gapped host has no internet. How do you find the syntax for a file format?"
    **Say first:** section 5 man pages and the package's example files.

    **Proof:** `man 5 fstab`, `man 5 crontab`, `ls /usr/share/doc/<package>`.

    **Follow-up:** Which man page describes the filesystem hierarchy? (`man 7 hier`.)

---

## Related

- [Command Resolution](command-resolution.md): `type` and builtins
- [Text Editors](text-editors.md): the pager keys match `vim` searches

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
