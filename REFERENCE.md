# MkDocs UI/UX & Kubernetes-Style Sidebar Navigation: Complete Reference & Migration Blueprint

> **Master Architecture & Cross-Repository Portability Guide**  
> *Target Audience:* Non-technical project owners, technical architects, and autonomous coding agents (ChatGPT, Claude, Gemini).  
> *Purpose:* A definitive, drop-in blueprint to upgrade any Material for MkDocs repository with an enterprise-grade Obsidian design system and Kubernetes.io-style collapsible tree navigation.

---

## Table of Contents

1. [Section 1: Overview & What Was Accomplished](#section-1-overview--what-was-accomplished)
   - [1.1 Modern Premium Developer Portal UI/UX](#11-modern-premium-developer-portal-uiux)
   - [1.2 Kubernetes.io-Style Sidebar Navigation](#12-kubernetesio-style-sidebar-navigation)
2. [Section 2: Non-Technical Explanation (What Broke & How It Was Fixed)](#section-2-non-technical-explanation-what-broke--how-it-was-fixed)
   - [2.1 Analogy 1: The "Accordion with Stretchy Buttons" (Caret Drift)](#21-analogy-1-the-accordion-with-stretchy-buttons-caret-drift)
   - [2.2 Analogy 2: The "Dangling Switch" (Non-Functional Section Arrow)](#22-analogy-2-the-dangling-switch-non-functional-section-arrow)
   - [2.3 Analogy 3: The "Stray Pencil Line" (Harsh Vertical Border)](#23-analogy-3-the-stray-pencil-line-harsh-vertical-border)
3. [Section 3: The 3 Core Files Modified (The "Trio")](#section-3-the-3-core-files-modified-the-trio)
   - [3.1 File 1: `mkdocs.yml` (Configuration & Feature Flags)](#31-file-1-mkdocsyml-configuration--feature-flags)
   - [3.2 File 2: `docs/overrides/partials/nav-item.html` (Jinja2 Template Override)](#32-file-2-docsoverridespartialsnav-itemhtml-jinja2-template-override)
   - [3.3 File 3: `docs/stylesheets/extra.css` (Design Tokens & CSS Layout Rules)](#33-file-3-docsstylesheetsextracss-design-tokens--css-layout-rules)
4. [Section 4: Step-by-Step Migration Guide for Other MkDocs Repositories](#section-4-step-by-step-migration-guide-for-other-mkdocs-repositories)
   - [Step 1: Check and Update `mkdocs.yml`](#step-1-check-and-update-mkdocsyml)
   - [Step 2: Create the Template Override Directory and File](#step-2-create-the-template-override-directory-and-file)
   - [Step 3: Integrate Styles into `extra.css`](#step-3-integrate-styles-into-extracss)
   - [Step 4: Build, Inspect, and Verify](#step-4-build-inspect-and-verify)
5. [Section 5: Ready-to-Use LLM Prompt Template](#section-5-ready-to-use-llm-prompt-template)

---

## Section 1: Overview & What Was Accomplished

The transformation of **Nectar** into a world-class engineering portal addressed two fundamental domains: visual presentation (**UI/UX Modernization**) and hierarchical exploration (**Kubernetes.io-Style Tree Navigation**).

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                NECTAR MODERN PORTAL                                    │
├────────────────────────────────────────────────────────────────────────────────────────┤
│  Top Navigation Bar: 10 First-Class Tabs (Stable, Zero-Wrap, Sticky Blur Header)      │
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

## Section 2: Non-Technical Explanation (What Broke & How It Was Fixed)

If you do not write code every day, browser styling can look like a mystery. Here is what was happening behind the scenes, explained through three simple everyday analogies.

---

### 2.1 Analogy 1: The "Accordion with Stretchy Buttons" (Caret Drift)

#### What Was Happening
Imagine an accordion where each button row plays a song. But instead of the buttons being fastened into metal slots, the buttons are attached to stretchy rubber bands. When a song has a short name (like "Go"), the button sits near the left. But when a song has a long name (like "Continuous Delivery & GitOps Pipelines"), the long name stretches the rubber band and shoves the button sideways!

#### Why It Happened in MkDocs
When an MkDocs section has an index page (e.g. `docs/containers/index.md`), Material for MkDocs wraps the row in a container box (`.md-nav__container`). Inside that container box, there are two items:
1. The `<label>` toggle button (the clickable arrow).
2. The `<a>` link (the title of the page).

Both of these items were sharing CSS rules. The browser treated the arrow button like regular text, letting it stretch, shrink, and slide depending on the length of the words next to it. On some rows, the arrow sat at 24 pixels from the left edge; on other rows, it sat at 38 pixels. The arrows were dancing in an uneven zigzag down your screen!

#### How It Was Fixed
We gave the arrow toggle button a rigid, unbendable metal frame using CSS:
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
Imagine walking into a hotel room and seeing a light switch on the wall. You flick the switch up and down, but no lights turn on or off—it turns out the switch isn't wired to anything at all. You walk away confused, wondering if the electrical system is broken.

#### Why It Happened in MkDocs
In default Material for MkDocs templates, the computer generates an expand/collapse arrow for *every single item that has sub-folders*. But when `navigation.tabs` is enabled in your configuration, the top-level section headers in the sidebar are **always open** by design. They do not collapse.

Because the template blindly generated an arrow for everything, the top section title (like "CONTAINERS & ORCHESTRATION") showed an arrow. When users clicked that arrow, **nothing happened**. It violated user trust and felt broken.

#### How It Was Fixed
We edited the master template (`docs/overrides/partials/nav-item.html`) to teach it common sense:
```jinja2
{% if nav_item.children | length > 1 and not is_section %}
  <label class="md-nav__link md-nav__link--toggle ...">
    <span class="md-nav__icon md-icon"></span>
  </label>
{% endif %}
```
Notice the phrase `and not is_section`. This tells the computer: *"If this row is a top-level section header, DO NOT print an arrow switch."* Now, switches only appear on folders that actually open and close!

---

### 2.3 Analogy 3: The "Stray Pencil Line" (Harsh Vertical Border)

#### What Was Happening
Imagine writing a neat, indented outline in a notebook. Now imagine someone took a dark black pencil and drew a harsh, 400-pixel vertical line down the left side of the page, cutting right through your notes. It doesn't connect cleanly to your bullet points, it doesn't stop when a section ends, and it makes the entire page look crowded and claustrophobic.

#### Why It Happened in MkDocs
Default documentation themes often add a `border-left: 1px solid gray` to every sub-list. When documentation trees get 3 or 4 levels deep, these border lines overlap, stack, or stretch continuously down the entire height of the sidebar, creating an ugly "jailhouse bars" appearance.

#### How It Was Fixed
We stripped out the artificial borders and adopted the **Kubernetes.io documentation standard**:
```css
.md-nav--primary .md-nav__list .md-nav__list {
  padding-left: 0.85rem !important;
  margin-left: 0 !important;
  border-left: none !important;
}
```
We rely on clean, generous whitespace indentation (`0.85rem`). The human eye instantly understands the hierarchy naturally, and the sidebar looks light, modern, and uncluttered.

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

`mkdocs.yml` is the master configuration for your site. It tells MkDocs which features to activate and which to turn off.

#### Critical Invariants & Rules

1. **`custom_dir: docs/overrides`**:
   - **MUST BE SET** under `theme`. This tells MkDocs to look in `docs/overrides/` for custom Jinja2 template files before falling back to default theme files.
2. **`navigation.tabs` & `navigation.indexes`**:
   - **MUST BE ENABLED**.
   - `navigation.tabs` groups your documentation into top-level horizontal tabs.
   - `navigation.indexes` links directory landing pages (`index.md`) directly to section titles.
3. **`navigation.sections`**:
   - **MUST NOT BE ENABLED**.
   - *Why:* If you enable `navigation.sections`, MkDocs converts nested directories into flat, non-collapsible section headers. This destroys the collapsible tree architecture!
4. **`navigation.prune`**:
   - **MUST NOT BE ENABLED**.
   - *Why:* If you enable `navigation.prune`, MkDocs strips non-active directory branches out of the HTML when building the site. When a user clicks an arrow to expand a collapsed folder, nothing happens because the HTML for that branch does not exist in the browser!
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
      {% set toc = page.toc %}
      <input class="md-nav__toggle md-toggle" type="checkbox" id="__toc">
      {% set first = toc | first %}
      {% if first and first.level == 1 %}
        {% set toc = first.children %}
      {% endif %}
      {% if toc %}
        <label class="md-nav__link md-nav__link--active" for="__toc">
          <span class="md-nav__icon md-icon"></span>
          {{ render_content(nav_item) }}
        </label>
      {% endif %}
      <a href="{{ nav_item.url | url }}" class="md-nav__link md-nav__link--active">
        {{ render_content(nav_item) }}
      </a>
      {% if toc %}
        {% include "partials/toc.html" %}
      {% endif %}
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
  --nx-content-max: 84rem;
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

/* Direct Label for Sections Without an Index Page */
.md-nav--primary .md-nav__item > label.md-nav__link {
  padding: 0.35rem 0.6rem !important;
  display: flex !important;
  align-items: center !important;
  margin: 0 !important;
}

.md-nav--primary .md-nav__item > label.md-nav__link .md-nav__icon {
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

## Section 4: Step-by-Step Migration Guide for Other MkDocs Repositories

Follow these 4 steps to apply this exact layout and navigation system to any other Material for MkDocs website.

```
MIGRATION FLOW:
┌────────────────────┐     ┌────────────────────────────┐     ┌────────────────────────┐     ┌─────────────────────┐
│  STEP 1: CONFIG    │ ──> │  STEP 2: JINJA OVERRIDE    │ ──> │  STEP 3: CSS INJECTION │ ──> │  STEP 4: VERIFY     │
│  Update mkdocs.yml │     │  Create nav-item.html      │     │  Append to extra.css   │     │  Build & Inspect    │
└────────────────────┘     └────────────────────────────┘     └────────────────────────┘     └─────────────────────┘
```

---

### Step 1: Check and Update `mkdocs.yml`

1. Open `mkdocs.yml` in your target repository.
2. Under the `theme` key, ensure `custom_dir: docs/overrides` is defined.
3. Verify feature flags:
   - **Ensure enabled**: `navigation.tabs`, `navigation.indexes`.
   - **Ensure disabled (remove if present)**: `navigation.sections`, `navigation.prune`.
4. Ensure `docs/stylesheets/extra.css` is registered under `extra_css`.

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
```

---

### Step 2: Create the Template Override Directory and File

1. In your repository root, create the folder path:
   ```bash
   mkdir -p docs/overrides/partials
   ```
2. Create the file `docs/overrides/partials/nav-item.html`.
3. Copy and paste the entire 173-line template provided in [Section 3.2](#32-file-2-docsoverridespartialsnav-itemhtml-jinja2-template-override) into this file.

---

### Step 3: Integrate Styles into `extra.css`

1. Open or create `docs/stylesheets/extra.css`.
2. Copy the CSS rules provided in [Section 3.3](#33-file-3-docsstylesheetsextracss-design-tokens--css-layout-rules) and append them to your `extra.css`.
3. If your site already has custom color variables, you can retain them or adopt the Obsidian Black (`#09090b`) tokens provided for an instant dark mode upgrade.

---

### Step 4: Build, Inspect, and Verify

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
- [ ] **Responsive Stacking**: Resize the browser window to mobile width (`< 768px`) and tablet width (`768px - 1024px`) to ensure the navigation drawer opens and functions seamlessly.

---

## Section 5: Ready-to-Use LLM Prompt Template

When starting work on another repository, you do not need to explain everything from scratch. Simply copy and paste the prompt below directly into **ChatGPT**, **Claude**, or **Gemini**:

***

```markdown
I have an MkDocs repository using the Material for MkDocs theme. I want to upgrade the site to match the Kubernetes.io-style collapsible tree navigation and modern Obsidian Dark / Frosted Light UI standards.

Please inspect this repository and apply the following architectural changes:

1. In `mkdocs.yml`:
   - Set `theme.custom_dir: docs/overrides`.
   - Set `theme.font.text: Inter` and `theme.font.code: JetBrains Mono`.
   - In `theme.features`, ensure `navigation.tabs` and `navigation.indexes` are present.
   - Crucially, ensure `navigation.sections` and `navigation.prune` are REMOVED (they break collapsible trees and client-side branch expansion).
   - Ensure `docs/stylesheets/extra.css` is included under `extra_css`.

2. In `docs/overrides/partials/nav-item.html`:
   - Create this file (and parent directories if missing).
   - Implement the Jinja2 navigation item macro override that:
     a) Places the toggle caret on the LEFT of directory titles.
     b) Guards section headers with `and not is_section` so static domain titles never display non-functional toggle arrows.
     c) Wraps index-bearing items in `.md-nav__container` with a dedicated toggle `<label>`.

3. In `docs/stylesheets/extra.css`:
   - Add the design tokens for True Obsidian Black (`#09090b` canvas in dark mode) and Frosted Light (`#fafafa` canvas in light mode).
   - Add the Kubernetes.io sidebar CSS rules:
     a) Lock the toggle label width inside `.md-nav__container` to `flex: 0 0 1.15rem !important; width: 1.15rem !important; margin: 0 !important; padding: 0 !important;`.
     b) Scope direct item labels to `.md-nav--primary .md-nav__item > label.md-nav__link`.
     c) Set the link text to `flex: 1 1 auto !important; margin: 0 0 0 0.45rem !important;`.
     d) Implement crisp SVG filled triangle carets (rightward ▶ rotating 90deg to downward ▼) via `-webkit-mask-image` / `mask-image`.
     e) Remove vertical list borders (`border-left: none !important;`) and apply clean whitespace indentation (`padding-left: 0.85rem !important;`).

4. Verification:
   - Run `mkdocs build` to confirm an exit code of 0.
   - Verify that all directory carets on the same level share identical horizontal coordinates and that section headers have no arrows.

Please review the repository and implement these changes step by step.
```

***

## Summary Reference Table

| Target Area | File | Key Invariant / Mechanism | Purpose |
| :--- | :--- | :--- | :--- |
| **Theme & Features** | `mkdocs.yml` | `custom_dir: docs/overrides`<br>`navigation.tabs: enabled`<br>`navigation.indexes: enabled` | Directs MkDocs to custom Jinja templates and establishes domain tabs + index page bindings. |
| **Collapsible Invariants** | `mkdocs.yml` | **DO NOT USE** `navigation.sections`<br>**DO NOT USE** `navigation.prune` | Prevents flattening nested trees into static text and preserves all branches in DOM for instant click unfolding. |
| **Left Caret Ordering** | `docs/overrides/partials/nav-item.html` | `<label class="...--toggle">` rendered before link title; CSS `order: -1` | Anchors the expand/collapse trigger to the left of the title link matching VS Code / Kubernetes.io. |
| **Section Header Guard** | `docs/overrides/partials/nav-item.html` | `{% if ... and not is_section %}` | Eliminates dangling, non-functional arrow switches next to permanent top-level domain headers. |
| **Sub-Pixel Caret Alignment** | `docs/stylesheets/extra.css` | `.md-nav__container > label { flex: 0 0 1.15rem !important; width: 1.15rem !important; }` | Locks toggle box dimensions into an exact rigid square, preventing text-length caret drift. |
| **Crisp Triangle Caret** | `docs/stylesheets/extra.css` | `mask-image: url("data:image/svg+xml,...")`<br>`transform: rotate(90deg)` | Vector-sharp filled triangle (`▶` rotating to `▼`) with zero font glyph misalignment. |
| **Clean Indentation** | `docs/stylesheets/extra.css` | `.md-nav__list .md-nav__list { padding-left: 0.85rem !important; border-left: none !important; }` | Clean whitespace hierarchy replacing cluttered, full-height vertical borders. |
| **Modern Developer UI** | `docs/stylesheets/extra.css` | Obsidian Black (`#09090b`), Inter, JetBrains Mono, `.nx-terminal` | Establishes a luxury developer portal aesthetic with authentic dark surfaces and terminal diagnostic components. |

---
*Created as part of the Nectar Architecture Reference Series. Maintained for cross-repository portability across all personal MkDocs documentation portals.*
