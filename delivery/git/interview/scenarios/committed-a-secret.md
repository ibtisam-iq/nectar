# Committed a Secret

A credential was committed and pushed, and deleting the file in a later commit did not remove it from history. Interviewers use this because the right answer pairs two steps people forget to do together: rotate the secret (it is already compromised) and rewrite history to purge it.

---

## Symptom

> "I committed a .env with a database password, pushed, then deleted the file and added it to .gitignore. A scanner still flags the secret. How do I get it out, and what else do I need to do?"

---

## Clarifying Questions

- **Is the secret still valid?** If so, rotation is the first and most urgent step; history rewriting alone does not contain a leak.
- **Was it pushed, forked, or in CI logs?** Every place the history reached still has the secret, which changes the cleanup scope.
- **How far back is it?** `git log -- <file>` finds the commits, which decides the `filter-repo` invocation.
- **Who else has clones?** They must re-clone after the rewrite, or they will reintroduce the secret.

---

## Diagnostic Path

### 1. Confirm the Secret Persists in History

```bash
git log --oneline -- .env
```

Output:

```text
6261168 Remove .env, add to gitignore
c85d0c1 Add env
```

Deleting the file created a new commit, but the earlier commits still contain it. The content is fully retrievable from history.

```bash
git show c85d0c1:.env
```

Output:

```text
DB_PASSWORD=hunter2SECRET
```

Anyone with the repository (or a fork, or a cached view) can read the secret from `c85d0c1`. Adding it to `.gitignore` only stops future commits, not past ones.

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Secret file committed and pushed | `git log -- <file>` shows it in history | Rotate, then `filter-repo --path --invert-paths` |
| Deleting the file did not purge history | The blob still resolves in old commits | Rewrite history, not a new commit alone |
| Secret string inside a kept file | The value appears in a file you need | `filter-repo --replace-text` |
| Assuming rewrite contains the leak | The secret was already fetched elsewhere | Rotate the credential regardless |

---

## Fix

Rotate the credential first at its provider; treat it as already stolen. Then purge it from history with `git filter-repo`, run on a fresh clone.

```bash
git filter-repo --path .env --invert-paths --force
git log --oneline -- .env
```

Output:

```text
(no output)
```

No commit references `.env` any more. Confirm the secret string is gone from every object, not the file path alone.

```bash
git log --all -p | grep -c 'hunter2SECRET'
```

Output:

```text
0
```

Zero matches: the value exists in no object. If the secret lived inside a file you must keep, use `git filter-repo --replace-text rules.txt` instead, mapping the string to a placeholder. Finish by force-pushing every branch and telling all collaborators to re-clone, and ask the host to purge cached views and pull-request refs.

!!! danger "Rotation is containment; the rewrite is only cleanup"
    By the time a scanner flags a pushed secret, it may be in clones, forks, CI logs and backups that your rewrite cannot reach. Rotating the credential is what actually stops the damage. Never skip it because the history "looks clean" afterwards.

---

## Prevention

- Keep secrets out of the repo entirely: `.gitignore` the env files from the start, and load secrets from a manager or environment.
- Add a pre-commit secret scanner (gitleaks, detect-secrets) so a credential never gets committed.
- Use short-lived, rotatable credentials so a leak is cheap to contain.
- Review the first commit of any config file before pushing, when secrets most often slip in.

---

## Related

- [Filter-Repo and Secrets](../../05-history-and-recovery/filter-repo-and-secrets.md): the purge tooling and the rotate-first rule in full
- [Ignoring and Attributes](../../01-core-workflow/ignoring-and-attributes.md): keeping secrets untracked from the start
- [Rewriting History](../../05-history-and-recovery/rewriting-history.md): why the rewrite changes SHAs and forces re-clones
- [Object Model](../../06-internals/object-model.md): why the blob persists until history is rewritten

Captured on macOS 26 with git 2.50.1 and git-filter-repo (throwaway local repositories), 2026-09.
