# Cheatsheet

The commands used most often, grouped by task, with no collapsible blocks so the page prints on one sweep. Each group links to the topic that explains the commands in full. Where RHEL and Ubuntu differ, both are shown inline.

---

## Files and Directories

```bash
cp -a src dst              # copy preserving mode, owner, timestamps, links
mv old new                 # rename, or move across directories
rm -rf dir                 # remove a directory tree (no confirmation)
mkdir -p a/b/c             # create parents as needed
ln -s target link          # symbolic link; ln without -s makes a hard link
find /path -type f -mtime +7 -size +100M   # files older than 7 days, over 100 MB
find /path -name '*.log' -delete            # delete matches (test without -delete first)
du -sh /path               # total size of a directory
```

See [File Operations](../02-files-and-filesystem/file-operations.md), [Finding Files](../02-files-and-filesystem/finding-files.md) and [Inodes and Links](../02-files-and-filesystem/inodes-and-links.md).

---

## Archives and Transfer

```bash
tar czf out.tgz dir/       # create a gzip archive
tar xzf out.tgz            # extract it
tar tzf out.tgz            # list contents without extracting
rsync -a --delete src/ dst/    # mirror src into dst (trailing slash matters)
rsync -avn src/ host:dst/      # dry run first (-n), then drop -n
scp file host:/path        # copy one file over SSH
```

See [Archiving and Compression](../02-files-and-filesystem/archiving-and-compression.md) and [File Transfer](../14-ssh-and-remote-access/file-transfer.md).

---

## Users, Groups and Permissions

```bash
useradd -m -s /bin/bash alice      # create with home and shell
usermod -aG wheel alice            # add to a group (-a appends; RHEL admin group)
passwd alice                       # set a password
chage -l alice                     # show password aging
chmod 2775 dir                     # setgid directory for a shared team
chown -R alice:devs dir            # recursive owner and group
setfacl -m u:bob:rwx file          # grant one user access beyond the mode
getfacl file                       # show ACLs
```

See [Users](../04-users-and-access/users.md), [Groups](../04-users-and-access/groups.md), [Basic Permissions](../05-permissions/basic-permissions.md) and [ACL](../05-permissions/acl.md).

---

## Processes and Signals

```bash
ps aux --sort=-%mem | head         # top memory users
ps -eo pid,ppid,stat,comm          # states and parents
pgrep -a nginx                     # find PIDs by name, with command line
kill -TERM PID                     # ask to stop; kill -KILL only if it will not
pkill -f 'pattern'                 # match against the full command line
nice -n 10 cmd; renice 10 -p PID   # lower priority
strace -f -e trace=open,openat -p PID   # watch a running process's syscalls
```

See [Viewing Processes](../07-processes/viewing-processes.md), [Signals](../07-processes/signals.md) and [System Calls and Tracing](../07-processes/system-calls-and-tracing.md).

---

## Services and Logs

```bash
systemctl status svc               # state, PID, recent log lines
systemctl enable --now svc         # start now and on boot
systemctl edit svc                 # add an override drop-in
systemctl daemon-reload            # after editing unit files
journalctl -u svc -b               # this boot's logs for one unit
journalctl -p err -b               # errors this boot
journalctl -f                      # follow live
```

See [systemctl](../08-systemd-and-services/systemctl.md), [Unit Files](../08-systemd-and-services/unit-files.md) and [journalctl](../09-logging/journalctl.md).

---

## Storage

```bash
lsblk -f                           # tree of disks with filesystems and UUIDs
blkid                              # UUIDs and types
mount -a                          # mount everything in fstab
findmnt --verify                   # check fstab before trusting it
pvs; vgs; lvs                      # LVM summary
lvextend -r -L +2G vg/lv           # grow a volume and its filesystem
df -h; df -i                       # space, then inodes
lsof +L1                          # deleted-but-open files holding space
```

See [Disks and Devices](../12-storage/disks-and-devices.md), [Mounting and fstab](../12-storage/mounting-and-fstab.md), [LVM](../12-storage/lvm.md) and [Disk Usage](../12-storage/disk-usage.md).

---

## Networking

```bash
ip -br addr                        # addresses, one line per interface
ip route                          # routing table and default gateway
ss -tulpn                         # listening TCP and UDP ports with process
dig +short name; getent hosts name # resolve through DNS, then through nsswitch
ping -c3 host; mtr host            # reachability and per-hop loss
curl -v https://host/             # request with headers and TLS detail
tcpdump -ni eth0 port 443         # capture without name resolution
```

See [Interfaces and Addresses](../13-networking/interfaces-and-addresses.md), [Routing](../13-networking/routing.md), [Ports and Sockets](../13-networking/ports-and-sockets.md) and [DNS Resolution](../13-networking/dns-resolution.md).

---

## Firewall and SELinux

```bash
firewall-cmd --add-service=https --permanent && firewall-cmd --reload   # RHEL
ufw allow 443/tcp                  # Ubuntu
getenforce                        # SELinux mode
restorecon -Rv /path              # reset SELinux labels to policy default
semanage port -a -t http_port_t -p tcp 8080   # allow a service to bind a new port
ausearch -m avc -ts recent        # recent SELinux denials
```

See [Firewalld and UFW](../15-security/firewalld-and-ufw.md) and [SELinux](../15-security/selinux.md).

---

## Performance Triage

```bash
uptime                            # load average against core count (nproc)
top; then press 1                 # per-core CPU, memory
vmstat 1 5                        # run queue, swap, io, cpu split
free -h                           # judge by 'available', not 'free'
iostat -xz 1                      # per-disk %util and await
sar -q; sar -r                    # historical load and memory
```

See [Methodology](../17-performance-and-troubleshooting/methodology.md), [CPU and Load](../17-performance-and-troubleshooting/cpu-and-load.md), [Memory](../17-performance-and-troubleshooting/memory.md) and [Disk I/O](../17-performance-and-troubleshooting/disk-io.md).

---

## Packages

```bash
dnf install pkg; dnf remove pkg    # RHEL
apt update && apt install pkg      # Ubuntu
rpm -qf /path/to/file              # which package owns a file (RHEL)
dpkg -S /path/to/file              # which package owns a file (Ubuntu)
```

See [rpm and dnf](../06-package-management/rpm-and-dnf.md) and [dpkg and apt](../06-package-management/dpkg-and-apt.md).

---

## Related

- [Command Index](command-index.md): the same commands A to Z with their topic files
- [Important Files](important-files.md): the configuration files these commands write
- [RHEL vs Ubuntu](rhel-vs-ubuntu.md): the family differences shown above in full
