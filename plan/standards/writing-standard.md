# Writing Standard

This standard applies to every page in every Nectar tool folder. It exists so that notes read as deliberate engineering documentation: structured, concise, accurate, and free of the patterns that mark text as machine-generated.

---

## Sources of Authority

Rules come from three sources, in this order. A higher source wins on conflict.

1. **Persona rules** in [My Core AI Engineering Persona](https://blog.ibtisam-iq.com/my-core-ai-engineering-persona/) (`blog/docs/posts/career/001-my-core-ai-engineering-persona.md`). These are hard rules.
2. **Published practice** on `runbook.ibtisam-iq.com` (pages edited after 2026-06-25) and `blog.ibtisam-iq.com`. Both follow the persona rules, with zero em dashes in prose.
3. **Industry documentation standards** where the first two are silent:

    - **Diátaxis**: each page is one type (tutorial, how-to, reference, explanation), never a blend.
    - **Google developer documentation style guide**: active voice, present tense, one idea per sentence, descriptive link text, no "simply", "just" or "easy".

Older Nectar pages are not a benchmark. Many were written before these standards existed, and some contain pasted chatbot output.

---

## Division of Purpose

The runbook states the boundary: Nectar holds concepts, theory and fundamentals; the runbook holds commands that were run, problems that were hit, and how they were solved.

- Nectar pages explain mechanisms, options and failure modes.
- When a real procedure exists in the runbook, a Nectar page links to it (absolute `https://runbook.ibtisam-iq.com/...` URL) instead of repeating it.

---

## Page Types

| Location | Diátaxis type | Voice |
|---|---|---|
| Module topic files | Explanation + reference | Declarative, present tense, third person: "`usermod -aG` appends a supplementary group." No "you should". |
| `reference/` | Reference | Tables and one-line entries only |
| `interview/scenarios/`, `reference/error-messages.md` | How-to (troubleshooting) | Symptom, cause, fix. First person only for events that happened. |
| `labs/` | Tutorial | The only place imperative steps are allowed ("Create a user named `amor`.") |
| `interview/round-*` | Question and answer | "Say first", "Proof", "Follow-up" |

---

## Structure and Formatting

- **Headings:** H1 is the topic name. H2 and H3 use Title Case, no emoji, no numbering except for real sequences (`### 1. Create the Volume Group`). Separate H2 sections with `---`.
- **Opening:** at most two sentences under the H1 (what it is, why it matters), followed by the `Track · Interview weight` line. No "This guide covers" introductions.
- **Paragraphs:** three sentences maximum. A concept gets at most three sentences before a command, table or list demonstrates it. Definitions are one sentence. Basic commands (`mkdir`, `cp`) get a table row, not a paragraph.
- **Commands:** `bash` code blocks with no `$` prompt. Use `sudo` explicitly when root is required. Define variables at the top of the block. Inline comments explain non-obvious flags only.
- **Output:** a separate `text` code block introduced by the line `Output:`, and only when the output was captured from a real session. A command without captured output has no output block. Placeholder output is never written. Trimmed output is marked `# ... (trimmed)`.
- **Admonitions:** Material for MkDocs syntax only (`!!! note "Title"`), body indented four spaces. Every admonition has a title that states a claim or asks a question, for example `!!! warning "usermod -G without -a replaces every group"`.

    - Allowed types: `note`, `tip`, `info`, `warning`, `danger`, `abstract`.
    - Never `important` (not a Material type) and never GitHub `> [!NOTE]` syntax.
    - Two to five per page.

- **Tables:** comparison tables leave the top-left cell empty and bold the row labels (`| | RHEL / Rocky | Ubuntu / Debian |`). Tables are for lookups and comparisons, never for prose. Commands inside table cells contain no `|`: an escaped pipe renders with a literal backslash inside code, so pipelines go in a code block instead.
- **Lists:** a blank line before every list. Nested lists are indented four spaces, with a blank line before the nested list. Bullets may start with a bold lead phrase.
- **Troubleshooting headings:** the exact error string in backticks, for example ``### `useradd: user 'amor' already exists` ``, followed by `**Cause:**` and `**Fix:**`.
- **Distro tabs:** labels are exactly `=== "RHEL / Rocky"` and `=== "Ubuntu / Debian"` (byte-identical, because `content.tabs.link` synchronises tabs across the site). Use tabs only where commands or output differ.
- **Links:** relative `.md` links inside Nectar; absolute URLs for the runbook and blog; official project documentation only for external sources. Every page ends with a `## Related` section written as "link: short note".
- **Versions:** stated in text and in the capture footer, never in headings or filenames.

---

## Sentence Rules

- **No em dashes (`—`) and no en dashes (`–`) as sentence breaks.** Use a colon, parentheses, or a new sentence. Avoid spaced hyphens (` - `) as punctuation. ASCII punctuation only (no U+2011 non-breaking hyphen).
- **Banned vocabulary (persona list):** delve, leverage, seamless, robust, ever-evolving, elevate, unleash, unlock, dive into, navigate.
- **Also banned:**

    - Senior-sounding words: mastery, expert, flawless, visionary, ultimate, true engineer, deep expertise.
    - Junior-sounding words: learning journey, practicing, student, exploring, trying out, playing around.
    - "Production-grade" or "production-ready" for lab work.
    - Fillers: simply, just, easy, easily, obviously, "it's important to note", "note that", "under the hood".

- **Banned structures:** "In conclusion", "To summarize", "Key takeaways", "TL;DR"; "Not only X but also Y"; dramatic one-line cadence ("One key. Fifty servers."); rhetorical questions; reflexive lists of three; analogy sections; chatbot phrases ("Great question", "Let me", "Would you like").
- **Active voice, present tense, one idea per sentence.** State the condition before the instruction ("On Ubuntu, `adduser` creates the home directory.").
- **Concise, not student-style.** Assume the reader knows what a server, a file and a process are. Explain the mechanism and the trade-off, not the obvious. If a sentence can be deleted without losing a fact, delete it.
- **No invented experience.** Personal references appear only for events recorded in the owner's repositories (for example, the kubelet `status=203/EXEC` journal entry, `sudo cd` failing because `cd` is a shell builtin, `newgrp docker` on an iximiuz dev machine, the WireGuard "run as root" error on EC2).

---

## Accuracy

- Every `text` output block comes from a real capture session. Flags are verified against `man` on the capture machine.
- Version-dependent statements name the version ("NIC teaming is deprecated in RHEL 9", "Linux 6.6 replaced CFS with EEVDF").
- Source material (course handouts, PDFs, third-party question banks) is used as a topic checklist only. Its wording is never copied, and its errors are corrected.

---

## Enforcement

- `scripts/lint-prose.py` checks prose outside code blocks for dashes, spaced hyphens, banned vocabulary and structures, GitHub alerts, untitled or `important` admonitions, untagged code blocks, emoji in headings, and paragraphs or list items over three sentences. It must exit 0 before a batch is committed. Structural rules (Track and Weight line, line budgets, section order) are checked by `scripts/audit-tool.py`.
- `scripts/lint-prose.py` also enforces MkDocs list rules: a blank line before every list and four-space nesting. (`mdformat` was evaluated and rejected: it rewrites `---` section breaks into underscore lines.)
- The owner's review is the final human pass. Each batch lists three to five places where a first-hand line from the owner adds the most value; the owner writes those lines.
