# Flatpak and Snap

Flatpak and Snap install applications together with their runtimes, separate from the distribution's packages. RHCSA 10 includes installing software with Flatpak; Snap is Canonical's equivalent and is preinstalled on Ubuntu.

**Track:** RHCSA · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Flatpak remotes | Sources such as Flathub; system-wide or per user | `flatpak remotes` |
| Install, update, remove | `flatpak remote-add`, `install`, `update`, `uninstall`; apps pull shared runtimes | `flatpak list` |
| Scope | `--system` (default for root, `/var/lib/flatpak`) or `--user` (`~/.local/share/flatpak`) | `flatpak list --columns=installation` |
| Clean up | `flatpak uninstall --unused` removes orphaned runtimes | `du -sh /var/lib/flatpak` |
| Snap | Squashfs images mounted under `/snap`, managed by `snapd` | `snap list` |
| Snap updates | Automatic by default; `snap refresh --hold` pauses them | `snap refresh --list` |
<!-- --8<-- [end:facts] -->

---

## Flatpak

```bash
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y --noninteractive flathub org.gnome.Tetravex
flatpak remotes
flatpak list --columns=application,branch,installation
flatpak info org.gnome.Tetravex | grep -E 'ID:|Version:|Runtime:|Installation:|Installed:'
du -sh /var/lib/flatpak
```

Output:

```text
# ... (trimmed)
Installing runtime/org.gnome.Platform/x86_64/50
Installing app/org.gnome.Tetravex/x86_64/stable
flathub	system
# ... (trimmed)
org.gnome.Platform	50	system
org.gnome.Tetravex	stable	system
          ID: org.gnome.Tetravex
     Version: 3.38.3
Installation: system
   Installed: 1.7 MB
     Runtime: org.gnome.Platform/x86_64/50
2.4G	/var/lib/flatpak
```

!!! tip "Uninstalling an app leaves its runtime behind"
    The application is 1.7 MB; its runtime and graphics extensions brought the total to 2.4 GB. `sudo flatpak uninstall <app>` leaves the runtime behind, and `sudo flatpak uninstall --unused` removes it. A remote added with `sudo` exists only in the system installation, so `flatpak install --user` needs `flatpak remote-add --user` first.

---

## Snap

```bash
snap list
findmnt -t squashfs -o TARGET,SOURCE | head -3
sudo snap remove hello-world
```

Output:

```text
Name         Version             Rev    Tracking       Publisher    Notes
core         16-2.61.4-20260225  17292  latest/stable  canonical**  core
hello-world  6.4                 29     latest/stable  canonical**  -
snapd        2.76.3              27738  latest/stable  canonical**  snapd
TARGET               SOURCE
/snap/snapd/27738    /dev/loop0
/snap/core/17292     /dev/loop1
hello-world removed (snap data snapshot saved)
```

!!! note "Each snap revision is a squashfs image on a loop device"
    The `hello-world` snap was installed with `sudo snap install hello-world`. Each snap revision is a squashfs image on a loop device, which is why `lsblk` and `df` on Ubuntu show `/dev/loopN` entries.

---

## Common Errors

### `error: No remote refs found for ‘flathub’`

**Cause:** `flatpak install --user` ran while the remote exists only in the system installation (or the reverse); Flatpak prints `Looking for matches…` first.

**Fix:** `flatpak remotes --show-details` to see the scope; add the remote to the scope being used.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: How do Flatpak and Snap differ from RPM or DEB packages?"
    **Say first:** they bundle an application with its runtime, run it sandboxed, and update independently of the distribution; RPM and DEB share system libraries.

    **Proof:** `flatpak info <app>` names its own runtime; `snap list` shows each snap's revision.

    **Follow-up:** What does that cost in disk space and in patching responsibility?
<!-- --8<-- [end:l1] -->

??? question "L2: Install an application from Flathub for all users on RHEL 10."
    **Say first:** add the remote system-wide, then install.

    **Proof:** `sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && sudo flatpak install flathub <app-id>`

    **Follow-up:** How do you update it later? (`flatpak update`.)

??? question "L2: Free disk space used by old Flatpak runtimes."
    **Say first:** remove runtimes no application uses.

    **Proof:** `sudo flatpak uninstall --unused; du -sh /var/lib/flatpak`

    **Follow-up:** Where do user installations keep their data?

??? question "L2: Explain the loop devices in lsblk on an Ubuntu server."
    **Say first:** each snap revision is a squashfs image mounted from a loop device.

    **Proof:** `snap list`; `findmnt -t squashfs`

    **Follow-up:** How do you limit how many old revisions are kept? (`snap set system refresh.retain=2`.)

??? question "L3: A user's flatpak install fails with No remote refs found, although flathub is configured."
    **Say first:** compare the scope of the remote with the scope of the install.

    **Proof:** `flatpak remotes --show-details` shows `system`; the user ran `--user`.

    **Follow-up:** Which scope suits a shared workstation?

??? question "L3: An Ubuntu server's application changed version overnight without an apt upgrade."
    **Say first:** check whether it is a snap, which refreshes automatically.

    **Proof:** `snap list`, `snap changes`; `snap refresh --hold=<duration> <snap>` pauses updates.

    **Follow-up:** How do you schedule refreshes instead? (`snap set system refresh.timer=...`.)

---

## Related

- [Packaging Concepts](packaging-concepts.md): what traditional packages contain; [Repositories](repositories.md): remotes for RPM and DEB

Captured on Rocky Linux 10.2 and Ubuntu 24.04.4 LTS (iximiuz Labs microVMs, kernel 6.1.167), 2026-09.
