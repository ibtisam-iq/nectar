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
