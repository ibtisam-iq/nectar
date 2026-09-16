# Binary Won't Execute

A program exists on disk but does not start. Interviewers use this scenario because several unrelated causes (permissions, mount options, architecture, interpreter, libraries, glibc version) produce similar one-line errors, and the fix depends on reading which one appeared.

---

## Symptom

> "We copied a set of tools to a new server. None of them run, and the errors all look like 'not found' or 'permission denied'. What do you check?"

---

## Clarifying Questions

- **What is the exact message and exit status?** `126` means found but not executable; `127` means something was not found, often not the file itself.
- **Where did the files come from?** A different distribution, architecture or a Windows editor each points to a different cause.
- **Scripts or compiled binaries?** Scripts depend on their interpreter line; binaries on their loader and libraries.
- **Where do they live?** `/tmp`, removable media and container volumes are often mounted `noexec`.

---

## Diagnostic Path

Six tools in `/opt/tools` and one on a tmpfs mount, each started from a script:

```bash
for f in ./report-gen ./metrics-agent ./backup-cli ./deploy.sh ./musl-tool ./cleanup.sh /mnt/scratch/health-check; do $f >/dev/null; echo "rc=$?"; done
```

Output:

```text
./report-gen: error while loading shared libraries: libgreet.so.1: cannot open shared object file: No such file or directory
rc=127
./metrics-agent: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.42' not found (required by ./metrics-agent)
rc=1
/tmp/scen.sh: line 14: ./backup-cli: cannot execute binary file: Exec format error
rc=126
/tmp/scen.sh: line 14: ./deploy.sh: cannot execute: required file not found
rc=127
/tmp/scen.sh: line 14: ./musl-tool: cannot execute: required file not found
rc=127
/tmp/scen.sh: line 14: ./cleanup.sh: Permission denied
rc=126
/tmp/scen.sh: line 14: /mnt/scratch/health-check: Permission denied
rc=126
```

### 1. Check the Execute Bit and the Mount

```bash
ls -l cleanup.sh /mnt/scratch/health-check
findmnt -no OPTIONS -T /mnt/scratch/health-check
```

Output:

```text
-rwxr-xr-x 1 root     root     26936 Sep 16 18:45 /mnt/scratch/health-check
-rw-r--r-- 1 laborant laborant    25 Sep 16 18:45 cleanup.sh
rw,noexec,relatime
```

`cleanup.sh` has no `x` bit. `health-check` has one, but its filesystem is mounted `noexec`, which gives the same `Permission denied`.

### 2. Check the File Type and Architecture

```bash
file backup-cli deploy.sh musl-tool | cut -c1-90
uname -m
```

Output:

```text
backup-cli: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically link
deploy.sh:  Bourne-Again shell script, ASCII text executable, with CRLF line terminators
musl-tool:  ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, i
x86_64
```

`backup-cli` is built for ARM, which explains `Exec format error`. `deploy.sh` has Windows line endings.

### 3. Check the Interpreter

"required file not found" means the kernel could not find the program named in the shebang or the ELF interpreter field.

```bash
head -1 deploy.sh | cat -A
readelf -l musl-tool | grep interpreter
ls -l /lib/ld-musl-x86_64.so.1
strace -f -e trace=execve ./deploy.sh 2>&1 | tail -2
```

Output:

```text
#!/bin/bash^M$
      [Requesting program interpreter: /lib/ld-musl-x86_64.so.1]
ls: cannot access '/lib/ld-musl-x86_64.so.1': No such file or directory
strace: exec: No such file or directory
+++ exited with 1 +++
```

`deploy.sh` asks for `/bin/bash\r`, which does not exist; `musl-tool` requests the musl loader, as any binary built on Alpine does, and this server has only glibc.

### 4. Check Shared Libraries

```bash
ldd ./report-gen | grep 'not found'
```

Output:

```text
	libgreet.so.1 => not found
```

### 5. Check the glibc Version

```bash
objdump -T metrics-agent | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1
ldd --version | head -1
```

Output:

```text
GLIBC_2.42
ldd (Ubuntu GLIBC 2.39-0ubuntu8.9) 2.39
```

The binary was built on a distribution with glibc 2.42 or newer (Fedora 44 here); the server has 2.39.

---

## Root Causes

| Branch | Evidence | Fix |
|---|---|---|
| No execute bit | `ls -l` shows no `x`; exit 126 | `chmod +x`, or run through the interpreter |
| `noexec` mount | `findmnt` shows `noexec`; exit 126 | Move the file, or remount without `noexec` if policy allows |
| Wrong architecture | `file` names another CPU; `Exec format error` | Download the build for `uname -m` |
| Windows line endings | `cat -A` shows `^M`; `required file not found` | `sed -i 's/\r$//'` or `dos2unix` |
| Missing ELF interpreter | `readelf -l` names a loader that does not exist | Build for glibc, or install the musl runtime |
| Missing library | `ldd` shows `not found`; exit 127 | Install the package or register the directory with `ldconfig` |
| glibc too old | `version GLIBC_x not found` | Build on the oldest target, link statically, or use a container |

---

## Fix

```bash
sed -i 's/\r$//' deploy.sh && ./deploy.sh
chmod +x cleanup.sh && ./cleanup.sh
sudo cp -a ~/libdemo/libgreet.so* /usr/local/lib/ && sudo ldconfig && ./report-gen
bash /mnt/scratch/health-check
```

Output:

```text
deploy
cleanup
hello, world
/mnt/scratch/health-check: /mnt/scratch/health-check: cannot execute binary file
```

Passing a file to `bash` works only for scripts, even on a `noexec` mount; `bash` cannot run an ELF binary, so `health-check` has to move to an executable filesystem.

---

## Prevention

- Publish builds per architecture and name them with `uname -m` values; check `file` in the deployment pipeline.
- Build release binaries on the oldest supported distribution, or statically, and record the minimum glibc.
- Enforce LF line endings with `.gitattributes` (`*.sh text eol=lf`) and a pre-commit check.
- Install tools with `install -m 0755` into `/usr/local/bin` or `/opt`, never on `noexec` mounts.
- Ship libraries with the application (`$ORIGIN` runpath) or as packages that run `ldconfig`.

---

## Related

- [Command Resolution](../../01-shell-and-cli/command-resolution.md): 126, 127 and `required file not found`
- [Shared Libraries](../../06-package-management/shared-libraries.md): loader search and glibc versions
- [File Types](../../02-files-and-filesystem/file-types.md): `file` and `Exec format error`
- [Basic Permissions](../../05-permissions/basic-permissions.md): the execute bit

Captured on Rocky Linux 10.2, Fedora 44 (where noted) and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
