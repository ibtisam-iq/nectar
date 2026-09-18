# Error Messages

Real error text seen on Linux servers, with its cause and first fix. Search this page for the words of an error; the linked topic explains the mechanism and shows the captured output. Entries are added as each module is written.

---

## Foundations

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `# No SMBIOS nor DMI entry point found, sorry.` | The VM or container exposes no SMBIOS table | Use `lscpu`, `lsmem`, `lspci`, or the cloud metadata service | [System Information](../00-foundations/system-information.md) |
| `ls: cannot access '/nonexistent': No such file or directory` | A system call returned `ENOENT` | Check the path; `strace -e trace=file` shows what was tried | [Architecture](../00-foundations/architecture.md) |
| `not a dynamic executable` | Static binary, script or other architecture | `file <path>` | [Architecture](../00-foundations/architecture.md) |

---

## Shell and CLI

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `bash: toool: command not found` (exit 127) | No alias, function, builtin or `PATH` entry has that name | Check spelling, `PATH`, and the owning package | [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| `bash: ./tool: No such file or directory` | The file is not in the current directory | `ls -l ./tool` | [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| `bash: /home/.../app: No such file or directory` for a command that exists | Bash hashed the command's old location | `hash -r` | [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| `cannot execute: required file not found` | The interpreter in the shebang, or the ELF loader, is missing; often CRLF line endings | `file <path>` shows CRLF terminators; strip them with `sed -i 's/\r$//'` | [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| `bash: /home/laborant/tool.sh: Permission denied` (exit 126) | No execute bit, or a `noexec` mount | `chmod +x`, or `bash <file>` | [Command Resolution](../01-shell-and-cli/command-resolution.md) |
| `./check.sh: 3: [[: not found` | Bash syntax run by `dash` (`/bin/sh` on Ubuntu) | `#!/bin/bash` | [Shell Basics](../01-shell-and-cli/shell-basics.md) |
| `not a tty` | A command that needs a terminal runs from cron, systemd or CI | Remove prompts, or `ssh -t` | [Shell Basics](../01-shell-and-cli/shell-basics.md) |
| `No manual entry for bash` | Documentation excluded at install (`tsflags=nodocs`, minimized image) | Re-enable docs, reinstall, `mandb` | [Getting Help](../01-shell-and-cli/getting-help.md) |
| `sudo: mytool: command not found` | `sudo` uses `secure_path`, which lacks the tool's directory | Full path, or extend `secure_path` | [Variables and Environment](../01-shell-and-cli/variables-and-environment.md) |
| `warning: setlocale: LC_ALL: cannot change locale` | The requested locale is not installed, often forwarded by SSH | Install the locale or unset the variable | [Locale and Encoding](../01-shell-and-cli/locale-and-encoding.md) |
| `ls: cannot access 'report': No such file or directory` for a file named `report 2026.txt` | Unquoted variable split on spaces | Quote: `"$file"` | [Quoting and Expansion](../01-shell-and-cli/quoting-and-expansion.md) |
| `/etc/demo2.conf: Permission denied` after `sudo echo ... >` | The redirection runs as the calling user | Pipe into `sudo tee` | [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md) |
| `log.txt: cannot overwrite existing file` | `noclobber` is set | Append with `>>`, or use the forced-overwrite operator shown in the topic | [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md) |
| `$logfile: ambiguous redirect` | Unquoted target variable is empty or has spaces | Quote and set it | [Streams and Redirection](../01-shell-and-cli/streams-and-redirection.md) |
| `Killed` (exit 137) | `SIGKILL`, often the OOM killer | `dmesg -T`, `journalctl -k` | [Exit Codes and Chaining](../01-shell-and-cli/exit-codes-and-chaining.md) |
| `mkdir: cannot create directory ...: File exists` | The directory exists, so the `&&` chain stops | `mkdir -p` | [Exit Codes and Chaining](../01-shell-and-cli/exit-codes-and-chaining.md) |
| `[: =: unary operator expected` | Unquoted empty variable inside `[ ]` | Quote it or use `[[ ]]` | [Scripting Essentials](../01-shell-and-cli/scripting-essentials.md) |
| `syntax error: unexpected end of file` | Missing `fi`, `done`, `esac` or quote | `bash -n script.sh` | [Scripting Essentials](../01-shell-and-cli/scripting-essentials.md) |

---

## Files and Filesystem

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `No space left on device` with free space in `df -h` | Inodes exhausted, or a different filesystem is full | `df -i <path>`, `df -h <path>` | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| Disk full, `du` finds much less | Deleted files still open | `sudo lsof +L1` | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| `dpkg-query: no path found matching pattern /etc/ssh/sshd_config` | File created by a maintainer script | Query the directory instead | [Filesystem Hierarchy](../02-files-and-filesystem/filesystem-hierarchy.md) |
| `cannot execute binary file: Exec format error` | Binary for another architecture | Download the build for `uname -m` | [File Types](../02-files-and-filesystem/file-types.md) |
| `syntax error near unexpected token` when running a downloaded binary | An HTML error page was saved as the binary | `file <path>`; download with `curl -f` | [File Types](../02-files-and-filesystem/file-types.md) |
| `/dev/vda: Permission denied` | A device node was run as a command | Use `lsblk` or `fdisk -l` | [File Types](../02-files-and-filesystem/file-types.md) |
| `mkdir: cannot create directory 'a/b/c': No such file or directory` | Parent directory missing | `mkdir -p` | [File Operations](../02-files-and-filesystem/file-operations.md) |
| `cp: -r not specified; omitting directory 'app'` | Source is a directory | `cp -r` or `cp -a` | [File Operations](../02-files-and-filesystem/file-operations.md) |
| `rmdir: failed to remove 'app': Directory not empty` | `rmdir` removes empty directories only | Check contents, then `rm -r` | [File Operations](../02-files-and-filesystem/file-operations.md) |
| `curl: (22) The requested URL returned error: 404` | HTTP error with `curl -f` | Check the URL; the script stops as intended | [File Operations](../02-files-and-filesystem/file-operations.md) |
| `ln: failed to create hard link ...: Invalid cross-device link` | Hard links cannot span filesystems | `ln -s` or copy | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| `ln: ...: hard link not allowed for directory` | Directories cannot have extra hard links | Symlink or bind mount | [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md) |
| `[Errno 24] Too many open files` | Per-process descriptor limit reached | Check for leaks; raise `LimitNOFILE=` | [File Descriptors](../02-files-and-filesystem/file-descriptors.md) |
| `bash: line 1: 3: Bad file descriptor` | Redirection to a descriptor that is not open | `exec 3> file` first | [File Descriptors](../02-files-and-filesystem/file-descriptors.md) |
| `find: ‘/root’: Permission denied` | No read access to a directory | `sudo`, or `2>/dev/null` | [Finding Files](../02-files-and-filesystem/finding-files.md) |
| `find: paths must precede expression` | Unquoted `-name` pattern expanded by the shell | Quote the pattern | [Finding Files](../02-files-and-filesystem/finding-files.md) |
| `find: missing argument to -exec` | `-exec` not terminated | End with `{} \;` or `{} +` | [Finding Files](../02-files-and-filesystem/finding-files.md) |
| `tar: Refusing to read archive contents from terminal (missing -f option?)` | `-f` missing | `tar -xf <archive>` | [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |
| `gzip: stdin: not in gzip format` | Not a gzip file, often an HTML page | `file <archive>`; `tar -xf` without `-z` | [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |
| `tar: nosuch: Not found in archive` | Member path differs from the stored path | `tar -tf` for the exact name | [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |
| `` tar: Removing leading `/' from member names `` | Informational: absolute paths stored as relative | None; use `-C /` to avoid the message | [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) |

---

## Text Processing

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `sha256sum: WARNING: 1 computed checksum did NOT match` | File changed or download corrupt | Download again; do not use the file | [Viewing and Comparing](../03-text-processing/viewing-and-comparing.md) |
| `gzip: plain.gz: not in gzip format` | `zcat` given data that is not gzip | `file <path>`; use the matching tool | [Viewing and Comparing](../03-text-processing/viewing-and-comparing.md) |
| `tail: '/tmp/app.log' has become inaccessible` | The followed log was rotated away | Normal with `tail -F`; it reopens the new file | [Viewing and Comparing](../03-text-processing/viewing-and-comparing.md) |
| `grep: /usr/bin/ls: binary file matches` | Input contains NUL bytes | `grep -a`, or `strings` first | [grep and Regex](../03-text-processing/grep-and-regex.md) |
| `grep: Invalid regular expression` | Unbalanced bracket or brace | Escape it or use `grep -F` | [grep and Regex](../03-text-processing/grep-and-regex.md) |
| ``sed: -e expression #1, char 5: unterminated `s' command`` | Missing final delimiter or an unescaped `/` | Close the command or change the delimiter | [sed](../03-text-processing/sed.md) |
| `sed: no input files` | `sed -i` used in a pipeline | Pass a file name, or drop `-i` | [sed](../03-text-processing/sed.md) |
| `unescaped newline inside substitute pattern` (macOS) | BSD `sed -i` took the script as the backup suffix | `sed -i '' ...` or GNU `gsed` | [sed](../03-text-processing/sed.md) |
| `awk: cmd. line:1: ... unexpected newline or end of string` | Unclosed brace or quote in the program | Fix the braces; keep the program in single quotes | [awk](../03-text-processing/awk.md) |
| ``awk: fatal: cannot open file `nosuch.log' for reading`` | Wrong input path | Check the path | [awk](../03-text-processing/awk.md) |
| `sort: access.log:14: disorder:` | Input not sorted in the current locale | Sort with the same `LC_ALL` before `comm` or `join` | [Cut, Sort, Uniq and Tr](../03-text-processing/cut-sort-uniq-tr.md) |
| `bash: bc: command not found` | `bc` not installed | Install `bc`, or use `awk` | [Cut, Sort, Uniq and Tr](../03-text-processing/cut-sort-uniq-tr.md) |
| `rm: missing operand` from an `xargs` pipeline | Empty input still ran the command | `xargs -r` | [xargs and tee](../03-text-processing/xargs-and-tee.md) |
| `xargs: sh: exited with status 255; aborting` | A command exited 255 | Return 1 for ordinary failures | [xargs and tee](../03-text-processing/xargs-and-tee.md) |
| `xargs: argument line too long` | One input item exceeds the command-line limit | Pass the data through stdin or a file | [xargs and tee](../03-text-processing/xargs-and-tee.md) |
| `jq: parse error: Unfinished JSON term at EOF` | Input is not valid JSON | Check the raw input; `curl -f` | [JSON and YAML on the CLI](../03-text-processing/json-and-yaml-on-cli.md) |
| `jq: error (at ...): Cannot iterate over null (null)` | `.[]` on a missing key | Check the path; `.key[]?` | [JSON and YAML on the CLI](../03-text-processing/json-and-yaml-on-cli.md) |
| `Error: bad file '-': yaml: line 2: did not find expected key` | Inconsistent YAML indentation | Align keys; `yamllint` | [JSON and YAML on the CLI](../03-text-processing/json-and-yaml-on-cli.md) |

---

## Users and Access

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `useradd: user 'amor' already exists` | The name is taken | `getent passwd amor` | [Users](../04-users-and-access/users.md) |
| `userdel: user amor is currently used by process 1244` | The user still has running processes | Stop them (`pkill -u amor`), then delete | [Users](../04-users-and-access/users.md) |
| `userdel: /home/amor not owned by amor, not removing` | Home directory belongs to another UID | Check ownership; remove it manually if intended | [Users](../04-users-and-access/users.md) |
| `groupdel: cannot remove the primary group of user 'amor'` | The group is a user's primary group | `usermod -g` first | [Groups](../04-users-and-access/groups.md) |
| `groupadd: group 'amor' already exists` | Name taken, often by a user private group | `getent group amor` | [Groups](../04-users-and-access/groups.md) |
| `su: User account has expired` | Account expiry date passed | `chage -E -1 <user>` | [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| `You are required to change your password immediately (administrator enforced).` | `chage -d 0` forced a change | Set a new password at login | [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| `passwd: unrecognized option '--stdin'` | `--stdin` exists only in the RHEL build of `passwd` | `chpasswd` | [Passwords and Aging](../04-users-and-access/passwords-and-aging.md) |
| `amor is not in the sudoers file.` | No sudoers rule matches the user | Add to `wheel` or `sudo`, or a drop-in rule | [Sudo and Su](../04-users-and-access/sudo-and-su.md) |
| `sudo: a password is required` | The command line does not match a `NOPASSWD` rule exactly | Match arguments exactly, or use `sudo -l` | [Sudo and Su](../04-users-and-access/sudo-and-su.md) |
| `/etc/sudoers.d/deploy:2:48: syntax error` | Invalid sudoers syntax | `visudo -cf <file>` before installing | [Sudo and Su](../04-users-and-access/sudo-and-su.md) |

---

## Permissions

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `chown: changing ownership of 'report.txt': Operation not permitted` | Only root changes owners | `sudo chown` | [Basic Permissions](../05-permissions/basic-permissions.md) |
| `ls: cannot access 'd-rw/f': Permission denied` with `-?????????` | Directory has `r` without `x` | Add `x` on the directory | [Basic Permissions](../05-permissions/basic-permissions.md) |
| `./run.sh: Permission denied` (exit 126) | No execute bit, or `noexec` mount | `chmod +x`; `findmnt -no OPTIONS -T <file>` | [Basic Permissions](../05-permissions/basic-permissions.md) |
| `umask: 999: octal number out of range` | Non-octal digits | Use 0 to 7 or symbolic form | [umask](../05-permissions/umask.md) |
| `rm: cannot remove '...': Operation not permitted` in a shared directory | Sticky bit; the caller owns neither file nor directory | The owner removes it | [Special Permissions](../05-permissions/special-permissions.md) |
| `rm: cannot remove 'resolv.conf': Operation not permitted` as root | Immutable or append-only attribute | `lsattr`, then `chattr -i` | [File Attributes](../05-permissions/file-attributes.md) |
| `chattr: Operation not permitted while setting flags` | Only root may set `i` and `a` | `sudo chattr` | [File Attributes](../05-permissions/file-attributes.md) |
| `lsattr: Operation not supported While reading flags` | Filesystem without attribute support | Use ext4, XFS or btrfs | [File Attributes](../05-permissions/file-attributes.md) |
| `setfacl: secret.conf: Operation not permitted` | Only the owner or root changes an ACL | `sudo setfacl` | [ACL](../05-permissions/acl.md) |
| `setfacl: Option -m: Invalid argument near character 3` | Unknown user or group, or malformed entry | `getent passwd <user>` | [ACL](../05-permissions/acl.md) |

---

## Package Management

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `Error: Unable to find a match: nosuchpackage` | Wrong name or disabled repository | `dnf search`, `dnf provides`, `dnf repolist --all` | [rpm and dnf](../06-package-management/rpm-and-dnf.md) |
| `Error: Failed to download metadata for repo 'broken'` | One repository unreachable; `dnf` stops | Fix or disable it; `skip_if_unavailable=True` | [rpm and dnf](../06-package-management/rpm-and-dnf.md) |
| `missing ... (Permission denied)` from `rpm -V` | Verification run without root | `sudo rpm -V` | [rpm and dnf](../06-package-management/rpm-and-dnf.md) |
| `Package hello-notes-1.0-1.el10.noarch.rpm is not signed` / `GPG check FAILED` | Unsigned package with `gpgcheck=1` | Sign it; do not disable checks | [Packaging Concepts](../06-package-management/packaging-concepts.md) |
| `E: Unable to locate package nosuchpackage` | Stale package lists or wrong name | `sudo apt update`; `apt-cache search` | [dpkg and apt](../06-package-management/dpkg-and-apt.md) |
| `E: Could not get lock /var/lib/dpkg/lock-frontend` | Another package process runs | Wait; `DPkg::Lock::Timeout` in scripts | [dpkg and apt](../06-package-management/dpkg-and-apt.md) |
| `E: dpkg was interrupted, you must manually run 'sudo dpkg --configure -a'` | A previous install stopped halfway | `sudo dpkg --configure -a`, `sudo apt -f install` | [dpkg and apt](../06-package-management/dpkg-and-apt.md) |
| `NO_PUBKEY 7EA0A9C3F273FCD8` | Keyring for a source missing or wrong | Download the key into `/etc/apt/keyrings/` | [Repositories](../06-package-management/repositories.md) |
| `W: Failed to fetch ... Could not resolve` | APT repository unreachable; APT continues | Fix DNS or remove the source | [Repositories](../06-package-management/repositories.md) |
| `error: No remote refs found for ‘flathub’` | Flatpak remote in the other scope | Add the remote to the scope in use | [Flatpak and Snap](../06-package-management/flatpak-and-snap.md) |
| `error while loading shared libraries: libgreet.so.1` | Library missing or not in the search path | Install it or `ldconfig` its directory | [Shared Libraries](../06-package-management/shared-libraries.md) |
| ``version `GLIBC_2.42' not found`` | Binary built for a newer glibc | Build on the oldest target or link statically | [Shared Libraries](../06-package-management/shared-libraries.md) |
| `cannot execute: required file not found` for an ELF file | The ELF interpreter (for example musl's loader) is missing | `readelf -l`; build for glibc | [Binary Won't Execute](../interview/scenarios/binary-wont-execute.md) |
| `error: externally-managed-environment` | Ubuntu 24.04 blocks system `pip install` | Use a venv or `pipx` | [Other Install Methods](../06-package-management/other-install-methods.md) |

---

## Processes

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `bash: fork: retry: Resource temporarily unavailable` | User or system process limit reached (`ulimit -u`, `TasksMax=`, `pid_max`) | Find the owner of the tasks; fix the leak, then the limit | [Process Lifecycle](../07-processes/process-lifecycle.md) |
| `ls: cannot read symbolic link '/proc/2102/cwd': Permission denied` | The process belongs to another user | `sudo`, or read `status` instead | [Process Fundamentals](../07-processes/process-fundamentals.md) |
| `error: list of process IDs must follow -p` | Empty command substitution after `ps -p` | Check the `pgrep` match first | [Viewing Processes](../07-processes/viewing-processes.md) |
| `kill: (1) - Operation not permitted` | Target belongs to another user (`EPERM`) | `sudo`, or signal as the owner | [Signals](../07-processes/signals.md) |
| `kill: (2251) - No such process` | PID gone (`ESRCH`); stale PID file | `pgrep -a`, `systemctl show -p MainPID` | [Signals](../07-processes/signals.md) |
| `sleep: no process found` | `killall` matched nothing; exits 1 | Check the name with `pgrep -a` | [Signals](../07-processes/signals.md) |
| `Killed` reported only after a hung write returns | `SIGKILL` pending on a `D`-state process | Fix the resource in `wchan` | [Process States](../07-processes/process-states.md) |
| `bash: fg: current: no such job` | Empty job table in this shell | `pgrep -a`; the job belongs to another shell | [Job Control](../07-processes/job-control.md) |
| `nice: cannot set niceness: Permission denied` | Negative nice without privilege | `sudo`, `limits.d`, or `Nice=` in a unit | [Priority and Nice](../07-processes/priority-and-nice.md) |
| `renice: failed to set priority for 2815 (process ID): Permission denied` | User tried to lower a nice value | `sudo renice` | [Priority and Nice](../07-processes/priority-and-nice.md) |
| `chrt: failed to set pid 0's policy: Operation not permitted` | Real-time policy needs `CAP_SYS_NICE` | `sudo chrt`, or `CPUSchedulingPolicy=` | [Priority and Nice](../07-processes/priority-and-nice.md) |
| `sudo: effective uid is not 0, is /usr/bin/sudo on a file system with the 'nosuid' option set ...` | `strace sudo` drops the setuid bit | `sudo strace ...` | [System Calls and Tracing](../07-processes/system-calls-and-tracing.md) |

---

## Systemd and Services

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `Failed to start nginx.service: Interactive authentication required.` | State change without root | `sudo systemctl ...` | [systemctl](../08-systemd-and-services/systemctl.md) |
| `Failed to start nginx.service: Unit nginx.service is masked.` | Unit linked to `/dev/null` | `sudo systemctl unmask` | [systemctl](../08-systemd-and-services/systemctl.md) |
| `Unit nosuch.service could not be found.` | Wrong name, missing package or no `daemon-reload` | `systemctl list-unit-files`, `daemon-reload` | [systemctl](../08-systemd-and-services/systemctl.md) |
| `Warning: The unit file, source configuration file or drop-ins of nginx.service changed on disk.` | Edited without reloading | `sudo systemctl daemon-reload` | [Unit Files](../08-systemd-and-services/unit-files.md) |
| `Unit nginx.service has a bad unit file setting.` | Parse error, often a second `ExecStart=` | Empty `ExecStart=` first; `systemd-analyze verify` | [Unit Files](../08-systemd-and-services/unit-files.md) |
| `Service has more than one ExecStart= setting, which is only allowed for Type=oneshot services. Refusing.` | Drop-in added an `ExecStart=` without resetting | Add `ExecStart=` with no value before it | [Unit Files](../08-systemd-and-services/unit-files.md) |
| `flaky.service: Start request repeated too quickly.` | Start limit reached | Fix the cause, `reset-failed` | [Unit Files](../08-systemd-and-services/unit-files.md) |
| `A dependency job for app-web.service failed.` | A `Requires=` unit failed | `systemctl list-dependencies`, `--failed` | [Unit Files](../08-systemd-and-services/unit-files.md) |
| `status=203/EXEC` / `Failed at step EXEC spawning` | `ExecStart=` not executable or missing | Check the path, mode, shebang, `noexec` | [Writing a Service](../08-systemd-and-services/writing-a-service.md) |
| `Failed to spawn 'start' task: No such file or directory` | `EnvironmentFile=` missing | Create it, or prefix the path with `-` | [Writing a Service](../08-systemd-and-services/writing-a-service.md) |
| `Read-only file system` inside a service | `ProtectSystem=strict` | `ReadWritePaths=` or `StateDirectory=` | [Writing a Service](../08-systemd-and-services/writing-a-service.md) |
| `sudo: The "no new privileges" flag is set` | `NoNewPrivileges=yes` in the unit | Remove `sudo` from the service's code path | [Writing a Service](../08-systemd-and-services/writing-a-service.md) |
| `State 'stop-sigterm' timed out. Killing.` | Process ignores `SIGTERM` longer than `TimeoutStopSec=` | Handle `SIGTERM`; `exec` in wrappers | [Signals](../07-processes/signals.md) |
| `Failed to load environment files: No such file or directory` | `EnvironmentFile=` missing; `Result: resources` | Create it, or prefix with `-` | [Service Won't Start](../interview/scenarios/service-wont-start.md) |
| `Failed to determine user credentials: No such process` / `status=217/USER` | `User=` names no existing user | Create the user or fix the name | [Service Won't Start](../interview/scenarios/service-wont-start.md) |
| `OSError: [Errno 98] Address already in use` | Another process owns the port | `ss -tlnp "sport = :<port>"` | [Service Won't Start](../interview/scenarios/service-wont-start.md) |

---

## Logging

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `tail: cannot open '/var/log/secure' for reading: Permission denied` | RHEL log files are root only; Ubuntu's need group `adm` | `sudo`, or `journalctl` as `wheel` or `adm` | [Log Locations](../09-logging/log-locations.md) |
| `Specifying boot ID or boot offset has no effect, no persistent journal was found.` | Volatile journal | Create `/var/log/journal`, `journalctl --flush` | [journalctl](../09-logging/journalctl.md) |
| `No journal files were opened due to insufficient permissions.` | User not in `adm`, `systemd-journal` or `wheel` | Add the group, log in again | [journalctl](../09-logging/journalctl.md) |
| `Suppressed 4725 messages from flood.service` | journald rate limit reached | Lower the log volume or raise `LogRateLimitBurst=` | [journalctl](../09-logging/journalctl.md) |
| `rsyslogd: error during parsing file /etc/rsyslog.d/30-payments.conf, on or before line 2` | rsyslog syntax error | Fix the line, `rsyslogd -N1` | [rsyslog](../09-logging/rsyslog.md) |
| `error: skipping "/var/log/app/app.log" because parent directory has insecure permissions` | Log directory writable by a non-root group or everyone | `chmod 755` the directory, or `su user group` in the rule | [logrotate](../09-logging/logrotate.md) |
| `warning: /tmp/bad.conf:4 unknown option 'copytruncte' -- ignoring line` | Misspelled logrotate directive | Correct it; `logrotate -d` | [logrotate](../09-logging/logrotate.md) |
| `error: /tmp/dup.conf:1 duplicate log entry for /var/log/app/app.log` | Two rules match one file | Keep one rule | [logrotate](../09-logging/logrotate.md) |

---

## Scheduling

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `"/tmp/bad.cron":1: bad minute` / `Invalid crontab file, can't install.` | Field out of range | Correct the schedule | [cron and at](../10-scheduling/cron-and-at.md) |
| ``/bin/sh: -c: line 2: unexpected EOF while looking for matching `)'`` | Unescaped `%` in a crontab command | `\%` | [cron and at](../10-scheduling/cron-and-at.md) |
| `db-backup: command not found` (in `CMDOUT`) | Command outside cron's `PATH` | Full path or `PATH=` in the crontab | [cron and at](../10-scheduling/cron-and-at.md) |
| `/bin/sh: line 1: /opt/jobs/crlf.sh: cannot execute: required file not found` | CRLF line endings in the script | `sed -i 's/\r$//'` | [cron and at](../10-scheduling/cron-and-at.md) |
| `/bin/sh: line 1: /opt/reports/run.sh: Permission denied` | Script not executable | `chmod 755` | [Cron Job Not Running](../interview/scenarios/cron-job-not-running.md) |
| `(CRON) bad command (/etc/cron.d/report)` | `cron.d` line without a user field (RHEL) | Add the user | [cron and at](../10-scheduling/cron-and-at.md) |
| `Error: bad username; while reading /etc/cron.d/nouser` | `cron.d` line without a user field (Ubuntu) | Add the user | [Cron Job Not Running](../interview/scenarios/cron-job-not-running.md) |
| `You (bob) are not allowed to use this program (crontab)` | `cron.deny` or `cron.allow` | Update the access files | [cron and at](../10-scheduling/cron-and-at.md) |
| `(CRON) info (No MTA installed, discarding output)` | Job output with no mail server (Ubuntu) | Redirect output to a file | [Cron Job Not Running](../interview/scenarios/cron-job-not-running.md) |
| `You do not have permission to use at.` | `at.deny` or `at.allow` | Update the access files | [cron and at](../10-scheduling/cron-and-at.md) |
| `Exec failed for mail command: No such file or directory` | `atd` could not mail job output | Redirect output inside the job | [cron and at](../10-scheduling/cron-and-at.md) |
| `Timer unit lacks value setting. Refusing.` | Timer without `OnCalendar=` or `On*Sec=` | Add a trigger | [Systemd Timers](../10-scheduling/systemd-timers.md) |
| `orphan.timer: Refusing to start, unit orphan.service to trigger not loaded.` | No matching service | Create it or set `Unit=` | [Systemd Timers](../10-scheduling/systemd-timers.md) |
| `Failed to parse calendar specification 'Mon..Fri 25:00': Invalid argument` | Invalid calendar expression | `systemd-analyze calendar` | [Systemd Timers](../10-scheduling/systemd-timers.md) |

---

## Kernel and Hardware

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `-bash: line 1: /proc/sys/vm/swappiness: Permission denied` | `sudo echo ... >` redirects as the user | `sudo tee` or `sysctl -w` | [proc and sys](../11-kernel-and-hardware/proc-and-sys.md) |
| `echo: write error: Input/output error` | Read-only proc file | Use the matching tunable | [proc and sys](../11-kernel-and-hardware/proc-and-sys.md) |
| `sysctl: permission denied on key "vm.swappiness"` | Not root | `sudo sysctl -w` | [sysctl](../11-kernel-and-hardware/sysctl.md) |
| `sysctl: setting key "vm.swappiness": Invalid argument` | Non-numeric or out-of-range value | Check the valid range | [sysctl](../11-kernel-and-hardware/sysctl.md) |
| `sysctl: cannot stat /proc/sys/net/sctp/rto_min: No such file or directory` | Typo, or the module is not loaded | `sysctl -a --pattern`; load the module | [sysctl](../11-kernel-and-hardware/sysctl.md) |
| `modprobe: FATAL: Module sctpp not found in directory /lib/modules/6.1.167` | Wrong name or missing modules for the kernel | `find /lib/modules/$(uname -r)`; install extra modules | [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md) |
| `rmmod: ERROR: Module sctp is in use` | Use count above zero | Stop the users, or reboot | [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md) |
| `insmod: ERROR: could not insert module ...: File exists` | Already loaded | `lsmod` | [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md) |
| `modprobe: FATAL: Module libcrc32c is builtin.` | Built into the kernel | Parameters go on the kernel command line | [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md) |
| `Error running install command '/bin/false' for module nbd: retcode 1` | Module blocked with `install ... /bin/false` | Remove the rule if the module is needed | [Kernel Modules](../11-kernel-and-hardware/kernel-modules.md) |
| `/tmp/99-bad.rules:1 Invalid operator for KERNEL.` | `=` used on a udev match key | `==` | [Devices and udev](../11-kernel-and-hardware/devices-and-udev.md) |
| `parse-config[4369]: segfault at 0 ip ... error 6 in parse-config[401000+1000]` | NULL pointer write | `coredumpctl debug` | [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md) |
| `Memory cgroup out of memory: Killed process 4383 (python3)` | cgroup memory limit reached | Raise `MemoryMax=` or fix the leak | [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md) |
| `Buffer I/O error on dev dm-0, logical block 0, async page read` | Read error from the block device | Check hardware, restore from backup | [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md) |
| `INFO: task sh:4577 blocked for more than 10 seconds.` | Task stuck in `D` state | Fix the device or filesystem it waits on | [dmesg and Kernel Messages](../11-kernel-and-hardware/dmesg-and-kernel-messages.md) |

---

## Storage

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `/dev/vda: Unable to detect device type` | Virtual or hidden disk behind a controller | `smartctl -d <type>`, or check health on the host | [Disks and Devices](../12-storage/disks-and-devices.md) |
| `losetup: cannot find an unused loop device` | All loop devices in use, or no `/dev/loop-control` | `losetup -l`; detach stale ones | [Disks and Devices](../12-storage/disks-and-devices.md) |
| `Re-reading the partition table failed.: Invalid argument` | Kernel refused the whole-table re-read | `partprobe` or `partx -a` | [Partitioning](../12-storage/partitioning.md) |
| `Error: /dev/loop2: unrecognised disk label` | No partition table on the disk | `parted -s <disk> mklabel gpt` | [Partitioning](../12-storage/partitioning.md) |
| `mkfs.xfs: /dev/loop0p1 appears to contain an existing filesystem (ext4).` | Existing signature | Confirm the device; `wipefs -a` or `-f` | [Filesystems](../12-storage/filesystems.md) |
| `Filesystem must be larger than 300MB.` | xfsprogs 6.16 minimum XFS size | Use a larger device or ext4 | [RAID and Encryption](../12-storage/raid-and-encryption.md) |
| `e2fsck: need terminal for interactive repairs` | `e2fsck -f` without a terminal | `-p`, `-y` or `-n` | [Filesystems](../12-storage/filesystems.md) |
| `dumpe2fs: Bad magic number in super-block while trying to open /dev/loop0p3` | Damaged primary superblock or another filesystem type | `blkid`; `e2fsck -b <backup>` | [Filesystems](../12-storage/filesystems.md) |
| `xfs_repair: /dev/loop1p2 contains a mounted and writable filesystem` | Repair attempted on a mounted XFS | Unmount first | [Filesystems](../12-storage/filesystems.md) |
| `xfs_growfs: XFS_IOC_FSGROWFSDATA xfsctl failed: Invalid argument` | Shrink below the last allocation group | Back up, recreate, restore | [Filesystems](../12-storage/filesystems.md) |
| `mount: /srv/app: wrong fs type, bad option, bad superblock on /dev/loop0p3, missing codepage or helper program, or other error.` | Wrong type, bad option, missing helper or damage | `dmesg`, `blkid` | [Filesystems](../12-storage/filesystems.md) |
| `touch: cannot touch '/srv/app/test': Read-only file system` | Mounted or remounted `ro` | `findmnt -no OPTIONS`; check the kernel log | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `umount: /srv/app: target is busy.` | Open files, working directories or nested mounts | `fuser -vm`, `lsof +f --` | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `mount: /srv/data: can't find UUID=683f9429-0000-4267-a91e-79c8e5787e21.` | No device with that UUID | `blkid`; fix the line or add `nofail` | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `[E] unreachable on boot required source: UUID=...` | `findmnt --verify` found a missing device | Fix fstab before rebooting | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `A dependency job for srv-data.mount failed. See 'journalctl -xe' for details.` | Device did not appear before the timeout | `journalctl -b`; fix fstab | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `cache.mount: Where= setting doesn't match unit name. Refusing.` | Mount unit named differently from its path | `systemd-escape -p --suffix=mount <path>` | [Mounting and fstab](../12-storage/mounting-and-fstab.md) |
| `mount: /srv/secure: unknown filesystem type 'crypto_LUKS'.` | LUKS device mounted directly | Open it and mount `/dev/mapper/<name>` | [RAID and Encryption](../12-storage/raid-and-encryption.md) |
| `swapon: /swapfile: skipping - it appears to have holes.` | Sparse swap file | Recreate with `dd` or `fallocate` | [Swap](../12-storage/swap.md) |
| `swapon: /swapfile: insecure permissions 0644, 0600 suggested.` | World-readable swap file | `chmod 600` before `mkswap` | [Swap](../12-storage/swap.md) |
| `swapon: /dev/loop0p1: read swap header failed` | No swap signature on the device | `blkid`; `mkswap` | [Swap](../12-storage/swap.md) |
| `Cannot use /dev/loop0: device is partitioned` | `pvcreate` on a partitioned disk | Use a partition or `wipefs -a` | [LVM](../12-storage/lvm.md) |
| `Can't open /dev/loop0p3 exclusively.  Mounted filesystem?` | Device is mounted or in use | Pick an unused device | [LVM](../12-storage/lvm.md) |
| `Insufficient free space: 512 extents needed, but only 258 available` | Too few free extents in the VG | `vgextend`, or `-l +100%FREE` | [LVM](../12-storage/lvm.md) |
| `File system reduce is required and not supported (xfs).` | `lvreduce -r` on XFS | Back up, recreate, restore | [LVM](../12-storage/lvm.md) |
| `fsadm: Xfs filesystem shrinking is unsupported.` | Same, on LVM 2.03.16 (Ubuntu 24.04) | Back up, recreate, restore | [LVM](../12-storage/lvm.md) |
| `device-mapper: snapshots: Invalidating snapshot: Unable to allocate exception.` | Snapshot ran out of space | Size snapshots for the change rate | [LVM](../12-storage/lvm.md) |
| `Aborting. Manual intervention required.` | `lvcreate -s` on an already frozen filesystem | `fsfreeze -u`, `lvremove`, `dmsetup remove` | [Backup and Restore](../12-storage/backup-and-restore.md) |
| `NOCHANGE: partition 1 is size 6289375. it cannot be grown` | No free space after the partition | Check `lsblk`; rescan the disk | [Resizing and Cloud Disks](../12-storage/resizing-and-cloud-disks.md) |
| `must supply partition-number` | `growpart` given the partition as one argument | `growpart <disk> <number>` | [Resizing and Cloud Disks](../12-storage/resizing-and-cloud-disks.md) |
| `No space left on device` | Blocks (including the reserve) or inodes exhausted | `df -h`, `df -i`, `lsof -a +L1` | [Disk Usage](../12-storage/disk-usage.md) |
| `bash: line 1: /usr/bin/rm: Argument list too long` | Glob expanded beyond the argument limit | `find ... -delete` | [Disk Usage](../12-storage/disk-usage.md) |
| `dd: error writing '/srv/web/uploads/a.bin': Disk quota exceeded` | User reached the hard quota | `quota -s <user>` | [Quotas](../12-storage/quotas.md) |
| `rsync: [Receiver] mkdir "/backup/daily/2026-09-16" failed: No such file or directory (2)` | Destination parent missing | `mkdir -p` or `--mkpath` | [Backup and Restore](../12-storage/backup-and-restore.md) |

---

## Networking

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `RTNETLINK answers: File exists` | Address or route already present | `ip -br addr`; `ip addr replace` | [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md) |
| `Cannot find device "eth9"` | Wrong interface name | `ip -br link` (includes `altname`) | [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md) |
| `RTNETLINK answers: Operation not permitted` | Changing links or routes without `CAP_NET_ADMIN` | Run with `sudo` | [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md) |
| `From 172.16.0.2 icmp_seq=1 Destination Host Unreachable` | No ARP answer for the target or gateway on the local subnet | `ip neigh`; check VLAN and prefix | [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md) |
| `Error: Failed to modify connection 'dmz': Error checking authorization` | `nmcli` without `sudo` and without polkit | Run with `sudo` | [Network Configuration](../13-networking/network-configuration.md) |
| `Error in network definition: expected sequence` | netplan list written as a single value | `addresses: [172.16.0.2/24]` | [Network Configuration](../13-networking/network-configuration.md) |
| `Invalid YAML: inconsistent indentation` | netplan key indented differently from its siblings | Align it; `sudo netplan generate` | [Network Configuration](../13-networking/network-configuration.md) |
| `Permissions for /etc/netplan/50-bad.yaml are too open.` | netplan file readable by other users | `sudo chmod 600 /etc/netplan/*.yaml` | [Network Configuration](../13-networking/network-configuration.md) |
| `ping: connect: Network is unreachable` | No route matches the destination | `ip route`; add the default or static route | [Routing](../13-networking/routing.md) |
| `Error: Nexthop has invalid gateway.` | `via` address not on a connected subnet | Use a local gateway, or `onlink` | [Routing](../13-networking/routing.md) |
| `ping: connect: Invalid argument` | A `blackhole` route matches | `ip route`; delete the route | [Routing](../13-networking/routing.md) |
| `curl: (6) Could not resolve host: api.shop.internal` | No nsswitch source knows the name | `getent hosts`, `resolvectl status`, `dig @server` | [DNS Resolution](../13-networking/dns-resolution.md) |
| `ping: api.shop.internal: Name or service not known` | Name lookup failed in `getaddrinfo()` | As for `Could not resolve host` | [DNS Resolution](../13-networking/dns-resolution.md) |
| `;; communications error to 172.16.1.99#53: timed out` | No DNS server there, or port 53 filtered | `nc -vzu <server> 53`; firewalls | [DNS Resolution](../13-networking/dns-resolution.md) |
| `;; WARNING: recursion requested but not available` | Authoritative-only server asked for another zone | Use a recursive resolver or a routing domain | [DNS Resolution](../13-networking/dns-resolution.md) |
| `zone shop.internal/IN: not loaded due to errors.` | Syntax error in the zone file; old data stays served | `named-checkzone`, fix, reload | [DNS Not Resolving](../interview/scenarios/dns-not-resolving.md) |
| `nc: connect to 172.16.1.3 port 9000 (tcp) failed: Connection refused` | Nothing listens on that address, or bound to loopback | `sudo ss -tlpn 'sport = :9000'` on the server | [Ports and Sockets](../13-networking/ports-and-sockets.md) |
| `nc: Address already in use` | Port already has a listener | `sudo ss -tlpn 'sport = :<port>'` | [Ports and Sockets](../13-networking/ports-and-sockets.md) |
| `nc: Permission denied` | Unprivileged bind below port 1024 | `sudo`, `CAP_NET_BIND_SERVICE`, or a high port | [Ports and Sockets](../13-networking/ports-and-sockets.md) |
| `nf_conntrack: table full, dropping packet` | More tracked flows than `nf_conntrack_max` | Raise the limit, shorten timeouts, `notrack` | [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md) |
| `Cannot assign requested address` | Client out of ephemeral ports, often many `TIME-WAIT` | Reuse connections; widen `ip_local_port_range` | [Sockets and TCP States](../13-networking/sockets-and-tcp-states.md) |
| `ping: local error: message too long, mtu=1400` | Packet with DF set exceeds the known path MTU | Smaller packets; `tracepath` | [Connectivity Testing](../13-networking/connectivity-testing.md) |
| `From 172.16.0.3 icmp_seq=1 Frag needed and DF set (mtu = 1400)` | A router on the path has a smaller MTU | Align MTUs; let ICMP through | [Connectivity Testing](../13-networking/connectivity-testing.md) |
| `nc: connect to 172.16.1.3 port 9200 (tcp) timed out: Operation now in progress` | SYN or reply dropped on the way | Firewalls, security groups, routing | [Connectivity Testing](../13-networking/connectivity-testing.md) |
| `curl: (28) Connection timed out after 3002 milliseconds` | Connection attempt dropped | Capture on the server; walk the ladder | [Troubleshooting Ladder](../13-networking/troubleshooting-ladder.md) |
| `tcpdump: eth0: You don't have permission to perform this capture on that device` | Capture without root | `sudo tcpdump` | [Packet Capture](../13-networking/packet-capture.md) |
| `tcpdump: eth9: No such device exists` | Wrong interface name | `tcpdump -D`; `-i any` | [Packet Capture](../13-networking/packet-capture.md) |
| `tcpdump: truncated dump file; tried to read 4 file header bytes, only got 0` | Empty pcap file | Write with `-U`; stop with `-c` or Ctrl-C | [Packet Capture](../13-networking/packet-capture.md) |
| `hwclock: Cannot access the Hardware Clock via any known method.` | VM without an RTC | Nothing; time comes from the hypervisor and NTP | [Time and Timezones](../13-networking/time-and-timezones.md) |
| `506 Cannot talk to daemon` | `chronyd` not running | `sudo systemctl enable --now chronyd` | [Time and Timezones](../13-networking/time-and-timezones.md) |
| `error 9 at 0 depth lookup: certificate is not yet valid` | Local clock earlier than `notBefore` | Fix time sync; `chronyc tracking` | [Time and Timezones](../13-networking/time-and-timezones.md) |
| `connect() failed (111: Connection refused) while connecting to upstream` | Backend not listening | Check the backend service and bind address | [Reverse Proxy and Load Balancing](../13-networking/reverse-proxy-and-load-balancing.md) |
| `no live upstreams while connecting to upstream` | Every upstream server marked failed | Fix backends; retried after `fail_timeout` | [Reverse Proxy and Load Balancing](../13-networking/reverse-proxy-and-load-balancing.md) |
| `Server shop_api/client is DOWN, reason: Layer4 connection problem` | HAProxy health check cannot connect | Check the backend; `show stat` | [Reverse Proxy and Load Balancing](../13-networking/reverse-proxy-and-load-balancing.md) |
| `ping: sendmsg: Required key not available` | No WireGuard peer's `AllowedIPs` covers the destination | Add the range to the right peer | [VPN (WireGuard)](../13-networking/vpn-wireguard.md) |

---

## SSH and Remote Access

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `Permission denied (publickey).` | No offered key is accepted by the server | Check `ssh -v` and the server log; install the key or fix modes | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `ssh: connect to host X port 22: Connection refused` | Nothing listens on the port | Start `sshd`; check the port with `ss -tlnp` | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `ssh: connect to host X port 22: Connection timed out` | A firewall or the route drops the packets | Open the port; check routes and security groups | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` | The stored host key differs | Verify the new fingerprint, then `ssh-keygen -R host` | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `Authentication refused: bad ownership or modes for directory` | Home or `.ssh` writable by group or others | `chmod 755 ~`, `700 ~/.ssh`, `600 authorized_keys` | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `Could not open user 'X' authorized keys ...: Permission denied` | Wrong SELinux label on `authorized_keys` | `restorecon -Rv ~/.ssh` | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `Received disconnect ... 2: Too many authentication failures` | The agent offered more keys than `MaxAuthTries` | `IdentitiesOnly yes` with one `IdentityFile` | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `kex_exchange_identification: read: Connection reset by peer` | Server closed before key exchange (penalty, `MaxStartups`) | Read the server log for `penalty`; wait or fix the client | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `Your account has expired; please contact your system administrator.` | Account expiry date passed | `chage -E -1 user` | [SSH Troubleshooting](../14-ssh-and-remote-access/ssh-troubleshooting.md) |
| `Bad owner or permissions on /home/X/.ssh/config` | Client config writable by others | `chmod 600 ~/.ssh/config` | [SSH Client](../14-ssh-and-remote-access/ssh-client.md) |
| `Bad configuration option: PasswordAuthentcation` | Misspelled or unsupported sshd option | Fix the line, then `sshd -t` | [sshd Server](../14-ssh-and-remote-access/sshd-server.md) |
| `bad ownership or modes for chroot directory "..."` | SFTP chroot path not root-owned or group-writable | `chown root:root` and `chmod 755` the chroot | [sshd Server](../14-ssh-and-remote-access/sshd-server.md) |
| `channel N: open failed: administratively prohibited: open failed` | `AllowTcpForwarding no` on the server | Allow forwarding, or check `PermitOpen` | [SSH Tunnels](../14-ssh-and-remote-access/ssh-tunnels.md) |
| `bind [127.0.0.1]:PORT: Address already in use` | The local forward port is taken | Free the port; use `-o ExitOnForwardFailure=yes` | [SSH Tunnels](../14-ssh-and-remote-access/ssh-tunnels.md) |
| `scp: dest open "...": Permission denied` | The remote user cannot write the destination | Copy to `/tmp`, then `sudo install` | [File Transfer](../14-ssh-and-remote-access/file-transfer.md) |
| `bash: line 1: rsync: command not found` | `rsync` missing on the remote host | Install `rsync`, or use `tar` over `ssh` | [File Transfer](../14-ssh-and-remote-access/file-transfer.md) |

---

## Security

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `curl: (7) Failed to connect ... Couldn't connect to server` | Nothing listens, or firewalld rejected the packet | Check `ss -tlnp` and `firewall-cmd --list-all` | [firewalld and ufw](../15-security/firewalld-and-ufw.md) |
| `nc: connect to X port P (tcp) failed: Connection timed out` | A drop rule (ufw, security group, nft `drop`) | Check `ufw status` and `nft list ruleset` | [firewalld and ufw](../15-security/firewalld-and-ufw.md) |
| `nc: connect to X port P (tcp) failed: No route to host` | firewalld rejected with ICMP host-prohibited | Add the port or service to the zone | [firewalld and ufw](../15-security/firewalld-and-ufw.md) |
| `avc: denied { read } for ... comm="nginx" ... tcontext=...:default_t` | SELinux: wrong file label | `semanage fcontext -a` then `restorecon` | [SELinux](../15-security/selinux.md) |
| `nginx: [emerg] bind() to 0.0.0.0:PORT failed (13: Permission denied)` | SELinux: port has no matching label | `semanage port -a -t http_port_t -p tcp PORT` | [SELinux](../15-security/selinux.md) |
| `avc: denied { name_connect } ... comm="nginx"` | SELinux boolean off (proxy to a backend) | `setsebool -P httpd_can_network_connect on` | [SELinux](../15-security/selinux.md) |
| `ping: sendmsg: Operation not permitted` (setcap gone) | File capability lost on copy | Reapply `setcap`, or grant it in the unit | [Capabilities](../15-security/capabilities.md) |
| `curl: (60) SSL certificate problem: unable to get local issuer certificate` | Issuing CA not trusted, or missing intermediate | Add the CA to the trust store; serve the full chain | [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md) |
| `curl: (60) SSL: no alternative certificate subject name matches target host name` | Requested name not in the certificate SAN | Use a listed name, or reissue with the name | [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md) |
| `curl: (60) SSL certificate problem: certificate has expired` | Certificate expired, or the clock is wrong | Renew the certificate; fix time sync | [OpenSSL and Trust Store](../15-security/openssl-and-trust-store.md) |
| `Failed to restart auditd.service: Operation refused ...` | `auditd` refuses manual restart | `service auditd restart`, or `augenrules --load` for rules | [auditd](../15-security/auditd.md) |
| `gpg: BAD signature from ...` | The signed content changed, or the wrong key | Re-download; verify the signer's key by fingerprint | [GPG](../15-security/gpg.md) |

## Boot and Recovery

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)` | Wrong `root=` or an initramfs missing the root driver | Correct `root=`, rebuild the initramfs, or boot an older kernel | [Kernel Panic](../16-boot-and-recovery/kernel-panic.md) |
| `You are in emergency mode` | A filesystem in `/etc/fstab` failed to mount | Remount root rw, fix the entry, `mount -a`, reboot | [Recovery](../16-boot-and-recovery/recovery.md) |
| `mount: /data: can't find UUID=...` | The device or UUID in `/etc/fstab` is wrong or absent | Correct the UUID, or add `nofail` for non-critical mounts | [Recovery](../16-boot-and-recovery/recovery.md) |
| `error: file '/vmlinuz-...' not found` (GRUB) | The kernel a menu entry references was removed | Boot an older entry, reinstall the kernel, regenerate `grub.cfg` | [GRUB2](../16-boot-and-recovery/grub2.md) |
| edits to `/etc/default/grub` have no effect | `grub.cfg` was not regenerated after the change | Run `grub2-mkconfig -o` or `update-grub`, then reboot | [GRUB2](../16-boot-and-recovery/grub2.md) |

## Performance and Troubleshooting

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `[Errno 24] Too many open files` (`EMFILE`) | The process hit its per-process descriptor limit | Raise `LimitNOFILE` (service) or `limits.conf` (login), or fix a leak | [Limits and File Descriptors](../17-performance-and-troubleshooting/limits-and-file-descriptors.md) |
| `bash: fork: retry: Resource temporarily unavailable` (`EAGAIN`) | `RLIMIT_NPROC` or `pid_max` exhausted | Kill the runaway with builtins; raise `-u` or `pid_max` | [Cannot Fork](../interview/scenarios/cannot-fork.md) |
| `Out of memory: Killed process N (name)` | Memory and swap exhausted; OOM killer ran | Fix the leak or add RAM; protect a process with `oom_score_adj` | [Memory](../17-performance-and-troubleshooting/memory.md) |
| container exits with code `137` and no app error | Cgroup memory limit hit; OOM-killed (128 + 9) | Raise the memory limit or reduce footprint; check `dmesg` | [Memory](../17-performance-and-troubleshooting/memory.md) |
| `CONFIG_TASK_DELAY_ACCT not enabled` (`iotop`) | Per-process I/O delay accounting is off | `echo 1 > /proc/sys/kernel/task_delayacct`, or use `pidstat -d` | [Disk I/O](../17-performance-and-troubleshooting/disk-io.md) |
| `Command 'iostat' not found` | The `sysstat` package is not installed | Install `sysstat`; `vmstat`/`top`/`free` work without it | [Methodology](../17-performance-and-troubleshooting/methodology.md) |

## Network Storage

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `clnt_create: RPC: Program not registered` | The NFS server is not running, or a firewall blocks it | Start `nfs-server`; allow the `nfs` service (port 2049) | [NFS](../18-network-storage/nfs.md) |
| `mount.nfs: access denied by server while mounting` | The client is not in `/etc/exports`, or exports not re-applied | Fix the client range; `sudo exportfs -rav` | [NFS](../18-network-storage/nfs.md) |
| a process is stuck in `D` on an NFS mount, ignoring `kill -9` | Hard mount with the server unreachable; uninterruptible sleep | Restore the server or network; lazy or force unmount | [NFS](../18-network-storage/nfs.md) |
| `mount error(13): Permission denied` (CIFS) | Wrong credentials or unsupported SMB version | Check the credentials file; add `vers=3.0` | [Samba and CIFS](../18-network-storage/samba-cifs.md) |
| `mount error(112): Host is down` (CIFS) | The server refused the requested SMB version | Specify a supported version such as `vers=3.0` | [Samba and CIFS](../18-network-storage/samba-cifs.md) |
| `iscsiadm: no records found` | The initiator IQN is not in the target ACL, or wrong portal | Add the IQN to the ACL; rediscover the correct portal | [iSCSI and NBD](../18-network-storage/iscsi-and-nbd.md) |

## Containers

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `unshare: unshare failed: Operation not permitted` | Creating the namespace needs `CAP_SYS_ADMIN` | Use `sudo`, or first `unshare --user --map-root-user` | [Namespaces](../19-containers/namespaces.md) |
| `echo: write error: No such file or directory` (cgroup file) | The controller is not enabled in the parent `cgroup.subtree_control` | `echo +memory +cpu > <parent>/cgroup.subtree_control` first | [Cgroups](../19-containers/cgroups.md) |
| container exits `137` with no application error | Cgroup OOM killer hit `memory.max` (128 + SIGKILL) | Raise the limit if legitimate, or fix the leak; check `dmesg` | [Cgroups](../19-containers/cgroups.md) |
| `docker stop` waits then kills the container | PID 1 does not forward `SIGTERM` | `exec` the app as PID 1, or run with `--init` | [Containers vs VMs](../19-containers/containers-vs-vms.md) |
| bind-mounted files are `Permission denied` in a container on RHEL | SELinux blocks a host mount with no matching label | Add `:Z` to the volume flag | [Podman and Quadlet](../19-containers/podman-and-quadlet.md) |

## Virtualization and Provisioning

| Error | Cause | Fix | Topic |
|---|---|---|---|
| `virt-host-validate`: hardware virtualization `FAIL` | No `vmx`/`svm` flag, or nested virt off; no `/dev/kvm` | Enable virtualization in firmware or nested virt on the host | [KVM and libvirt](../20-virtualization-and-provisioning/kvm-and-libvirt.md) |
| `error: failed to connect to the hypervisor` | `libvirtd` not running, or user not in `libvirt` group | Start `libvirtd`; add the user to `libvirt`; reconnect | [KVM and libvirt](../20-virtualization-and-provisioning/kvm-and-libvirt.md) |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` on a new clone | The clone reused the template's SSH host keys | Regenerate host keys (`ssh-keygen -A`); `virt-sysprep` does this | [VM Images and Cloning](../20-virtualization-and-provisioning/vm-images-and-cloning.md) |
| a cloned VM ignored its cloud-config | The instance-id was unchanged, so first-boot modules skipped | `cloud-init clean` on the template before cloning | [Cloud-init and Kickstart](../20-virtualization-and-provisioning/cloud-init-and-kickstart.md) |
