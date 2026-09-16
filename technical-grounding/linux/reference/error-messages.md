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
