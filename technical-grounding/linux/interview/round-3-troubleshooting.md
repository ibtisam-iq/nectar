# Round 3: Troubleshooting

The troubleshooting round starts with a symptom and no instructions. Interviewers score the path more than the final answer: whether the candidate asks the right questions, forms hypotheses, and checks the cheapest and most likely causes first.

---

## Method

1. **Restate the symptom** in one sentence and confirm it: what fails, for whom, since when.
2. **Ask clarifying questions** that split the problem: one user or all, always or since a change, one host or many.
3. **Form two or three hypotheses** and say which is most likely and why.
4. **Check in order of cost:** read-only commands first (`getent`, `id`, `journalctl`, `ss`, `df`), changes last.
5. **Fix the proven cause only,** then verify with the same command that found it.
6. **Name the prevention:** the control that stops a repeat.

!!! warning "Changing things before reading the evidence loses points"
    Restarting services, `chmod 777` or `setenforce 0` as a first step suggests guessing. Say what you would look at first, and what each result would mean.

---

## Scenario Index

| Scenario | Symptom as asked | Modules |
|---|---|---|
| [Cannot Log In or Use Sudo](scenarios/cannot-login-or-sudo.md) | "A user cannot log in, and another gets an error from sudo." | 04 Users and Access |
| [Binary Won't Execute](scenarios/binary-wont-execute.md) | "We copied tools to a new server and none of them run." | 01 Shell and CLI, 06 Package Management |
| [Process Won't Die](scenarios/process-wont-die.md) | "We ran kill -9 and the process is still there." | 07 Processes |
| [Service Won't Start](scenarios/service-wont-start.md) | "We deployed the new service and systemctl start fails." | 08 Systemd and Services, 09 Logging |
| [Cron Job Not Running](scenarios/cron-job-not-running.md) | "The script works when I run it, but the scheduled job produces nothing." | 01 Shell and CLI, 10 Scheduling |
| [Disk Full](scenarios/disk-full.md) | "The log says No space left on device, and deleting the big log did not help." | 02 Files and Filesystem, 07 Processes, 12 Storage |
