# Shared Libraries in Jenkins

Shared libraries in Jenkins are reusable code components that centralize common logic, making pipelines modular, maintainable, and consistent. They address key problems like:

- **Avoiding Code Duplication**: Centralizes repetitive logic across multiple pipelines.
- **Simplifying Maintenance**: Updates to shared libraries automatically propagate to dependent pipelines.
- **Improving Modularity**: Keeps Jenkinsfiles clean by abstracting complex or repetitive steps.
- **Enhancing Collaboration**: Allows teams to manage reusable logic separately.

---

## Directory Structure

Shared libraries have two main directories: `vars/` and `src/`.

### `vars/`
- Contains global Groovy scripts (`<file-name>.groovy`) that are **directly callable** in pipelines.
- **Use Case**: Simple, globally accessible functions.
- **Example**:
  ```groovy
  // vars/deployApp.groovy
  def call() {
      echo 'Deploying application...'
  }
  ```

### `src/`
- Contains reusable classes organized in a Java-like package structure (e.g., `src/org/example`).
- Requires explicit imports in pipeline scripts or `vars` functions.

- **Use Case**: Encapsulating complex logic in classes.
- **Example**:
  ```groovy
  // src/org/example/MyUtils.groovy
  package org.example

  class MyUtils {
      def performTask() {
          echo 'Performing task...'
      }
  }
  ```

#### Key Differences

| **Feature**              | **`vars/`**                     | **`src/`**                      |
|--------------------------|-----------------------------------|-----------------------------------|
| **Purpose**              | Global functions for pipelines   | Encapsulated reusable classes    |
| **Structure**            | Flat, one level of scripts       | Nested, Java-like package structure |
| **Complexity**           | Simpler functions                | Advanced object-oriented logic   |
| **Accessibility**        | Automatically available globally | Requires explicit imports        |

---

