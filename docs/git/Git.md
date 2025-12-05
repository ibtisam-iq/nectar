# Git and GitHub: Essential Concepts and Commands

## **Distributed Version Control System (VCS)** 
Git is a distributed version control system designed to handle projects with speed and efficiency. The repository structure typically includes several branches, each serving a specific purpose:

- **Main (master)**: The stable and production-ready codebase.
- **Dev (development)**: Active development branches, e.g.:
  - `feature-1`
  - `feature-2`
- **QA (Quality Assurance)**: Used for testing and validation.
- **PPD (Pre-production)**: A staging environment before production.
- **DR (Disaster Recovery)**: A backup branch for critical recovery scenarios.

---

## **Pull Request (PR)**
A **Pull Request** is a request to merge changes from one branch (or fork) into another, typically into the `main` branch. It is a key collaboration feature that allows for:
- **Code Review**: Teams can review proposed changes, suggest improvements, and discuss implementation details.
- **Discussion**: PRs facilitate team discussions about new features or fixes before integration.

---

## **Git Fetch vs Git Pull**
Understanding the difference between `git fetch` and `git pull` is crucial for managing your repository effectively:
- **Fetch**: Updates only the `.git` directory with the latest references from the remote repository. It does not alter the working directory.
  - Example: `git fetch origin`
- **Pull**: Combines `git fetch` and `git merge`. It updates the `.git` directory and synchronizes the working directory with the latest code.
  - Example: `git pull origin <branch_name>`

---

## **Recovering Deleted Files in Git**

Git provides multiple ways to recover deleted files, depending on their state in the repository. Below are common scenarios and commands:

| **Scenario**                       | **Command**                                                                 |
|------------------------------------|-----------------------------------------------------------------------------|
| Recover a **deleted staged file**  | `git restore --staged <file>` + `git restore <file>`                        |
| Recover a **deleted committed file** | `git checkout <commit_hash> -- <file>`                                      |
| Recover a file from the **latest commit** | `git restore <file>`                                                        |
| Recover **all deleted files**      | `git restore .`                                                             |

---

### **Additional Notes:**
1. **Git Restore**:
   - `git restore` is used to restore files in the working directory.
   - It replaces older commands like `git checkout` for file restoration.
2. **Git Checkout**:
   - Though largely replaced by `git switch` and `git restore`, it remains useful for certain scenarios like switching branches or checking out specific files from commits.
3. Always verify the commit hash (`<commit_hash>`) using `git log` or `git reflog` to ensure you're restoring the correct version.

---

Feel free to expand further or suggest modifications for clarity! 🚀

