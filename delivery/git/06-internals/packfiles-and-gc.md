# Packfiles and GC

Git first writes objects loose (one compressed file each), then `git gc` collects them into a delta-compressed packfile. Interviewers touch this to check you know why `.git` does not grow linearly with history.

**Track:** Advanced · **Interview weight:** Low

---

## Must-Know Facts

<!-- --8<-- [start:facts] -->
| Fact | Value | Verify with |
|---|---|---|
| Loose object | One zlib-compressed file under `.git/objects/` | `git count-objects -v` |
| Packfile | Many objects in one delta-compressed `.pack` | `ls .git/objects/pack` |
| `git gc` | Packs objects, prunes unreachable, packs refs | `git count-objects -v` |
| Delta compression | Similar objects stored as diffs against a base | `git verify-pack` |
| Auto gc | Runs when loose objects pile up (`gc.auto`) | `git config gc.auto` |
| Prune window | Unreachable objects kept ~2 weeks by default | `git config gc.pruneExpire` |
| Integrity check | `git fsck` verifies objects and connectivity | `git fsck` |
<!-- --8<-- [end:facts] -->

---

## Loose Versus Packed

A new object is stored loose: one file named by its SHA, zlib-compressed. Many small commits produce many loose files, which is simple to write but shares nothing between similar content.

```bash
git count-objects -v | grep -E '^count:|^in-pack:'
```

Output:

```text
count: 15
in-pack: 0
```

`count` is loose objects; `in-pack` is zero until they are packed.

---

## What GC Does

`git gc` packs loose objects into a single packfile, delta-compresses them, packs refs, and prunes unreachable objects past the expiry window. It also runs automatically once loose objects accumulate.

```bash
git gc
git count-objects -v | grep -E '^count:|^in-pack:|^packs:'
```

Output:

```text
count: 0
in-pack: 15
packs: 1
```

Inside the pack, successive versions of a file are stored as deltas against a base object, so ten edits of a large file cost roughly one copy plus nine small diffs. This is why `.git` stays compact as history grows, and why a packfile ships with an `.idx` index for lookup.

!!! info "gc prunes only unreachable objects, and not immediately"
    Objects reachable from a ref or the reflog are always kept. Unreachable ones survive a grace period (about two weeks by default) before pruning, which is what gives the reflog time to recover lost work.

!!! warning "git gc --prune=now removes the recovery safety net"
    Forcing an immediate prune deletes unreachable objects at once, so a commit you dropped minutes ago can become unrecoverable. Run it only when you are sure nothing needs recovery.

---

## Checking Integrity

`git fsck` walks the object graph, verifies each object's hash matches its content, and reports dangling or missing objects; silent output means healthy. `git fsck --lost-found` additionally lists dangling commits for recovery before `gc` prunes them.

---

## Common Errors

### `warning: There are too many unreachable loose objects; run 'git prune'`

**Cause:** many objects became unreachable (repeated resets or rebases) and are still within the prune window.

**Fix:** they clear after the window, or `git gc --prune=now` removes them immediately, once nothing needs recovery.

### `fatal: bad object` or `missing blob` from `git fsck`

**Cause:** a packfile or loose object is corrupt or absent.

**Fix:** recover from another clone (object SHAs are identical everywhere) or a backup; `git fsck` names the object.

---

## Interview Checkpoints

<!-- --8<-- [start:l1] -->
??? question "L1: What is the difference between loose and packed objects?"
    **Say first:** loose objects are one compressed file each; packed objects are collected into a single delta-compressed packfile, which `git gc` produces.

    **Proof:** `git count-objects -v` shows `count` fall to zero and `in-pack` rise after `git gc`.

    **Follow-up:** What does delta compression save?

??? question "L1: What does git gc do?"
    **Say first:** it packs loose objects into a delta-compressed packfile, packs refs, and prunes unreachable objects past the expiry window; it also runs automatically.

    **Proof:** after `git gc`, `git count-objects -v` shows `in-pack` populated and `packs: 1`.

    **Follow-up:** Does `gc` ever delete a commit you might still need?
<!-- --8<-- [end:l1] -->

??? question "L2: Your .git has thousands of loose objects and feels slow. What do you run?"
    **Say first:** `git gc` (or `git repack -ad`) to pack and compress them.

    **Proof:** `git count-objects -v` shows loose `count` fall to zero and a single pack afterwards.

    **Follow-up:** Why did they not auto-pack sooner?

??? question "L2: You force-pushed a rebase and now want the dropped objects gone from disk immediately. Any risk?"
    **Say first:** `git gc --prune=now` removes them, but it also deletes any other unreachable objects, so recovery via the reflog is lost.

    **Proof:** after `--prune=now`, `git fsck --lost-found` no longer finds the dropped commits.

    **Follow-up:** What is the default window before normal `gc` prunes them?

??? question "L3: A clone reports a corrupt object and commands start failing. How do you diagnose and fix it?"
    **Say first:** run `git fsck` to name the bad object, then recover it from another clone where its SHA is identical, or re-clone.

    **Proof:** `git fsck` reports the bad SHA; copying that object from a healthy clone (or re-cloning) restores integrity.

    **Follow-up:** Why is the same object guaranteed to have the same SHA elsewhere?

??? question "L4: How does a packfile store many versions of a large file without a full copy each?"
    **Say first:** the packer keeps one version whole and stores the others as deltas (binary diffs) against a base object, so similar objects cost only their differences plus a base reference.

    **Proof:** `git verify-pack -v <pack>.idx` lists each object with its type and, for deltas, its base and delta depth.

    **Don't say:** "Each version is whole and only zlib-compressed." That is loose storage; packs add delta compression.

---

## Related

- [Object Model](object-model.md): the objects that get packed
- [Refs and HEAD](refs-and-head.md): `pack-refs`, the ref side of what `gc` packs
- [Reflog and Recovery](../05-history-and-recovery/reflog-and-recovery.md): why the prune window matters for recovery
- [What Is Git](../00-foundations/what-is-git.md): content addressing behind dedup and integrity

Captured on macOS 26 with git 2.50.1 (throwaway local repositories), 2026-09.
