# Tuning

`tuned` applies a named profile of kernel and device settings for a workload, and `sysctl` sets individual kernel parameters. Choosing a profile is usually safer and more complete than hand-editing settings.

**Track:** RHCSA · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| tuned | Daemon that applies workload profiles (RHEL family) | `tuned-adm active` |
| List profiles | Show available and current profile | `tuned-adm list` |
| Recommend | Suggest a profile for this host | `tuned-adm recommend` |
| Apply | Switch profile, persists across reboot | `tuned-adm profile NAME` |
| Common profiles | `throughput-performance`, `latency-performance`, `virtual-guest`, `powersave` | `tuned-adm list` |
| sysctl | Set individual kernel parameters | `sysctl -w`, `/etc/sysctl.d` |
| Persist sysctl | A `.conf` in `/etc/sysctl.d`, applied with `sysctl --system` | `sysctl --system` |
| Measure first | Tune the proven bottleneck, one change at a time | `vmstat`, `iostat` |
| Ubuntu | No `tuned` by default; use `sysctl` and scheduler settings | `sysctl -a` |
<!-- --8<-- [end:facts] -->

---

## tuned Profiles

A `tuned` profile bundles many settings (CPU governor, I/O scheduler, kernel parameters) tested together for a workload, so one command applies a coherent set instead of a dozen manual edits. `tuned-adm` lists, recommends, and switches profiles.

```bash
tuned-adm active
tuned-adm recommend
tuned-adm list
```

Output:

```text
Current active profile: virtual-guest
virtual-guest
Available profiles:
- latency-performance         - Optimize for deterministic performance at the cost of increased power consumption
- throughput-performance      - Broadly applicable tuning that provides excellent performance across a variety of common server workloads
- virtual-guest               - Optimize for running inside a virtual guest
```

The host runs `virtual-guest`, which `tuned-adm recommend` also selects, because it is a VM. A bare-metal server handling steady load would use `throughput-performance`, while a trading or database host might use `latency-performance`.

!!! tip "Prefer a profile over scattered sysctl edits"
    A `tuned` profile is a tested combination, so it avoids the conflicts that come from copying individual `sysctl` lines from unrelated guides. Switch profiles with `tuned-adm profile`, and layer only the specific overrides a workload proves it needs.

---

## sysctl for Tuning

Where a single parameter needs changing, `sysctl` sets it at runtime and a file in `/etc/sysctl.d` persists it. Each subsystem's tunables live with that topic rather than here.

```bash
sudo sysctl -w vm.swappiness=10             # runtime only
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-tuning.conf
sudo sysctl --system                        # apply all .d files
```

Common examples are `vm.swappiness` for paging behaviour, `net.core.somaxconn` for the accept queue, and `net.ipv4.ip_local_port_range` for ephemeral ports. Each is documented with its subsystem; see [sysctl](../11-kernel-and-hardware/sysctl.md) for the mechanism.

!!! note "Measure before and after every change"
    Tuning without a before-and-after measurement is guesswork that can quietly make things worse. Capture the metric, change one setting, and compare, so each change is justified by evidence.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What does tuned do that setting sysctl values by hand does not?"
    **Say first:** `tuned` applies a tested profile of many settings chosen together for a workload, avoiding conflicts between hand-copied values.

    **Proof:** `tuned-adm list` shows profiles like `throughput-performance`; `tuned-adm active` shows the current one.

    **Follow-up:** how do you make a profile survive a reboot? (it already does; `tuned-adm profile` persists it.)
??? question "L1: When does tuning actually help, and what must come first?"
    **Say first:** tuning helps only after the bottleneck is measured; changing a knob before that adds variables without evidence.

    **Proof:** confirm the limiting resource with `vmstat`/`iostat`, then apply one change and re-measure.

    **Follow-up:** why change one setting at a time? (so the effect is attributable.)
<!-- --8<-- [end:l1] -->

??? question "L2: Pick and apply a profile for a throughput-heavy server."
    **Say first:** list the profiles, then switch to the throughput profile.

    **Proof:**

    ```bash
    tuned-adm list
    sudo tuned-adm profile throughput-performance
    ```

    **Follow-up:** what does `tuned-adm recommend` base its suggestion on? (the host role and virtualization.)

??? question "L2: Persist a single kernel parameter without tuned."
    **Say first:** write it to a file in `/etc/sysctl.d` and apply it.

    **Proof:** `echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-tuning.conf && sudo sysctl --system`.

    **Follow-up:** why prefer a `.d` file over editing `/etc/sysctl.conf`? (package-safe, ordered, simple to remove.)

??? question "L3: A latency-sensitive service is jittery on a tuned host. What profile and settings would you check?"
    **Say first:** a latency profile plus the CPU governor and huge-page settings, since throughput profiles trade latency for throughput.

    **Proof:** `tuned-adm active`; consider `latency-performance`; check the governor and transparent huge pages.

    **Follow-up:** why might a database vendor ask to disable transparent huge pages? (THP compaction can pause the process.)

??? question "L4: Why can a throughput profile hurt a latency-sensitive service?"
    **Say first:** throughput profiles favour batching and power states that raise average throughput but add latency jitter, which a latency-sensitive service feels as tail latency.

    **Proof:** `tuned-adm active` shows the profile; `latency-performance` trades power for deterministic latency.

    **Don't say:** that one profile is best for every workload.

---

## Related

- [sysctl](../11-kernel-and-hardware/sysctl.md): runtime and persistent kernel parameters
- [Methodology](methodology.md): measure the bottleneck before tuning
- [CPU and Load](cpu-and-load.md): scheduler and CPU tunables
- [Memory](memory.md): `vm.swappiness` and swap behaviour

Captured on Rocky Linux 10.2 on an iximiuz Labs FlexBox microVM, kernel 6.1.167, 2026-09. Ubuntu ships no `tuned` by default, so the `tuned-adm` output is from the Rocky host.
