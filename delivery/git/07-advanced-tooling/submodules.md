# Submodules

A submodule embeds one repository inside another as a pinned pointer, not a copy: the parent stores a single commit SHA of the child. Interviewers ask about them because the pointer model, the empty-folder-after-clone trap, and the two-step update are where people get stuck.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| A submodule is a pointer | The parent stores a commit SHA, not the files | `git ls-files --stage <path>` |
| Gitlink mode | `160000` marks a submodule entry in the tree | `git ls-files --stage` |
| `.gitmodules` | Tracked file mapping path to URL | `cat .gitmodules` |
| Local config | `.git/config` holds the resolved URL per clone | `git config --list` |
| Add | `git submodule add <url> <path>` | `git submodule status` |
| Clone with them | `git clone --recurse-submodules <url>` | folder is populated |
| After a plain clone | `git submodule update --init --recursive` | folder is populated |
| Update to tracked tip | `git submodule update --remote` | new SHA checked out |
| Pointer move is a commit | The parent must commit the new SHA | `git status` |
| Remove | `git submodule deinit` then `git rm` | `.gitmodules` updated |
<!-- --8<-- [end:facts] -->

---

## A Pointer, Not a Copy

A submodule lets one repository consume another at a specific, reviewed commit without duplicating its files. The parent records only which commit of the child it wants, so there is one source of truth and no copy to drift.

Adding one clones the child into a subdirectory and writes a `.gitmodules` entry.

```bash
git submodule add ../lib.git vendor/lib
```

Output:

```text
Cloning into 'vendor/lib'...
done.
```

The tracked `.gitmodules` file maps the path to the child's URL, so every clone knows where to fetch it.

```bash
cat .gitmodules
```

Output:

```text
[submodule "vendor/lib"]
	path = vendor/lib
	url = ../lib.git
```

---

## The Gitlink

The parent does not store the child's files. In the parent's tree the submodule is a single entry with mode `160000`, a gitlink, whose value is the child commit the parent is pinned to.

```bash
git ls-files --stage vendor/lib
```

Output:

```text
160000 5bbc51696e62a5724caddc028d07046aef896fca 0	vendor/lib
```

That mode `160000` is what distinguishes a submodule from a normal directory (`040000`) or file (`100644`). Committing the add records both `.gitmodules` and this gitlink.

```bash
git status --short
```

Output:

```text
A  .gitmodules
A  vendor/lib
```

`git submodule status` then shows the pinned SHA and the branch it came from.

```bash
git submodule status
```

Output:

```text
 5bbc51696e62a5724caddc028d07046aef896fca vendor/lib (heads/main)
```

---

## Cloning a Repo That Has Submodules

A plain `git clone` copies the parent but leaves every submodule directory empty, because the gitlink is only a pointer. This is the most common submodule surprise.

```bash
git clone ../app app-clone
ls app-clone/vendor/lib
```

Output:

```text
(empty)
```

Cloning with `--recurse-submodules` populates them in one step. After a plain clone, `git submodule update --init --recursive` does the same after the fact.

```bash
git submodule update --init --recursive
```

Output:

```text
Submodule 'vendor/lib' (../lib.git) registered for path 'vendor/lib'
Cloning into 'app-clone/vendor/lib'...
done.
Submodule path 'vendor/lib': checked out '76d4951aa9cbb14b805d186d7e679b96df3a5243'
```

`--init` copies the URL from `.gitmodules` into local config; `--recursive` handles submodules nested inside submodules.

!!! warning "A plain clone leaves submodule folders empty"
    `git clone <url>` alone gives empty submodule directories, which breaks builds that expect the files. Clone with `--recurse-submodules`, or run `git submodule update --init --recursive` right after. Put this instruction in the parent repo's README so contributors are not caught out.

---

## Updating a Submodule

Updating is two steps, and forgetting the second is the classic mistake. `git submodule update --remote` fetches the child's tracked branch tip and checks it out in the submodule.

```bash
git submodule update --remote vendor/lib
```

Output:

```text
From ../lib
   5bbc516..76d4951  main       -> origin/main
Submodule path 'vendor/lib': checked out '76d4951aa9cbb14b805d186d7e679b96df3a5243'
```

That only moves the child's working tree. The parent still points at the old SHA, and now reports the submodule as changed.

```bash
git status --short
```

Output:

```text
 M vendor/lib
```

The diff of the submodule path is the pointer move itself, from the old commit to the new.

```bash
git diff --submodule=short
```

Output:

```text
Subproject commit 5bbc51696e62a5724caddc028d07046aef896fca
Subproject commit 76d4951aa9cbb14b805d186d7e679b96df3a5243
```

The pointer move is itself a change that must be committed in the parent (`git add vendor/lib && git commit`). Until then, other clones still fetch the old SHA.

!!! danger "Updating the child does not update the parent's pointer"
    `git submodule update --remote` moves the submodule's checkout but leaves the parent pinned to the old commit. You must `git add` the submodule path and commit in the parent, or CI and teammates keep getting the previous version. Running `git pull` in the parent root does not touch the submodule at all.

---

## When to Use Submodules

Submodules fit a narrow case: a separate repository, versioned independently, that another repo must consume at a pinned commit.

- **Use** when a child repo produces code, schemas or configs that a parent needs pinned to a specific reviewed version, and the two release on different cadences.
- **Avoid** when the code always changes together (keep it in one repo), or when the team is unfamiliar with the workflow and the extra steps will cause more breakage than the sharing saves.

Alternatives worth naming in an interview are a package registry (publish the child as a versioned dependency) and `git subtree` (vendor the child's files into the parent, no pointer). Each trades the pinning for fewer moving parts.

---

## Common Errors

### `fatal: no submodule mapping found in .gitmodules for path 'vendor/lib'`

**Cause:** the gitlink exists in the tree but `.gitmodules` has no entry, usually because `.gitmodules` was edited or ignored.

**Fix:** restore the `.gitmodules` entry (path and url); never add `.gitmodules` to `.gitignore`.

### Submodule directory is empty after cloning

**Cause:** the parent was cloned without `--recurse-submodules`, so only the pointer came down.

**Fix:** `git submodule update --init --recursive`.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a Git submodule, and what does the parent actually store?"
    **Say first:** a submodule is another repository embedded at a path, and the parent stores only a pinned commit SHA of it (a gitlink), not the child's files.

    **Proof:** `git ls-files --stage <path>` shows mode `160000` and a commit SHA, not file blobs.

    **Follow-up:** What happens to that folder on a plain clone?

??? question "L1: Why is a submodule folder empty after cloning, and how do you fix it?"
    **Say first:** a plain clone copies only the pointer, so the folder is empty; clone with `--recurse-submodules`, or run `git submodule update --init --recursive` afterwards.

    **Proof:** `ls` on the submodule path shows nothing until the update populates it.

    **Follow-up:** Where does `--init` get the URL from?
<!-- --8<-- [end:l1] -->

??? question "L2: Update a submodule to the latest of its tracked branch and record it in the parent."
    **Say first:** fetch and check out the tip with `--remote`, then commit the moved pointer in the parent.

    **Proof:**

    ```bash
    git submodule update --remote vendor/lib
    git add vendor/lib && git commit -m "chore: bump lib submodule"
    ```

    **Follow-up:** What breaks if you skip the second command?

??? question "L2: How do you tell a submodule entry from an ordinary directory in the tree?"
    **Say first:** by the mode; a submodule is a gitlink with mode `160000`, whereas a directory is `040000`.

    **Proof:**

    ```bash
    git ls-files --stage vendor/lib   # 160000 <sha> 0  vendor/lib
    ```

    **Follow-up:** What tracked file maps that path to a URL?

??? question "L3: A teammate ran git pull in the repo root and says the submodule is still on the old code. Why, and what is the correct command?"
    **Say first:** `git pull` in the parent updates the parent only; the submodule stays at whatever commit is checked out, so they need `git submodule update` (add `--remote` to move to the tracked tip).

    **Proof:** `git submodule status` shows the child SHA unchanged after the parent pull; `git submodule update --init --recursive` brings it to the pinned SHA.

    **Follow-up:** When would you use `--remote` versus the plain `git submodule update`?

??? question "L2: When would you choose a package registry or subtree over a submodule?"
    **Say first:** a registry when the child is a releasable dependency you can version, and subtree when you want the child's files vendored in with no pointer or extra clone step.

    **Proof:** both remove the empty-folder and two-step-update traps at the cost of losing the independent pinned pointer.

    **Follow-up:** What does a submodule give you that vendoring the files does not?

---

## Related

- [Object Model](../06-internals/object-model.md): the tree modes, including the `160000` gitlink
- [Remotes](../03-remotes-and-collaboration/remotes.md): fetch and pull, which behave differently across the submodule boundary
- [Large Repos](large-repos.md): other ways to manage code that does not all belong in one clone
- [Error Messages](../reference/error-messages.md): submodule and other errors, cause and fix

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
