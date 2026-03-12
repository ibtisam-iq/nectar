# USER in Dockerfiles — The Complete Mental Model

This document explains one of the most misunderstood concepts in Dockerfile
authoring: the word `USER` means two completely different things depending on
context, and confusing them leads to broken builds, permission errors, and
failed containers.

---

## Two Independent Meanings of "USER"

| Concept | Type | What It Controls | Example |
|---|---|---|---|
| `USER root` / `USER appuser` | Dockerfile directive | Which OS user **runs the process** | Switches the active process identity |
| `$USER` / `${USER}` | Shell environment variable | A string value passed into scripts | `appuser`, `ibtisam`, etc. |

These two are completely independent. A shell variable named `USER` does **not**
override or affect the active process user set by the `USER` directive.

---

## The `USER` Directive — Process Context

```dockerfile
USER root       # all following RUN/CMD/ENTRYPOINT run as root (UID 0)
USER appuser    # all following RUN/CMD/ENTRYPOINT run as appuser
```

Once declared, **every `RUN`, `CMD`, and `ENTRYPOINT` instruction** after it
executes under that user's OS identity — until the next `USER` directive
appears. This is a process-level switch, not a variable assignment.

---

## The `${USER}` Shell Variable — Environment Context

```dockerfile
ARG USER
RUN USER=${USER} bash /tmp/scripts/install-docker.sh
```

Here, `USER=${USER}` sets a shell environment variable to the value of the
build ARG (e.g., `ibtisam`). The script receives it internally. The **process
still runs as whatever `USER` directive was last declared** — typically `root`.

```bash
# Inside install-docker.sh — process is root, but $USER = ibtisam
usermod -aG docker "${USER}"    # root runs usermod, adds ibtisam to docker group ✅
```

If the process were `ibtisam`, `usermod` would fail. If `$USER` held `root`,
you'd configure the wrong user. The combination is intentional and correct.

---

## Real-World Pattern — Full Dockerfile User Strategy

```dockerfile
FROM ghcr.io/ibtisam-iq/ubuntu-24-04-rootfs:latest

# ── SWITCH 1: Explicitly become root ──────────────────────────────────────────
# The base image may or may not default to root.
# Declaring it explicitly makes intent clear and avoids inherited surprises.
USER root

ARG USER

# All scripts below run as root — required for:
# apt installs, systemctl enable, usermod, chown, chmod, sed on system files
RUN /opt/scripts/install-jenkins.sh
RUN /opt/scripts/configure-nginx.sh
RUN systemctl enable nginx && systemctl enable jenkins
RUN /opt/scripts/healthcheck.sh ${USER}    # $USER = ibtisam (shell var, not process user)
RUN /opt/scripts/install-cloudflared.sh

# ── OWNERSHIP FIX ─────────────────────────────────────────────────────────────
# Everything above ran as root. Any files written into /home/$USER are currently
# owned by root. Fix ownership BEFORE switching to non-root user.
RUN chown -R ${USER}:${USER} /home/${USER}

# ── SWITCH 2: Become the non-root user ────────────────────────────────────────
# Scripts here must run as ibtisam — customizing .bashrc touches
# files in $HOME that should be user-owned.
USER $USER
ENV HOME=/home/$USER

COPY welcome $HOME/.welcome
RUN --mount=type=bind,source=scripts,target=/tmp/scripts \
    bash /tmp/scripts/customize-bashrc.sh    # runs as ibtisam ✅

# ── SWITCH 3: Return to root for runtime ──────────────────────────────────────
# This image uses systemd as PID 1. systemd MUST run as root.
# If you leave the final USER as ibtisam, the image builds fine
# but FAILS at runtime — systemd cannot initialize.
USER root

EXPOSE 22 80 8080

CMD ["/lib/systemd/systemd"]
```

---

## Why Each Switch Exists

| Switch | From → To | Reason |
|---|---|---|
| Switch 1 | base default → `root` | Required for system-level installs, configs, and `systemctl` |
| Switch 2 | `root` → `$USER` | User-specific customizations (`.bashrc`, welcome) must run as target user |
| Switch 3 | `$USER` → `root` | `systemd` as PID 1 requires root; skipping this causes container startup failure |

---

## The Ownership Fix — Why It Is Not Redundant

All `RUN` instructions before `USER $USER` execute as `root`. Any files created
in `/home/$USER` during those steps are **owned by root**. When the container
switches to the non-root user, those files become inaccessible.

```dockerfile
# Without this: /home/ibtisam/* owned by root → permission denied at runtime
RUN chown -R ${USER}:${USER} /home/${USER}
```

This line must appear **after all root-level work is done** and **before
switching to the non-root user**. It is a necessary cleanup step.

---

## Key Rules to Remember

- `USER root` and `$USER=root` are not the same thing.
- The shell variable `$USER` only affects what gets passed into scripts — not who runs them.
- Always fix `/home/$USER` ownership before switching to the non-root user.
- If your container uses `systemd` as PID 1, the **final** `USER` must be `root`.
- If your container runs an app as non-root, the **final** `USER` should be that user.
