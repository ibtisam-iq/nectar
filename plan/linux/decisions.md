# Linux Plan Decisions

Dated log of every decision that shaped the plan. Later changes are appended with the reason and the commit that applied them.

---

## 2026-09-15: Plan Approved

| # | Decision | Reason |
|---|---|---|
| D1 | Distro-neutral commands first; RHEL / Rocky and Ubuntu / Debian shown in equal tabs where they differ | The course was RHEL-based; most DevOps servers run Ubuntu or Debian |
| D2 | Interview questions live in two places: checkpoints at the end of every topic, and a separate `interview/` layer with rounds, scenarios and mocks | Topic checkpoints support self-testing while learning; the `interview/` layer supports round-by-round preparation |
| D3 | Raw course material moves to a git-ignored `_sources/`, also listed in `exclude_docs`; the third-party resume leaves the repository | Institute PDFs are not the owner's to publish; MkDocs ignores `.gitignore` |
| D4 | Scope is core Linux plus DevOps-relevant topics; Ansible, Git, Python and full shell scripting are covered in their own folders | Keeps the Linux folder focused while nothing is lost (tracked in `_sources/INVENTORY.md`) |
| D5 | Folder-based depth: 21 numbered modules, one focused file per topic, organised in four layers (Learn, Revise, Interview, Practice) | The owner asked for Kubernetes-style depth, with better structure than existing folders |
| D6 | Every topic declares Track (Core, RHCSA, Advanced) and Interview weight (High, Med, Low); weight sets the line budget and the study paths | Certifications demand breadth; interviews reward depth on a smaller set; both are served without slowing revision |
| D7 | The writing benchmark is the persona post, then runbook and blog practice, then Diátaxis and the Google developer documentation style guide; older Nectar pages are not a benchmark | Owner feedback: early Nectar pages predate any documentation standard and include pasted chatbot output |
| D8 | Output format follows runbook practice: `bash` blocks without prompts, captured output in `text` blocks introduced by `Output:` | Replaces an earlier draft that used `console` blocks with prompts |
| D9 | The plan is logged in `plan/` and committed first; `CLAUDE.md`, `GEMINI.md` and a new `AGENTS.md` point to it | Any LLM working in the repository must read the plan and standards before writing a tool folder |
| D10 | Completion is proven by `scripts/audit-tool.py` (16 automated checks against `manifest.yml`), an independent review, and owner sign-off | The owner asked for an A-to-Z check that nothing in the plan is missed |
| D11 | Pilot is module `04-users-and-access` as a vertical slice through all four layers | Uses every template feature, covers all four interview levels, and was a weak area in the first interview |

---

## 2026-09-15: Structure Corrections from Research

| # | Decision | Reason |
|---|---|---|
| D12 | Package management moved from module 10 to module 06 | Later modules need tools installed (RH124 teaches RPM before processes) |
| D13 | `file-transfer.md` moved into `14-ssh-and-remote-access/`; `log-parsing-recipes.md` moved into `09-logging/`; `capabilities.md` moved into `15-security/` | Each depended on a module taught later |
| D14 | New module `11-kernel-and-hardware/` (proc and sys, sysctl, modules, udev, dmesg) placed before storage, networking and security | Those modules use sysctl and kernel modules |
| D15 | Added topics: scripting essentials, locale, file descriptors, JSON and YAML on the CLI, centralized identity, Flatpak, shared libraries, process lifecycle, system calls and tracing, quotas, backup and restore, TCP socket states, reverse proxy, VPN, GPG, OpenSSL trust store, compliance tools, kernel panic, virtual memory, profiling, monitoring, Podman and Quadlet, virtualization and provisioning | Gaps found against RHCSA 10, LFCS, LPIC-1, Linux+ and interview sources |
| D16 | File sharing renamed `18-network-storage/` and treated as core | NFS and autofs are core objectives in RHCSA 10 and LFCS |
| D17 | Stratis and VDO reduced to one line; NIC teaming documented as deprecated | Dropped from RHCSA 9 and 10 objectives; teaming deprecated in RHEL 9 |
| D18 | 19 interview scenarios (not 20 as first drafted). Read-only filesystem is a branch of `permission-denied.md`; kernel panic at boot is a branch of `boot-failure.md` | Count corrected while building `manifest.yml` |
| D19 | Agents commit locally only: no push, no pull requests, no AI attribution lines. The rule is recorded in `plan/README.md`, `CLAUDE.md`, `GEMINI.md` and `AGENTS.md` | An agent pushed a branch and opened a pull request without being asked, with an attribution trailer. That PR was closed, the remote branch deleted, and the commit amended. |
