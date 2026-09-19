# Podman and Quadlet

Podman runs OCI containers without a daemon and, by default, without root, using a user namespace to map container root to an unprivileged host uid. Quadlet is the supported way to run those containers as systemd services on RHEL.

**Track:** RHCSA · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Daemonless | No central daemon; each command is a process | `podman version` |
| Rootless | Runs as a normal user by default | `podman info | grep rootless` |
| subuid/subgid | Ranges a user may map into a container | `grep $USER /etc/subuid` |
| uid mapping | Container root maps to the user; other ids to the subuid range | `cat /proc/PID/uid_map` |
| Docker CLI | `podman` is command-compatible with `docker` | `alias docker=podman` |
| Image build | `Containerfile` (or `Dockerfile`) with `podman build` | `podman build -t x .` |
| Volume | Persist data outside the container layer | `podman volume create` |
| SELinux label | `:Z` relabels a bind mount for the container | `-v /data:/data:Z` |
| skopeo | Inspect and copy images between registries | `skopeo inspect` |
| Quadlet | `.container` unit files run containers as systemd services | `systemctl start x` |
| Quadlet path | `/etc/containers/systemd/` (system), `~/.config/containers/systemd/` (user) | drop the unit there |
<!-- --8<-- [end:facts] -->

---

## Rootless by Default

Podman runs containers as an ordinary user. A user namespace maps container uid 0 to the user's own host uid, and further container ids to the user's `subuid` range, so root inside the container owns nothing privileged on the host.

```bash
grep $USER /etc/subuid /etc/subgid
podman run --rm busybox id             # root inside the container
```

Output:

```text
/etc/subuid:laborant:524288:65536
/etc/subgid:laborant:524288:65536
uid=0(root) gid=0(root) groups=10(wheel)
```

The user has 65536 ids starting at 524288 to allocate to containers. Inside the container the process is uid 0, but that maps back to the unprivileged user on the host.

```bash
cat /proc/$(podman inspect -f '{{.State.Pid}}' r)/uid_map
```

Output:

```text
         0       1001          1
         1     524288      65536
```

The map reads: container uid 0 is host uid 1001 (the user), and container uids 1 and up come from the subuid range at 524288. A file the container creates as root is owned on the host by a subuid, not by real root.

!!! note "Rootless containers cannot do everything root can"
    Binding a port below 1024, or using a device that needs real root, may fail rootless. Lower the port, grant the capability, or run the specific container as root; do not switch the whole workflow to root for one requirement.

---

## Running and Persisting Data

Podman's CLI matches Docker's, so `podman run`, `build`, `ps` and `logs` work as expected. Data in the container's writable layer is lost on removal, so anything that must survive goes in a volume or bind mount.

```bash
mkdir -p ~/data && echo "on the host" > ~/data/file.txt
podman run --rm -v ~/data:/data:ro busybox cat /data/file.txt
```

Output:

```text
on the host
```

The host directory appears inside the container at `/data`. On an SELinux-enforcing host, a bind mount needs a label the container can access, added with `:Z` (private) or `:z` (shared): `-v ~/data:/data:Z`.

!!! warning "A bind mount on SELinux needs :Z or the container gets permission denied"
    Without a matching label, SELinux blocks the container from reading a host bind mount even though the file permissions allow it. Append `:Z` to relabel it for this container, or `:z` to share it between containers.

---

## Quadlet: Containers as systemd Services

Quadlet turns a declarative `.container` file into a generated systemd service, replacing the older `podman generate systemd`. The unit is placed in a Quadlet directory, and systemd generates and manages the service on `daemon-reload`.

```ini
# /etc/containers/systemd/web.container
[Unit]
Description=Web container

[Container]
Image=docker.io/library/nginx:latest
PublishPort=8080:80
Volume=/srv/web:/usr/share/nginx/html:ro,Z

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
```

After writing the file, `systemctl daemon-reload` generates a `web.service`, which is then started and enabled like any unit. This gives a container automatic restart, ordering, and journald logging through systemd, without a container-specific supervisor.

```bash
sudo systemctl daemon-reload
sudo systemctl start web.service       # generated from web.container
```

---

## Common Errors

### `Error: rootless netavark did not set up the network` binding port 80

**Cause:** a rootless container cannot bind a privileged port below 1024 without extra configuration.

**Fix:** publish a high host port (`-p 8080:80`), or set `net.ipv4.ip_unprivileged_port_start`, or run that container as root.

### bind-mounted files are `Permission denied` inside the container on RHEL

**Cause:** SELinux blocks the container's access to a host mount that has no matching label.

**Fix:** add `:Z` to the volume flag (`-v /data:/data:Z`) to relabel it for the container.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does it mean that Podman is daemonless and rootless?"
    **Say first:** each `podman` command runs as its own process with no central daemon, and containers run as an ordinary user by default rather than as root.

    **Proof:** `podman info` shows `rootless: true`; there is no `dockerd`-style service.

    **Follow-up:** how does container root stay unprivileged? (a user namespace maps it to the user's uid and subuid range.)

??? question "L1: Where does a rootless container's 'root' user map on the host?"
    **Say first:** container uid 0 maps to the running user's uid, and higher container ids map into the user's subuid range.

    **Proof:** `/proc/PID/uid_map` shows `0 <user-uid> 1`; `/etc/subuid` holds the range.

    **Follow-up:** who owns a file the container creates as root? (a host subuid, not real root.)
<!-- --8<-- [end:l1] -->

??? question "L2: Persist a database's data across container recreation."
    **Say first:** store it in a volume or bind mount, not the container's writable layer.

    **Proof:**

    ```bash
    podman run -v pgdata:/var/lib/postgresql/data postgres
    ```

    **Follow-up:** what happens to the container layer on removal? (it is deleted; only volumes survive.)

??? question "L2: Run a container as a systemd service on RHEL. What is the supported way?"
    **Say first:** write a Quadlet `.container` unit and let systemd generate the service.

    **Proof:** put the file in `/etc/containers/systemd/`, `systemctl daemon-reload`, then start the generated unit.

    **Follow-up:** what did Quadlet replace? (`podman generate systemd`, now deprecated.)

??? question "L3: A rootless container gets permission denied reading a bind-mounted host directory on RHEL. Diagnose it."
    **Say first:** the file permissions may allow it while SELinux blocks it, because the mount has no label the container can use.

    **Proof:** check `getenforce`; `ls -Z` the host path; add `:Z` to the volume flag to relabel it.

    **Follow-up:** what is the difference between `:Z` and `:z`? (`:Z` labels it private to one container, `:z` shared between containers.)

??? question "L4: How does a rootless container run as root inside with no real root on the host?"
    **Say first:** a user namespace maps container uid 0 to the invoking user's uid, so the process is root only within that namespace and holds no privilege on the host.

    **Proof:** `/proc/PID/uid_map` shows `0 <user> 1`; a file it creates is owned by a subuid on the host.

    **Don't say:** that rootless Podman needs a setuid daemon; it uses `newuidmap`/`newgidmap` and user namespaces.

---

## Related

- [Namespaces](namespaces.md): the user namespace behind rootless
- [Cgroups](cgroups.md): the limits `--memory` and `--cpus` set
- [Containers vs VMs](containers-vs-vms.md): what a container is under the CLI
- [SELinux](../15-security/selinux.md): why bind mounts need `:Z`
- [systemctl](../08-systemd-and-services/systemctl.md): the units Quadlet generates

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. SELinux was disabled on the capture host, so `:Z` behaviour is described from the RHEL default of enforcing.
