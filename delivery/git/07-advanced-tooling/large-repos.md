# Large Repos

Large repositories make clone and checkout slow because Git fetches all history and every file by default. Interviewers ask about the levers that trim that: shallow and partial clones for history and blobs, sparse-checkout for the working tree, LFS for big binaries, and maintenance for ongoing speed.

**Track:** Advanced · **Interview weight:** Med

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Shallow clone | `--depth N` fetches only the last N commits | `git rev-list --count HEAD` |
| Deepen later | `git fetch --deepen N` adds more history | commit count grows |
| Unshallow | `git fetch --unshallow` fetches the rest | `--is-shallow-repository` |
| Partial clone | `--filter=blob:none` skips blobs until needed | missing-object count |
| Promisor | Absent blobs are fetched on demand from the remote | `--missing=print` |
| Sparse-checkout | Materialize only chosen paths in the working tree | `git sparse-checkout list` |
| Cone mode | Directory-based sparse patterns, the default and fast | `sparse-checkout set` |
| Git LFS | Stores large binaries out of band, a pointer in Git | `git lfs ls-files` |
| Maintenance | `git maintenance start` schedules background upkeep | `git config maintenance.strategy` |
| History is intact | Shallow/partial/sparse limit transfer, not the repo | the remote is complete |
<!-- --8<-- [end:facts] -->

---

## Shallow Clone: Less History

A shallow clone with `--depth` fetches only the most recent commits, which is common for CI where old history is not needed. A full clone here has eight commits; a depth-1 clone has one.

```bash
git clone "file://$PWD/repo.git" full
git -C full rev-list --count HEAD
```

Output:

```text
8
```

```bash
git clone --depth 1 "file://$PWD/repo.git" shallow
git -C shallow rev-list --count HEAD
git -C shallow rev-parse --is-shallow-repository
```

Output:

```text
1
true
```

The clone is marked shallow, and history can be extended later without re-cloning. `git fetch --deepen 2` adds two more commits; `git fetch --unshallow` fetches the rest.

```bash
git -C shallow fetch --deepen 2
git -C shallow rev-list --count HEAD
```

Output:

```text
3
```

!!! note "Shallow clones need a file:// or network URL for --depth to apply"
    Cloning a local path by plain filesystem copy ignores `--depth` and warns `--depth is ignored in local clones; use file:// instead`. Real remotes over SSH or HTTPS honour it; the `file://` form above reproduces that behaviour locally.

---

## Partial Clone: Less File Content

A partial clone fetches all commits and trees but skips blob content, downloading each file only when something reads it. `--filter=blob:none` is the usual filter.

```bash
git clone --filter=blob:none "file://$PWD/repo.git" partial
git -C partial rev-list --count HEAD
git -C partial config remote.origin.partialclonefilter
```

Output:

```text
8
blob:none
```

All eight commits are present, so history and `git log` work fully, but the blobs are absent until needed. Listing objects with `--missing=print` shows them as not-yet-fetched.

```bash
git -C partial rev-list --objects --all --missing=print | grep -c '^?'
```

Output:

```text
7
```

Those seven blobs live on the remote as a promisor source and are fetched lazily on first access. Partial clone keeps full history while deferring the bulk, which suits large repos where you rarely touch old file versions.

---

## Sparse-Checkout: Fewer Files in the Working Tree

Sparse-checkout limits which paths are written to the working tree, without changing history. It pairs well with a partial clone in a monorepo where you work on one area.

```bash
git sparse-checkout set src2
ls
```

Output:

```text
history.txt
src2
```

Only `src2` (plus root-level files, in the default cone mode) is materialized; the `docs` directory is omitted from disk though still fully in history. `git sparse-checkout list` shows the active patterns, and `git sparse-checkout disable` restores the full tree.

!!! tip "Combine partial clone and sparse-checkout for a monorepo"
    In a large monorepo, `git clone --filter=blob:none` plus `git sparse-checkout set <your-area>` fetches little and checks out only what you touch. History stays complete on the remote, so `log`, `blame` and switching areas still work, fetching more on demand.

---

## Large Binaries: Git LFS

Git stores every version of a file in full, so large binaries (media, datasets, build artifacts) bloat every clone forever. Git LFS replaces the file in history with a small text pointer and stores the real bytes on a separate LFS server, fetched on checkout.

```bash
git lfs track "*.psd"
git add .gitattributes design.psd
git commit -m "chore: track psd with LFS"
```

LFS is a separate extension, not part of core Git, and it writes its patterns into `.gitattributes`. It is the right tool going forward; a binary already bloating history is removed with `git filter-repo`, covered in [Bloated Repo](../interview/scenarios/bloated-repo-large-file.md).

---

## Maintenance: Keeping a Clone Fast

Over time loose objects and stale refs slow a repository. `git maintenance` runs upkeep (repacking, commit-graph, loose-object pruning) on a schedule, a lighter touch than a full `gc`.

```bash
git maintenance register
git config maintenance.strategy
```

Output:

```text
incremental
```

`git maintenance start` enables scheduled background runs. The commit-graph it builds speeds up history traversal (`log --graph`, `merge-base`) noticeably on large repos.

---

## Common Errors

### `warning: --depth is ignored in local clones; use file:// instead`

**Cause:** cloning a local filesystem path copies objects directly and skips the depth negotiation.

**Fix:** use a `file://` URL (or a real remote) so `--depth` and `--filter` are honoured.

### `error: unable to read sha1 file` after a partial clone offline

**Cause:** a blob was never fetched and the promisor remote is unreachable, so an absent object cannot be lazily downloaded.

**Fix:** reconnect to the remote, or fetch the needed objects first (`git fetch origin`), before working offline.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is a shallow clone, and when would you use one?"
    **Say first:** a shallow clone (`--depth N`) fetches only the last N commits instead of all history, which speeds up CI and one-off builds that do not need the past.

    **Proof:** `git rev-list --count HEAD` returns N, and `git rev-parse --is-shallow-repository` returns `true`.

    **Follow-up:** How do you get the rest of the history later?

??? question "L1: What is the difference between a shallow clone and a partial clone?"
    **Say first:** shallow limits how many commits you fetch; partial (`--filter=blob:none`) keeps all commits but skips file contents until they are needed.

    **Proof:** a partial clone shows the full commit count but reports missing blobs with `rev-list --missing=print`.

    **Follow-up:** Where do the missing blobs come from when you finally read a file?
<!-- --8<-- [end:l1] -->

??? question "L2: A monorepo takes forever to clone and you only work in one directory. What do you set up?"
    **Say first:** a partial clone plus sparse-checkout of your area.

    **Proof:**

    ```bash
    git clone --filter=blob:none <url>
    git sparse-checkout set teams/payments
    ```

    **Follow-up:** Does this lose any history from the remote?

??? question "L2: Why does committing large binaries hurt, and what does Git LFS change?"
    **Say first:** Git keeps every version of a file in full, so binaries bloat every clone permanently; LFS stores a pointer in history and keeps the bytes on a separate server, fetched on checkout.

    **Proof:** `git lfs track "*.bin"` writes the pattern to `.gitattributes`; the committed file is a small pointer.

    **Follow-up:** How do you remove a big file that is already in history?

??? question "L2: A clone has grown slow over months. What upkeep helps?"
    **Say first:** `git maintenance start` schedules incremental repacking and a commit-graph, which speed up traversal without a heavy full `gc`.

    **Proof:**

    ```bash
    git maintenance register
    git config maintenance.strategy   # incremental
    ```

    **Follow-up:** What does the commit-graph accelerate specifically?

??? question "L2: Convert an existing shallow CI clone into a full one to run git blame across history."
    **Say first:** `git fetch --unshallow` fetches the remaining history in place.

    **Proof:**

    ```bash
    git fetch --unshallow
    git rev-parse --is-shallow-repository   # false
    ```

    **Follow-up:** What would `--deepen N` do instead?

---

## Related

- [Bloated Repo, Large File](../interview/scenarios/bloated-repo-large-file.md): finding and purging a big blob already in history
- [Filter-Repo and Secrets](../05-history-and-recovery/filter-repo-and-secrets.md): the history rewrite that reclaims space
- [Packfiles and GC](../06-internals/packfiles-and-gc.md): how Git compresses and repacks objects
- [Submodules](submodules.md): splitting code out of one clone entirely

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
