# Internals

How Git stores and moves data underneath the porcelain: the object model, refs and `HEAD`, the mechanics of merge and rebase, and packfiles. These are the senior and SRE questions, and each topic here feeds the internals interview round.

---

## Revision Card

| Fact | Value |
|---|---|
| Objects | Blob, tree, commit, tag; addressed by content hash |
| Content addressed | Identical content, identical SHA (dedup, integrity) |
| Ref | A file holding one SHA; branches, tags, remotes |
| `HEAD` | Symbolic ref to the current branch, or a raw SHA when detached |
| Merge base | Common ancestor; input to a three-way merge |
| Merge commit | Two parents; preserves the DAG |
| Rebase | Replays commits as new SHAs; linear, one parent each |
| Packfile | Delta-compressed store `git gc` builds from loose objects |

| Task | Command |
|---|---|
| Inspect an object | `git cat-file -p <sha>` |
| Object type / size | `git cat-file -t <sha>` / `-s <sha>` |
| Compute a blob SHA | `git hash-object <file>` |
| List all refs | `git for-each-ref` |
| Find the merge base | `git merge-base A B` |
| See a merge's parents | `git log --pretty='%h %p'` |
| Pack and prune | `git gc` |
| Verify integrity | `git fsck` |

---

## Topic Map

| File | Covers | Track | Weight |
|---|---|---|---|
| [Object Model](object-model.md) | Blob, tree, commit, tag; content addressing | Advanced | High |
| [Refs and HEAD](refs-and-head.md) | Refs, `HEAD`, symbolic refs, packed refs | Advanced | High |
| [How Merge and Rebase Work](how-merge-and-rebase-work.md) | Merge base, three-way merge, patch replay | Advanced | High |
| [Packfiles and GC](packfiles-and-gc.md) | Loose vs packed, `gc`, delta compression, `fsck` | Advanced | Low |

---

## Scenarios and Labs

- These internals underpin every recovery scenario in [History and Recovery](../05-history-and-recovery/README.md)
- The internals-by-hand lab (building objects with plumbing) is added in a later batch
