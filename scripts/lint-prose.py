#!/usr/bin/env python3
"""Check Markdown prose against plan/standards/writing-standard.md.

Checks run on prose only: fenced code blocks, inline code, HTML comments and
URLs are ignored.

Usage: python scripts/lint-prose.py <file-or-folder> [...]
Exit code 1 if any violation is found. Folders named _sources are skipped.
"""

import re
import sys
from pathlib import Path

BANNED = [
    # persona list
    r"delve[sd]?", r"delving", r"leverag(e|es|ed|ing)", r"seamless(ly)?", r"robust(ly|ness)?",
    r"ever-evolving", r"elevat(e|es|ed|ing)", r"unleash(es|ed|ing)?", r"unlock(s|ed|ing)?",
    r"dive into", r"diving into", r"navigat(e|es|ed|ing)",
    # senior and junior register
    r"mastery", r"experts?", r"flawless(ly)?", r"visionary", r"ultimate(ly)?", r"true engineer",
    r"deep expertise", r"learning journey", r"practicing", r"students?", r"exploring",
    r"trying out", r"playing around",
    # lab work is never production
    r"production-grade", r"production-ready",
    # fillers
    r"simply", r"just", r"easy", r"easily", r"obviously", r"it'?s important to note",
    r"note that", r"under the hood",
    # structures
    r"in conclusion", r"to summari[sz]e", r"key takeaways?", r"tl;dr", r"not only",
    r"great question", r"let me", r"would you like",
]
BANNED_RE = re.compile(r"(?<![\w-])(" + "|".join(BANNED) + r")(?![\w-])", re.IGNORECASE)

ADMONITION_TYPES = {"note", "tip", "info", "warning", "danger", "abstract"}
ADMON_RE = re.compile(r"^(?P<indent>\s*)(?P<kind>!!!|\?\?\?\+?)\s*(?P<type>[\w-]*)\s*(?P<title>\".*\")?\s*$")
FENCE_RE = re.compile(r"^(?P<indent>\s*)(?P<fence>`{3,}|~{3,})(?P<info>.*)$")
LIST_RE = re.compile(r"^(?P<indent>\s*)(?:[-*+]|\d+[.)])\s+\S")
HEADING_RE = re.compile(r"^#{1,6}\s")
EMOJI_RE = re.compile(
    "[\U0001F300-\U0001FAFF\U00002600-\U000027BF\U0001F000-\U0001F2FF⭐⬆↔-↪✅❌️⃣]"
)
DASH_RE = re.compile("[—–‑]")
SPACED_HYPHEN_RE = re.compile(r"\S - \S")
GH_ALERT_RE = re.compile(r"^\s*>\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]", re.IGNORECASE)
INLINE_CODE_RE = re.compile(r"(`+)(.+?)\1")
HTML_COMMENT_RE = re.compile(r"<!--.*?-->")
URL_RE = re.compile(r"\]\([^)]*\)|https?://\S+")
ABBREV_RE = re.compile(r"\b(e\.g|i\.e|etc|vs|cf|approx|no)\.", re.IGNORECASE)
SENTENCE_END_RE = re.compile(r"[.!?](?=\s+[A-Z(`*\"']|\s*$)")


def strip_inline(text: str) -> str:
    text = HTML_COMMENT_RE.sub(" ", text)
    text = INLINE_CODE_RE.sub("CODE", text)
    text = URL_RE.sub("](LINK)", text)
    return text


def sentence_count(text: str) -> int:
    text = ABBREV_RE.sub(r"\1", strip_inline(text)).strip()
    if not text:
        return 0
    return max(1, len(SENTENCE_END_RE.findall(text)))


def is_table(line: str) -> bool:
    return line.lstrip().startswith("|")


def lint_file(path: Path) -> list[str]:
    errors: list[str] = []
    lines = path.read_text().splitlines()

    def err(n: int, rule: str, msg: str) -> None:
        errors.append(f"{path}:{n}: [{rule}] {msg}")

    in_fence = False
    fence_marker = ""
    in_comment = False
    para: list[tuple[int, str]] = []

    def flush_para() -> None:
        if para:
            text = " ".join(t for _, t in para)
            count = sentence_count(text)
            if count > 3:
                err(para[0][0], "paragraph-length", f"{count} sentences (max 3)")
        para.clear()

    prev = ""
    for n, raw in enumerate(lines, 1):
        line = raw.rstrip("\n")

        # fenced code blocks
        m = FENCE_RE.match(line)
        if in_fence:
            if m and m.group("fence")[0] == fence_marker[0] and len(m.group("fence")) >= len(fence_marker) and not m.group("info").strip():
                in_fence = False
            prev = line
            continue
        if m:
            flush_para()
            in_fence = True
            fence_marker = m.group("fence")
            if not m.group("info").strip():
                err(n, "code-fence-language", "code block has no language tag (use bash, text, yaml, ...)")
            prev = line
            continue

        # multi-line HTML comments
        if in_comment:
            if "-->" in line:
                in_comment = False
            continue
        if line.strip().startswith("<!--") and "-->" not in line:
            in_comment = True
            continue

        stripped = line.strip()
        prose = strip_inline(line)

        if DASH_RE.search(prose):
            err(n, "dash", "em dash, en dash or non-breaking hyphen in prose (use a colon, parentheses or a new sentence)")
        if not is_table(line) and SPACED_HYPHEN_RE.search(LIST_RE.sub("", prose, count=1) if LIST_RE.match(prose) else prose):
            err(n, "spaced-hyphen", "' - ' used as punctuation")
        for bm in BANNED_RE.finditer(prose):
            err(n, "banned-word", f"'{bm.group(0)}'")
        if is_table(line) and re.search(r"`[^`]*\\\|[^`]*`", line):
            err(n, "table-pipe", "escaped pipe inside code in a table renders a literal backslash; rewrite without '|'")
        if GH_ALERT_RE.match(line):
            err(n, "github-alert", "GitHub alert syntax; use a titled !!! admonition")

        am = ADMON_RE.match(line)
        if am:
            flush_para()
            kind, atype, title = am.group("kind"), am.group("type").lower(), am.group("title")
            if kind == "!!!":
                if atype not in ADMONITION_TYPES:
                    err(n, "admonition-type", f"'{atype or '(none)'}' is not an allowed type")
            elif atype not in ADMONITION_TYPES | {"question"}:
                err(n, "admonition-type", f"'{atype or '(none)'}' is not an allowed type")
            if not title or title == '""':
                err(n, "admonition-title", "admonition has no title")
            prev = line
            continue

        if HEADING_RE.match(line):
            flush_para()
            if EMOJI_RE.search(line):
                err(n, "heading-emoji", "emoji in heading")
            prev = line
            continue

        lm = LIST_RE.match(line)
        if lm:
            flush_para()
            indent = len(lm.group("indent"))
            if indent % 4:
                err(n, "list-indent", f"list marker indented {indent} spaces (use multiples of 4)")
            prev_lm = LIST_RE.match(prev)
            if prev.strip() and not prev_lm and not HEADING_RE.match(prev) and not is_table(prev) and not ADMON_RE.match(prev):
                err(n, "list-blank-line", "no blank line before list")
            if prev_lm and indent > len(prev_lm.group("indent")):
                err(n, "list-blank-line", "no blank line before nested list")
            if sentence_count(line) > 3:
                err(n, "paragraph-length", "list item has more than 3 sentences")
            prev = line
            continue

        if not stripped:
            flush_para()
        elif is_table(line) or stripped.startswith(("<", "===", "--8<--", "**Track:**")) or stripped in ("---",):
            flush_para()
        else:
            para.append((n, stripped))
        prev = line

    flush_para()
    if in_fence:
        err(len(lines), "code-fence", "unclosed code block")
    return errors


def collect(paths: list[str]) -> list[Path]:
    files: list[Path] = []
    for p in map(Path, paths):
        if p.is_dir():
            files += sorted(f for f in p.rglob("*.md") if "_sources" not in f.parts)
        elif p.suffix == ".md":
            files.append(p)
    return files


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip())
        return 2
    errors: list[str] = []
    files = collect(sys.argv[1:])
    for f in files:
        errors += lint_file(f)
    for e in errors:
        print(e)
    print(f"lint-prose: {len(files)} files, {len(errors)} violations")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
