# History and Recovery

Getting work back and reshaping the past: the reflog safety net, binary-searching for a bad commit, rewriting history safely, and purging a leaked secret. These are the topics that turn "I broke Git" into a routine fix.

---

## Revision Card

| Fact | Value |
|---|---|
| Reflog | Local log of every `HEAD`/tip move; recovers lost commits |
| `HEAD@{n}` | Where `HEAD` was n moves ago |
| `ORIG_HEAD` | The tip before the last reset, merge or rebase |
| Bisect | Binary search for the first bad commit (`log2(n)` tests) |
| `bisect run` | Automates the search with a test script |
| Rewrite = new SHAs | Amend, reset, rebase, filter-repo all replace commits |
| Golden rule | Never rewrite commits others have pulled |
| Committed secret | Rotate first, then `filter-repo`, then re-clone |

| Task | Command |
|---|---|
| See history of moves | `git reflog` |
| Undo a bad reset | `git reset --hard HEAD@{1}` (or `ORIG_HEAD`) |
| Recover a deleted branch | `git branch <name> <sha>` |
| Find the bad commit | `git bisect start <bad> <good>; git bisect run ./test.sh` |
| Reshape local commits | `git rebase -i <base>` |
| Purge a file from history | `git filter-repo --path <file> --invert-paths` |
| Scrub a secret string | `git filter-repo --replace-text rules.txt` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Reflog and Recovery](reflog-and-recovery.md) | Reflog, `ORIG_HEAD`, recovering commits and branches | Core | High |
| [Bisect](bisect.md) | Binary search for a regression, `bisect run` | Advanced | Med |
| [Rewriting History](rewriting-history.md) | Amend, reset, rebase, the golden rule, safe force | Advanced | High |
| [Filter-Repo and Secrets](filter-repo-and-secrets.md) | Removing a file or secret from all history | Advanced | Med |

---

## Scenarios and Labs

- [Lost Commits After Reset](../interview/scenarios/lost-commits-after-reset.md): recover work after a hard reset
- [Committed a Secret](../interview/scenarios/committed-a-secret.md): rotate and purge a leaked credential
- [Force-Push Clobbered a Teammate](../interview/scenarios/force-push-clobbered-teammate.md): recover overwritten commits
- [Recovery and Bisect Lab](../labs/recovery-and-bisect-lab.md): reflog recovery, reset and an automated bisect
