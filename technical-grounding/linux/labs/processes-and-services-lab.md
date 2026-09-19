# Processes and Services Lab

Inspect, signal, prioritize and trace processes, then turn a script into a hardened systemd service and repair broken units. Run it on a `rockylinux` playground; tasks that differ on Ubuntu say so.

---

## Setup

Open a root shell on a fresh playground and install the tools:

```bash
sudo -i
dnf install -y nginx strace gdb stress-ng psmisc
systemctl enable --now nginx
```

On Ubuntu, use `apt-get install -y nginx strace gdb stress-ng psmisc`; the package starts `nginx` by itself.

---

## Processes

### 1. Read the Process Table

List the five processes using the most resident memory, then show the process tree of nginx with PIDs and the user of each worker.

??? tip "Solution"
    ```bash
    ps -eo pid,user,rss,comm --sort=-rss | head -6
    pstree -p $(pgrep -o nginx)
    ps -C nginx -o pid,ppid,user,args
    ```

    The master runs as `root`, the workers as `nginx` (`www-data` on Ubuntu).

### 2. Create and Remove a Zombie

Start a Python process that forks a child which exits immediately, without waiting for it. Confirm the zombie, try `kill -9` on it, then remove it properly.

??? tip "Solution"
    ```bash
    python3 -c 'import os, time
    if os.fork() == 0: os._exit(0)
    time.sleep(600)' &
    P=$!
    sleep 1; ps -o pid,ppid,stat,cmd --ppid $P
    kill -9 $(ps -o pid= --ppid $P); ps -o pid,stat --ppid $P   # still Z
    kill $P; sleep 1; ps -o pid,stat --ppid $P                  # gone
    ```

    Ending the parent hands the zombie to PID 1, which reaps it.

### 3. Handle Signals in a Script

Write `/root/worker.sh` that prints `reloading` on `SIGHUP`, ignores `SIGINT`, and prints `bye` and exits 0 on `SIGTERM`. Start it in the background and prove each behavior. Decode its `SigCgt` mask.

??? tip "Solution"
    ```bash
    cat > /root/worker.sh <<'EOF'
    #!/bin/bash
    trap 'echo reloading' HUP
    trap '' INT
    trap 'echo bye; exit 0' TERM
    while :; do sleep 1 & wait $!; done
    EOF
    chmod +x /root/worker.sh
    /root/worker.sh & W=$!
    kill -HUP $W; kill -INT $W; sleep 1; ps -o pid,stat -p $W
    grep SigCgt /proc/$W/status
    kill $W; wait $W; echo "exit=$?"
    ```

    `sleep 1 & wait $!` lets the trap run as soon as the signal arrives.

### 4. Survive a Logout

Start `sleep 900` so that it keeps running after the SSH session closes, in two different ways. Log out, log back in and confirm both are running with `PPID 1`.

??? tip "Solution"
    ```bash
    nohup sleep 900 > /dev/null 2>&1 &
    setsid sleep 901 > /dev/null 2>&1 < /dev/null &
    exit
    # new session
    ps -o pid,ppid,sid,tty,args -C sleep
    ```

    `sleep 902 &` without either survives only if bash's `huponexit` is off and the terminal was not hung up; closing the terminal window kills it.

### 5. Share One CPU

Pin two CPU hogs to CPU 0, one at nice 0 and one at nice 10, and measure the split. Then lower the priority of the first as a normal user and try to raise it back.

??? tip "Solution"
    ```bash
    taskset -c 0 stress-ng --cpu 1 --timeout 60 >/dev/null 2>&1 &
    taskset -c 0 nice -n 10 stress-ng --cpu 1 --timeout 60 >/dev/null 2>&1 &
    sleep 10; ps -o pid,ni,psr,%cpu,comm -C stress-ng-cpu      # about 90 / 10
    ```

    As a normal user, `renice -n 5 -p <pid>` works and `renice -n 0 -p <pid>` fails with `Permission denied`.

### 6. Find a Missing File with strace

Create a program that fails with a vague message, then find the paths it looked for.

??? tip "Solution"
    ```bash
    cat > /root/app.py <<'EOF'
    import os, sys
    for p in ("/etc/myapp/config.yml", os.path.expanduser("~/.config/myapp.yml")):
        if os.path.exists(p):
            break
    else:
        sys.exit("config missing")
    EOF
    strace -f -e trace=%file -e status=failed python3 /root/app.py 2>&1 | grep myapp
    mkdir -p /etc/myapp && touch /etc/myapp/config.yml && python3 /root/app.py; echo $?
    ```

### 7. Unblock a D-State Process

Create a loop-mounted filesystem, freeze it, and start a write to it in the background. Show that `kill -9` does not remove the writer, find where it waits, and release it.

??? tip "Solution"
    ```bash
    truncate -s 200M /var/tmp/lab.img && mkfs.ext4 -q /var/tmp/lab.img
    mkdir -p /mnt/lab && mount -o loop /var/tmp/lab.img /mnt/lab
    fsfreeze -f /mnt/lab
    (echo x > /mnt/lab/f) &
    sleep 1; ps -eo pid,stat,wchan:30,cmd | awk '$2 ~ /^D/'
    kill -9 $!; sleep 1; ps -o pid,stat -p $!                 # still D
    cat /proc/$!/stack | head -3
    fsfreeze -u /mnt/lab; sleep 1; ps -p $! || echo gone
    umount /mnt/lab
    ```

---

## Services

### 8. Write a Hardened Service

Turn the health-check script from [Writing a Service](../08-systemd-and-services/writing-a-service.md) into `healthcheck.service`: run it as a system user `healthcheck`, read `TARGET_URL` from `/etc/healthcheck/healthcheck.env`, keep state in `/var/lib/healthcheck`, restart on failure, and make the filesystem read-only for it. Enable it and read its log.

??? tip "Solution"
    Create the user, script and environment file as shown on the topic page, then:

    ```bash
    systemd-analyze verify /etc/systemd/system/healthcheck.service
    systemctl daemon-reload
    systemctl enable --now healthcheck
    journalctl -u healthcheck -n 5
    ls -l /var/lib/healthcheck
    systemd-analyze security healthcheck.service | tail -1
    ```

    The unit needs `Type=exec`, `User=`, `EnvironmentFile=`, `StateDirectory=healthcheck`, `Restart=on-failure`, `ProtectSystem=strict` and `WantedBy=multi-user.target`.

### 9. Override a Vendor Unit

Raise the open-file limit of nginx to 65536 and make it restart on failure, without editing `/usr/lib/systemd/system/nginx.service`. Prove the running master has the new limit.

??? tip "Solution"
    ```bash
    systemctl edit nginx
    # [Service]
    # LimitNOFILE=65536
    # Restart=on-failure
    systemctl restart nginx
    systemctl show nginx -p DropInPaths -p Restart
    grep 'open files' /proc/$(systemctl show -p MainPID --value nginx)/limits
    ```

### 10. Fix status=203/EXEC

Create `report.service` with `ExecStart=/opt/report/bin/report --daily`, start it, and explain the failure from the journal. Fix it by creating the program.

??? tip "Solution"
    ```bash
    printf '[Unit]\nDescription=Nightly report generator\n\n[Service]\nExecStart=/opt/report/bin/report --daily\n' > /etc/systemd/system/report.service
    systemctl daemon-reload; systemctl start report
    systemctl status report                      # status=203/EXEC
    journalctl -u report -n 4 -o cat             # Failed at step EXEC spawning ...
    install -D -m 0755 /dev/stdin /opt/report/bin/report <<'EOF'
    #!/bin/bash
    echo "report for $(date +%F)"
    EOF
    systemctl start report; journalctl -u report -n 2 -o cat
    ```

    `systemctl start` returned 0 the first time because the unit uses the default `Type=simple`. Repeat with `Type=exec` to see the start command fail.

### 11. Stop a Crash Loop

Create `flaky.service` that exits 1 on start, restarts after 1 second and gives up after 3 failures in 30 seconds. Watch it hit the limit, then start it again.

??? tip "Solution"
    ```bash
    cat > /etc/systemd/system/flaky.service <<'EOF'
    [Unit]
    Description=Crashes on start
    StartLimitIntervalSec=30
    StartLimitBurst=3

    [Service]
    ExecStart=/usr/bin/bash -c 'echo starting; exit 1'
    Restart=on-failure
    RestartSec=1
    EOF
    systemctl daemon-reload; systemctl start flaky; sleep 5
    systemctl status flaky            # Start request repeated too quickly.
    systemctl show flaky -p NRestarts
    systemctl reset-failed flaky
    ```

### 12. A Service That Ignores SIGTERM

Create a unit whose process ignores `SIGTERM`, with `TimeoutStopSec=3`. Time `systemctl stop` and read what systemd logged.

??? tip "Solution"
    ```bash
    printf '[Service]\nExecStart=/usr/bin/bash -c %s\nTimeoutStopSec=3\n' "'trap \"\" TERM; while :; do sleep 1; done'" > /etc/systemd/system/stubborn.service
    systemctl daemon-reload; systemctl start stubborn
    time systemctl stop stubborn                 # about 3 seconds
    journalctl -u stubborn -o cat -n 6           # State 'stop-sigterm' timed out. Killing.
    ```

### 13. Change the Boot Target

Make the machine boot to `multi-user.target`, confirm the symlink, then restore the original default.

??? tip "Solution"
    ```bash
    systemctl get-default
    systemctl set-default multi-user.target
    ls -l /etc/systemd/system/default.target
    systemctl set-default graphical.target
    ```

---

## Verification

```bash
systemctl is-enabled healthcheck nginx
systemctl is-active healthcheck nginx
systemctl show nginx -p Restart -p LimitNOFILE
systemctl --failed
ps -eo stat= | cut -c1 | sort | uniq -c
```

`systemctl --failed` should list nothing you created, and no `Z` or `D` processes should remain.

---

## Cleanup

```bash
systemctl disable --now healthcheck
systemctl stop flaky stubborn report 2>/dev/null
rm -f /etc/systemd/system/{flaky,stubborn,report}.service
rm -rf /etc/systemd/system/nginx.service.d
systemctl daemon-reload; systemctl reset-failed
```

---

## Related

- [Processes module](../07-processes/README.md): topics behind tasks 1 to 7
- [Systemd and Services module](../08-systemd-and-services/README.md): topics behind tasks 8 to 13
- [Process Won't Die](../interview/scenarios/process-wont-die.md): the same failures as an interview drill
