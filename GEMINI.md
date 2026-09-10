# Antigravity Agent Guidelines & Directives

## 1. Multi-Agent Concurrency (MANDATORY DIRECTIVE)
- **Always dispatch multiple specialized subagents in parallel** whenever there is research, design, component auditing, responsive inspection, or multi-faceted work to be done.
- Divide tasks logically (e.g. Navigation Inspector, Design Auditor, Implementation/Styling Agent, Test/Build Validator) so tasks are executed and verified quickly and thoroughly.
- Never operate purely sequentially when concurrent subagents can inspect, test, or draft solutions simultaneously.

## 2. UI/UX Design Standards (Modern Premium Developer Portal)
- **Typography**: Strictly use standard, high-legibility fonts:
  - **Prose & Interface**: `Inter` (-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif).
  - **Code & Syntax**: `JetBrains Mono` (ui-monospace, Menlo, Monaco, Consolas, monospace).
  - Never revert to awkward condensed, quirky grotesk, or hard-to-read font types.
- **Color Palettes**:
  - **Dark Mode**: True Obsidian Black (`#09090b` canvas, `#121215` / `#111114` elevated card surfaces, hairline translucent dividers `rgba(255, 255, 255, 0.08)`). No muddy navy or blue-gray washes.
  - **Light Mode**: Frosted clean white (`#fafafa` canvas, `#ffffff` cards, soft `#e4e4e7` borders, Royal Blue `#2563eb` accents).
- **Navigation Integrity**:
  - All 10 top-level sections (`Home`, `Grounding`, `Cloud & Infrastructure`, `Containers & Orchestration`, `CI/CD & Delivery`, `Observability & Security`, `Operations`, `Servers & Runtime`, `Scratchpad`, `About`) must always remain visible and stable on desktop/laptop navigation bars without clipping, overflow, or auto-scroll drag.
  - Mobile/tablet hamburger drawer must always function seamlessly across all pages including homepage.
- **Build Quality**:
  - Every change must verify cleanly with `mkdocs build` (exit code 0).
