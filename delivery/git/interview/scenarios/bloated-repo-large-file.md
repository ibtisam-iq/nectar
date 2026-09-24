# Bloated Repo, Large File

A repository clones slowly and its `.git` is huge, even though no large file is in the working tree. Interviewers use this because the fix has two parts people conflate: finding which historical blob is heavy, and rewriting history to remove it, not merely deleting the file in a new commit.

---

## Symptom

> "Our repo is 5 MB on disk but the checked-out files are tiny, and clones are slow. Someone committed a build artifact months ago and later deleted it. How do I actually get the size back?"

---

## Clarifying Questions

- **Is the file still in the working tree, or only in history?** A `git rm` in a later commit removes it going forward but leaves every earlier commit carrying it.
- **How big is the offending blob, and which path?** This decides the `filter-repo` invocation and whether LFS is the better long-term home.
- **Is the repo shared?** A history rewrite changes SHAs, so everyone must re-clone afterwards, the same constraint as any rewrite.
- **Should big files of this kind exist at all?** If they must, LFS or an artifact store, not the Git history, is where they belong.

---

## Diagnostic Path

### 1. Confirm the Size Is in History, Not the Working Tree

```bash
du -sk .git
ls
```

Output:

```text
5116	.git
app.txt
```

The working tree holds one small file, yet `.git` is over 5 MB. The weight is in history, where a deleted file still lives in the commits that had it.

### 2. Find the Largest Objects

List every object in history with its size, and sort. The biggest blob and its path stand out.

```bash
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  awk '$1=="blob"{print $3, $4}' | sort -rn | head -3
```

Output:

```text
5120000 build.bin
4 app.txt
```

`build.bin` is 5 MB; everything else is tiny. `git log --oneline -- build.bin` shows the commit that added it and the later one that deleted it, proving the delete did not reclaim the space.

```bash
git log --oneline -- build.bin
```

Output:

```text
1f28c27 remove build artifact
91bc777 add build artifact
```

---

## Root Causes

| Cause | Evidence | Fix |
|---|---|---|
| Large file committed, later deleted | `git log -- <file>` shows add then remove | `filter-repo --path <file> --invert-paths` |
| Deleting the file did not shrink `.git` | Working tree is small, `.git` is large | Rewrite history, not a new delete commit |
| Big binaries belong in Git at all | The file type recurs (media, artifacts) | Move future ones to LFS or an artifact store |
| Space not reclaimed after rewrite | Objects linger in reflog and packs | Expire reflog, then `gc --prune=now` |

---

## Fix

Purge the file from all history with `git filter-repo`, then expire the reflog and garbage-collect to reclaim the space. Run it on a fresh clone, because the rewrite changes SHAs.

```bash
git filter-repo --path build.bin --invert-paths --force
```

Output:

```text
New history written in 0.04 seconds; now repacking/cleaning...
Repacking your repo and cleaning out old unneeded objects
Completely finished after 0.18 seconds.
```

`filter-repo` repacks as it finishes, but objects still reachable from the reflog survive until it is expired.

```bash
git reflog expire --expire=now --all
git gc --prune=now --aggressive
du -sk .git
```

Output:

```text
144	.git
```

The repository dropped from 5116 KB to 144 KB. Confirm the blob is gone from every commit, rather than from the tip alone.

```bash
git log --oneline -- build.bin
```

Output:

```text
(no output)
```

Finish by force-pushing every branch and tag and telling all collaborators to re-clone, exactly as for any history rewrite.

!!! danger "Deleting the file in a new commit does not shrink the repo"
    A `git rm` plus commit removes the file from future checkouts but leaves it in every past commit, so `.git` stays large and clones stay slow. Only rewriting history (`filter-repo`) followed by reflog expiry and `gc` reclaims the space.

---

## Prevention

- Keep build artifacts and large binaries out of Git: `.gitignore` them, and publish artifacts to a registry or object store.
- Adopt Git LFS for large files that must be versioned, so history holds a pointer, not the bytes.
- Add a pre-commit or CI size check that rejects files over a threshold before they ever land.
- Review the first commit that introduces a new file type, where large files most often slip in.

---

## Related

- [Large Repos](../../07-advanced-tooling/large-repos.md): shallow/partial clone, sparse-checkout and LFS
- [Filter-Repo and Secrets](../../05-history-and-recovery/filter-repo-and-secrets.md): the same rewrite tool, applied to secrets
- [Packfiles and GC](../../06-internals/packfiles-and-gc.md): why `gc` and reflog expiry are what reclaim space
- [Committed a Secret](committed-a-secret.md): the other reason to purge something from all history

Captured on macOS 26 with git 2.50.1 and git-filter-repo (throwaway local repositories), 2026-09.
