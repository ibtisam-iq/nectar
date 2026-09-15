#!/usr/bin/env python3
"""Generate plan/<tool>/checklist.md from plan/<tool>/manifest.yml.

Every item carries a stable id in a trailing HTML comment. When the checklist
is regenerated, items that were already ticked stay ticked.

Usage: python scripts/gen-checklist.py plan/linux
"""

import re
import sys
from pathlib import Path

import yaml

ITEM_RE = re.compile(r"^- \[(?P<mark>[ xX])\] .*<!-- id:(?P<id>[^ ]+) -->\s*$")
BATCH_ORDER = ["P", "A", "B", "C", "D", "E", "F", "G", "H", "I", "4", "5"]


def load_ticked(path: Path) -> set[str]:
    if not path.exists():
        return set()
    ticked = set()
    for line in path.read_text().splitlines():
        m = ITEM_RE.match(line)
        if m and m.group("mark").lower() == "x":
            ticked.add(m.group("id"))
    return ticked


def item(ticked: set[str], item_id: str, text: str) -> str:
    mark = "x" if item_id in ticked else " "
    return f"- [{mark}] {text} <!-- id:{item_id} -->"


def batch_items(m: dict, batch: str) -> list[tuple[str, str]]:
    """Content deliverables scheduled for one batch, as (id, text) pairs."""
    root = m["root"]
    out = []
    for mod in m["modules"]:
        if mod["batch"] != batch:
            continue
        d = mod["dir"]
        out.append((f"{d}/.pages", f"`{d}/.pages`"))
        out.append((f"{d}/README.md", f"`{d}/README.md` (Revision Card, Topic Map)"))
        for t in mod["topics"]:
            flag = ", internals" if t.get("internals") else ""
            out.append(
                (f"{d}/{t['file']}", f"`{d}/{t['file']}` ({t['track']}, {t['weight']}{flag})")
            )
        for legacy in mod.get("absorbs", []):
            out.append(
                (f"remove:{legacy}", f"Remove `{root}/{legacy}` (absorbed into `{d}/`)")
            )
    for section in ("reference", "labs"):
        sec = m[section]
        for p in sec["pages"]:
            if p["batch"] == batch:
                out.append((f"{sec['dir']}/{p['file']}", f"`{sec['dir']}/{p['file']}`"))
            if p.get("completed_in") == batch:
                out.append(
                    (f"{sec['dir']}/{p['file']}:complete", f"Complete `{sec['dir']}/{p['file']}`")
                )
    iv = m["interview"]
    for p in iv["pages"]:
        if p["batch"] == batch:
            out.append((f"{iv['dir']}/{p['file']}", f"`{iv['dir']}/{p['file']}`"))
    sc = iv["scenarios"]
    for s in sc["items"]:
        if s["batch"] == batch:
            feeds = ", ".join(s["feeds"])
            out.append((f"{sc['dir']}/{s['file']}", f"`{sc['dir']}/{s['file']}` (modules {feeds})"))
    for p in m["top_level"]:
        if p["batch"] == batch:
            out.append((p["file"], f"`{p['file']}`"))
    return out


def batch_checks(batch: str, label: str) -> list[tuple[str, str]]:
    return [
        (f"check:{batch}:grows", f"{label}: aggregators, `roadmap.md` and `coverage-map.md` updated"),
        (f"check:{batch}:lint", f"{label}: `scripts/lint-prose.py` exits 0"),
        (f"check:{batch}:mdformat", f"{label}: `mdformat --check` passes"),
        (f"check:{batch}:audit", f"{label}: `scripts/audit-tool.py --scope` exits 0"),
        (f"check:{batch}:build", f"{label}: `mkdocs build` has no warnings for the tool folder"),
        (f"check:{batch}:owner", f"{label}: owner review done; first-hand line spots listed"),
    ]


def render(m: dict, ticked: set[str]) -> str:
    root = m["root"]
    hk = m["housekeeping"]
    lines = [
        f"# {m['tool'].capitalize()} Checklist",
        "",
        f"Generated from `manifest.yml` by `scripts/gen-checklist.py`. Tick items in the same commit as the work. "
        "Regenerate after any manifest change; ticked items are preserved by id.",
        "",
    ]

    def section(title: str, entries: list[tuple[str, str]]) -> None:
        lines.append("---")
        lines.append("")
        lines.append(f"## {title}")
        lines.append("")
        for item_id, text in entries:
            lines.append(item(ticked, item_id, text))
        lines.append("")

    section(
        "Phase 0: Plan Logged in Repository",
        [
            ("p0:plan-readme", "`plan/README.md`"),
            ("p0:standards", "`plan/standards/` (writing standard, blueprint, definition of done)"),
            ("p0:plan-files", f"`plan/{m['tool']}/` (plan, manifest, decisions, research, checklist)"),
            ("p0:gen-checklist", "`scripts/gen-checklist.py`"),
            ("p0:exclude-plan", "`plan/` listed in `exclude_docs`"),
        ]
        + [(f"p0:pointer:{f}", f"`{f}` points to `plan/`") for f in hk["llm_pointers"]]
        + [("p0:merged", "Phase 0 pull request merged to `main`")],
    )

    section(
        "Phase 1: Housekeeping",
        [
            ("p1:sources-moved", f"Raw course material moved to `{root}/{m['sources']['dir']}/`"),
            ("p1:resume-removed", "Third-party resume moved out of the repository; duplicate zip deleted"),
        ]
        + [(f"p1:gitignore:{g}", f"`{g}` in `.gitignore`") for g in hk["gitignore"]]
        + [(f"p1:exclude:{e}", f"`{e}` in `exclude_docs`") for e in hk["exclude_docs"] if e != "plan/"]
        + [
            (f"remove:{Path(f).name}", f"Remove `{f}`")
            for f in hk["remove"]
            if Path(f).name in ("Linux.md", "cheatSheet.md", "troubleshooting.md")
        ]
        + [(f"p1:links:{f}", f"Inbound links fixed in `{f}`") for f in hk["inbound_links_fixed"]]
        + [
            ("p1:venv", "Local virtual environment synced with `requirements.txt`"),
            ("p1:inventory", f"`{m['sources']['inventory']}` written"),
        ],
    )

    section(
        "Phase 2: Pilot",
        [(f"repo:{f}", f"`{f}`") for f in hk["repo_files"] if not f.endswith("gen-checklist.py")]
        + [(f"{root}/.pages", "Tool folder `.pages`")]
        + [
            (f"{root}/{d}/.pages", f"`{d}/.pages`")
            for d in (m["reference"]["dir"], m["interview"]["dir"], m["interview"]["scenarios"]["dir"], m["labs"]["dir"])
        ]
        + [(f"{root}/{i}", t) for i, t in batch_items(m, "P")]
        + batch_checks("P", "Pilot")
        + [
            ("p2:signoff", "Owner sign-off on the pilot"),
            ("p2:conventions", f"`{hk['conventions_section']['file']}` has the {hk['conventions_section']['heading']} section"),
        ],
    )

    for batch in BATCH_ORDER[1:10]:
        mods = [x["id"] for x in m["modules"] if x["batch"] == batch]
        section(
            f"Phase 3: Batch {batch} (modules {', '.join(mods)})",
            [(f"{root}/{i}" if not i.startswith("remove:") else i, t) for i, t in batch_items(m, batch)]
            + batch_checks(batch, f"Batch {batch}"),
        )

    section(
        "Phase 4: Interview Layer",
        [(f"{root}/{i}", t) for i, t in batch_items(m, "4")]
        + [("p4:output-drills", "Output-reading drills in `round-2-hands-on.md`")]
        + batch_checks("4", "Phase 4"),
    )

    section(
        "Phase 5: Reference and Labs",
        [(f"{root}/{i}", t) for i, t in batch_items(m, "5")]
        + [
            ("p5:inventory-resolved", "Every `INVENTORY.md` item resolved"),
            ("p5:coverage-resolved", "Every `coverage-map.md` row points to an existing file"),
        ]
        + batch_checks("5", "Phase 5"),
    )

    section(
        "Phase 6: Completion Audit",
        [
            ("p6:audit-full", f"`scripts/audit-tool.py --manifest plan/{m['tool']}/manifest.yml --full` exits 0"),
            ("p6:lychee", "`lychee` on the final build"),
            ("p6:render", "Rendering checked (order, cards, tabs, checkpoints, snippets, phone width, dark mode)"),
            ("p6:independent-review", "Independent review by a fresh agent; findings fixed"),
            ("p6:audit-report", f"`plan/{m['tool']}/audit-report.md` written"),
            ("p6:status", "`plan/README.md` marks the tool complete"),
            ("p6:pr", "Pull request opened with CI preview"),
            ("p6:owner-signoff", "Owner final sign-off"),
        ],
    )
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2
    plan_dir = Path(sys.argv[1])
    manifest = yaml.safe_load((plan_dir / "manifest.yml").read_text())
    out = plan_dir / "checklist.md"
    ticked = load_ticked(out)
    out.write_text(render(manifest, ticked))
    total = sum(1 for line in out.read_text().splitlines() if ITEM_RE.match(line))
    print(f"{out}: {total} items, {len(ticked)} ticked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
