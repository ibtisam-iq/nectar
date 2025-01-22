## Static Application Security Testing (SAST)

Static Application Security Testing (SAST)
SAST is a methodology for analyzing source code to identify vulnerabilities, bugs, and security flaws early in the development cycle. SonarQube uses SAST to provide actionable insights without requiring the code to be executed, ensuring that developers can address issues before they reach production.

### Why is SAST Important?
- Detects vulnerabilities early in the development process.
- Reduces the cost of fixing issues.
- Improves overall security and code quality.

---

## Common Code Issues and Their Impact

### Types of Code Issues

| Type            | Definition                                                                 | Impact                                                                                 | Difference from Others                                                          |
|-----------------|---------------------------------------------------------------------------|---------------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| **Bugs**        | Errors in logic or implementation that cause incorrect behavior.          | Can lead to crashes, data corruption, or unexpected behavior.                        | Unique because they directly impact functionality.                             |
| **Vulnerabilities** | Security flaws exploitable by attackers.                                 | Can result in data breaches, unauthorized access, or system compromise.              | Related to bugs but specifically tied to security.                             |
| **Code Smells** | Maintainability issues that make code harder to understand or modify.     | Slows down development and increases technical debt.                                 | Does not cause immediate problems but impacts long-term productivity.          |
| **Duplications**| Repeated code fragments across the codebase.                              | Increases maintenance efforts and risks introducing bugs during changes.             | Closely tied to technical debt but focused on redundancy.                      |
| **Technical Debt** | Accumulated issues that require extra effort to fix or refactor.         | Slows down future development and increases costs.                                   | Encompasses all the above categories when not addressed.                       |

### Summary
Ignoring these issues can lead to degraded system performance, higher costs, and increased security risks. Addressing them ensures maintainable, secure, and efficient codebases.

#### Note

- `Code Quality Check` is performed based upon the above mentioned issue types in SonarQube.
- The more the number of these issues, the less code quality it exhibits.

---
