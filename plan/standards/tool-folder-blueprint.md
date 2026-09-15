# Tool Folder Blueprint

Every Nectar tool folder (Linux first, then Docker, Kubernetes, Jenkins and others) follows this layout. The goal is one folder that serves four uses: learning a topic in depth, revising before an interview, preparing for interview rounds, and day-to-day lookup.

---

## Four Layers

| Layer | Location | Used for |
|---|---|---|
| **Learn** | Numbered module folders (`00-...` to `NN-...`), one focused file per topic | Depth and daily lookup |
| **Revise** | The Revision card in each module `README.md`, plus `reference/` | Night-before review, one-hour sweep |
| **Interview** | Checkpoints (L1 to L4) at the end of every topic, plus `interview/` | Round-by-round preparation, mock interviews |
| **Practice** | `labs/`, plus `roadmap.md` as a progress tracker | Hands-on repetition and break-fix drills |

---

## Folder Layout

```text
<tool>/
├── README.md          # the four layers, module map, study paths, out-of-scope list
├── roadmap.md         # checkbox tracker for every topic and lab, with Track and Weight columns
├── .pages
├── 00-<module>/       # numbered from basic to advanced
│   ├── .pages         # title: without the number; explicit nav, no "..." catch-all
│   ├── README.md      # module README (template below)
│   └── <topic>.md     # topic files, not numbered
├── reference/         # cheatsheet, must-know facts, command index, error messages, glossary, coverage map
├── interview/         # README, round-1 to round-4, scenarios/, mock interviews
├── labs/              # hands-on labs, exam-style tasks, break-fix
└── _sources/          # raw source material: git-ignored and excluded from MkDocs
```

Module folders are numbered to show the learning order. Topic files inside a module are not numbered; their order comes from the module `.pages`.

---

## Track and Interview Weight

Every topic file declares both values on the line after its opening sentences:

```markdown
**Track:** Core · **Interview weight:** High
```

| Track | Meaning |
|---|---|
| Core | Needed by every DevOps engineer |
| RHCSA | Certification-relevant (or the tool's equivalent exam); lower daily use |
| Advanced | Internals, specialised or senior-level material |

| Weight | Meaning | Line budget |
|---|---|---|
| High | Appears in most interview sources | 250 to 400 lines |
| Med | Appears in some sources | 150 to 300 lines |
| Low | Rarely asked; kept for completeness | 60 to 150 lines |

Other budgets: module `README.md` up to 150 lines; scenario up to 300; lab up to 400. Files marked `(I)` in a manifest are internals topics that feed the round-4 interview page.

Study paths in the tool `README.md` filter by weight (for example, the one-week plan covers every High topic plus all scenarios).

---

## Topic Template

Sections appear in this order:

1. `# <Topic>`, at most two sentences on what it is and why it matters, then the Track and Weight line.
2. `## Must-Know Facts`: a table of at most 15 rows with a `Verify with` column, wrapped in snippet markers so aggregator pages can include it:

    ```markdown
    <!-- --8<-- [start:facts] -->
    | Fact | Value | Verify with |
    |---|---|---|
    <!-- --8<-- [end:facts] -->
    ```

3. Topic sections (`##`, Title Case, separated by `---`). Each has at most three sentences of prose, then `bash` commands and a captured `text` output block introduced by `Output:`.
4. Titled admonitions only, two to five per page.
5. Distro or platform tabs only where commands actually differ.
6. `## Common Errors`: exact error strings as backticked H3 headings, each with `**Cause:**` and `**Fix:**`.
7. `## Interview Checkpoints`: 6 to 12 collapsible questions. L1 questions come first and sit inside `<!-- --8<-- [start:l1] -->` markers:

    ```markdown
    ??? question "L2: Create a service account that cannot log in and owns /srv/app"
        **Say first:** ...
        **Proof:** ...
        **Follow-up:** ...
    ```

8. `## Related`: "link: short note" entries.
9. Capture footer: `Captured on Rocky Linux 9.x and Ubuntu 24.04 (kernel ...), YYYY-MM.`

No relative links inside snippet sections (included text is re-rendered from other folders).

---

## Module README Template

1. `# <Module Title>` and one purpose sentence.
2. `## Revision Card`: the module's key facts and top commands, printable, no collapsible blocks.
3. `## Topic Map`: `| File | Covers | Track | Weight |`, listing exactly the files in the folder.
4. `## Scenarios and Labs`: links to the interview scenarios and labs this module feeds.

---

## Scenario Template

Matches the runbook debug-entry order:

1. `## Symptom`: phrased the way an interviewer states it.
2. `## Clarifying Questions`
3. `## Diagnostic Path`: `### 1. Check ...` steps, each with its command and captured output.
4. `## Root Causes`: table of branch, evidence, fix.
5. `## Fix`
6. `## Prevention`
7. `## Related`

---

## Interview Question Rules

- **Levels:**

    - **L1** screening: explain, why, difference.
    - **L2** hands-on: do X, or read this output. Answered with a captured command.
    - **L3** troubleshooting: a symptom with no tool named. Scored on the path: clarify, hypothesise, ordered checks.
    - **L4** internals and trade-offs: what happens when.

- **Trivia test:** if someone who never used the tool could answer from a memorised list, it is not a question. It becomes a Must-Know Facts row with a `Verify with` command ("SSH listens on port 22" is a fact, verified with `ss -tlnp`).
- **Answer format:** `**Say first:**` (one sentence), `**Proof:**` (command or output), `**Follow-up:**` (the next-level question). Follow-ups chain L1 to L4 the way real rounds escalate. An optional `**Don't say:**` records a common wrong answer.
- **Coverage:** every High-weight topic has at least one L3 question. Every `(I)` topic has at least one L4 question and is linked from `interview/round-4-internals.md`. Questions in `interview/` span at least two topics, link back to them, and never copy topic questions.
- **Source material:** third-party question banks and course PDFs are input only. Each item is rewritten in this format, turned into a fact, or dropped.

---

## Output Capture Rules

- Output is captured on real machines (for Linux: iximiuz Labs Rocky Linux and Ubuntu playgrounds, or a local VM). Never invented.
- IP addresses, MAC addresses, keys, tokens and account IDs are scrubbed before output enters a page.
- Commands that could not be captured keep their `bash` block and have no output block.
- The capture footer names the distribution, version, kernel and month.

---

## Enforcement

- `scripts/lint-prose.py <folder>`: writing standard checks.
- `scripts/audit-tool.py --manifest plan/<tool>/manifest.yml`: structure and completeness checks (see `definition-of-done.md`).
- `scripts/gen-checklist.py plan/<tool>`: regenerates the progress checklist from the manifest.
