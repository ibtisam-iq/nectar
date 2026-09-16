# Linux Checklist

Generated from `manifest.yml` by `scripts/gen-checklist.py`. Tick items in the same commit as the work. Regenerate after any manifest change; ticked items are preserved by id.

---

## Phase 0: Plan Logged in Repository

- [x] `plan/README.md` <!-- id:p0:plan-readme -->
- [x] `plan/standards/` (writing standard, blueprint, definition of done) <!-- id:p0:standards -->
- [x] `plan/linux/` (plan, manifest, decisions, research, checklist) <!-- id:p0:plan-files -->
- [x] `scripts/gen-checklist.py` <!-- id:p0:gen-checklist -->
- [x] `plan/` listed in `exclude_docs` <!-- id:p0:exclude-plan -->
- [x] `CLAUDE.md` points to `plan/` <!-- id:p0:pointer:CLAUDE.md -->
- [x] `GEMINI.md` points to `plan/` <!-- id:p0:pointer:GEMINI.md -->
- [x] `AGENTS.md` points to `plan/` <!-- id:p0:pointer:AGENTS.md -->
- [ ] Phase 0 on `main` (owner pushes and merges) <!-- id:p0:merged -->

---

## Phase 1: Housekeeping

- [x] Raw course material moved to `technical-grounding/linux/_sources/` <!-- id:p1:sources-moved -->
- [ ] Third-party resume moved out of the repository; duplicate zip deleted <!-- id:p1:resume-removed -->
- [x] `_sources/` in `.gitignore` <!-- id:p1:gitignore:_sources/ -->
- [x] `_sources/` in `exclude_docs` <!-- id:p1:exclude:_sources/ -->
- [x] Remove `technical-grounding/linux/Linux.md` <!-- id:remove:Linux.md -->
- [x] Remove `technical-grounding/linux/cheatSheet.md` <!-- id:remove:cheatSheet.md -->
- [x] Remove `technical-grounding/linux/troubleshooting.md` <!-- id:remove:troubleshooting.md -->
- [x] Inbound links fixed in `technical-grounding/basics/index.md` <!-- id:p1:links:technical-grounding/basics/index.md -->
- [x] Local virtual environment synced with `requirements.txt` <!-- id:p1:venv -->
- [x] `_sources/INVENTORY.md` written <!-- id:p1:inventory -->

---

## Phase 2: Pilot

- [x] `templates/topic.md` <!-- id:repo:templates/topic.md -->
- [x] `templates/module-readme.md` <!-- id:repo:templates/module-readme.md -->
- [x] `templates/scenario.md` <!-- id:repo:templates/scenario.md -->
- [x] `scripts/lint-prose.py` <!-- id:repo:scripts/lint-prose.py -->
- [x] `scripts/audit-tool.py` <!-- id:repo:scripts/audit-tool.py -->
- [x] Tool folder `.pages` <!-- id:technical-grounding/linux/.pages -->
- [x] `reference/.pages` <!-- id:technical-grounding/linux/reference/.pages -->
- [x] `interview/.pages` <!-- id:technical-grounding/linux/interview/.pages -->
- [x] `interview/scenarios/.pages` <!-- id:technical-grounding/linux/interview/scenarios/.pages -->
- [x] `labs/.pages` <!-- id:technical-grounding/linux/labs/.pages -->
- [x] `04-users-and-access/.pages` <!-- id:technical-grounding/linux/04-users-and-access/.pages -->
- [x] `04-users-and-access/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/04-users-and-access/README.md -->
- [x] `04-users-and-access/users.md` (Core, High) <!-- id:technical-grounding/linux/04-users-and-access/users.md -->
- [x] `04-users-and-access/groups.md` (Core, High) <!-- id:technical-grounding/linux/04-users-and-access/groups.md -->
- [x] `04-users-and-access/passwords-and-aging.md` (Core, Med) <!-- id:technical-grounding/linux/04-users-and-access/passwords-and-aging.md -->
- [x] `04-users-and-access/sudo-and-su.md` (Core, High, internals) <!-- id:technical-grounding/linux/04-users-and-access/sudo-and-su.md -->
- [x] `04-users-and-access/pam.md` (Core, Low) <!-- id:technical-grounding/linux/04-users-and-access/pam.md -->
- [x] `04-users-and-access/login-sessions.md` (Core, Low) <!-- id:technical-grounding/linux/04-users-and-access/login-sessions.md -->
- [x] `04-users-and-access/centralized-identity.md` (Advanced, Low) <!-- id:technical-grounding/linux/04-users-and-access/centralized-identity.md -->
- [x] `reference/must-know-facts.md` <!-- id:technical-grounding/linux/reference/must-know-facts.md -->
- [x] `reference/coverage-map.md` <!-- id:technical-grounding/linux/reference/coverage-map.md -->
- [x] `labs/README.md` <!-- id:technical-grounding/linux/labs/README.md -->
- [x] `labs/users-and-permissions-lab.md` <!-- id:technical-grounding/linux/labs/users-and-permissions-lab.md -->
- [x] `interview/README.md` <!-- id:technical-grounding/linux/interview/README.md -->
- [x] `interview/round-1-screening.md` <!-- id:technical-grounding/linux/interview/round-1-screening.md -->
- [x] `interview/round-3-troubleshooting.md` <!-- id:technical-grounding/linux/interview/round-3-troubleshooting.md -->
- [x] `interview/round-4-internals.md` <!-- id:technical-grounding/linux/interview/round-4-internals.md -->
- [x] `interview/scenarios/cannot-login-or-sudo.md` (modules 04) <!-- id:technical-grounding/linux/interview/scenarios/cannot-login-or-sudo.md -->
- [x] `README.md` <!-- id:technical-grounding/linux/README.md -->
- [x] `roadmap.md` <!-- id:technical-grounding/linux/roadmap.md -->
- [x] Pilot: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:P:grows -->
- [x] Pilot: `scripts/lint-prose.py` exits 0 <!-- id:check:P:lint -->
- [x] Pilot: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:P:audit -->
- [x] Pilot: `mkdocs build` has no warnings for the tool folder <!-- id:check:P:build -->
- [x] Pilot: owner review done; first-hand line spots listed <!-- id:check:P:owner -->
- [x] Owner sign-off on the pilot <!-- id:p2:signoff -->
- [x] `CLAUDE.md` has the Notes Conventions section <!-- id:p2:conventions -->

---

## Phase 3: Batch A (modules 00, 01, 02)

- [x] `00-foundations/.pages` <!-- id:technical-grounding/linux/00-foundations/.pages -->
- [x] `00-foundations/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/00-foundations/README.md -->
- [x] `00-foundations/what-is-linux.md` (Core, Low) <!-- id:technical-grounding/linux/00-foundations/what-is-linux.md -->
- [x] `00-foundations/kernel-vs-os-vs-distro.md` (Core, Med) <!-- id:technical-grounding/linux/00-foundations/kernel-vs-os-vs-distro.md -->
- [x] `00-foundations/distributions.md` (Core, Low) <!-- id:technical-grounding/linux/00-foundations/distributions.md -->
- [x] `00-foundations/linux-vs-windows.md` (Core, Low) <!-- id:technical-grounding/linux/00-foundations/linux-vs-windows.md -->
- [x] `00-foundations/architecture.md` (Core, High) <!-- id:technical-grounding/linux/00-foundations/architecture.md -->
- [x] `00-foundations/system-information.md` (Core, Med) <!-- id:technical-grounding/linux/00-foundations/system-information.md -->
- [x] `01-shell-and-cli/.pages` <!-- id:technical-grounding/linux/01-shell-and-cli/.pages -->
- [x] `01-shell-and-cli/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/01-shell-and-cli/README.md -->
- [x] `01-shell-and-cli/shell-basics.md` (Core, Med) <!-- id:technical-grounding/linux/01-shell-and-cli/shell-basics.md -->
- [x] `01-shell-and-cli/getting-help.md` (Core, Low) <!-- id:technical-grounding/linux/01-shell-and-cli/getting-help.md -->
- [x] `01-shell-and-cli/command-resolution.md` (Core, Med) <!-- id:technical-grounding/linux/01-shell-and-cli/command-resolution.md -->
- [x] `01-shell-and-cli/variables-and-environment.md` (Core, High) <!-- id:technical-grounding/linux/01-shell-and-cli/variables-and-environment.md -->
- [x] `01-shell-and-cli/locale-and-encoding.md` (Core, Low) <!-- id:technical-grounding/linux/01-shell-and-cli/locale-and-encoding.md -->
- [x] `01-shell-and-cli/quoting-and-expansion.md` (Core, Med) <!-- id:technical-grounding/linux/01-shell-and-cli/quoting-and-expansion.md -->
- [x] `01-shell-and-cli/streams-and-redirection.md` (Core, High) <!-- id:technical-grounding/linux/01-shell-and-cli/streams-and-redirection.md -->
- [x] `01-shell-and-cli/exit-codes-and-chaining.md` (Core, High) <!-- id:technical-grounding/linux/01-shell-and-cli/exit-codes-and-chaining.md -->
- [x] `01-shell-and-cli/text-editors.md` (Core, Low) <!-- id:technical-grounding/linux/01-shell-and-cli/text-editors.md -->
- [x] `01-shell-and-cli/scripting-essentials.md` (RHCSA, Med) <!-- id:technical-grounding/linux/01-shell-and-cli/scripting-essentials.md -->
- [x] Remove `technical-grounding/linux/STDOUT_STDERR_Guide.md` (absorbed into `01-shell-and-cli/`) <!-- id:remove:STDOUT_STDERR_Guide.md -->
- [x] `02-files-and-filesystem/.pages` <!-- id:technical-grounding/linux/02-files-and-filesystem/.pages -->
- [x] `02-files-and-filesystem/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/02-files-and-filesystem/README.md -->
- [x] `02-files-and-filesystem/filesystem-hierarchy.md` (Core, High) <!-- id:technical-grounding/linux/02-files-and-filesystem/filesystem-hierarchy.md -->
- [x] `02-files-and-filesystem/file-types.md` (Core, Med) <!-- id:technical-grounding/linux/02-files-and-filesystem/file-types.md -->
- [x] `02-files-and-filesystem/navigation-and-listing.md` (Core, Low) <!-- id:technical-grounding/linux/02-files-and-filesystem/navigation-and-listing.md -->
- [x] `02-files-and-filesystem/file-operations.md` (Core, Med) <!-- id:technical-grounding/linux/02-files-and-filesystem/file-operations.md -->
- [x] `02-files-and-filesystem/inodes-and-links.md` (Core, High) <!-- id:technical-grounding/linux/02-files-and-filesystem/inodes-and-links.md -->
- [x] `02-files-and-filesystem/file-descriptors.md` (Advanced, High, internals) <!-- id:technical-grounding/linux/02-files-and-filesystem/file-descriptors.md -->
- [x] `02-files-and-filesystem/finding-files.md` (Core, High) <!-- id:technical-grounding/linux/02-files-and-filesystem/finding-files.md -->
- [x] `02-files-and-filesystem/archiving-and-compression.md` (Core, Med) <!-- id:technical-grounding/linux/02-files-and-filesystem/archiving-and-compression.md -->
- [x] Remove `technical-grounding/linux/tar-command.md` (absorbed into `02-files-and-filesystem/`) <!-- id:remove:tar-command.md -->
- [x] `reference/error-messages.md` <!-- id:technical-grounding/linux/reference/error-messages.md -->
- [x] Batch A: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:A:grows -->
- [x] Batch A: `scripts/lint-prose.py` exits 0 <!-- id:check:A:lint -->
- [x] Batch A: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:A:audit -->
- [x] Batch A: `mkdocs build` has no warnings for the tool folder <!-- id:check:A:build -->
- [ ] Batch A: owner review done; first-hand line spots listed <!-- id:check:A:owner -->

---

## Phase 3: Batch B (modules 03, 05, 06)

- [ ] `03-text-processing/.pages` <!-- id:technical-grounding/linux/03-text-processing/.pages -->
- [ ] `03-text-processing/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/03-text-processing/README.md -->
- [ ] `03-text-processing/viewing-and-comparing.md` (Core, Med) <!-- id:technical-grounding/linux/03-text-processing/viewing-and-comparing.md -->
- [ ] `03-text-processing/grep-and-regex.md` (Core, High) <!-- id:technical-grounding/linux/03-text-processing/grep-and-regex.md -->
- [ ] `03-text-processing/sed.md` (Core, High) <!-- id:technical-grounding/linux/03-text-processing/sed.md -->
- [ ] `03-text-processing/awk.md` (Core, High) <!-- id:technical-grounding/linux/03-text-processing/awk.md -->
- [ ] `03-text-processing/cut-sort-uniq-tr.md` (Core, High) <!-- id:technical-grounding/linux/03-text-processing/cut-sort-uniq-tr.md -->
- [ ] `03-text-processing/xargs-and-tee.md` (Core, Med) <!-- id:technical-grounding/linux/03-text-processing/xargs-and-tee.md -->
- [ ] `03-text-processing/json-and-yaml-on-cli.md` (Core, Med) <!-- id:technical-grounding/linux/03-text-processing/json-and-yaml-on-cli.md -->
- [ ] `05-permissions/.pages` <!-- id:technical-grounding/linux/05-permissions/.pages -->
- [ ] `05-permissions/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/05-permissions/README.md -->
- [ ] `05-permissions/basic-permissions.md` (Core, High) <!-- id:technical-grounding/linux/05-permissions/basic-permissions.md -->
- [ ] `05-permissions/umask.md` (Core, Med) <!-- id:technical-grounding/linux/05-permissions/umask.md -->
- [ ] `05-permissions/special-permissions.md` (Core, High) <!-- id:technical-grounding/linux/05-permissions/special-permissions.md -->
- [ ] `05-permissions/acl.md` (RHCSA, Med) <!-- id:technical-grounding/linux/05-permissions/acl.md -->
- [ ] `05-permissions/file-attributes.md` (Core, Med) <!-- id:technical-grounding/linux/05-permissions/file-attributes.md -->
- [ ] `06-package-management/.pages` <!-- id:technical-grounding/linux/06-package-management/.pages -->
- [ ] `06-package-management/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/06-package-management/README.md -->
- [ ] `06-package-management/packaging-concepts.md` (Core, Med) <!-- id:technical-grounding/linux/06-package-management/packaging-concepts.md -->
- [ ] `06-package-management/rpm-and-dnf.md` (Core, Med) <!-- id:technical-grounding/linux/06-package-management/rpm-and-dnf.md -->
- [ ] `06-package-management/dpkg-and-apt.md` (Core, Med) <!-- id:technical-grounding/linux/06-package-management/dpkg-and-apt.md -->
- [ ] `06-package-management/repositories.md` (Core, Low) <!-- id:technical-grounding/linux/06-package-management/repositories.md -->
- [ ] `06-package-management/flatpak-and-snap.md` (RHCSA, Low) <!-- id:technical-grounding/linux/06-package-management/flatpak-and-snap.md -->
- [ ] `06-package-management/shared-libraries.md` (Advanced, Med, internals) <!-- id:technical-grounding/linux/06-package-management/shared-libraries.md -->
- [ ] `06-package-management/other-install-methods.md` (Core, Low) <!-- id:technical-grounding/linux/06-package-management/other-install-methods.md -->
- [ ] Complete `labs/users-and-permissions-lab.md` <!-- id:technical-grounding/linux/labs/users-and-permissions-lab.md:complete -->
- [ ] `interview/scenarios/binary-wont-execute.md` (modules 01, 06) <!-- id:technical-grounding/linux/interview/scenarios/binary-wont-execute.md -->
- [ ] Batch B: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:B:grows -->
- [ ] Batch B: `scripts/lint-prose.py` exits 0 <!-- id:check:B:lint -->
- [ ] Batch B: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:B:audit -->
- [ ] Batch B: `mkdocs build` has no warnings for the tool folder <!-- id:check:B:build -->
- [ ] Batch B: owner review done; first-hand line spots listed <!-- id:check:B:owner -->

---

## Phase 3: Batch C (modules 07, 08)

- [ ] `07-processes/.pages` <!-- id:technical-grounding/linux/07-processes/.pages -->
- [ ] `07-processes/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/07-processes/README.md -->
- [ ] `07-processes/process-fundamentals.md` (Core, High) <!-- id:technical-grounding/linux/07-processes/process-fundamentals.md -->
- [ ] `07-processes/process-lifecycle.md` (Advanced, High, internals) <!-- id:technical-grounding/linux/07-processes/process-lifecycle.md -->
- [ ] `07-processes/viewing-processes.md` (Core, High) <!-- id:technical-grounding/linux/07-processes/viewing-processes.md -->
- [ ] `07-processes/process-states.md` (Core, High) <!-- id:technical-grounding/linux/07-processes/process-states.md -->
- [ ] `07-processes/signals.md` (Core, High, internals) <!-- id:technical-grounding/linux/07-processes/signals.md -->
- [ ] `07-processes/job-control.md` (Core, Med) <!-- id:technical-grounding/linux/07-processes/job-control.md -->
- [ ] `07-processes/priority-and-nice.md` (Core, Med) <!-- id:technical-grounding/linux/07-processes/priority-and-nice.md -->
- [ ] `07-processes/system-calls-and-tracing.md` (Advanced, High, internals) <!-- id:technical-grounding/linux/07-processes/system-calls-and-tracing.md -->
- [ ] `08-systemd-and-services/.pages` <!-- id:technical-grounding/linux/08-systemd-and-services/.pages -->
- [ ] `08-systemd-and-services/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/08-systemd-and-services/README.md -->
- [ ] `08-systemd-and-services/init-and-targets.md` (Core, Med) <!-- id:technical-grounding/linux/08-systemd-and-services/init-and-targets.md -->
- [ ] `08-systemd-and-services/systemctl.md` (Core, High) <!-- id:technical-grounding/linux/08-systemd-and-services/systemctl.md -->
- [ ] `08-systemd-and-services/unit-files.md` (Core, High) <!-- id:technical-grounding/linux/08-systemd-and-services/unit-files.md -->
- [ ] `08-systemd-and-services/writing-a-service.md` (Core, Med) <!-- id:technical-grounding/linux/08-systemd-and-services/writing-a-service.md -->
- [ ] `08-systemd-and-services/systemd-toolbox.md` (Core, Low) <!-- id:technical-grounding/linux/08-systemd-and-services/systemd-toolbox.md -->
- [ ] `labs/processes-and-services-lab.md` <!-- id:technical-grounding/linux/labs/processes-and-services-lab.md -->
- [ ] `interview/scenarios/process-wont-die.md` (modules 07) <!-- id:technical-grounding/linux/interview/scenarios/process-wont-die.md -->
- [ ] Batch C: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:C:grows -->
- [ ] Batch C: `scripts/lint-prose.py` exits 0 <!-- id:check:C:lint -->
- [ ] Batch C: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:C:audit -->
- [ ] Batch C: `mkdocs build` has no warnings for the tool folder <!-- id:check:C:build -->
- [ ] Batch C: owner review done; first-hand line spots listed <!-- id:check:C:owner -->

---

## Phase 3: Batch D (modules 09, 10, 11)

- [ ] `09-logging/.pages` <!-- id:technical-grounding/linux/09-logging/.pages -->
- [ ] `09-logging/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/09-logging/README.md -->
- [ ] `09-logging/log-locations.md` (Core, High) <!-- id:technical-grounding/linux/09-logging/log-locations.md -->
- [ ] `09-logging/journalctl.md` (Core, High) <!-- id:technical-grounding/linux/09-logging/journalctl.md -->
- [ ] `09-logging/rsyslog.md` (Core, Low) <!-- id:technical-grounding/linux/09-logging/rsyslog.md -->
- [ ] `09-logging/logrotate.md` (Core, Med) <!-- id:technical-grounding/linux/09-logging/logrotate.md -->
- [ ] `09-logging/log-parsing-recipes.md` (Core, High) <!-- id:technical-grounding/linux/09-logging/log-parsing-recipes.md -->
- [ ] `10-scheduling/.pages` <!-- id:technical-grounding/linux/10-scheduling/.pages -->
- [ ] `10-scheduling/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/10-scheduling/README.md -->
- [ ] `10-scheduling/cron-and-at.md` (Core, High) <!-- id:technical-grounding/linux/10-scheduling/cron-and-at.md -->
- [ ] `10-scheduling/systemd-timers.md` (Core, Med) <!-- id:technical-grounding/linux/10-scheduling/systemd-timers.md -->
- [ ] `11-kernel-and-hardware/.pages` <!-- id:technical-grounding/linux/11-kernel-and-hardware/.pages -->
- [ ] `11-kernel-and-hardware/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/11-kernel-and-hardware/README.md -->
- [ ] `11-kernel-and-hardware/proc-and-sys.md` (Core, High) <!-- id:technical-grounding/linux/11-kernel-and-hardware/proc-and-sys.md -->
- [ ] `11-kernel-and-hardware/sysctl.md` (Core, High) <!-- id:technical-grounding/linux/11-kernel-and-hardware/sysctl.md -->
- [ ] `11-kernel-and-hardware/kernel-modules.md` (Core, Med) <!-- id:technical-grounding/linux/11-kernel-and-hardware/kernel-modules.md -->
- [ ] `11-kernel-and-hardware/devices-and-udev.md` (Advanced, Low) <!-- id:technical-grounding/linux/11-kernel-and-hardware/devices-and-udev.md -->
- [ ] `11-kernel-and-hardware/dmesg-and-kernel-messages.md` (Core, Med) <!-- id:technical-grounding/linux/11-kernel-and-hardware/dmesg-and-kernel-messages.md -->
- [ ] `interview/scenarios/service-wont-start.md` (modules 08, 09) <!-- id:technical-grounding/linux/interview/scenarios/service-wont-start.md -->
- [ ] `interview/scenarios/cron-job-not-running.md` (modules 01, 10) <!-- id:technical-grounding/linux/interview/scenarios/cron-job-not-running.md -->
- [ ] Batch D: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:D:grows -->
- [ ] Batch D: `scripts/lint-prose.py` exits 0 <!-- id:check:D:lint -->
- [ ] Batch D: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:D:audit -->
- [ ] Batch D: `mkdocs build` has no warnings for the tool folder <!-- id:check:D:build -->
- [ ] Batch D: owner review done; first-hand line spots listed <!-- id:check:D:owner -->

---

## Phase 3: Batch E (modules 12)

- [ ] `12-storage/.pages` <!-- id:technical-grounding/linux/12-storage/.pages -->
- [ ] `12-storage/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/12-storage/README.md -->
- [ ] `12-storage/disks-and-devices.md` (Core, Med) <!-- id:technical-grounding/linux/12-storage/disks-and-devices.md -->
- [ ] `12-storage/partitioning.md` (RHCSA, Med) <!-- id:technical-grounding/linux/12-storage/partitioning.md -->
- [ ] `12-storage/filesystems.md` (Core, Med) <!-- id:technical-grounding/linux/12-storage/filesystems.md -->
- [ ] `12-storage/mounting-and-fstab.md` (Core, High) <!-- id:technical-grounding/linux/12-storage/mounting-and-fstab.md -->
- [ ] `12-storage/swap.md` (Core, Med) <!-- id:technical-grounding/linux/12-storage/swap.md -->
- [ ] `12-storage/lvm.md` (Core, High) <!-- id:technical-grounding/linux/12-storage/lvm.md -->
- [ ] `12-storage/resizing-and-cloud-disks.md` (Core, Med) <!-- id:technical-grounding/linux/12-storage/resizing-and-cloud-disks.md -->
- [ ] `12-storage/disk-usage.md` (Core, High) <!-- id:technical-grounding/linux/12-storage/disk-usage.md -->
- [ ] `12-storage/quotas.md` (RHCSA, Low) <!-- id:technical-grounding/linux/12-storage/quotas.md -->
- [ ] `12-storage/backup-and-restore.md` (Core, Med) <!-- id:technical-grounding/linux/12-storage/backup-and-restore.md -->
- [ ] `12-storage/raid-and-encryption.md` (Advanced, Low) <!-- id:technical-grounding/linux/12-storage/raid-and-encryption.md -->
- [ ] `labs/storage-and-lvm-lab.md` <!-- id:technical-grounding/linux/labs/storage-and-lvm-lab.md -->
- [ ] `interview/scenarios/disk-full.md` (modules 02, 07, 12) <!-- id:technical-grounding/linux/interview/scenarios/disk-full.md -->
- [ ] Batch E: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:E:grows -->
- [ ] Batch E: `scripts/lint-prose.py` exits 0 <!-- id:check:E:lint -->
- [ ] Batch E: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:E:audit -->
- [ ] Batch E: `mkdocs build` has no warnings for the tool folder <!-- id:check:E:build -->
- [ ] Batch E: owner review done; first-hand line spots listed <!-- id:check:E:owner -->

---

## Phase 3: Batch F (modules 13)

- [ ] `13-networking/.pages` <!-- id:technical-grounding/linux/13-networking/.pages -->
- [ ] `13-networking/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/13-networking/README.md -->
- [ ] `13-networking/interfaces-and-addresses.md` (Core, High) <!-- id:technical-grounding/linux/13-networking/interfaces-and-addresses.md -->
- [ ] `13-networking/network-configuration.md` (Core, Med) <!-- id:technical-grounding/linux/13-networking/network-configuration.md -->
- [ ] `13-networking/routing.md` (Core, High) <!-- id:technical-grounding/linux/13-networking/routing.md -->
- [ ] `13-networking/dns-resolution.md` (Core, High) <!-- id:technical-grounding/linux/13-networking/dns-resolution.md -->
- [ ] `13-networking/ports-and-sockets.md` (Core, High) <!-- id:technical-grounding/linux/13-networking/ports-and-sockets.md -->
- [ ] `13-networking/sockets-and-tcp-states.md` (Advanced, Med, internals) <!-- id:technical-grounding/linux/13-networking/sockets-and-tcp-states.md -->
- [ ] `13-networking/connectivity-testing.md` (Core, High) <!-- id:technical-grounding/linux/13-networking/connectivity-testing.md -->
- [ ] `13-networking/packet-capture.md` (Core, Med) <!-- id:technical-grounding/linux/13-networking/packet-capture.md -->
- [ ] `13-networking/bridges-bonds-vlans.md` (Advanced, Low) <!-- id:technical-grounding/linux/13-networking/bridges-bonds-vlans.md -->
- [ ] `13-networking/time-and-timezones.md` (Core, Med) <!-- id:technical-grounding/linux/13-networking/time-and-timezones.md -->
- [ ] `13-networking/reverse-proxy-and-load-balancing.md` (Core, Med) <!-- id:technical-grounding/linux/13-networking/reverse-proxy-and-load-balancing.md -->
- [ ] `13-networking/vpn-wireguard.md` (Advanced, Low) <!-- id:technical-grounding/linux/13-networking/vpn-wireguard.md -->
- [ ] `13-networking/troubleshooting-ladder.md` (Core, High) <!-- id:technical-grounding/linux/13-networking/troubleshooting-ladder.md -->
- [ ] `labs/networking-lab.md` <!-- id:technical-grounding/linux/labs/networking-lab.md -->
- [ ] `interview/scenarios/dns-not-resolving.md` (modules 13) <!-- id:technical-grounding/linux/interview/scenarios/dns-not-resolving.md -->
- [ ] Batch F: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:F:grows -->
- [ ] Batch F: `scripts/lint-prose.py` exits 0 <!-- id:check:F:lint -->
- [ ] Batch F: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:F:audit -->
- [ ] Batch F: `mkdocs build` has no warnings for the tool folder <!-- id:check:F:build -->
- [ ] Batch F: owner review done; first-hand line spots listed <!-- id:check:F:owner -->

---

## Phase 3: Batch G (modules 14, 15)

- [ ] `14-ssh-and-remote-access/.pages` <!-- id:technical-grounding/linux/14-ssh-and-remote-access/.pages -->
- [ ] `14-ssh-and-remote-access/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/14-ssh-and-remote-access/README.md -->
- [ ] `14-ssh-and-remote-access/ssh-client.md` (Core, High) <!-- id:technical-grounding/linux/14-ssh-and-remote-access/ssh-client.md -->
- [ ] `14-ssh-and-remote-access/ssh-tunnels.md` (Core, Med) <!-- id:technical-grounding/linux/14-ssh-and-remote-access/ssh-tunnels.md -->
- [ ] `14-ssh-and-remote-access/sshd-server.md` (Core, Med) <!-- id:technical-grounding/linux/14-ssh-and-remote-access/sshd-server.md -->
- [ ] `14-ssh-and-remote-access/file-transfer.md` (Core, Med) <!-- id:technical-grounding/linux/14-ssh-and-remote-access/file-transfer.md -->
- [ ] `14-ssh-and-remote-access/ssh-troubleshooting.md` (Core, High) <!-- id:technical-grounding/linux/14-ssh-and-remote-access/ssh-troubleshooting.md -->
- [ ] `15-security/.pages` <!-- id:technical-grounding/linux/15-security/.pages -->
- [ ] `15-security/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/15-security/README.md -->
- [ ] `15-security/firewalld-and-ufw.md` (Core, Med) <!-- id:technical-grounding/linux/15-security/firewalld-and-ufw.md -->
- [ ] `15-security/nftables-and-iptables.md` (Core, Med) <!-- id:technical-grounding/linux/15-security/nftables-and-iptables.md -->
- [ ] `15-security/selinux.md` (RHCSA, Med, internals) <!-- id:technical-grounding/linux/15-security/selinux.md -->
- [ ] `15-security/apparmor.md` (Core, Low) <!-- id:technical-grounding/linux/15-security/apparmor.md -->
- [ ] `15-security/capabilities.md` (Advanced, Med) <!-- id:technical-grounding/linux/15-security/capabilities.md -->
- [ ] `15-security/auditd.md` (Advanced, Low) <!-- id:technical-grounding/linux/15-security/auditd.md -->
- [ ] `15-security/gpg.md` (Core, Low) <!-- id:technical-grounding/linux/15-security/gpg.md -->
- [ ] `15-security/openssl-and-trust-store.md` (Core, Med) <!-- id:technical-grounding/linux/15-security/openssl-and-trust-store.md -->
- [ ] `15-security/compliance-and-integrity.md` (Advanced, Low) <!-- id:technical-grounding/linux/15-security/compliance-and-integrity.md -->
- [ ] `15-security/hardening-checklist.md` (Core, Med) <!-- id:technical-grounding/linux/15-security/hardening-checklist.md -->
- [ ] `labs/security-lab.md` <!-- id:technical-grounding/linux/labs/security-lab.md -->
- [ ] `interview/scenarios/cannot-ssh.md` (modules 14, 15) <!-- id:technical-grounding/linux/interview/scenarios/cannot-ssh.md -->
- [ ] `interview/scenarios/service-unreachable.md` (modules 13, 15) <!-- id:technical-grounding/linux/interview/scenarios/service-unreachable.md -->
- [ ] `interview/scenarios/cannot-reach-host.md` (modules 13, 15) <!-- id:technical-grounding/linux/interview/scenarios/cannot-reach-host.md -->
- [ ] `interview/scenarios/tls-certificate-errors.md` (modules 13, 15) <!-- id:technical-grounding/linux/interview/scenarios/tls-certificate-errors.md -->
- [ ] `interview/scenarios/permission-denied.md` (modules 05, 12, 15) <!-- id:technical-grounding/linux/interview/scenarios/permission-denied.md -->
- [ ] `interview/scenarios/suspected-compromise.md` (modules 07, 13, 15) <!-- id:technical-grounding/linux/interview/scenarios/suspected-compromise.md -->
- [ ] Batch G: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:G:grows -->
- [ ] Batch G: `scripts/lint-prose.py` exits 0 <!-- id:check:G:lint -->
- [ ] Batch G: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:G:audit -->
- [ ] Batch G: `mkdocs build` has no warnings for the tool folder <!-- id:check:G:build -->
- [ ] Batch G: owner review done; first-hand line spots listed <!-- id:check:G:owner -->

---

## Phase 3: Batch H (modules 16, 17)

- [ ] `16-boot-and-recovery/.pages` <!-- id:technical-grounding/linux/16-boot-and-recovery/.pages -->
- [ ] `16-boot-and-recovery/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/16-boot-and-recovery/README.md -->
- [ ] `16-boot-and-recovery/boot-process.md` (Core, High) <!-- id:technical-grounding/linux/16-boot-and-recovery/boot-process.md -->
- [ ] `16-boot-and-recovery/grub2.md` (RHCSA, Med) <!-- id:technical-grounding/linux/16-boot-and-recovery/grub2.md -->
- [ ] `16-boot-and-recovery/recovery.md` (RHCSA, Med) <!-- id:technical-grounding/linux/16-boot-and-recovery/recovery.md -->
- [ ] `16-boot-and-recovery/kernel-panic.md` (Advanced, Med, internals) <!-- id:technical-grounding/linux/16-boot-and-recovery/kernel-panic.md -->
- [ ] `16-boot-and-recovery/kernel-updates.md` (Core, Low) <!-- id:technical-grounding/linux/16-boot-and-recovery/kernel-updates.md -->
- [ ] `17-performance-and-troubleshooting/.pages` <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/.pages -->
- [ ] `17-performance-and-troubleshooting/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/README.md -->
- [ ] `17-performance-and-troubleshooting/methodology.md` (Core, High) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/methodology.md -->
- [ ] `17-performance-and-troubleshooting/cpu-and-load.md` (Core, High) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/cpu-and-load.md -->
- [ ] `17-performance-and-troubleshooting/memory.md` (Core, High) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/memory.md -->
- [ ] `17-performance-and-troubleshooting/virtual-memory.md` (Advanced, High, internals) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/virtual-memory.md -->
- [ ] `17-performance-and-troubleshooting/disk-io.md` (Core, Med) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/disk-io.md -->
- [ ] `17-performance-and-troubleshooting/limits-and-file-descriptors.md` (Core, High) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/limits-and-file-descriptors.md -->
- [ ] `17-performance-and-troubleshooting/profiling-and-tracing.md` (Advanced, Med, internals) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/profiling-and-tracing.md -->
- [ ] `17-performance-and-troubleshooting/monitoring-and-capacity.md` (Core, Low) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/monitoring-and-capacity.md -->
- [ ] `17-performance-and-troubleshooting/tuning.md` (RHCSA, Low) <!-- id:technical-grounding/linux/17-performance-and-troubleshooting/tuning.md -->
- [ ] `interview/scenarios/server-slow.md` (modules 07, 17) <!-- id:technical-grounding/linux/interview/scenarios/server-slow.md -->
- [ ] `interview/scenarios/too-many-open-files.md` (modules 02, 17) <!-- id:technical-grounding/linux/interview/scenarios/too-many-open-files.md -->
- [ ] `interview/scenarios/cannot-fork.md` (modules 07, 17) <!-- id:technical-grounding/linux/interview/scenarios/cannot-fork.md -->
- [ ] `interview/scenarios/boot-failure.md` (modules 12, 16) <!-- id:technical-grounding/linux/interview/scenarios/boot-failure.md -->
- [ ] Batch H: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:H:grows -->
- [ ] Batch H: `scripts/lint-prose.py` exits 0 <!-- id:check:H:lint -->
- [ ] Batch H: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:H:audit -->
- [ ] Batch H: `mkdocs build` has no warnings for the tool folder <!-- id:check:H:build -->
- [ ] Batch H: owner review done; first-hand line spots listed <!-- id:check:H:owner -->

---

## Phase 3: Batch I (modules 18, 19, 20)

- [ ] `18-network-storage/.pages` <!-- id:technical-grounding/linux/18-network-storage/.pages -->
- [ ] `18-network-storage/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/18-network-storage/README.md -->
- [ ] `18-network-storage/nfs.md` (Core, Med) <!-- id:technical-grounding/linux/18-network-storage/nfs.md -->
- [ ] `18-network-storage/autofs.md` (RHCSA, Low) <!-- id:technical-grounding/linux/18-network-storage/autofs.md -->
- [ ] `18-network-storage/samba-cifs.md` (RHCSA, Low) <!-- id:technical-grounding/linux/18-network-storage/samba-cifs.md -->
- [ ] `18-network-storage/iscsi-and-nbd.md` (Advanced, Low) <!-- id:technical-grounding/linux/18-network-storage/iscsi-and-nbd.md -->
- [ ] `19-containers/.pages` <!-- id:technical-grounding/linux/19-containers/.pages -->
- [ ] `19-containers/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/19-containers/README.md -->
- [ ] `19-containers/namespaces.md` (Core, High, internals) <!-- id:technical-grounding/linux/19-containers/namespaces.md -->
- [ ] `19-containers/cgroups.md` (Core, High, internals) <!-- id:technical-grounding/linux/19-containers/cgroups.md -->
- [ ] `19-containers/overlayfs-and-chroot.md` (Core, Med) <!-- id:technical-grounding/linux/19-containers/overlayfs-and-chroot.md -->
- [ ] `19-containers/containers-vs-vms.md` (Core, High) <!-- id:technical-grounding/linux/19-containers/containers-vs-vms.md -->
- [ ] `19-containers/podman-and-quadlet.md` (RHCSA, Med) <!-- id:technical-grounding/linux/19-containers/podman-and-quadlet.md -->
- [ ] `20-virtualization-and-provisioning/.pages` <!-- id:technical-grounding/linux/20-virtualization-and-provisioning/.pages -->
- [ ] `20-virtualization-and-provisioning/README.md` (Revision Card, Topic Map) <!-- id:technical-grounding/linux/20-virtualization-and-provisioning/README.md -->
- [ ] `20-virtualization-and-provisioning/kvm-and-libvirt.md` (Advanced, Low) <!-- id:technical-grounding/linux/20-virtualization-and-provisioning/kvm-and-libvirt.md -->
- [ ] `20-virtualization-and-provisioning/vm-images-and-cloning.md` (Advanced, Low) <!-- id:technical-grounding/linux/20-virtualization-and-provisioning/vm-images-and-cloning.md -->
- [ ] `20-virtualization-and-provisioning/cloud-init-and-kickstart.md` (Core, Low) <!-- id:technical-grounding/linux/20-virtualization-and-provisioning/cloud-init-and-kickstart.md -->
- [ ] `labs/containers-by-hand-lab.md` <!-- id:technical-grounding/linux/labs/containers-by-hand-lab.md -->
- [ ] `interview/scenarios/high-load-low-cpu.md` (modules 07, 17, 18) <!-- id:technical-grounding/linux/interview/scenarios/high-load-low-cpu.md -->
- [ ] `interview/scenarios/high-memory-oom.md` (modules 07, 17, 19) <!-- id:technical-grounding/linux/interview/scenarios/high-memory-oom.md -->
- [ ] Batch I: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:I:grows -->
- [ ] Batch I: `scripts/lint-prose.py` exits 0 <!-- id:check:I:lint -->
- [ ] Batch I: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:I:audit -->
- [ ] Batch I: `mkdocs build` has no warnings for the tool folder <!-- id:check:I:build -->
- [ ] Batch I: owner review done; first-hand line spots listed <!-- id:check:I:owner -->

---

## Phase 4: Interview Layer

- [ ] `interview/round-2-hands-on.md` <!-- id:technical-grounding/linux/interview/round-2-hands-on.md -->
- [ ] `interview/mock-interviews.md` <!-- id:technical-grounding/linux/interview/mock-interviews.md -->
- [ ] Output-reading drills in `round-2-hands-on.md` <!-- id:p4:output-drills -->
- [ ] Phase 4: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:4:grows -->
- [ ] Phase 4: `scripts/lint-prose.py` exits 0 <!-- id:check:4:lint -->
- [ ] Phase 4: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:4:audit -->
- [ ] Phase 4: `mkdocs build` has no warnings for the tool folder <!-- id:check:4:build -->
- [ ] Phase 4: owner review done; first-hand line spots listed <!-- id:check:4:owner -->

---

## Phase 5: Reference and Labs

- [ ] `reference/cheatsheet.md` <!-- id:technical-grounding/linux/reference/cheatsheet.md -->
- [ ] `reference/command-index.md` <!-- id:technical-grounding/linux/reference/command-index.md -->
- [ ] `reference/important-files.md` <!-- id:technical-grounding/linux/reference/important-files.md -->
- [ ] `reference/rhel-vs-ubuntu.md` <!-- id:technical-grounding/linux/reference/rhel-vs-ubuntu.md -->
- [ ] `reference/no-tools-fallbacks.md` <!-- id:technical-grounding/linux/reference/no-tools-fallbacks.md -->
- [ ] `reference/glossary.md` <!-- id:technical-grounding/linux/reference/glossary.md -->
- [ ] `labs/rhcsa-style-tasks.md` <!-- id:technical-grounding/linux/labs/rhcsa-style-tasks.md -->
- [ ] `labs/break-fix-lab.md` <!-- id:technical-grounding/linux/labs/break-fix-lab.md -->
- [ ] Every `INVENTORY.md` item resolved <!-- id:p5:inventory-resolved -->
- [ ] Every `coverage-map.md` row points to an existing file <!-- id:p5:coverage-resolved -->
- [ ] Phase 5: aggregators, `roadmap.md` and `coverage-map.md` updated <!-- id:check:5:grows -->
- [ ] Phase 5: `scripts/lint-prose.py` exits 0 <!-- id:check:5:lint -->
- [ ] Phase 5: `scripts/audit-tool.py --scope` exits 0 <!-- id:check:5:audit -->
- [ ] Phase 5: `mkdocs build` has no warnings for the tool folder <!-- id:check:5:build -->
- [ ] Phase 5: owner review done; first-hand line spots listed <!-- id:check:5:owner -->

---

## Phase 6: Completion Audit

- [ ] `scripts/audit-tool.py --manifest plan/linux/manifest.yml --full` exits 0 <!-- id:p6:audit-full -->
- [ ] `lychee` on the final build <!-- id:p6:lychee -->
- [ ] Rendering checked (order, cards, tabs, checkpoints, snippets, phone width, dark mode) <!-- id:p6:render -->
- [ ] Independent review by a fresh agent; findings fixed <!-- id:p6:independent-review -->
- [ ] `plan/linux/audit-report.md` written <!-- id:p6:audit-report -->
- [ ] `plan/README.md` marks the tool complete <!-- id:p6:status -->
- [ ] Work committed locally and handed to the owner (owner pushes and opens the pull request) <!-- id:p6:pr -->
- [ ] Owner final sign-off <!-- id:p6:owner-signoff -->
