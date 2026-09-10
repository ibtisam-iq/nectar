---
hide:
  - toc
  - navigation
---

<section class="nx-hero">
  <div class="nx-hero__inner">
    <!-- Left Column: Copy, CTAs, Credibility -->
    <div class="nx-hero__left">
      <div class="nx-hero__badge">
        <span class="nx-hero__badge-pulse"></span>
        <span class="nx-hero__badge-text">✦ Living Engineering Knowledge Base</span>
      </div>
      <h1 class="nx-hero__title">Where I document how I <span class="nx-accent">reason about systems.</span></h1>
      <p class="nx-hero__tagline">
        Approaching every tool from its problem up, not its documentation down. 365+ production notes across Kubernetes, Cloud, GitOps, and Systems Architecture.
      </p>
      <div class="nx-hero__actions">
        <a href="containers-orchestration/" class="nx-btn nx-btn--primary">
          <span>Start Reading</span>
          <span class="nx-btn__arrow">→</span>
        </a>
        <a href="about/" class="nx-btn nx-btn--ghost">About Author</a>
        <a href="https://github.com/ibtisam-iq/nectar" target="_blank" rel="noopener" class="nx-btn nx-btn--ghost">GitHub ↗</a>
      </div>
      <div class="nx-hero__stats">
        <span class="nx-hero__stat"><span class="nx-hero__stat-icon">☸️</span> CKA &amp; CKAD Certified</span>
        <span class="nx-hero__stat-sep">•</span>
        <span class="nx-hero__stat"><span class="nx-hero__stat-icon">☁️</span> Multi-Cloud &amp; GitOps</span>
        <span class="nx-hero__stat-sep">•</span>
        <span class="nx-hero__stat"><span class="nx-hero__stat-icon">⚡</span> 10 Knowledge Domains</span>
      </div>
    </div>

    <!-- Right Column: macOS Developer Terminal Window -->
    <div class="nx-hero__right">
      <div class="nx-terminal">
        <div class="nx-terminal__header">
          <div class="nx-terminal__controls">
            <span class="nx-terminal__dot nx-terminal__dot--red"></span>
            <span class="nx-terminal__dot nx-terminal__dot--yellow"></span>
            <span class="nx-terminal__dot nx-terminal__dot--green"></span>
          </div>
          <div class="nx-terminal__tab">
            <span class="nx-terminal__tab-icon">⚡</span>
            <span class="nx-terminal__tab-title">nectar-diagnostics.sh</span>
            <span class="nx-terminal__tab-badge">live</span>
          </div>
          <div class="nx-terminal__meta">
            <span class="nx-terminal__pill">bash</span>
          </div>
        </div>
        <div class="nx-terminal__body">
          <div class="nx-terminal__row nx-terminal__row--cmd">
            <span class="nx-terminal__prompt">$</span>
            <span class="nx-terminal__cmd">nectar probe --target=infrastructure</span>
          </div>
          <div class="nx-terminal__row nx-terminal__row--out">
            <span class="nx-terminal__check">✓</span>
            <span class="nx-terminal__label">Cluster:</span>
            <span class="nx-terminal__val">Multi-cluster EKS <span class="nx-terminal__sep">•</span> Cilium CNI <span class="nx-terminal__sep">•</span> Istio</span>
          </div>
          <div class="nx-terminal__row nx-terminal__row--out">
            <span class="nx-terminal__check">✓</span>
            <span class="nx-terminal__label">Delivery:</span>
            <span class="nx-terminal__val">ArgoCD GitOps <span class="nx-terminal__sep">•</span> Automated Canary</span>
          </div>
          <div class="nx-terminal__row nx-terminal__row--out">
            <span class="nx-terminal__check">✓</span>
            <span class="nx-terminal__label">Telemetry:</span>
            <span class="nx-terminal__val">Prometheus <span class="nx-terminal__sep">•</span> Grafana <span class="nx-terminal__sep">•</span> OpenTelemetry</span>
          </div>
          <div class="nx-terminal__row nx-terminal__row--out">
            <span class="nx-terminal__check">✓</span>
            <span class="nx-terminal__label">Hardened:</span>
            <span class="nx-terminal__val">Rootless Pods <span class="nx-terminal__sep">•</span> Vault Secrets</span>
          </div>
          <div class="nx-terminal__row nx-terminal__row--status">
            <span class="nx-terminal__tag">[status]</span>
            <span class="nx-terminal__msg">All 10 engineering domains verified.</span>
            <span class="nx-terminal__cursor"></span>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<div class="nx-section">
  <div class="nx-section__eyebrow">Knowledge Domains</div>
  <h2 class="nx-section__title">Explore the system architecture &amp; runbooks.</h2>
  <p class="nx-section__lead">
    Over 365 notes organized by domain. Built from problem-first engineering encounters, production debugging, and verified implementations.
  </p>
</div>

<div class="nx-grid">
  <a href="containers-orchestration/" class="nx-card">
    <div class="nx-card__head">
      <span class="nx-card__icon">☸️</span>
      <span class="nx-card__badge">Core</span>
    </div>
    <div class="nx-card__title">Containers &amp; Orchestration</div>
    <p class="nx-card__desc">Kubernetes architecture, Helm packaging, Docker runtimes, CNI/CRI internals, and production workloads.</p>
  </a>

  <a href="cloud-infrastructure/" class="nx-card">
    <div class="nx-card__head">
      <span class="nx-card__icon">☁️</span>
      <span class="nx-card__badge">Cloud</span>
    </div>
    <div class="nx-card__title">Cloud &amp; Infrastructure</div>
    <p class="nx-card__desc">AWS architectures, Cloudflare network security, VPC topologies, IAM policies, and cloud cost control.</p>
  </a>

  <a href="delivery/" class="nx-card">
    <div class="nx-card__head">
      <span class="nx-card__icon">🚀</span>
      <span class="nx-card__badge">GitOps</span>
    </div>
    <div class="nx-card__title">CI/CD &amp; Delivery</div>
    <p class="nx-card__desc">ArgoCD GitOps synchronization, GitHub Actions pipelines, quality gates, artifact repositories, and promotion workflows.</p>
  </a>

  <a href="observability-security/" class="nx-card">
    <div class="nx-card__head">
      <span class="nx-card__icon">🛡️</span>
      <span class="nx-card__badge">Reliability</span>
    </div>
    <div class="nx-card__title">Observability &amp; Security</div>
    <p class="nx-card__desc">Prometheus telemetry, Grafana dashboards, Elastic logging, vulnerability scanning, and hardening practices.</p>
  </a>

  <a href="operations/" class="nx-card">
    <div class="nx-card__head">
      <span class="nx-card__icon">⚡</span>
      <span class="nx-card__badge">Ops</span>
    </div>
    <div class="nx-card__title">Operations &amp; Runbooks</div>
    <p class="nx-card__desc">Production incident playbooks, self-hosted CI runners, WireGuard mesh networks, and server configuration.</p>
  </a>

  <a href="about/" class="nx-card">
    <div class="nx-card__head">
      <span class="nx-card__icon">👤</span>
      <span class="nx-card__badge">Profile</span>
    </div>
    <div class="nx-card__title">About &amp; Ecosystem</div>
    <p class="nx-card__desc">Background, CKA/CKAD credentials, downstream projects (SilverStack), and personal engineering philosophy.</p>
  </a>
</div>

<div class="nx-section">
  <div class="nx-section__eyebrow">Philosophy</div>
  <h2 class="nx-section__title">A knowledge base, not a tutorial site.</h2>
  <p class="nx-section__lead">
    Nectar is a personal engineering knowledge base: 365 pages across Kubernetes, AWS, CI/CD,
    observability, and platform operations. It is not a blog, a course, or a reference manual.
    It is the raw layer where understanding is built first, before it surfaces as a runnable
    component, a write-up, or a deployed system.
  </p>
  <p class="nx-section__lead">
    The depth is uneven by design. Entries written mid-project are sharper than entries written
    during study. Both belong here. It expands with every new deployment, every new tool, every
    production encounter.
  </p>
</div>
