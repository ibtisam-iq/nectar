# Interview Preparation

Git interviews for DevOps, SRE and platform roles move through rounds that get deeper each time. This folder follows that structure: each round page collects questions at one level, and the scenarios drill the troubleshooting round. It grows as each module is added.

---

## Rounds

| Round | Level | What is tested | How it is scored |
|---|---|---|---|
| [Round 1: Screening](round-1-screening.md) | L1 | Fundamentals: explain, why, difference | Correct, short answers without hesitation |
| Round 2: Hands-On (batch 4) | L2 | Doing a task in a live repository, reading real output | The right command, first time, and knowing its flags |
| [Round 3: Troubleshooting](round-3-troubleshooting.md) | L3 | An open symptom in a broken repository | The path: questions, hypotheses, ordered checks |
| [Round 4: Internals](round-4-internals.md) | L4 | What Git stores and how commands change it | Mechanism-level explanations and trade-offs |

Round 2 (hands-on) and the mock interviews are added in batch 4.

---

## Answer Method

Every checkpoint in the topic files uses the same shape, and the same shape works in a live interview:

1. **Say first:** one sentence that answers the question directly (bottom line up front).
2. **Proof:** the command or output that shows it, ideally one you have run.
3. **Follow-up:** the next question the interviewer is likely to ask; preparing it is how an L1 answer leads into an L4 discussion.

A **Don't say** line records a common wrong answer worth avoiding.

---

## Study Paths

| Time available | Path |
|---|---|
| 15 minutes | [Must-Know Facts](../reference/must-know-facts.md), read once |
| 1 hour | Must-Know Facts, then [Round 1](round-1-screening.md) aloud, then one scenario |
| 1 day | Every High-weight topic's checkpoints, all scenarios, one lab |
| 1 week | One module per day: topic files, checkpoints, the module lab |

---

## Scenarios

| Scenario | Modules |
|---|---|
| [Accidental Commit to Main](scenarios/accidental-commit-to-main.md) | 01 Core Workflow, 02 Branching and Merging |
| [Wrong-Branch Commits](scenarios/wrong-branch-commits.md) | 01 Core Workflow, 02 Branching and Merging |
| [Merge Conflict Resolution](scenarios/merge-conflict-resolution.md) | 02 Branching and Merging |
| [Detached HEAD](scenarios/detached-head.md) | 02 Branching and Merging |
| [Diverged Branches, Push Rejected](scenarios/diverged-branches-push-rejected.md) | 03 Remotes and Collaboration |
| [Messy History Before a PR](scenarios/messy-history-before-pr.md) | 02 Branching and Merging, 04 Team Workflows |
