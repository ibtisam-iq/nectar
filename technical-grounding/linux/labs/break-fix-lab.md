# Break-Fix Lab

Break a working system on purpose, then diagnose and repair it the way an on-call engineer does: from the symptom, not from knowing what changed. Run each exercise on a throwaway `rockylinux` playground, since several tasks damage the boot path, the network or the package database.

---

## How to Use These

Run the break block without reading the solution, then work from the symptom back to the cause before opening the fix. The skill being practised is the diagnostic path, so narrate each check out loud as if in an interview. Reset with a fresh playground between the destructive exercises.

!!! danger "These commands break real things"
    Every break block below damages the machine it runs on: a bad `fstab`, a masked service, a blocked port. Run them only on a disposable VM or playground, never on a host you care about. See [Break-Fix Lab environments](README.md).

---

## Boot and Storage

### 1. The Machine Will Not Boot

**Break:**

```bash
echo '/dev/sdz /mnt/missing xfs defaults 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo reboot
```

**Symptom:** the boot stops in emergency mode asking for the root password, because a required mount failed.

??? tip "Diagnosis and fix"
    ```bash
    journalctl -xb | grep -i 'dependency\|failed\|mount'   # find the failed mount
    sudo vi /etc/fstab                                      # remove or fix the bad line
    sudo systemctl daemon-reload
    sudo mount -a && findmnt --verify
    sudo systemctl reboot
    ```

    The device `/dev/sdz` never existed, so `local-fs.target` failed and pulled the boot into emergency mode. The lasting fix is to add `nofail` to any non-critical mount, so a missing disk logs a warning instead of blocking the boot. See [Boot Failure](../interview/scenarios/boot-failure.md).

### 2. Writes Fail With Space Free

**Break:**

```bash
sudo mkdir -p /mnt/tiny
sudo mount -t tmpfs -o size=2M tmpfs /mnt/tiny        # a 2 MB filesystem
sudo dd if=/dev/zero of=/mnt/tiny/fill bs=1M count=3 2>/dev/null   # fill it
```

**Symptom:** an application reports `No space left on device` on `/mnt/tiny`, yet the underlying disk has plenty of room.

??? tip "Diagnosis and fix"
    ```bash
    df -h /mnt/tiny        # this filesystem is full, even though / is not
    df -i /mnt/tiny        # rule out the other cause: inode exhaustion
    du -sh /mnt/tiny/*     # what is consuming it
    sudo rm /mnt/tiny/fill # free the space
    ```

    `No space left on device` comes from either full blocks (`df -h`) or exhausted inodes (`df -i`); checking only one misses the other cause. Here it is blocks on a small `tmpfs`; on a real disk, many tiny files can exhaust inodes long before blocks fill, which `df -i` catches. See [Disk Full](../interview/scenarios/disk-full.md).

---

## Services and Permissions

### 3. A Service Refuses to Start

**Break:**

```bash
sudo systemctl mask chronyd
sudo systemctl stop chronyd
```

**Symptom:** `systemctl start chronyd` returns `Unit chronyd.service is masked` and time sync is off.

??? tip "Diagnosis and fix"
    ```bash
    systemctl status chronyd        # shows 'masked'
    systemctl list-unit-files chronyd.service
    sudo systemctl unmask chronyd
    sudo systemctl enable --now chronyd
    ```

    Masking links the unit to `/dev/null` so it cannot start by any means, which is stronger than disabling. `status` naming the unit as `masked` is the clue that a plain `enable` will not fix. See [Service Won't Start](../interview/scenarios/service-wont-start.md).

### 4. A User Cannot Read Their Own Files

**Break:**

```bash
sudo useradd tester
echo secret | sudo tee /home/tester/notes.txt
sudo chmod 000 /home/tester
```

**Symptom:** `tester` logs in but every command in the home directory returns `Permission denied`, including `ls ~`.

??? tip "Diagnosis and fix"
    ```bash
    sudo -u tester ls /home/tester     # reproduce the denial
    ls -ld /home/tester                # mode 000, no owner access
    sudo chmod 700 /home/tester        # owner needs rwx to enter and list
    sudo -u tester ls /home/tester     # confirm
    ```

    A directory needs `x` to enter it and `r` to list it, so mode `000` locks out even the owner. On SELinux systems, a home directory restored from elsewhere may also need `restorecon -R /home/tester`. See [Permission Denied](../interview/scenarios/permission-denied.md).

---

## Networking

### 5. A Service Answers Locally but Not Remotely

**Break:**

```bash
sudo systemctl start httpd 2>/dev/null || sudo systemctl start nginx
sudo firewall-cmd --remove-service=http 2>/dev/null
sudo firewall-cmd --remove-service=https 2>/dev/null
```

**Symptom:** `curl localhost` on the server works, but a client on another host times out on port 80.

??? tip "Diagnosis and fix"
    ```bash
    curl -sS localhost >/dev/null && echo 'local ok'   # rules out the app
    sudo ss -tlnp | grep ':80'                          # confirm it listens on 0.0.0.0
    sudo firewall-cmd --list-services                   # http is missing
    sudo firewall-cmd --add-service=http --permanent && sudo firewall-cmd --reload
    ```

    Local success with remote failure points below the application: the firewall, the bind address, or a SELinux port label, in that order of likelihood. If `ss` shows `127.0.0.1:80` instead of `0.0.0.0:80`, the fix is the app's bind address, not the firewall. See [Service Unreachable](../interview/scenarios/service-unreachable.md).

### 6. Name Resolution Is Broken

**Break:**

```bash
sudo cp /etc/resolv.conf /etc/resolv.conf.bak
echo 'nameserver 203.0.113.1' | sudo tee /etc/resolv.conf   # a dead resolver
```

**Symptom:** `ping 1.1.1.1` works but `ping google.com` fails with `Name or service not known`.

??? tip "Diagnosis and fix"
    ```bash
    ping -c1 1.1.1.1        # IP works, so routing is fine
    dig google.com          # times out against the dead resolver
    cat /etc/resolv.conf    # points at the unreachable nameserver
    sudo cp /etc/resolv.conf.bak /etc/resolv.conf
    getent hosts google.com # confirm through nsswitch
    ```

    Connectivity by IP but not by name isolates the fault to DNS, not routing or the firewall. On a `systemd-resolved` host, edit the resolver through NetworkManager or netplan, since `/etc/resolv.conf` is a managed symlink that gets rewritten. See [DNS Not Resolving](../interview/scenarios/dns-not-resolving.md).

---

## Packages and Processes

### 7. A Runaway Process Pins a Core

**Break:**

```bash
nohup bash -c 'while :; do :; done' >/dev/null 2>&1 &
```

**Symptom:** load average climbs, one core sits at 100% user, and the machine feels slow.

??? tip "Diagnosis and fix"
    ```bash
    uptime                            # load rising
    top -o %CPU                       # the loop at 100%, note its PID
    ps -o pid,ppid,etime,cmd -p PID   # confirm it is the runaway
    kill PID                          # TERM first; KILL only if it ignores TERM
    ```

    A single busy loop shows as `100% us` on one core with no iowait, so the fix is on the process, not the host. Identify by `%CPU` in `top`, confirm the command line, then signal it. See [Server Slow](../interview/scenarios/server-slow.md) and [CPU and Load](../17-performance-and-troubleshooting/cpu-and-load.md).

---

## Related

- [Interview Scenarios](../interview/round-3-troubleshooting.md): the same faults as open-ended interview questions
- [RHCSA-Style Tasks](rhcsa-style-tasks.md): build the skills these exercises break
- [Methodology](../17-performance-and-troubleshooting/methodology.md): the 60-second checklist behind each diagnosis
