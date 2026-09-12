# MkDocs UI/UX & Kubernetes-Style Sidebar Navigation: Complete Reference & Migration Blueprint

> **Master Architecture & Cross-Repository Portability Guide**  
> *Target Audience:* Non-technical project owners, technical architects, and autonomous coding agents (ChatGPT, Claude, Gemini).  
> *Purpose:* A definitive, drop-in blueprint to upgrade any Material for MkDocs repository with an enterprise-grade Obsidian design system and Kubernetes.io-style collapsible tree navigation.

---

## Table of Contents

1. [Section 1: Overview & What Was Accomplished](#section-1-overview--what-was-accomplished)
   - [1.1 Modern Premium Developer Portal UI/UX](#11-modern-premium-developer-portal-uiux)
   - [1.2 Kubernetes.io-Style Sidebar Navigation](#12-kubernetesio-style-sidebar-navigation)
   - [1.3 Adaptive 3-Column Layout & Distraction-Free Focus Mode (Option A)](#13-adaptive-3-column-layout--distraction-free-focus-mode-option-a)
2. [Section 2: Non-Technical Explanation (What Broke & How It Was Fixed)](#section-2-non-technical-explanation-what-broke--how-it-was-fixed)
   - [2.1 Analogy 1: The "Accordion with Stretchy Buttons" (Caret Drift)](#21-analogy-1-the-accordion-with-stretchy-buttons-caret-drift)
   - [2.2 Analogy 2: The "Dangling Switch" (Non-Functional Section Arrow)](#22-analogy-2-the-dangling-switch-non-functional-section-arrow)
   - [2.3 Analogy 3: The "Stray Pencil Line" (Harsh Vertical Border)](#23-analogy-3-the-stray-pencil-line-harsh-vertical-border)
3. [Section 3: The 3 Core Files Modified (The "Trio")](#section-3-the-3-core-files-modified-the-trio)
   - [3.1 File 1: `mkdocs.yml` (Configuration & Feature Flags)](#31-file-1-mkdocsyml-configuration--feature-flags)
   - [3.2 File 2: `docs/overrides/partials/nav-item.html` (Jinja2 Template Override)](#32-file-2-docsoverridespartialsnav-itemhtml-jinja2-template-override)
   - [3.3 File 3: `docs/stylesheets/extra.css` (Design Tokens & CSS Layout Rules)](#33-file-3-docsstylesheetsextracss-design-tokens--css-layout-rules)
4. [Section 4: Modern Adaptive 3-Column Layout & Focus Mode Architecture (Option A)](#section-4-modern-adaptive-3-column-layout--focus-mode-architecture-option-a)
   - [4.1 Container Max-Width & Horizontal Geometry (`--nx-content-max: 76rem`)](#41-container-max-width--horizontal-geometry---nx-content-max-76rem)
   - [4.2 Laptop Responsive Auto-Collapse (`960px` to `1279px`)](#42-laptop-responsive-auto-collapse-960px-to-1279px)
   - [4.3 Distraction-Free Focus Mode Implementation](#43-distraction-free-focus-mode-implementation)
     - [4.3.1 Header Toggle Control (`.nx-focus-btn`) & Keyboard Shortcuts](#431-header-toggle-control-nx-focus-btn--keyboard-shortcuts)
     - [4.3.2 Session Persistence Engine (`sessionStorage`)](#432-session-persistence-engine-sessionstorage)
     - [4.3.3 Adaptive Focus Mode CSS Rules (`body.nx-focus-mode`)](#433-adaptive-focus-mode-css-rules-bodynx-focus-mode)
5. [Section 5: Header & Navigation Tabs Vertical Geometry / Navbar Uplift Architecture](#section-5-header--navigation-tabs-vertical-geometry--navbar-uplift-architecture)
   - [5.1 Root Cause: Material for MkDocs Default Spacing Void](#51-root-cause-material-for-mkdocs-default-spacing-void)
   - [5.2 The Fix & Blueprint: Geometric Calibration](#52-the-fix--blueprint-geometric-calibration)
   - [5.3 Production CSS Implementation](#53-production-css-implementation)
6. [Section 6: Step-by-Step Migration Guide for Other MkDocs Repositories](#section-6-step-by-step-migration-guide-for-other-mkdocs-repositories)
   - [Step 1: Check and Update `mkdocs.yml`](#step-1-check-and-update-mkdocsyml)
   - [Step 2: Create the Template Override Directory and File](#step-2-create-the-template-override-directory-and-file)
   - [Step 3: Integrate Styles into `extra.css`](#step-3-integrate-styles-into-extracss)
   - [Step 4: Register Interactive Focus Engine in `extra.js`](#step-4-register-interactive-focus-engine-in-extrajs)
   - [Step 5: Build, Inspect, and Verify](#step-5-build-inspect-and-verify)
7. [Section 7: Ready-to-Use LLM Prompt Template](#section-7-ready-to-use-llm-prompt-template)
8. [Summary Reference Table](#summary-reference-table)

---

## Section 1: Overview & What Was Accomplished

The transformation of **Nectar** into a world-class engineering portal addressed two fundamental domains: visual presentation (**UI/UX Modernization**) and hierarchical exploration (**Kubernetes.io-Style Tree Navigation**).

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                NECTAR MODERN PORTAL                                    │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  Top Navigation Bar: 10 First-Class Tabs (Stable, Zero-Wrap, Sticky Blur Header)       │
├───────────────────────────────┬────────────────────────────────────────────────────────┤
│  LEFT SIDEBAR NAVIGATION      │  MAIN CONTENT & HOMEPAGE HERO                          │
│  (Kubernetes.io Paradigm)     │                                                        │
│                               │  [2-Column Desktop Grid @ >= 1080px]                   │
│  ▶ Home                       │  Left: High-Impact Editorial & CTAs                    │
│  ▼ Containers & Orchestration │  - Live Pill Badge ("✦ Living Knowledge Base")         │
│    ▶ Architecture & Core      │  - H1 Display Heading with Gradient Accent             │
│    ▼ Kubernetes Workloads     │  - Dual Action Buttons (Solid Accent + Ghost Glass)    │
│      • Deployments & Rollouts │  - Credibility Stats Row (Certifications, Domains)     │
│      • StatefulSets & Storage │                                                        │
│    ▶ Networking & Ingress     │  Right: macOS Developer Terminal Window (.nx-terminal) │
│  ▶ Cloud & Infrastructure     │  - Traffic Light Controls (Red, Yellow, Green)         │
│  ▶ CI/CD & Delivery           │  - Active Tab Pill ("nectar-diagnostics.sh")           │
│                               │  - Monospace Syntax Diagnostic Output & Status Checks  │
└───────────────────────────────┴────────────────────────────────────────────────────────┘
```

### 1.1 Modern Premium Developer Portal UI/UX

1. **True Obsidian Dark Mode & Frosted Light Mode**:
   - **Dark Mode (`slate`)**: Replaced default muddy blue/gray slate backgrounds with **True Obsidian Black** (`#09090b` canvas), elevated dark surfaces (`#121215` / `#111114` card backgrounds), translucent hairline dividers (`rgba(255, 255, 255, 0.08)`), and electric blue accents (`#3b82f6` / `#60a5fa`).
   - **Light Mode (`default`)**: Crisp frosted white canvas (`#fafafa`), pure white card surfaces (`#ffffff`), subtle borders (`#e4e4e7`), and Royal Blue accents (`#2563eb`).
2. **Standard High-Legibility Typography**:
   - Replaced condensed or idiosyncratic fonts with industry-standard web typography:
     - **Prose & Interface**: `Inter`, `-apple-system`, `BlinkMacSystemFont`, `"Segoe UI"`, `Roboto`, sans-serif.
     - **Code & Syntax**: `JetBrains Mono`, `ui-monospace`, `Menlo`, `Monaco`, monospace.
3. **Desktop Navbar Stability (10 Knowledge Domains)**:
   - All 10 top-level navigation tabs (`Home`, `Grounding`, `Cloud & Infrastructure`, `Containers & Orchestration`, `CI/CD & Delivery`, `Observability & Security`, `Operations`, `Servers & Runtime`, `Scratchpad`, `About`) remain visible, crisp, and anchored on desktop navigation bars without clipping, horizontal scrollbars, or layout shifts.
4. **2-Column Responsive Homepage Hero with macOS Developer Terminal**:
   - Designed for wide screens (`>= 1080px`):
     - **Left Column**: Live indicator pill badge, editorial display title with CSS gradient text clipping, dual action buttons (solid primary with hover arrow transition + frosted ghost button), and credibility metrics.
     - **Right Column**: Interactive macOS-style terminal (`.nx-terminal`) featuring authentic traffic-light buttons (red `#ff5f56`, yellow `#ffbd2e`, green `#27c93f`), tab title, shell prompt, and diagnostic output rows.
   - Designed for tablets and phones (`< 1080px`): Stacks cleanly into a vertical layout with a 100% full-width terminal to prevent text truncation or horizontal overflow bleed.
5. **Compact Header & Navigation Tabs Vertical Geometry (Navbar Uplift)**:
   - Eliminates the ~34px default vertical void between the top header row and navigation tabs by zeroing `.md-tabs__link` top margin and compacting item height to `1.95rem`, creating an integrated ~9px gap and reclaiming critical screen real estate above the fold.

---

### 1.2 Kubernetes.io-Style Sidebar Navigation

The left navigation sidebar in Material for MkDocs was redesigned from scratch to replicate the clean, intuitive collapsible tree paradigm made famous by [Kubernetes.io](https://kubernetes.io/docs/):

1. **Carets Positioned on the Left**: All expand/collapse toggle carets are anchored strictly to the **LEFT** of directory titles (`order: -1`), mirroring file explorer conventions (macOS Finder, VS Code, Kubernetes documentation).
2. **Crisp Filled Triangle Carets**:
   - Collapsed directories feature a solid rightward triangle: `▶`.
   - Expanded directories rotate 90 degrees smoothly into a downward triangle: `▼`.
   - Implemented via high-definition SVG vector masks (`mask-image`), ensuring zero pixelation on Retina and 4K displays.
3. **Sub-Pixel Caret Alignment**:
   - Regardless of whether an item is an *index section with a clickable landing page* or a *pure container folder*, every caret on the same nesting level shares the exact same horizontal coordinate.
4. **Removal of Non-Functional Section Carets**:
   - In tabbed navigation mode, top-level section headers are permanently open domain containers. Spurious arrows that previously appeared next to section headers and did nothing when clicked were completely eliminated.
5. **No Harsh Vertical Lines**:
   - Full-height, continuous vertical border lines (`border-left`) were removed in favor of clean whitespace hierarchy (`padding-left: 0.85rem`), producing an unencumbered tree that is effortless to scan.

---

### 1.3 Adaptive 3-Column Layout & Distraction-Free Focus Mode (Option A)

To balance high-density technical specifications with reading ergonomics across all screen sizes, the portal incorporates the **Option A Architecture**:

1. **Calibrated Container Geometry (`76rem` / ~1520px)**: Replaces cramped default widths (`61rem`) and overextended ultra-wide widths (`84rem`+) with a calibrated `76rem` boundary. This geometry provides generous horizontal space for wide Kubernetes manifests, multi-column comparison tables, and terminal diagnostics while capping prose line lengths for comfortable scanning.
2. **Laptop Responsive Auto-Collapse (`960px`–`1279px`)**: On viewports between `960px` (`60em`) and `1279px` (`79.9375em`), the secondary table of contents (`.md-sidebar--secondary`) automatically hides via CSS media queries, allocating 100% of available horizontal center track space to technical prose and code blocks without side-scrolling.
3. **Distraction-Free Focus Mode**: Instant viewport immersion triggered via a dedicated header toggle button (`.nx-focus-btn`) or keyboard shortcuts (`Z` to toggle, `Escape` to exit). Session state persists across instant page navigation through `sessionStorage`, while specialized CSS layout rules collapse both sidebars and center the entire reading canvas at `76rem` with a single unified left rail, guaranteeing that headings, prose, tables, and terminal blocks share an identical horizontal start position.

---

## Section 2: Non-Technical Explanation (What Broke & How It Was Fixed)

Browser layout mechanics can appear counter-intuitive when inspected without structural context. Below is an architectural breakdown of the root causes and solutions explained through three straightforward analogies.

---

### 2.1 Analogy 1: The "Accordion with Stretchy Buttons" (Caret Drift)

#### What Was Happening
Imagine an accordion where each button row plays a song. But instead of the buttons being fastened into metal slots, the buttons are attached to stretchy rubber bands. When a song has a short name (like "Go"), the button sits near the left. But when a song has a long name (like "Continuous Delivery & GitOps Pipelines"), the long name stretches the rubber band and shoves the button sideways!

#### Why It Happened in MkDocs
When an MkDocs section has an index page (e.g. `docs/containers/index.md`), Material for MkDocs wraps the row in a container box (`.md-nav__container`). Inside that container box, there are two items:
1. The `<label>` toggle button (the clickable arrow).
2. The `<a>` link (the title of the page).

Both of these items were sharing CSS rules. The browser treated the arrow button like regular text, letting it stretch, shrink, and slide depending on the length of the words next to it. On some rows, the arrow sat at 24 pixels from the left edge; on other rows, it sat at 38 pixels. The arrows drifted into an uneven zigzag alignment down the screen.

#### How It Was Fixed
Assign the arrow toggle button a rigid, unbendable metal frame using CSS:
```css
flex: 0 0 1.15rem !important;
width: 1.15rem !important;
min-width: 1.15rem !important;
max-width: 1.15rem !important;
margin: 0 !important;
padding: 0 !important;
```
Now, whether a directory title has 2 letters or 50 letters, the toggle arrow is locked into an exact `1.15rem` square slot. Every single arrow down the entire sidebar lines up on the exact same vertical ruler down to the millimeter.

---

### 2.2 Analogy 2: The "Dangling Switch" (Non-Functional Section Arrow)

#### What Was Happening
Imagine walking into a room and seeing a light switch on the wall. Flicking the switch produces no result—the switch is completely unwired. The fixture appears functional, yet connects to no underlying circuit.

#### Why It Happened in MkDocs
In default Material for MkDocs templates, the renderer generates an expand/collapse arrow for *every single item that has sub-folders*. But when `navigation.tabs` is enabled in `mkdocs.yml`, the top-level section headers in the sidebar are **always open** by design. They do not collapse.

Because the template blindly generated an arrow for everything, the top section title (like "CONTAINERS & ORCHESTRATION") showed an arrow. When users clicked that arrow, **nothing happened**. It violated user trust and felt broken.

#### How It Was Fixed
Add a conditional guard to the master template (`docs/overrides/partials/nav-item.html`):
```jinja2
{% if nav_item.children | length > 1 and not is_section %}
  <label class="md-nav__link md-nav__link--toggle ...">
    <span class="md-nav__icon md-icon"></span>
  </label>
{% endif %}
```
Notice the phrase `and not is_section`. This instructs the template: *"If this row is a top-level section header, DO NOT print an arrow switch."* Switches only appear on folders that actually open and close.

---

### 2.3 Analogy 3: The "Stray Pencil Line" (Harsh Vertical Border)

#### What Was Happening
Imagine writing a neat, indented outline in a notebook. Now imagine a dark pencil drawing a harsh, 400-pixel vertical line down the left side of the page, cutting right through the text. It fails to connect cleanly to bullet points, extends past section boundaries, and makes the entire page look crowded and claustrophobic.

#### Why It Happened in MkDocs
Default documentation themes often add a `border-left: 1px solid gray` to every sub-list. When documentation trees get 3 or 4 levels deep, these border lines overlap, stack, or stretch continuously down the entire height of the sidebar, creating an ugly "jailhouse bars" appearance.

#### How It Was Fixed
Strip out artificial borders and adopt the **Kubernetes.io documentation standard**:
```css
.md-nav--primary .md-nav__list .md-nav__list {
  padding-left: 0.85rem !important;
  margin-left: 0 !important;
  border-left: none !important;
}
```
The layout relies on clean, generous whitespace indentation (`0.85rem`). The visual hierarchy remains immediately clear, keeping the sidebar light, modern, and uncluttered.

---

## Section 3: The 3 Core Files Modified (The "Trio")

Every single feature, layout enhancement, and sidebar behavior in this architecture is driven by exactly **three files**:

```
repo-root/
├── mkdocs.yml                            # 1. Feature flags, tabs, typography & theme
└── docs/
    ├── overrides/
    │   └── partials/
    │       └── nav-item.html             # 2. Jinja2 template override (left carets & section guards)
    └── stylesheets/
        └── extra.css                     # 3. Design system tokens, caret alignment & Obsidian theme
```

---

### 3.1 File 1: `mkdocs.yml` (Configuration & Feature Flags)

`mkdocs.yml` is the master site configuration. It defines active features, visual themes, and navigation plugins.

#### Critical Invariants & Rules

1. **`custom_dir: docs/overrides`**:
   - **MUST BE SET** under `theme`. This tells MkDocs to look in `docs/overrides/` for custom Jinja2 template files before falling back to default theme files.
2. **`navigation.tabs` & `navigation.indexes`**:
   - **MUST BE ENABLED**.
   - `navigation.tabs` groups documentation into top-level horizontal tabs.
   - `navigation.indexes` links directory landing pages (`index.md`) directly to section titles.
3. **`navigation.sections`**:
   - **MUST NOT BE ENABLED**.
   - *Why:* Enabling `navigation.sections` converts nested directories into flat, non-collapsible section headers, destroying the collapsible tree architecture.
4. **`navigation.prune`**:
   - **MUST NOT BE ENABLED**.
   - *Why:* Enabling `navigation.prune` strips non-active directory branches out of the HTML when building the site. When a user clicks an arrow to expand a collapsed folder, nothing happens because the HTML for that branch does not exist in the browser.
5. **Fonts**:
   - Configured with `Inter` for prose and `JetBrains Mono` for code blocks.

#### Copy-Pasteable Configuration Snippet (`mkdocs.yml`)

```yaml
theme:
  name: material
  language: en
  custom_dir: docs/overrides
  font:
    text: Inter
    code: JetBrains Mono
  features:
    - navigation.instant
    - navigation.instant.progress
    - navigation.tabs
    - navigation.tabs.sticky
    - navigation.path
    - navigation.indexes
    - navigation.top
    - toc.follow
    - search.suggest
    - search.highlight
    - content.code.copy
    - content.tabs.link
    - content.tooltips
    # CRITICAL: DO NOT enable navigation.sections (breaks collapsible tree)
    # CRITICAL: DO NOT enable navigation.prune (breaks instant client-side expansion)
  palette:
    - media: "(prefers-color-scheme: light)"
      scheme: default
      primary: custom
      accent: custom
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - media: "(prefers-color-scheme: dark)"
      scheme: slate
      primary: custom
      accent: custom
      toggle:
        icon: material/brightness-4
        name: Switch to light mode

extra_css:
  - docs/stylesheets/extra.css
```

---

### 3.2 File 2: `docs/overrides/partials/nav-item.html` (Jinja2 Template Override)

This file overrides the upstream Material for MkDocs navigation item renderer. It is responsible for generating the HTML markup for every single link, folder, and arrow in the sidebar.

#### What Makes This File Special
1. **Section Header Guard (`not is_section`)**:
   - Lines 108 & 116 ensure that top-level domain sections do not render useless toggle arrows.
2. **Left Caret Positioning**:
   - The toggle button `<label>` and caret icon `<span class="md-nav__icon md-icon"></span>` are placed before the link title, giving the CSS complete control to position carets cleanly on the left.
3. **Single-Child Folder Handling**:
   - If a folder only contains an index file (`children | length <= 1`), it renders as a direct link without an unnecessary caret.

#### Complete, Copy-Pasteable Code (`docs/overrides/partials/nav-item.html`)

```html
{#-
  Custom Navigation Item Template for MkDocs Material
  Enables Kubernetes.io-style left carets and eliminates non-functional section header toggles.
-#}
{% macro render_status(nav_item, type) %}
  {% set class = "md-status md-status--" ~ type %}
  {% if config.extra.status and config.extra.status[type] %}
    <span class="{{ class }}" title="{{ config.extra.status[type] }}">
    </span>
  {% else %}
    <span class="{{ class }}"></span>
  {% endif %}
{% endmacro %}
{% macro render_title(nav_item) %}
  {% if nav_item.typeset %}
    <span class="md-typeset">
      {{ nav_item.typeset.title }}
    </span>
  {% else %}
    {{ nav_item.title }}
  {% endif %}
{% endmacro %}
{% macro render_content(nav_item, ref) %}
  {% set ref = ref or nav_item %}
  {% if nav_item.meta and nav_item.meta.icon %}
    {% include ".icons/" ~ nav_item.meta.icon ~ ".svg" %}
  {% endif %}
  <span class="md-ellipsis">
    {{ render_title(ref) }}
    {% if nav_item.meta and nav_item.meta.subtitle %}
      <br>
      <small>{{ nav_item.meta.subtitle }}</small>
    {% endif %}
  </span>
  {% if nav_item.meta and nav_item.encrypted %}
    {{ render_status(nav_item, "encrypted") }}
  {% endif %}
  {% if nav_item.meta and nav_item.meta.status %}
    {{ render_status(nav_item, nav_item.meta.status) }}
  {% endif %}
{% endmacro %}
{% macro render_pruned(nav_item, ref) %}
  {% set ref = ref or nav_item %}
  {% set first = nav_item.children | first %}
  {% if first and first.children %}
    {{ render_pruned(first, ref) }}
  {% else %}
    <a href="{{ first.url | url }}" class="md-nav__link">
      {% if nav_item.children | length > 0 %}
        <span class="md-nav__icon md-icon"></span>
      {% endif %}
      {{ render_content(ref) }}
    </a>
  {% endif %}
{% endmacro %}
{% macro render(nav_item, path, level, parent) %}
  {% set class = "md-nav__item" %}
  {% if nav_item.active %}
    {% set class = class ~ " md-nav__item--active" %}
  {% endif %}
  {% if nav_item.pages %}
    {% if page in nav_item.pages %}
      {% set nav_item = page %}
    {% endif %}
  {% endif %}
  {% if nav_item.children %}
    {% set _ = namespace(index = none) %}
    {% if "navigation.indexes" in features %}
      {% for item in nav_item.children %}
        {% if item.is_index and _.index is none %}
          {% set _.index = item %}
        {% endif %}
      {% endfor %}
    {% endif %}
    {% set index = _.index %}
    {% if "navigation.tabs" in features %}
      {% if level == 1 and nav_item.active %}
        {% set class = class ~ " md-nav__item--section" %}
        {% set is_section = true %}
      {% endif %}
      {% if "navigation.sections" in features %}
        {% if level == 2 and parent.active %}
          {% set class = class ~ " md-nav__item--section" %}
          {% set is_section = true %}
        {% endif %}
      {% endif %}
    {% elif "navigation.sections" in features %}
      {% if level == 1 %}
        {% set class = class ~ " md-nav__item--section" %}
        {% set is_section = true %}
      {% endif %}
    {% endif %}
    {% if "navigation.prune" in features %}
      {% if not is_section and not nav_item.active %}
        {% set class = class ~ " md-nav__item--pruned" %}
        {% set is_pruned = true %}
      {% endif %}
    {% endif %}
    <li class="{{ class }} md-nav__item--nested">
      {% if not is_pruned %}
        {% set checked = "checked" if nav_item.active %}
        {% if "navigation.expand" in features and not checked %}
          {% set indeterminate = "md-toggle--indeterminate" %}
        {% endif %}
        <input class="md-nav__toggle md-toggle {{ indeterminate }}" type="checkbox" id="{{ path }}" {{ checked }}>
        {% if not index %}
          {% set tabindex = "0" if not is_section else "-1" %}
          <label class="md-nav__link" for="{{ path }}" id="{{ path }}_label" tabindex="{{ tabindex }}">
            {% if not is_section %}
              <span class="md-nav__icon md-icon"></span>
            {% endif %}
            {{ render_content(nav_item) }}
          </label>
        {% else %}
          {% set class = "md-nav__link--active" if index == page %}
          <div class="md-nav__link md-nav__container">
            {% if nav_item.children | length > 1 and not is_section %}
              {% set tabindex = "0" %}
              <label class="md-nav__link md-nav__link--toggle {{ class }}" for="{{ path }}" id="{{ path }}_label" tabindex="{{ tabindex }}">
                <span class="md-nav__icon md-icon"></span>
              </label>
            {% endif %}
            <a href="{{ index.url | url }}" class="md-nav__link {{ class }}">
              {{ render_content(index, nav_item) }}
            </a>
          </div>
        {% endif %}
        <nav class="md-nav" data-md-level="{{ level }}" aria-labelledby="{{ path }}_label" aria-expanded="{{ nav_item.active | tojson }}">
          <label class="md-nav__title" for="{{ path }}">
            <span class="md-nav__icon md-icon"></span>
            {{ render_title(nav_item) }}
          </label>
          <ul class="md-nav__list" data-md-scrollfix>
            {% for item in nav_item.children %}
              {% if not index or item != index %}
                {{ render(item, path ~ "_" ~ loop.index, level + 1, nav_item) }}
              {% endif %}
            {% endfor %}
          </ul>
        </nav>
      {% else %}
        {{ render_pruned(nav_item) }}
      {% endif %}
    </li>
  {% elif nav_item == page %}
    <li class="{{ class }}">
      <a href="{{ nav_item.url | url }}" class="md-nav__link md-nav__link--active">
        {{ render_content(nav_item) }}
      </a>
    </li>
  {% else %}
    <li class="{{ class }}">
      <a href="{{ nav_item.url | url }}" class="md-nav__link">
        {{ render_content(nav_item) }}
      </a>
    </li>
  {% endif %}
{% endmacro %}
```

---

### 3.3 File 3: `docs/stylesheets/extra.css` (Design Tokens & CSS Layout Rules)

`extra.css` defines the visual rules of the portal. It handles color variables, typography imports, caret icon masks, flexbox locking, and hover animations.

#### The 4 Critical Architectural Rules in this CSS

1. **Locking the Toggle Width (`1.15rem`)**:
   Inside `.md-nav__container`, the toggle `<label>` is locked with `flex: 0 0 1.15rem !important; width: 1.15rem !important; margin: 0 !important; padding: 0 !important;`. This completely eliminates caret drift.
2. **Direct Label Scoping**:
   For items *without* index pages, styling is strictly scoped to `.md-nav--primary .md-nav__item > label.md-nav__link` so it never accidentally overrides container-wrapped items.
3. **SVG Filled Triangle Mask**:
   Instead of relying on fragile web-font chevrons, carets use an inline SVG mask (`mask-image: url("data:image/svg+xml,...")`). The arrow points right `▶` by default and rotates `90deg` down `▼` when the checkbox is checked.
4. **Clean Whitespace Indentation**:
   Sub-navigation lists use `padding-left: 0.85rem !important; border-left: none !important;`, replicating the clean Kubernetes.io look.

#### Copy-Pasteable CSS Snippets (`docs/stylesheets/extra.css`)

```css
/* ==========================================================================
   1. TYPOGRAPHY & DESIGN SYSTEM COLOR TOKENS
   ========================================================================== */

@import url('https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,300..700;1,14..32,300..700&family=JetBrains+Mono:ital,wght@0,400..600;1,400..600&display=swap');

:root {
  --nx-font-sans: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --nx-font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  --nx-radius-sm: 6px;
  --nx-radius-md: 8px;
  --nx-radius-lg: 12px;
  --nx-radius-xl: 16px;
  --nx-radius-pill: 9999px;
  --nx-content-max: 76rem; /* Option A: ~1520px at 20px rem scale */
}

/* Light Mode: Frosted Clean White */
[data-md-color-scheme="default"] {
  --md-primary-fg-color:          #2563eb;
  --md-primary-fg-color--light:   #3b82f6;
  --md-primary-fg-color--dark:    #1d4ed8;
  --md-primary-bg-color:          #ffffff;
  --md-primary-bg-color--light:   #f8fafc;
  --md-accent-fg-color:           #2563eb;
  --md-typeset-a-color:           #2563eb;

  --md-default-bg-color:          #fafafa;
  --md-default-bg-color--light:   #ffffff;
  --md-default-bg-color--lighter: #f4f4f5;
  --md-default-fg-color:          #09090b;
  --md-default-fg-color--light:   #52525b;
  --md-default-fg-color--lighter: #71717a;
  --md-default-fg-color--lightest:#e4e4e7;

  --nx-header-bg:                 rgba(255, 255, 255, 0.88);
  --nx-header-border:             #e4e4e7;
  --nx-header-fg:                 #09090b;
  --nx-card-bg:                   #ffffff;
  --nx-card-border:               #e4e4e7;
  --nx-card-border-hover:         #cbd5e1;
  --nx-accent-soft:               rgba(37, 99, 235, 0.06);
  --nx-accent-soft-2:             rgba(37, 99, 235, 0.12);
  --nx-accent-ring:               rgba(37, 99, 235, 0.20);
}

/* Dark Mode: True Obsidian Black */
[data-md-color-scheme="slate"] {
  --md-primary-fg-color:          #3b82f6;
  --md-primary-fg-color--light:   #60a5fa;
  --md-primary-fg-color--dark:    #2563eb;
  --md-primary-bg-color:          #09090b;
  --md-primary-bg-color--light:   #121215;
  --md-accent-fg-color:           #60a5fa;
  --md-typeset-a-color:           #60a5fa;

  --md-default-bg-color:          #09090b;
  --md-default-bg-color--light:   #121215;
  --md-default-bg-color--lighter: #18181b;
  --md-default-fg-color:          #f4f4f5;
  --md-default-fg-color--light:   #a1a1aa;
  --md-default-fg-color--lighter: #71717a;
  --md-default-fg-color--lightest:#27272a;

  --nx-header-bg:                 rgba(9, 9, 11, 0.85);
  --nx-header-border:             rgba(255, 255, 255, 0.08);
  --nx-header-fg:                 #f4f4f5;
  --nx-card-bg:                   #111114;
  --nx-card-border:               rgba(255, 255, 255, 0.08);
  --nx-card-border-hover:         rgba(255, 255, 255, 0.18);
  --nx-accent-soft:               rgba(59, 130, 246, 0.08);
  --nx-accent-soft-2:             rgba(59, 130, 246, 0.15);
  --nx-accent-ring:               rgba(59, 130, 246, 0.22);
}

html, body {
  font-family: var(--nx-font-sans);
  -webkit-font-smoothing: antialiased;
}

/* ==========================================================================
   2. KUBERNETES.IO-STYLE LEFT SIDEBAR TREE NAVIGATION
   ========================================================================== */

/* Base Link Styling */
.md-nav--primary .md-nav__link {
  display: flex !important;
  align-items: center !important;
  font-family: var(--nx-font-sans);
  font-size: 0.82rem;
  font-weight: 450;
  border-radius: 4px;
  padding: 0.35rem 0.6rem !important;
  color: var(--md-default-fg-color--light);
  transition: background-color 0.15s ease, color 0.15s ease;
}

/* Hover States */
[data-md-color-scheme="slate"] .md-nav--primary .md-nav__link:hover:not(.md-nav__container > .md-nav__link),
[data-md-color-scheme="slate"] .md-nav--primary .md-nav__container:hover {
  background-color: rgba(255, 255, 255, 0.04) !important;
  color: var(--md-default-fg-color) !important;
  border-radius: 4px !important;
}

[data-md-color-scheme="default"] .md-nav--primary .md-nav__link:hover:not(.md-nav__container > .md-nav__link),
[data-md-color-scheme="default"] .md-nav--primary .md-nav__container:hover {
  background-color: rgba(0, 0, 0, 0.03) !important;
  color: var(--md-default-fg-color) !important;
  border-radius: 4px !important;
}

/* Primary Active Item */
[data-md-color-scheme="slate"] .md-nav--primary .md-nav__link--active {
  color: #38bdf8 !important;
  font-weight: 600 !important;
}
[data-md-color-scheme="default"] .md-nav--primary .md-nav__link--active {
  color: #2563eb !important;
  font-weight: 600 !important;
}

/* Container for sections with index page (navigation.indexes) */
.md-nav--primary .md-nav__container {
  display: flex !important;
  align-items: center !important;
  padding: 0.35rem 0.6rem !important;
  margin: 0 !important;
  border-radius: 4px;
  transition: background-color 0.15s ease;
}

/* Caret Toggle Button inside Container: Locked Dimensions */
.md-nav--primary .md-nav__container > label.md-nav__link,
.md-nav--primary .md-nav__container > label.md-nav__link--toggle {
  order: -1 !important;
  flex: 0 0 1.15rem !important;
  width: 1.15rem !important;
  min-width: 1.15rem !important;
  max-width: 1.15rem !important;
  height: 1.15rem !important;
  margin: 0 !important;
  padding: 0 !important;
  background: transparent !important;
  cursor: pointer;
  display: inline-flex !important;
  align-items: center !important;
  justify-content: center !important;
}

/* Link Title inside Container: Spans Remaining Space with 0.45rem Gap */
.md-nav--primary .md-nav__container > a.md-nav__link {
  flex: 1 1 auto !important;
  min-width: 0 !important;
  padding: 0 !important;
  margin: 0 0 0 0.45rem !important;
  background: transparent !important;
  display: inline-flex !important;
  align-items: center !important;
}

/* Defensively hide in-page TOC toggle and nested TOC list in left primary navigation */
.md-nav--primary label[for="__toc"],
.md-nav--primary input[id="__toc"],
.md-nav--primary [for="__toc"] ~ .md-nav {
  display: none !important;
}

/* Direct Label for Sections Without an Index Page */
.md-nav--primary .md-nav__item--nested > label.md-nav__link,
.md-nav--primary .md-nav__item > label.md-nav__link:not([for="__toc"]) {
  padding: 0.35rem 0.6rem !important;
  display: flex !important;
  align-items: center !important;
  margin: 0 !important;
}

.md-nav--primary .md-nav__item--nested > label.md-nav__link .md-nav__icon,
.md-nav--primary .md-nav__item > label.md-nav__link:not([for="__toc"]) .md-nav__icon {
  margin: 0 0.45rem 0 0 !important;
}

/* Caret Icon Box: Anchored on LEFT */
.md-nav--primary .md-nav__link .md-nav__icon {
  order: -1 !important;
  margin-right: 0.45rem !important;
  margin-left: 0 !important;
  width: 1.15rem !important;
  height: 1.15rem !important;
  display: inline-flex !important;
  align-items: center !important;
  justify-content: center !important;
  flex-shrink: 0;
  border-radius: 4px;
  cursor: pointer;
  color: var(--md-default-fg-color--lighter);
  transition: color 0.15s ease, background-color 0.15s ease;
}

.md-nav--primary .md-nav__container > label.md-nav__link .md-nav__icon,
.md-nav--primary .md-nav__container > label.md-nav__link--toggle .md-nav__icon {
  margin: 0 !important;
  width: 1.15rem !important;
  height: 1.15rem !important;
}

/* Crisp Filled Triangle Caret (Collapsed: points right ▶) */
.md-nav--primary .md-nav__link .md-nav__icon:after {
  content: "" !important;
  display: block !important;
  width: 0.55rem !important;
  height: 0.55rem !important;
  background-color: currentColor !important;
  -webkit-mask-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath d='M8 5v14l11-7z' fill='%23000'/%3E%3C/svg%3E") !important;
  mask-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath d='M8 5v14l11-7z' fill='%23000'/%3E%3C/svg%3E") !important;
  -webkit-mask-repeat: no-repeat !important;
  mask-repeat: no-repeat !important;
  -webkit-mask-position: center !important;
  mask-position: center !important;
  -webkit-mask-size: contain !important;
  mask-size: contain !important;
  transform: rotate(0deg);
  transition: transform 0.15s cubic-bezier(0.4, 0, 0.2, 1) !important;
  transform-origin: center center !important;
}

/* Expanded State: Rotates 90deg to point down ▼ */
.md-nav__item--nested > .md-nav__toggle:checked ~ .md-nav__link .md-nav__icon:after,
.md-nav__item--nested > .md-toggle--indeterminate ~ .md-nav__link .md-nav__icon:after,
.md-nav__item--nested > .md-nav__toggle:checked ~ .md-nav__container .md-nav__icon:after,
.md-nav__item--nested > .md-toggle--indeterminate ~ .md-nav__container .md-nav__icon:after {
  transform: rotate(90deg) !important;
}

/* Indentation Hierarchy (Kubernetes.io Standard - No Vertical Lines) */
.md-nav--primary .md-nav__list .md-nav__list {
  padding-left: 0.85rem !important;
  margin-left: 0 !important;
  border-left: none !important;
}

/* Top-Level Section Header Styling */
.md-nav--primary .md-nav__item--section > .md-nav__link,
.md-nav--primary .md-nav__item--section > .md-nav__container > a.md-nav__link {
  font-family: var(--nx-font-sans);
  font-weight: 700;
  letter-spacing: -0.01em;
  color: var(--md-default-fg-color) !important;
  font-size: 0.88rem;
  padding: 0.5rem 0.6rem 0.35rem !important;
  margin: 0 !important;
}

/* ==========================================================================
   3. MACOS DEVELOPER TERMINAL (.nx-terminal) & HERO SHOWCASE
   ========================================================================== */

.nx-hero {
  position: relative;
  overflow: hidden;
  padding: 2.5rem 2rem;
  margin: 0.75rem 0 2.5rem;
  border-radius: var(--nx-radius-xl);
  border: 1px solid var(--nx-card-border);
  background: var(--nx-card-bg);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
}

.nx-hero__inner {
  display: grid;
  grid-template-columns: 1fr;
  gap: 2.25rem;
  align-items: center;
}

@media screen and (min-width: 1080px) {
  .nx-hero__inner {
    grid-template-columns: 1.08fr 0.92fr;
  }
}

.nx-terminal {
  border-radius: var(--nx-radius-lg);
  overflow: hidden;
  font-family: var(--nx-font-mono);
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.45);
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: #09090b;
}

.nx-terminal__header {
  display: flex;
  align-items: center;
  padding: 0.65rem 0.95rem;
  background: #111114;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.nx-terminal__controls {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  margin-right: 0.85rem;
}

.nx-terminal__dot {
  width: 11px;
  height: 11px;
  border-radius: 50%;
  display: inline-block;
}
.nx-terminal__dot--red    { background-color: #ff5f56; }
.nx-terminal__dot--yellow { background-color: #ffbd2e; }
.nx-terminal__dot--green  { background-color: #27c93f; }

.nx-terminal__tab {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.2rem 0.65rem;
  border-radius: 4px;
  background: #18181b;
  font-size: 0.73rem;
  color: #a1a1aa;
}

.nx-terminal__body {
  padding: 1.1rem 1.25rem;
  font-size: 0.8rem;
  line-height: 1.65;
  color: #f4f4f5;
}

.nx-terminal__row--cmd {
  display: flex;
  align-items: center;
  gap: 0.55rem;
  margin-bottom: 0.75rem;
}

.nx-terminal__prompt { color: #3b82f6; font-weight: 700; }
.nx-terminal__cmd    { color: #f4f4f5; font-weight: 600; }
.nx-terminal__check  { color: #10b981; font-weight: 700; margin-right: 0.4rem; }
.nx-terminal__label  { color: #71717a; margin-right: 0.35rem; }
.nx-terminal__val    { color: #e4e4e7; }
```

---

## Section 4: Modern Adaptive 3-Column Layout & Focus Mode Architecture (Option A)

Modern enterprise documentation portals present two competing layout demands:
1. **Technical Asset Density**: High-density engineering assets—such as multi-tier Kubernetes manifests, complex command pipelines, architectural diagrams, and multi-column comparison tables—require wide horizontal space to prevent awkward line wrapping and unnecessary horizontal scrollbars.
2. **Reading Ergonomics**: Prose narrative, operational instructions, and conceptual documentation require disciplined line lengths (65–85 characters per line) to maintain typographic legibility and minimize cognitive fatigue.

The Option A architecture solves this balance through calibrated container geometry, automatic secondary sidebar collapse on mid-range laptop displays, and an instant distraction-free focus mode with content-widening capabilities.

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                OPTION A: 3 ADAPTIVE VIEW MODES                                  │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 1. DESKTOP VIEW (>= 1280px / 80em): Full 3-Column Canvas                                        │
│ ┌───────────────────────┬─────────────────────────────────────────────┬───────────────────────┐ │
│ │ PRIMARY SIDEBAR       │ MAIN CONTENT AREA (51.8rem / ~1036px)       │ SECONDARY TOC         │ │
│ │ Tree Navigation       │ Prose, Code Manifests, Tables, Hero         │ In-Page Headings      │ │
│ │ (12.1rem / 242px)     │ (Max Container: 76rem / ~1520px)            │ (12.1rem / 242px)     │ │
│ └───────────────────────┴─────────────────────────────────────────────┴───────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 2. LAPTOP VIEW (960px - 1279px / 60em - 79.9375em): Auto-Collapsed Secondary TOC               │
│ ┌───────────────────────┬─────────────────────────────────────────────────────────────────────┐ │
│ │ PRIMARY SIDEBAR       │ EXPANDED CONTENT TRACK (100% Remaining Width)                       │ │
│ │ Tree Navigation       │ Full horizontal space allocated to technical prose and code blocks  │ │
│ │ (12.1rem / 242px)     │ Secondary TOC hidden automatically; zero horizontal scroll clipping  │ │
│ └───────────────────────┴─────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 3. DISTRACTION-FREE FOCUS MODE (body.nx-focus-mode): Full Immersion (`Z` toggle, `Esc` exit)    │
│ ┌─────────────────────────────────────────────────────────────────────────────────────────────┐ │
│ │                       PROSE TRACK CENTERED (54rem / ~1080px)                                │ │
│ │         Technical prose restricted to optimal reading width for high legibility             │ │
│ │ ┌─────────────────────────────────────────────────────────────────────────────────────────┐ │ │
│ │ │                 TECHNICAL ASSETS EXPANDED (72rem / ~1440px)                             │ │ │
│ │ │                 Code Blocks, Tables, Terminal Windows, Admonitions                      │ │ │
│ │ └─────────────────────────────────────────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 4.1 Container Max-Width & Horizontal Geometry (`--nx-content-max: 76rem`)

Material for MkDocs computes layout dimensions using a base root scaling factor where `1rem = 20px` at standard desktop display scales.

#### Dimension Comparison
- **Default Material Theme (`61rem` / ~1220px)**: Constricts the center content column when both primary and secondary sidebars are rendered (`~36.8rem` / ~736px). Wide configuration files, JSON specifications, and deep comparison tables suffer from aggressive wrapping and horizontal scrollbars.
- **Overextended Widths (`84rem`+ / >1680px)**: Produces unergonomic prose lines exceeding 120 characters per line on high-resolution desktop monitors, causing ocular drift and reading fatigue.
- **Option A Geometry (`--nx-content-max: 76rem` / ~1520px)**:
  - Total grid width: `76rem` (`~1520px`).
  - Primary navigation sidebar: `12.1rem` (`242px`).
  - Secondary table of contents sidebar: `12.1rem` (`242px`).
  - Net available content column: `51.8rem` (`~1036px`).
  - Balances generous horizontal space for 100-character code lines with comfortable typographic scan lines.

#### CSS Token Definition (`docs/stylesheets/extra.css`)
```css
:root {
  --nx-content-max: 76rem; /* Option A: ~1520px at 20px rem scale */
}

.md-grid {
  max-width: var(--nx-content-max);
  margin-left: auto;
  margin-right: auto;
  padding-left: 1.25rem !important;
  padding-right: 1.25rem !important;
}
```

---

### 4.2 Laptop Responsive Auto-Collapse (`960px` to `1279px`)

Standard 13-inch and 14-inch laptops operate at display viewport widths between `960px` (`60em`) and `1279px` (`79.9375em`). Under default Material for MkDocs configurations, this breakpoint renders both sidebars simultaneously, compressing the center column into a narrow slot between `476px` and `795px`.

Option A eliminates this layout compression by introducing an automated media query override that targets this viewport band.

#### The Auto-Collapse Mechanism
1. **Target Viewport Range**: `min-width: 60em` (960px) through `max-width: 79.9375em` (1279px).
2. **Action**: The secondary table of contents (`.md-sidebar--secondary`) is hidden via `display: none !important`.
3. **Space Reallocation**: 100% of the freed horizontal track is reallocated to `.md-content`.
4. **Result**: The primary navigation tree remains immediately available on the left, while the main content and code blocks gain `12.1rem` (242px) of uninterrupted horizontal space.

#### CSS Implementation Snippet (`docs/stylesheets/extra.css`)
```css
/* ==========================================================================
   OPTION A: LAPTOP RESPONSIVE AUTO-COLLAPSE (960px - 1279px)
   Hides secondary TOC on mid-range viewports to maximize code/manifest space.
   ========================================================================== */

@media screen and (min-width: 60em) and (max-width: 79.9375em) {
  /* Suppress secondary table of contents sidebar */
  .md-sidebar--secondary {
    display: none !important;
  }

  /* Expand content area to consume entire remaining horizontal track */
  .md-content {
    max-width: 100% !important;
  }

  .md-content__inner {
    margin-right: 0 !important;
  }
}
```

---

### 4.3 Distraction-Free Focus Mode Implementation

Distraction-Free Focus Mode enables complete visual immersion during deep technical tasks, code reviews, and incident troubleshooting by stripping away navigation chrome.

Focus Mode comprises four core architectural components:
1. Header Toggle Button (`.nx-focus-btn`)
2. Keyboard Interaction Controller (`Z` / `Escape`)
3. Session Persistence via `sessionStorage`
4. Dual-Track Responsive CSS Sizing (`54rem` prose / `72rem` assets)

#### 4.3.1 Header Toggle Control (`.nx-focus-btn`) & Keyboard Shortcuts

A dedicated focus toggle button is integrated into the header action bar.

- **DOM Representation**:
  ```html
  <button class="md-header__button md-icon nx-focus-btn" 
          title="Toggle Focus Mode (Press Z)" 
          aria-label="Toggle Focus Mode" 
          data-nx-focus-btn>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
      <path d="M5 5h5v2H7v3H5V5m9 0h5v5h-2V7h-3V5m3 9h2v5h-5v-2h3v-3m-9 3v2H5v-5h2v3h3Z"/>
    </svg>
  </button>
  ```

- **Keyboard Interaction Controller**:
  - **Press `Z` (or `z`)**: Toggles Focus Mode on or off.
  - **Press `Escape`**: Exits Focus Mode immediately when active.
  - **Input Shielding**: Keystrokes are ignored when the active target is an `<input>`, `<textarea>`, `<select>`, `[contenteditable]`, or search dialog to prevent conflict with text input.

#### 4.3.2 Session Persistence Engine (`sessionStorage`)

To ensure continuity across multi-page reference browsing, Focus Mode state is preserved across navigation events within the active browsing session.

- **Storage Key**: `nx-focus-mode`.
- **Allowed States**: `'enabled'` | `'disabled'`.
- **Storage Scope**: `sessionStorage` (isolated to the browser tab; automatically clears on tab close).
- **Instant Navigation Lifecycle**: Re-evaluates state on Material for MkDocs instant-loading events via `document$.subscribe()`.

#### JavaScript Implementation Snippet (`docs/javascripts/extra.js`)
```javascript
/* ==========================================================================
   OPTION A: FOCUS MODE INTERACTION & PERSISTENCE ENGINE
   Handles toggle button, Z / Escape keybindings, and sessionStorage sync.
   ========================================================================== */

(function () {
  var FOCUS_KEY = "nx-focus-mode";
  var FOCUS_CLASS = "nx-focus-mode";

  function setFocusMode(enabled) {
    if (enabled) {
      document.body.classList.add(FOCUS_CLASS);
      try { sessionStorage.setItem(FOCUS_KEY, "enabled"); } catch (e) {}
    } else {
      document.body.classList.remove(FOCUS_CLASS);
      try { sessionStorage.setItem(FOCUS_KEY, "disabled"); } catch (e) {}
    }
    updateFocusButtons(enabled);
  }

  function toggleFocusMode() {
    var isCurrentlyFocused = document.body.classList.contains(FOCUS_CLASS);
    setFocusMode(!isCurrentlyFocused);
  }

  function updateFocusButtons(enabled) {
    var buttons = document.querySelectorAll(".nx-focus-btn");
    buttons.forEach(function (btn) {
      btn.setAttribute("aria-pressed", enabled ? "true" : "false");
      btn.classList.toggle("nx-focus-btn--active", enabled);
    });
  }

  function initFocusMode() {
    // Restore persistent session state
    var savedState = null;
    try { savedState = sessionStorage.getItem(FOCUS_KEY); } catch (e) {}
    if (savedState === "enabled") {
      document.body.classList.add(FOCUS_CLASS);
      updateFocusButtons(true);
    } else {
      updateFocusButtons(false);
    }

    // Attach click listeners to all focus toggle buttons in DOM
    var buttons = document.querySelectorAll(".nx-focus-btn");
    buttons.forEach(function (btn) {
      if (!btn.dataset.focusBound) {
        btn.dataset.focusBound = "true";
        btn.addEventListener("click", function (e) {
          e.preventDefault();
          toggleFocusMode();
        });
      }
    });
  }

  // Global Keyboard Navigation Controller
  window.addEventListener("keydown", function (e) {
    // Ignore keystrokes when active element is an input, textarea, or content-editable
    var target = e.target;
    var tagName = target.tagName;
    if (
      tagName === "INPUT" ||
      tagName === "TEXTAREA" ||
      tagName === "SELECT" ||
      target.isContentEditable ||
      target.closest(".md-search__input")
    ) {
      return;
    }

    // Key 'Z' toggles focus mode
    if ((e.key === "z" || e.key === "Z") && !e.ctrlKey && !e.altKey && !e.metaKey) {
      e.preventDefault();
      toggleFocusMode();
    }

    // Key 'Escape' exits focus mode
    if (e.key === "Escape" && document.body.classList.contains(FOCUS_CLASS)) {
      e.preventDefault();
      setFocusMode(false);
    }
  });

  // Lifecycle registration: standard DOM ready + MkDocs instant navigation
  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(initFocusMode);
  } else {
    document.addEventListener("DOMContentLoaded", initFocusMode);
  }
})();
```

#### 4.3.3 Adaptive Focus Mode CSS Rules (`body.nx-focus-mode`)

When `body.nx-focus-mode` is activated, the layout transforms into an uncluttered technical canvas:
1. **Sidebar Elimination**: Primary navigation (`.md-sidebar--primary`) and secondary table of contents (`.md-sidebar--secondary`) are hidden completely.
2. **Prose Centering at `54rem` (~1080px)**: Text reading line length is locked to `54rem` and centered horizontally, maintaining strict ergonomic scan bounds.
3. **Asset Expansion to `72rem` (~1440px)**: Code blocks (`.highlight`, `.highlighttable`), terminal windows (`.nx-terminal`), data tables (`.md-typeset__table`), and admonitions project outward beyond the prose boundary to `72rem`, granting technical assets maximum clarity without disturbing prose ergonomics.

#### CSS Layout Rules Snippet (`docs/stylesheets/extra.css`)
```css
/* ==========================================================================
   OPTION A: FOCUS MODE LAYOUT RULES (body.nx-focus-mode)
   ========================================================================== */

/* 1. Focus Mode Header Button */
.nx-focus-btn {
  width: 2rem;
  height: 2rem;
  border-radius: var(--nx-radius-sm);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  border: none;
  background: transparent;
  color: var(--nx-header-fg-dim);
  transition: all 0.2s ease;
  margin-right: 0.5rem;
  padding: 0;
  flex-shrink: 0;
}

.nx-focus-btn:hover {
  color: var(--nx-header-fg);
  background: rgba(0, 0, 0, 0.05);
}

[data-md-color-scheme="slate"] .nx-focus-btn:hover {
  background: rgba(255, 255, 255, 0.08);
}

body.nx-focus-mode .nx-focus-btn {
  color: var(--md-primary-fg-color);
  background: var(--nx-accent-soft-2);
}

.nx-focus-btn svg {
  width: 1.15rem;
  height: 1.15rem;
  fill: currentColor;
}

/* 2. Hide Primary & Secondary Sidebars */
body.nx-focus-mode .md-sidebar--primary,
body.nx-focus-mode .md-sidebar--secondary {
  display: none !important;
}

/* 3. Expand Content Track to 100% Container */
body.nx-focus-mode .md-main__inner {
  display: flex !important;
  justify-content: center !important;
  max-width: 100% !important;
  margin-left: auto !important;
  margin-right: auto !important;
}

body.nx-focus-mode .md-content {
  max-width: 100% !important;
  width: 100% !important;
  margin-left: auto !important;
  margin-right: auto !important;
}

/* 4. Single Centered Reading Canvas (76rem): All elements share the exact same left rail */
body.nx-focus-mode .md-content__inner {
  max-width: 76rem !important;
  width: 100% !important;
  margin-left: auto !important;
  margin-right: auto !important;
  padding-left: 1.5rem !important;
  padding-right: 1.5rem !important;
}

/* 5. Unified Left Rail Alignment: Headings, text, code, tables, and terminals share identical start position */
.nx-focus-mode .md-typeset > p,
.nx-focus-mode .md-typeset > ul,
.nx-focus-mode .md-typeset > ol,
.nx-focus-mode .md-typeset > blockquote,
.nx-focus-mode .md-typeset > h1,
.nx-focus-mode .md-typeset > h2,
.nx-focus-mode .md-typeset > h3,
.nx-focus-mode .md-typeset > h4,
.nx-focus-mode .highlight,
.nx-focus-mode .md-typeset__scrollwrap,
.nx-focus-mode .md-typeset__table,
.nx-focus-mode .mermaid,
.nx-focus-mode .admonition,
.nx-focus-mode .tabbed-set {
  margin-left: 0 !important;
  margin-right: 0 !important;
  width: 100% !important;
  max-width: 100% !important;
}
```

---

## Section 5: Header & Navigation Tabs Vertical Geometry / Navbar Uplift Architecture

The navigation header represents the primary navigational plane across all documentation views. In default Material for MkDocs deployments with `navigation.tabs` enabled, excessive default spacing introduces an unergonomic vertical gap between the top header row and the horizontal tab bar. The **Navbar Uplift Architecture** eliminates this dead space, creating a cohesive, high-density header unit.

```
DEFAULT MATERIAL FOR MKDOCS (~34px Void):
┌────────────────────────────────────────────────────────────────────────┐
│ [Logo] Nectar                                   [Search] [Theme] [Repo]│  Header Row (48px)
├────────────────────────────────────────────────────────────────────────┤
│ ▲                                                                      │
│ │   34px Vertical Void (.md-tabs__link margin-top: 0.8rem; height: 2.4rem)
│ ▼                                                                      │
│   [Tab 1]   [Tab 2]   [Tab 3]   [Tab 4]   [Tab 5]                      │  Tabs Row (48px)
└────────────────────────────────────────────────────────────────────────┘

UPLIFT ARCHITECTURE (~9px Sleek Gap):
┌────────────────────────────────────────────────────────────────────────┐
│ [Logo] Nectar                                   [Search] [Theme] [Repo]│  Header Row (48px)
├────────────────────────────────────────────────────────────────────────┤
│ 9px Calibrated Gap (.md-tabs__link margin-top: 0; padding: 0.25rem 0.55rem)
│ [Tab 1]   [Tab 2]   [Tab 3]   [Tab 4]   [Tab 5]                        │  Tabs Row (39px)
│ ━━━━━━━ (Active Indicator ::after @ bottom: 0)                         │
└────────────────────────────────────────────────────────────────────────┘
```

### 5.1 Root Cause: Material for MkDocs Default Spacing Void

The standard Material for MkDocs stylesheet imposes generous spacing variables designed for sparse single-page documentation rather than high-density developer portals:

1. **Top Margin on Tab Anchors**: Default `.md-tabs__link` rules inject `margin-top: 0.8rem` (16px at base scaling).
2. **Elevated Item Height**: Default `.md-tabs__item` rules declare `height: 2.4rem` (48px).
3. **Compound Vertical Padding**: The enclosing `.md-tabs` wrapper and internal list structures compound this offset with supplementary vertical padding.

**The Cumulative Result**: A vertical void measuring approximately `34px` separates the bottom border of the primary header from the baseline text of the navigation tabs. This void disconnects the navigation controls visually, forces unnecessary downward eye traversal, and consumes critical vertical viewport height above the fold.

---

### 5.2 The Fix & Blueprint: Geometric Calibration

The Navbar Uplift Architecture compresses the vertical gap from `~34px` down to `~9px` through synchronized CSS overrides:

| Element Selector | Default Material Property | Uplift Override Property | Architectural Function |
| :--- | :--- | :--- | :--- |
| `.md-tabs` | `padding: 0;` (unconstrained) | `padding: 0.15rem 0 !important;` | Constrains top and bottom outer perimeter margins of the tab bar. |
| `.md-tabs__item` | `height: 2.4rem;` (48px) | `height: 1.95rem !important;` | Compacts item container height to 39px while centering content flexbox. |
| `.md-tabs__link` | `margin-top: 0.8rem;`<br>`padding: ...` | `margin-top: 0 !important;`<br>`padding: 0.25rem 0.55rem !important;` | Eliminates the 16px top offset completely and applies precise click padding. |
| `.md-tabs__indicator` | Default animated bar | `display: none !important;` | Suppresses upstream JS-calculated bar prone to horizontal lag and jitter. |
| `.md-tabs__item--active::after` | N/A | `height: 2px; bottom: 0 !important;` | Renders a hardware-accelerated active bottom bar locked to tab text width. |

#### Geometry Breakdown:
1. **Zero-Margin Baseline Alignment**: Setting `.md-tabs__link { margin-top: 0 !important; }` removes the artificial drop-down offset, pulling tab titles directly into alignment with the header boundary.
2. **Compact Vertical Envelope (`1.95rem` / ~39px)**: Reducing container item height to `1.95rem` provides sufficient vertical target room for cursor interactions while reclaiming ~9px of vertical document space.
3. **Integrated Active Underline**: Upstream Material calculates an indicator element (`.md-tabs__indicator`) via JavaScript transforms. By suppressing this element (`display: none !important;`) and attaching a CSS pseudo-element (`::after`) directly to `.md-tabs__item--active`, the active underline anchors firmly to `bottom: 0 !important` with inset margins (`left: 0.55rem; right: 0.55rem;`), matching tab link padding with pixel perfection.
4. **Horizontal Tab Preservation Across 10 Top-Level Domains**: Compact link padding (`0.25rem 0.55rem`) combined with `gap: 2px` and `font-size: 13.5px` guarantees all 10 domain tabs remain comfortably visible on laptop and desktop viewports without horizontal scrolling or wrapping.

---

### 5.3 Production CSS Implementation

Insert the following stylesheet block into `docs/stylesheets/extra.css` to implement the complete vertical geometry uplift:

```css
/* ==========================================================================
   HEADER & NAVIGATION TABS VERTICAL GEOMETRY / NAVBAR UPLIFT
   Compacts default ~34px spacing void down to ~9px for high-density portals.
   ========================================================================== */

/* 1. Header and Tab Grid Alignment */
.md-header .md-grid,
.md-tabs .md-grid {
  max-width: 100% !important;
  padding-left: 1.5rem !important;
  padding-right: 1.5rem !important;
}

@media screen and (max-width: 76.1875em) {
  .md-header .md-grid,
  .md-tabs .md-grid {
    padding-left: 1rem !important;
    padding-right: 1rem !important;
  }
}

/* 2. Compact Tab Bar Container */
.md-tabs {
  background-color: var(--nx-header-bg) !important;
  border-bottom: 1px solid var(--nx-header-border) !important;
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  padding: 0.15rem 0 !important;
}

@media screen and (min-width: 60em) {
  .md-tabs {
    display: block !important;
  }
}

/* 3. Horizontal Tab Flex List */
.md-tabs__list {
  display: flex !important;
  flex-wrap: nowrap !important;
  overflow-x: auto !important;
  overflow-y: hidden !important;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: none !important;
  gap: 2px !important;
  padding: 0 !important;
  margin: 0 !important;
  align-items: center !important;
}

.md-tabs__list::-webkit-scrollbar {
  display: none !important;
}

/* 4. Tab Item Geometry Override (Compacted to 1.95rem / ~39px) */
.md-tabs__item {
  padding: 0 !important;
  margin: 0 !important;
  flex-shrink: 0 !important;
  position: relative;
  height: 1.95rem !important;
  display: flex !important;
  align-items: center !important;
}

/* 5. Tab Link Geometry (Eliminates 0.8rem margin-top; compacts to 9px gap) */
.md-tabs__link {
  color: var(--nx-header-fg-dim) !important;
  font-family: var(--nx-font-sans) !important;
  font-size: 13.5px !important;
  font-weight: 500 !important;
  opacity: 0.85 !important;
  margin-top: 0 !important;
  padding: 0.25rem 0.55rem !important;
  border-radius: var(--nx-radius-sm);
  white-space: nowrap !important;
  display: inline-flex !important;
  align-items: center;
  line-height: 1.25 !important;
  letter-spacing: -0.01em !important;
  transition: color 0.15s ease, background-color 0.15s ease, opacity 0.15s ease !important;
}

.md-tabs__link:hover {
  color: var(--nx-header-fg) !important;
  opacity: 1 !important;
  background-color: var(--nx-accent-soft);
}

/* 6. Suppress Upstream JS Indicator */
.md-tabs__indicator {
  display: none !important;
}

/* 7. Active Tab Anchor and Underline Indicator */
.md-tabs__item--active {
  position: relative;
}

.md-tabs__item--active .md-tabs__link {
  color: var(--nx-header-fg) !important;
  font-weight: 600 !important;
  opacity: 1 !important;
}

.md-tabs__item--active::after {
  content: '';
  position: absolute;
  left: 0.55rem;
  right: 0.55rem;
  bottom: 0 !important;
  height: 2px;
  background: var(--md-primary-fg-color);
  border-radius: 1px;
}
```

---

## Section 6: Step-by-Step Migration Guide for Other MkDocs Repositories

Follow these 5 steps to apply this exact layout, navigation system, and Option A architecture to any other Material for MkDocs website.

```
MIGRATION FLOW:
┌────────────────────┐     ┌────────────────────────────┐     ┌────────────────────────┐     ┌────────────────────────┐     ┌─────────────────────┐
│  STEP 1: CONFIG    │ ──> │  STEP 2: JINJA OVERRIDE    │ ──> │  STEP 3: CSS INJECTION │ ──> │  STEP 4: JS INJECTION  │ ──> │  STEP 5: VERIFY     │
│  Update mkdocs.yml │     │  Create nav-item.html      │     │  Append to extra.css   │     │  Append to extra.js    │     │  Build & Inspect    │
└────────────────────┘     └────────────────────────────┘     └────────────────────────┘     └────────────────────────┘     └─────────────────────┘
```

---

### Step 1: Check and Update `mkdocs.yml`

1. Open `mkdocs.yml` in the target repository.
2. Under the `theme` key, ensure `custom_dir: docs/overrides` is defined.
3. Verify feature flags:
   - **Ensure enabled**: `navigation.tabs`, `navigation.indexes`.
   - **Ensure disabled (remove if present)**: `navigation.sections`, `navigation.prune`.
4. Ensure `docs/stylesheets/extra.css` is registered under `extra_css`.
5. Ensure `docs/javascripts/extra.js` is registered under `extra_javascript`.

```yaml
theme:
  name: material
  custom_dir: docs/overrides
  font:
    text: Inter
    code: JetBrains Mono
  features:
    - navigation.tabs
    - navigation.indexes
    # REMOVE: - navigation.sections
    # REMOVE: - navigation.prune

extra_css:
  - docs/stylesheets/extra.css

extra_javascript:
  - docs/javascripts/extra.js
```

---

### Step 2: Create the Template Override Directory and File

1. In the repository root, create the directory path:
   ```bash
   mkdir -p docs/overrides/partials
   ```
2. Create the file `docs/overrides/partials/nav-item.html`.
3. Copy and paste the entire 173-line template provided in [Section 3.2](#32-file-2-docsoverridespartialsnav-itemhtml-jinja2-template-override) into this file.

---

### Step 3: Integrate Styles into `extra.css`

1. Open or create `docs/stylesheets/extra.css`.
2. Copy the design tokens and navigation CSS rules provided in [Section 3.3](#33-file-3-docsstylesheetsextracss-design-tokens--css-layout-rules) and append them to `extra.css`.
3. Copy the Option A layout rules and Focus Mode styles provided in [Section 4.1](#41-container-max-width--horizontal-geometry---nx-content-max-76rem), [Section 4.2](#42-laptop-responsive-auto-collapse-960px-to-1279px), and [Section 4.3.3](#433-adaptive-focus-mode-css-rules-bodynx-focus-mode) along with the Header & Navigation Tabs vertical geometry styles in [Section 5.3](#53-production-css-implementation), and append them to `extra.css`.
4. If custom color variables already exist, retain them or adopt the Obsidian Black (`#09090b`) tokens provided for an instant dark mode upgrade.

---

### Step 4: Register Interactive Focus Engine in `extra.js`

1. Open or create `docs/javascripts/extra.js`.
2. Copy and paste the Focus Mode controller provided in [Section 4.3.2](#432-session-persistence-engine-sessionstorage) into this file.
3. Ensure the script is registered in `mkdocs.yml` under `extra_javascript`.

---

### Step 5: Build, Inspect, and Verify

Run the MkDocs build command to verify that there are no syntax errors or template conflicts:

```bash
# Build the site
mkdocs build --strict

# Or serve locally for live visual QA
mkdocs serve
```

#### Visual QA Checklist

- [ ] **Left Carets**: Verify that expand/collapse carets appear strictly on the **left** of folder names.
- [ ] **Sub-Pixel Alignment**: Inspect folders with index pages vs. folders without index pages. Verify their arrows share the exact same horizontal alignment.
- [ ] **Section Headers**: Verify that top-level domain headings in the left sidebar do **not** have non-functional arrow toggles.
- [ ] **No Vertical Jailhouse Bars**: Verify that nested sub-items are indented with clean whitespace (`0.85rem`) and have no harsh vertical border lines.
- [ ] **Smooth Rotation**: Click a caret and confirm it rotates 90 degrees smoothly (`▶` to `▼`).
- [ ] **Option A Container Max-Width**: Verify that the content grid is capped at `76rem` (~1520px) preventing runaway line lengths on ultra-wide screens.
- [ ] **Laptop Responsive Auto-Collapse**: Resize the viewport between `960px` and `1279px`. Verify the secondary table of contents sidebar hides automatically and content consumes 100% of the remaining horizontal space.
- [ ] **Header & Navigation Tabs Vertical Geometry**: Verify that the vertical gap between the top header row and navigation tabs is compacted to ~9px (`.md-tabs__link` has `margin-top: 0 !important; padding: 0.25rem 0.55rem !important;` and `.md-tabs__item` has `height: 1.95rem !important;`), the active tab underline indicator sits flush at `bottom: 0`, and all 10 domain tabs fit without clipping on desktop viewports.
- [ ] **Focus Mode Toggle & Keybindings**: Press `Z` or click `.nx-focus-btn`. Verify sidebars disappear, content centers on a unified `76rem` canvas, and headings, text, tables, and terminals strictly share an identical left alignment rail. Press `Escape` or `Z` again to verify clean restoration.
- [ ] **Session Persistence**: While in Focus Mode, navigate between pages. Verify that Focus Mode remains active across instant-loading page transitions via `sessionStorage`.
- [ ] **Responsive Stacking**: Resize the browser window to mobile width (`< 768px`) and tablet width (`768px - 1024px`) to ensure the navigation drawer opens and functions seamlessly.

---

## Section 7: Ready-to-Use LLM Prompt Template

When deploying this blueprint to another repository, copy and paste the prompt below directly into **ChatGPT**, **Claude**, or **Gemini**:

***

```markdown
I have an MkDocs repository using the Material for MkDocs theme. I want to upgrade the site to match the Kubernetes.io-style collapsible tree navigation, modern Obsidian Dark / Frosted Light UI standards, and the Option A adaptive layout architecture.

Please inspect this repository and apply the following architectural changes:

1. In `mkdocs.yml`:
   - Set `theme.custom_dir: docs/overrides`.
   - Set `theme.font.text: Inter` and `theme.font.code: JetBrains Mono`.
   - In `theme.features`, ensure `navigation.tabs` and `navigation.indexes` are present.
   - Crucially, ensure `navigation.sections` and `navigation.prune` are REMOVED (they break collapsible trees and client-side branch expansion).
   - Ensure `docs/stylesheets/extra.css` is included under `extra_css`.
   - Ensure `docs/javascripts/extra.js` is included under `extra_javascript`.

2. In `docs/overrides/partials/nav-item.html`:
   - Create this file (and parent directories if missing).
   - Implement the Jinja2 navigation item macro override that:
     a) Places the toggle caret on the LEFT of directory titles.
     b) Guards section headers with `and not is_section` so static domain titles never display non-functional toggle arrows.
     c) Wraps index-bearing items in `.md-nav__container` with a dedicated toggle `<label>`.

3. In `docs/stylesheets/extra.css`:
   - Add the design tokens for True Obsidian Black (`#09090b` canvas in dark mode) and Frosted Light (`#fafafa` canvas in light mode).
   - Configure Option A container max-width: `--nx-content-max: 76rem;`.
   - Add Header & Navbar Uplift geometry rules:
     Override `.md-tabs__link` with `margin-top: 0 !important;` and `padding: 0.25rem 0.55rem !important;`, set `.md-tabs__item` to `height: 1.95rem !important;`, suppress `.md-tabs__indicator`, and position active indicator `.md-tabs__item--active::after` at `bottom: 0; left: 0.55rem; right: 0.55rem;`.
   - Add the Kubernetes.io sidebar CSS rules:
     a) Lock the toggle label width inside `.md-nav__container` to `flex: 0 0 1.15rem !important; width: 1.15rem !important; margin: 0 !important; padding: 0 !important;`.
     b) Scope direct item labels to `.md-nav--primary .md-nav__item > label.md-nav__link`.
     c) Set the link text to `flex: 1 1 auto !important; margin: 0 0 0 0.45rem !important;`.
     d) Implement crisp SVG filled triangle carets (rightward ▶ rotating 90deg to downward ▼) via `-webkit-mask-image` / `mask-image`.
     e) Remove vertical list borders (`border-left: none !important;`) and apply clean whitespace indentation (`padding-left: 0.85rem !important;`).
   - Add Option A responsive auto-collapse rules:
     Between `60em` (960px) and `79.9375em` (1279px), hide `.md-sidebar--secondary` and expand `.md-content` to 100%.
   - Add Option A Focus Mode rules:
     When `body.nx-focus-mode` is active, hide primary and secondary sidebars, center prose at `54rem`, and expand code blocks/tables to `72rem`.

4. In `docs/javascripts/extra.js`:
   - Implement the Focus Mode controller supporting `.nx-focus-btn`, `Z` key to toggle, `Escape` key to exit, input element shielding, and session persistence via `sessionStorage`.
   - Integrate with Material for MkDocs instant-navigation lifecycle via `document$.subscribe()`.

5. Verification:
   - Run `mkdocs build` to confirm an exit code of 0.
   - Verify that all directory carets on the same level share identical horizontal coordinates and that section headers have no arrows.
   - Verify that the navigation tabs vertical gap is compacted from ~34px to ~9px and active tab indicator remains flush.
   - Test laptop auto-collapse between 960px and 1279px.
   - Test Focus Mode via `Z` shortcut, `Escape` shortcut, and session persistence across page transitions.

Please review the repository and implement these changes step by step.
```

***

## Summary Reference Table

| Target Area | File | Key Invariant / Mechanism | Purpose |
| :--- | :--- | :--- | :--- |
| **Theme & Features** | `mkdocs.yml` | `custom_dir: docs/overrides`<br>`navigation.tabs: enabled`<br>`navigation.indexes: enabled` | Directs MkDocs to custom Jinja templates and establishes domain tabs + index page bindings. |
| **Collapsible Invariants** | `mkdocs.yml` | **DO NOT USE** `navigation.sections`<br>**DO NOT USE** `navigation.prune` | Prevents flattening nested trees into static text and preserves all branches in DOM for instant click unfolding. |
| **Navbar Uplift Architecture** | `docs/stylesheets/extra.css` | `.md-tabs__link { margin-top: 0 !important; padding: 0.25rem 0.55rem !important; }`<br>`.md-tabs__item { height: 1.95rem !important; }` | Compacts the ~34px default vertical spacing void down to ~9px while preserving active indicator and 10-tab desktop visibility. |
| **Left Caret Ordering** | `docs/overrides/partials/nav-item.html` | `<label class="...--toggle">` rendered before link title; CSS `order: -1` | Anchors the expand/collapse trigger to the left of the title link matching VS Code / Kubernetes.io. |
| **Section Header Guard** | `docs/overrides/partials/nav-item.html` | `{% if ... and not is_section %}` | Eliminates dangling, non-functional arrow switches next to permanent top-level domain headers. |
| **Sub-Pixel Caret Alignment** | `docs/stylesheets/extra.css` | `.md-nav__container > label { flex: 0 0 1.15rem !important; width: 1.15rem !important; }` | Locks toggle box dimensions into an exact rigid square, preventing text-length caret drift. |
| **Crisp Triangle Caret** | `docs/stylesheets/extra.css` | `mask-image: url("data:image/svg+xml,...")`<br>`transform: rotate(90deg)` | Vector-sharp filled triangle (`▶` rotating to `▼`) with zero font glyph misalignment. |
| **Clean Indentation** | `docs/stylesheets/extra.css` | `.md-nav__list .md-nav__list { padding-left: 0.85rem !important; border-left: none !important; }` | Clean whitespace hierarchy replacing cluttered, full-height vertical borders. |
| **Modern Developer UI** | `docs/stylesheets/extra.css` | Obsidian Black (`#09090b`), Inter, JetBrains Mono, `.nx-terminal` | Establishes a luxury developer portal aesthetic with authentic dark surfaces and terminal diagnostic components. |
| **Container Geometry (Option A)** | `docs/stylesheets/extra.css` | `--nx-content-max: 76rem;` (~1520px at 20px rem) | Balances generous horizontal space for manifests and code with ergonomic reading length. |
| **Laptop Auto-Collapse** | `docs/stylesheets/extra.css` | `@media (min-width: 60em) and (max-width: 79.9375em) { .md-sidebar--secondary { display: none !important; } }` | Automatically hides secondary TOC on mid-range viewports (960px–1279px), giving 100% remaining width to content. |
| **Focus Mode Controller** | `docs/javascripts/extra.js` | `.nx-focus-btn` + `Z` toggle / `Escape` exit | Provides keyboard and click controls for instant distraction-free documentation immersion. |
| **Session Persistence** | `docs/javascripts/extra.js` | `sessionStorage.getItem("nx-focus-mode")` | Preserves focus mode state across instant navigation events within the same browsing session. |
| **Focus Mode Unified Geometry** | `docs/stylesheets/extra.css` | `body.nx-focus-mode` centers container at `76rem` with single unified left rail | Guarantees headings, prose, tables, and terminal code blocks strictly share the exact same start position. |

---
*Created as part of the Nectar Architecture Reference Series. Maintained for cross-repository portability across all personal MkDocs documentation portals.*
