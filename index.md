# Nectar — Engineering Knowledge Base

![Engineering Knowledge Base](https://img.shields.io/badge/Engineering_Knowledge_Base-blue)
![License](https://img.shields.io/badge/License-MIT-green)

This is where I build and verify my understanding in full detail.

It contains both:

- concepts I had to break down from first principles
- complete execution written while running real setups

Everything is documented in the form that helps me return, reconnect, and reason about a system again.

When an implementation becomes clear, trusted, and repeatable, its runnable form is promoted to **[SilverStack](https://github.com/ibtisam-iq/silver-stack)**.

When the practical path and decisions behind that implementation are distilled into a focused write-up, they appear in the **[Blog](https://blog.ibtisam-iq.com)**.

When multiple reproducible components come together as a complete running environment, the system view appears in **[Projects](https://projects.ibtisam-iq.com)**.

This space holds the depth behind both learning and execution.

---

## How Knowledge Flows

```mermaid
flowchart TD
    A(["❓ I don't understand something"])
    B["First-principles learning<br/>Deep mental model"]
    C(["🔧 I run it for real"])
    D["Full implementation<br/>Debugging & experiments"]
    E(["💡 It becomes clear & repeatable"])
    F["Reusable manifests<br/>Scripts & IaC"]
    G(["✍️ I explain the practical path"])
    H["Distilled, problem-oriented<br/>write-up"]
    I(["🏗️ Multiple components form a platform"])
    J["System view<br/>& architecture"]

    A --> B --> NECTAR[(📚 Nectar)]
    C --> D --> NECTAR
    NECTAR --> E --> F --> SILVER[("⚙️ SilverStack")]
    NECTAR --> G --> H --> BLOG[("📝 Blog")]
    NECTAR --> I --> J --> PROJECTS[("🏛️ Projects")]

    style NECTAR   fill:#1e3a5f,color:#fff,stroke:#4a9eff
    style SILVER   fill:#2d4a2d,color:#fff,stroke:#5aaa5a
    style BLOG     fill:#4a3000,color:#fff,stroke:#ffaa00
    style PROJECTS fill:#3a1a4a,color:#fff,stroke:#cc77ff
```

> 💡 **Nectar is the hub.** Everything I learn or run lives here first — before it becomes a reusable component, a blog post, or a project architecture.
