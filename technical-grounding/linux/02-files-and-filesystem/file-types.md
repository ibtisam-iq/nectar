# File Types

"Everything is a file" means that directories, devices, pipes and sockets all appear in the filesystem and are opened with the same system calls. The first character of `ls -l` output tells which of the seven types an entry is, and the type decides what reading or writing it does.

**Track:** Core · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| `-` | Regular file | `ls -l` |
| `d` | Directory | `ls -ld /etc` |
| `l` | Symbolic link | `ls -l /bin` |
| `c` | Character device (byte stream: terminals, `/dev/null`) | `ls -l /dev/null` |
| `b` | Block device (disks, partitions) | `ls -l /dev/vda` |
| `p` | Named pipe (FIFO) | `mkfifo p; ls -l p` |
| `s` | Unix domain socket | `ls -l /run/systemd/journal/stdout` |
| Device numbers | Major (driver) and minor (instance) replace the size column | `ls -l /dev/vda` |
| Type from content | `file` reads magic bytes; extensions mean nothing to the kernel | `file <path>` |
| Type as text | `stat -c %F` | `stat -c %F /dev/null` |
| Search by type | `find -type f,d,l,c,b,p,s` | `find /dev -type b` |
<!-- --8<-- [end:facts] -->

---

## The Seven Types

```bash
touch regular.txt
mkdir dir
ln -s regular.txt link
mkfifo pipe
python3 -c 'import socket; s=socket.socket(socket.AF_UNIX); s.bind("sock")'
ls -l
```

Output:

```text
total 4
drwxrwxr-x 2 laborant laborant 4096 Sep 16 13:52 dir
lrwxrwxrwx 1 laborant laborant   11 Sep 16 13:52 link -> regular.txt
prw-rw-r-- 1 laborant laborant    0 Sep 16 13:52 pipe
-rw-rw-r-- 1 laborant laborant    0 Sep 16 13:52 regular.txt
srwxrwxr-x 1 laborant laborant    0 Sep 16 13:52 sock
```

Devices already exist in `/dev`:

```bash
ls -l /dev/null /dev/vda /dev/tty1
```

Output:

```text
crw-rw-rw- 1 root root   1, 3 Sep 16 13:23 /dev/null
crw--w---- 1 root tty    4, 1 Sep 16 13:23 /dev/tty1
brw-rw---- 1 root disk 253, 0 Sep 16 13:23 /dev/vda
```

For devices, `1, 3` is the major and minor number: the kernel uses the major number to pick a driver (1 is the memory devices driver) and the minor number to pick the instance.

| Type | Holds data on disk | Typical use |
|---|---|---|
| Regular | Yes | Text, binaries, images |
| Directory | Names and inode numbers | Organizing files |
| Symbolic link | The target path | Version switching, `usrmerge` |
| Character device | No | Terminals, `/dev/null`, `/dev/urandom` |
| Block device | No | Disks, partitions, LVM volumes |
| FIFO | No (kernel buffer) | Passing data between unrelated processes |
| Socket | No | Local service APIs: Docker, systemd journal, MySQL |

---

## Identifying Types

`ls -F` appends a marker, `stat` prints the type name, and `file` inspects content:

```bash
ls -F
stat -c '%n: %F' regular.txt dir link pipe sock /dev/null /dev/vda
file regular.txt dir link pipe sock /dev/null /dev/vda /usr/bin/ls /etc/os-release
```

Output:

```text
dir/
link@
pipe|
regular.txt
sock=
regular.txt: regular empty file
dir: directory
link: symbolic link
pipe: fifo
sock: socket
/dev/null: character special file
/dev/vda: block special file
regular.txt:     empty
dir:             directory
link:            symbolic link to regular.txt
pipe:            fifo (named pipe)
sock:            socket
/dev/null:       character special (1/3)
/dev/vda:        block special (253/0)
/usr/bin/ls:     ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=daa5130f2a41f7fbc8662048f3294f3d439ca7ff, for GNU/Linux 3.2.0, stripped
/etc/os-release: symbolic link to ../usr/lib/os-release
```

`file` ignores extensions and trusts the first bytes:

```bash
printf '\x7fELF' > fake.bin; file fake.bin
echo "data" > report.pdf; file report.pdf
```

Output:

```text
fake.bin: ELF
report.pdf: ASCII text
```

!!! tip "Check a download before running it"
    `file ./tool` tells a real binary from an HTML error page saved under a binary's name. After a failed `curl` without `-f`, running the "binary" produces shell errors such as `syntax error near unexpected token`, because the kernel refuses the file (`ENOEXEC`) and bash then runs it as a shell script.

`find` selects by type:

```bash
find /tmp/types /dev/vda /dev/null -maxdepth 1 \( -type p -o -type s -o -type l -o -type b -o -type c \) -printf '%y %p\n'
```

Output:

```text
p /tmp/types/pipe
s /tmp/types/sock
l /tmp/types/link
b /dev/vda
c /dev/null
```

---

## Pipes and Sockets in Practice

A named pipe blocks the writer until a reader opens it, then passes data through a kernel buffer:

```bash
( sleep 1; echo "message through the FIFO" > pipe ) &
cat pipe
wait
```

Output:

```text
message through the FIFO
```

Unix sockets are how local services talk. `logger` and the C library's `syslog()` write to `/dev/log`, which systemd-journald owns:

```bash
ls -l /run/systemd/journal/stdout /dev/log
```

Output:

```text
lrwxrwxrwx 1 root root 28 Sep 16 13:23 /dev/log -> /run/systemd/journal/dev-log
srw-rw-rw- 1 root root  0 Sep 16 13:23 /run/systemd/journal/stdout
```

!!! warning "Socket permissions are access control"
    Anyone who can write to `/var/run/docker.sock` controls the Docker daemon, which runs as root. The socket's group (`docker`) is effectively a root group.

---

## Common Errors

`tool-arm64` below is a copy of `/usr/bin/true` with the ELF machine field changed to aarch64.

```bash
file tool-arm64 | cut -c1-60
./tool-arm64; echo "rc=$?"
uname -m
/dev/vda; echo "rc=$?"
```

Output:

```text
tool-arm64: ELF 64-bit LSB pie executable, ARM aarch64, vers
bash: line 1: ./tool-arm64: cannot execute binary file: Exec format error
rc=126
x86_64
bash: line 1: /dev/vda: Permission denied
rc=126
```

### `./tool-arm64: cannot execute binary file: Exec format error`

**Cause:** the file is a binary for another architecture (`aarch64` on an `x86_64` host).

**Fix:** download the build that matches `uname -m`.

### `/dev/vda: Permission denied`

**Cause:** a device node was run as a command; device files have no execute bit.

**Fix:** use the tool meant for the device (`lsblk`, `sudo fdisk -l`).

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does everything is a file mean in Linux?"
    **Say first:** devices, pipes, sockets and kernel state appear as paths and are used with the same `open`, `read` and `write` calls as regular files.

    **Proof:** `ls -l /dev/null /run/systemd/journal/stdout`; `cat /proc/loadavg`.

    **Follow-up:** What is the exception? (Network interfaces have no device file.)

??? question "L1: What is the difference between a character device and a block device?"
    **Say first:** a character device is an unbuffered byte stream (terminals, `/dev/null`); a block device is addressed in fixed-size blocks with kernel caching (disks).

    **Proof:** `ls -l /dev/tty1 /dev/vda` shows `c` and `b`.

    **Follow-up:** What do the two numbers in place of the size mean?
<!-- --8<-- [end:l1] -->

??? question "L2: List every block device file and every socket under /run."
    **Say first:** filter by type with `find`.

    **Proof:** `find /dev -type b; sudo find /run -type s`

    **Follow-up:** Which command shows the same disks as a tree? (`lsblk`.)

??? question "L2: Pass output from one process to another that starts later, without a temporary file."
    **Say first:** a named pipe.

    **Proof:** `mkfifo /tmp/p; producer > /tmp/p &` then `consumer < /tmp/p`.

    **Follow-up:** What happens to the writer if no reader ever opens the FIFO?

??? question "L3: A downloaded binary fails with Exec format error."
    **Say first:** check what the file really is and which architecture the host runs.

    **Proof:** `file ./tool` reports `ARM aarch64` or `HTML document`; `uname -m` reports `x86_64`.

    **Follow-up:** How do you make the download fail on an HTTP error instead? (`curl -fL`.)

??? question "L3: A user added to the docker group still gets permission denied on docker.sock."
    **Say first:** check the socket's mode and group, then the user's live group list.

    **Proof:** `ls -l /var/run/docker.sock` shows group `docker`; `id` in the current session lacks it until a new login.

    **Follow-up:** Why is membership of that group a security concern?

---

## Related

- [Inodes and Links](inodes-and-links.md): what symlinks and directories store
- [Filesystem Hierarchy](filesystem-hierarchy.md): `/dev`, `/run` and `/proc`
- [File Descriptors](file-descriptors.md): opening any file type returns a descriptor
- [Groups](../04-users-and-access/groups.md): the `docker` group and new sessions

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
