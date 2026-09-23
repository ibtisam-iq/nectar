#!/usr/bin/env python3
"""Completion audit for a Nectar tool folder, driven by plan/<tool>/manifest.yml.

Implements the automated checks in plan/standards/definition-of-done.md.

Usage:
    python scripts/audit-tool.py --manifest plan/linux/manifest.yml --scope B [--build]
    python scripts/audit-tool.py --manifest plan/linux/manifest.yml --full

--scope X   checks everything scheduled up to and including batch X
            (order: P, A, B, C, D, E, F, G, H, I, 4, 5)
--full      checks everything, plus the checklist, housekeeping, LLM pointers
            and a mkdocs build
--build     also runs mkdocs build and fails on warnings for the tool folder

Prints one line per failure and exits 1 if anything fails.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

import yaml

ORDER = ["P", "A", "B", "C", "D", "E", "F", "G", "H", "I", "4", "5"]
REPO = Path(__file__).resolve().parent.parent

# Track name is tool-specific (Linux uses Core/RHCSA/Advanced, git uses Core/Workflow/Advanced),
# so the pattern accepts any capitalised name and the value is validated against the manifest below.
TRACK_RE = re.compile(r"^\*\*Track:\*\* ([A-Z][A-Za-z]+) · \*\*Interview weight:\*\* (High|Med|Low)$")
QUESTION_RE = re.compile(r'^\?\?\?\+? question "(L[1-4]): ')
TAB_RE = re.compile(r'^\s*===\+? "([^"]+)"')
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})(.*)$")
SNIPPET_RE = re.compile(r'--8<--\s+"([^"]+)"')
ADMONITION_RE = re.compile(r'^\s*(?:!!!|\?\?\?\+?) (note|tip|info|warning|danger|abstract) "[^"]+"')
SCENARIO_SECTIONS = ["Symptom", "Clarifying Questions", "Diagnostic Path", "Root Causes", "Fix", "Prevention", "Related"]


class Audit:
    def __init__(self, manifest: dict, upto: str, full: bool, build: bool):
        self.m = manifest
        self.root = REPO / manifest["root"]
        self.upto = ORDER.index(upto)
        self.full = full
        self.build = build
        self.failures: list[str] = []

    # helpers -----------------------------------------------------------------

    def fail(self, check: int, where: str, msg: str) -> None:
        self.failures.append(f"[{check:02d}] {where}: {msg}")

    def due(self, batch: str) -> bool:
        return ORDER.index(str(batch)) <= self.upto

    def rel(self, p: Path) -> str:
        return str(p.relative_to(REPO))

    @staticmethod
    def prose_lines(text: str) -> list[tuple[int, str]]:
        """Lines outside fenced code blocks, with 1-based numbers."""
        out, in_fence, marker = [], False, ""
        for n, line in enumerate(text.splitlines(), 1):
            fm = FENCE_RE.match(line)
            if fm and (not in_fence or (fm.group(1)[0] == marker[0] and not fm.group(2).strip())):
                in_fence, marker = (not in_fence), fm.group(1)
                continue
            if not in_fence:
                out.append((n, line))
        return out

    def topics(self):
        for mod in self.m["modules"]:
            for t in mod["topics"]:
                yield mod, t

    def planned_paths(self) -> dict[Path, str]:
        """Every planned file (all batches) mapped to its batch."""
        m, root = self.m, self.root
        planned = {root / p["file"]: p["batch"] for p in m["top_level"]}
        for mod in m["modules"]:
            planned[root / mod["dir"] / "README.md"] = mod["batch"]
            for t in mod["topics"]:
                planned[root / mod["dir"] / t["file"]] = mod["batch"]
        for sec in ("reference", "labs"):
            for p in m[sec]["pages"]:
                planned[root / m[sec]["dir"] / p["file"]] = p["batch"]
        for p in m["interview"]["pages"]:
            planned[root / m["interview"]["dir"] / p["file"]] = p["batch"]
        sc = m["interview"]["scenarios"]
        for s in sc["items"]:
            planned[root / sc["dir"] / s["file"]] = s["batch"]
        return planned

    def legacy_allowed(self) -> set[Path]:
        """Legacy files that may still exist because their absorbing batch is not due."""
        allowed = set()
        for mod in self.m["modules"]:
            for legacy in mod.get("absorbs", []):
                if not self.due(mod["batch"]):
                    allowed.add(self.root / legacy)
        return allowed

    # checks ------------------------------------------------------------------

    def check_completeness(self) -> None:
        planned = self.planned_paths()
        for path, batch in planned.items():
            if self.due(batch) and not path.exists():
                self.fail(1, self.rel(path), f"planned for batch {batch} but missing")
        allowed = self.legacy_allowed()
        for f in self.root.rglob("*.md"):
            if "_sources" in f.parts:
                continue
            if f not in planned and f not in allowed:
                self.fail(1, self.rel(f), "not listed in the manifest (unplanned file)")

    def check_navigation(self) -> None:
        for d in [self.root, *[p for p in self.root.rglob("*") if p.is_dir()]]:
            if "_sources" in d.parts:
                continue
            entries = [p for p in d.iterdir() if (p.suffix == ".md") or (p.is_dir() and any(p.rglob("*.md")) and "_sources" not in p.parts)]
            if not entries:
                continue
            pages = d / ".pages"
            if not pages.exists():
                self.fail(2, self.rel(d), "folder has no .pages")
                continue
            data = yaml.safe_load(pages.read_text()) or {}
            nav = data.get("nav", [])
            targets = []
            for entry in nav:
                target = list(entry.values())[0] if isinstance(entry, dict) else entry
                if target == "...":
                    self.fail(2, self.rel(pages), "uses the '...' catch-all")
                    continue
                if isinstance(target, str) and not target.startswith("http"):
                    targets.append(target)
                    if not (d / target).exists():
                        self.fail(2, self.rel(pages), f"entry '{target}' does not exist")
            for p in entries:
                if p.name not in targets:
                    self.fail(2, self.rel(p), f"not listed in {self.rel(pages)}")

    def check_topic(self, mod: dict, t: dict, path: Path) -> None:
        text = path.read_text()
        lines = text.splitlines()
        where = self.rel(path)
        prose = self.prose_lines(text)
        # 3: H1, opening, track line
        if not lines or not lines[0].startswith("# "):
            self.fail(3, where, "first line is not an H1")
        track_idx = next((i for i, l in enumerate(lines) if TRACK_RE.match(l)), None)
        if track_idx is None:
            self.fail(3, where, "missing '**Track:** ... · **Interview weight:** ...' line")
        else:
            tm = TRACK_RE.match(lines[track_idx])
            if (tm.group(1), tm.group(2)) != (t["track"], t["weight"]):
                self.fail(3, where, f"Track/Weight {tm.group(1)}/{tm.group(2)} does not match manifest {t['track']}/{t['weight']}")
            opening = " ".join(l for l in lines[1:track_idx] if l.strip())
            if len(re.findall(r"[.!?](?:\s|$)", re.sub(r"`[^`]*`", "", opening))) > 2:
                self.fail(3, where, "opening has more than two sentences")
        headings = [(n, l[3:].strip()) for n, l in prose if l.startswith("## ")]
        names = [h for _, h in headings]
        for required in ("Must-Know Facts", "Interview Checkpoints", "Related"):
            if required not in names:
                self.fail(3, where, f"missing '## {required}'")
        if all(r in names for r in ("Must-Know Facts", "Interview Checkpoints", "Related")):
            if not names.index("Must-Know Facts") < names.index("Interview Checkpoints") < names.index("Related"):
                self.fail(3, where, "sections out of template order")
            if names[-1] != "Related":
                self.fail(3, where, "'## Related' is not the last section")
        if "<!-- --8<-- [start:facts] -->" not in text or "<!-- --8<-- [end:facts] -->" not in text:
            self.fail(3, where, "Must-Know Facts table is not wrapped in facts snippet markers")
        admonitions = [l for _, l in prose if ADMONITION_RE.match(l)]
        if not 2 <= len(admonitions) <= 5:
            self.fail(3, where, f"{len(admonitions)} titled admonitions (need 2 to 5)")
        # 4: checkpoints
        qs = [(n, QUESTION_RE.match(l).group(1)) for n, l in prose if QUESTION_RE.match(l)]
        if not 6 <= len(qs) <= 12:
            self.fail(4, where, f"{len(qs)} interview checkpoints (need 6 to 12)")
        levels = [lvl for _, lvl in qs]
        l1_start = next((n for n, l in prose if "[start:l1]" in l), None)
        l1_end = next((n for n, l in prose if "[end:l1]" in l), None)
        if "L1" not in levels:
            self.fail(4, where, "no L1 checkpoint")
        elif l1_start is None or l1_end is None:
            self.fail(4, where, "L1 checkpoints are not wrapped in l1 snippet markers")
        else:
            for n, lvl in qs:
                if lvl == "L1" and not l1_start < n < l1_end:
                    self.fail(4, where, f"L1 checkpoint on line {n} is outside the l1 markers")
        if "L1" in levels and any(lvl != "L1" for lvl in levels):
            last_l1 = max(i for i, lvl in enumerate(levels) if lvl == "L1")
            first_other = min(i for i, lvl in enumerate(levels) if lvl != "L1")
            if first_other < last_l1:
                self.fail(4, where, "L1 checkpoints must come first")
        if t["weight"] == "High" and "L3" not in levels:
            self.fail(4, where, "High-weight topic has no L3 checkpoint")
        if t.get("internals"):
            if "L4" not in levels:
                self.fail(4, where, "internals topic has no L4 checkpoint")
            r4 = self.root / self.m["interview"]["dir"] / "round-4-internals.md"
            if r4.exists() and f"{mod['dir']}/{t['file']}" not in r4.read_text():
                self.fail(4, where, "internals topic is not linked from round-4-internals.md")
        # 8: budget
        lo, hi = self.m["budgets"]["topic"][t["weight"]]
        if len(lines) > hi:
            self.fail(8, where, f"{len(lines)} lines exceeds the {t['weight']} budget of {hi}")
        elif len(lines) < lo:
            print(f"note: {where}: {len(lines)} lines is below the {t['weight']} guide of {lo}")

    def check_module_readme(self, mod: dict) -> None:
        path = self.root / mod["dir"] / "README.md"
        if not path.exists():
            return
        text = path.read_text()
        where = self.rel(path)
        if "## Revision Card" not in text:
            self.fail(6, where, "missing '## Revision Card'")
        if "## Topic Map" not in text:
            self.fail(6, where, "missing '## Topic Map'")
        else:
            section = text.split("## Topic Map", 1)[1].split("\n## ", 1)[0]
            listed = set(re.findall(r"\(([\w.-]+\.md)\)", section))
            expected = {t["file"] for t in mod["topics"]}
            for missing in sorted(expected - listed):
                self.fail(6, where, f"Topic Map does not list {missing}")
            for extra in sorted(listed - expected):
                self.fail(6, where, f"Topic Map lists {extra}, which is not in the module")
        if len(text.splitlines()) > self.m["budgets"]["module_readme"]:
            self.fail(8, where, "exceeds the module README budget")

    def check_scenarios(self) -> None:
        sc = self.m["interview"]["scenarios"]
        r3 = self.root / self.m["interview"]["dir"] / "round-3-troubleshooting.md"
        r3_text = r3.read_text() if r3.exists() else ""
        for s in sc["items"]:
            if not self.due(s["batch"]):
                continue
            path = self.root / sc["dir"] / s["file"]
            if not path.exists():
                continue
            where = self.rel(path)
            names = [l[3:].strip() for _, l in self.prose_lines(path.read_text()) if l.startswith("## ")]
            present = [x for x in SCENARIO_SECTIONS if x in names]
            for missing in [x for x in SCENARIO_SECTIONS if x not in names]:
                self.fail(5, where, f"missing '## {missing}'")
            if [x for x in names if x in SCENARIO_SECTIONS] != present:
                self.fail(5, where, "sections out of template order")
            if f"scenarios/{s['file']}" not in r3_text:
                self.fail(5, where, "not linked from round-3-troubleshooting.md")
            linked = False
            for mid in s["feeds"]:
                mod = next(x for x in self.m["modules"] if x["id"] == mid)
                readme = self.root / mod["dir"] / "README.md"
                if readme.exists() and s["file"] in readme.read_text():
                    linked = True
            if not linked:
                self.fail(5, where, "not linked from any module README it draws on")
            if len(path.read_text().splitlines()) > self.m["budgets"]["scenario"]:
                self.fail(8, where, "exceeds the scenario budget")

    def check_aggregators(self) -> None:
        ref = self.root / self.m["reference"]["dir"] / "must-know-facts.md"
        r1 = self.root / self.m["interview"]["dir"] / "round-1-screening.md"
        ref_text = ref.read_text() if ref.exists() else ""
        r1_text = r1.read_text() if r1.exists() else ""
        for mod, t in self.topics():
            if not self.due(mod["batch"]):
                continue
            target = f"{self.m['root']}/{mod['dir']}/{t['file']}"
            if ref.exists() and f'"{target}:facts"' not in ref_text:
                self.fail(7, self.rel(ref), f"does not include {target}:facts")
            if r1.exists() and f'"{target}:l1"' not in r1_text:
                self.fail(7, self.rel(r1), f"does not include {target}:l1")

    def check_coverage(self) -> None:
        inv = self.root / self.m["sources"]["dir"] / "INVENTORY.md"
        if not inv.exists():
            self.fail(9, self.rel(inv), "missing")
            return
        for n, line in enumerate(inv.read_text().splitlines(), 1):
            cells = [c.strip() for c in line.strip().strip("|").split("|")] if line.startswith("|") else []
            if len(cells) == 4 and cells[0] not in ("Source", "---") and not set(cells[0]) <= {"-"}:
                if cells[2] not in ("mapped", "fact", "deferred", "dropped"):
                    self.fail(9, f"{self.rel(inv)}:{n}", f"status '{cells[2]}' is not mapped/fact/deferred/dropped")
                if not cells[3]:
                    self.fail(9, f"{self.rel(inv)}:{n}", "no target or reason")

    def check_file_rules(self, path: Path) -> None:
        text = path.read_text()
        where = self.rel(path)
        lines = text.splitlines()
        tabs = set(self.m["tabs"])
        has_output = False
        in_fence = False
        in_snippet = False
        prev_nonblank = ""
        for n, line in enumerate(lines, 1):
            fm = FENCE_RE.match(line)
            if fm:
                if not in_fence:
                    lang = fm.group(2).strip().split()[0] if fm.group(2).strip() else ""
                    if lang == "text":
                        if prev_nonblank.strip() not in ("Output:", "Layout:"):
                            self.fail(10, f"{where}:{n}", "text block is not introduced by 'Output:' (or 'Layout:' for trees)")
                        if prev_nonblank.strip() == "Output:":
                            has_output = True
                    in_fence = True
                else:
                    in_fence = False
                prev_nonblank = line
                continue
            if in_fence:
                continue
            if "[start:" in line:
                in_snippet = True
            if "[end:" in line:
                in_snippet = False
            tm = TAB_RE.match(line)
            if tm and tm.group(1) not in tabs:
                self.fail(11, f"{where}:{n}", f"tab label '{tm.group(1)}' is not an approved label")
            for link in LINK_RE.findall(line):
                if link.startswith(("http://", "https://", "mailto:", "#")):
                    continue
                if in_snippet:
                    self.fail(12, f"{where}:{n}", f"relative link '{link}' inside a snippet section")
                target = (path.parent / link.split("#")[0]).resolve()
                if not target.exists():
                    self.fail(12, f"{where}:{n}", f"link target '{link}' does not exist")
            if line.strip():
                prev_nonblank = line
        if has_output and not any(l.startswith("Captured on") for l in lines[-5:]):
            self.fail(10, where, "page has captured output but no 'Captured on ...' footer")

    def check_housekeeping(self) -> None:
        hk = self.m["housekeeping"]
        for f in hk["remove"]:
            name = Path(f).name
            absorber = next((mod for mod in self.m["modules"] if name in mod.get("absorbs", [])), None)
            if absorber is None or self.due(absorber["batch"]):
                if (REPO / f).exists():
                    self.fail(13, f, "scheduled for removal but still present")
        gi = (REPO / ".gitignore").read_text()
        for pat in hk["gitignore"]:
            if pat not in gi.split():
                self.fail(13, ".gitignore", f"missing '{pat}'")
        mk_lines = {l.strip() for l in (REPO / "mkdocs.yml").read_text().splitlines()}
        for pat in hk["exclude_docs"]:
            if pat not in mk_lines and f"/{pat}" not in mk_lines:
                self.fail(13, "mkdocs.yml", f"exclude_docs missing '{pat}'")
        for f in hk["inbound_links_fixed"]:
            text = (REPO / f).read_text()
            for link in LINK_RE.findall(text):
                if link.startswith(("http", "#")):
                    continue
                if not ((REPO / f).parent / link.split("#")[0]).resolve().exists():
                    self.fail(13, f, f"dead link '{link}'")

    def check_pointers(self) -> None:
        hk = self.m["housekeeping"]
        for f in hk["llm_pointers"]:
            p = REPO / f
            if not p.exists() or "plan/README.md" not in p.read_text():
                self.fail(14, f, "does not point to plan/README.md")
        if self.full or self.upto > ORDER.index("P"):
            cs = hk["conventions_section"]
            if f"## {cs['heading']}" not in (REPO / cs["file"]).read_text():
                self.fail(14, cs["file"], f"missing '## {cs['heading']}' section")
        for f in hk["repo_files"]:
            if not (REPO / f).exists():
                self.fail(14, f, "repository file from the plan is missing")

    def check_checklist(self) -> None:
        cl = REPO / "plan" / self.m["tool"] / "checklist.md"
        for n, line in enumerate(cl.read_text().splitlines(), 1):
            if line.startswith("- [ ]"):
                self.fail(15, f"{self.rel(cl)}:{n}", line[6:].split(" <!--")[0])

    def run_delegated(self) -> None:
        allowed = self.legacy_allowed()
        files = [str(f) for f in sorted(self.root.rglob("*.md")) if "_sources" not in f.parts and f not in allowed]
        lint = subprocess.run([sys.executable, str(REPO / "scripts" / "lint-prose.py"), *files], capture_output=True, text=True) if files else None
        if lint and lint.returncode != 0:
            self.fail(16, "lint-prose.py", lint.stdout.strip().splitlines()[-1])
        if self.build:
            mkdocs = REPO / ".venv" / "bin" / "mkdocs"
            out = subprocess.run([str(mkdocs), "build", "-d", "/tmp/nectar-audit-site"], cwd=REPO, capture_output=True, text=True)
            if out.returncode != 0:
                self.fail(16, "mkdocs build", "build failed")
            for line in (out.stdout + out.stderr).splitlines():
                if ("WARNING" in line or "ERROR" in line) and self.m["root"] in line:
                    self.fail(16, "mkdocs build", line.strip())

    def run(self) -> int:
        self.check_completeness()
        self.check_navigation()
        for mod, t in self.topics():
            path = self.root / mod["dir"] / t["file"]
            if self.due(mod["batch"]) and path.exists():
                self.check_topic(mod, t, path)
        for mod in self.m["modules"]:
            if self.due(mod["batch"]):
                self.check_module_readme(mod)
        self.check_scenarios()
        self.check_aggregators()
        self.check_coverage()
        allowed = self.legacy_allowed()
        for f in sorted(self.root.rglob("*.md")):
            if "_sources" not in f.parts and f not in allowed:
                self.check_file_rules(f)
        self.check_housekeeping()
        self.check_pointers()
        if self.full:
            self.check_checklist()
        self.run_delegated()
        for line in self.failures:
            print(line)
        scope = "full" if self.full else f"through batch {ORDER[self.upto]}"
        print(f"audit-tool: {self.m['tool']} ({scope}): {len(self.failures)} failures")
        return 1 if self.failures else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--manifest", required=True)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument("--scope", choices=ORDER)
    group.add_argument("--full", action="store_true")
    ap.add_argument("--build", action="store_true")
    args = ap.parse_args()
    manifest = yaml.safe_load(Path(args.manifest).read_text())
    upto = ORDER[-1] if args.full else args.scope
    return Audit(manifest, upto, args.full, args.build or args.full).run()


if __name__ == "__main__":
    sys.exit(main())
