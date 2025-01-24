# Nexus and Docker: Artifact and Runtime Workflow

## Artifact: Definition and Key Differences

An **artifact** is a file or collection of files produced during a build process. These files are necessary for deploying, running, or distributing software. Examples include JAR files, WAR files, Docker images, and Python wheels.

### How Artifacts Differ from Other Files

| **File Type**    | **Definition**                                                                                     |
|------------------|---------------------------------------------------------------------------------------------------|
| **Artifact**     | Packaged, versioned files used for distribution or deployment.                                     |
| **Source Code**  | Human-readable code written by developers.                                                        |
| **Binary**       | Machine-readable compiled files (e.g., `.exe`, `.class`).                                         |
| **Library**      | Reusable code components packaged for integration into other projects.                            |
| **Package**      | Bundled files, including source code, binaries, and metadata for easy distribution (e.g., `.jar`). |

### Artifact Examples by Language

| **Language**      | **Artifact Types**          |
|-------------------|-----------------------------|
| **Java**          | `.jar`, `.war`, `.ear`      |
| **Python**        | `.whl`, `.tar.gz`           |
| **Node.js**       | `.tgz`                      |
| **.NET (C#)**     | `.dll`, `.nupkg`            |
| **C/C++**         | `.lib`, `.a`, `.so`, `.dll` |
| **Ruby**          | `.gem`                      |
| **Go**            | Compiled binaries           |

---

## Understanding Artifacts and Their Components

A **project** typically contains the following components:

1. **Source Code**: The human-readable instructions written by developers (e.g., Python, Java, JavaScript code).
2. **Dependencies**: External libraries or modules the project relies on, often defined in files like `pom.xml` (Maven), `requirements.txt` (Python), or `package.json` (Node.js).
3. **Libraries**: Pre-written code that provides functionality (e.g., `.jar`, `.dll` files).
4. **Packages**: Bundled versions of your application or its dependencies (e.g., `.whl`, `.nupkg`).
5. **Runtime**: The environment required to execute the program (e.g., JVM for Java, Python interpreter).

### Components Inside an Artifact File

An **artifact file** is typically created during the build process and usually contains:

| **Component**        | **Presence in Artifact File**                                                                 |
|-----------------------|-----------------------------------------------------------------------------------------------|
| **Source Code**       | Rarely included (except for interpreted languages like Python or JavaScript).                |
| **Dependencies**      | Partially included (e.g., fat JARs or referenced metadata for dependency managers).          |
| **Libraries**         | Partially included (depends on the build process and packaging settings).                    |
| **Packages**          | Always included (artifacts are inherently packaged versions of the application).             |
| **Runtime**           | Not included; the runtime environment must be available separately.                          |

### Components Handled by Docker

Docker addresses the **remaining components** to make the program fully functional:

| **Component**        | **Handled by Docker**                                                              |
|-----------------------|-----------------------------------------------------------------------------------|
| **Source Code**       | May include if not precompiled (e.g., interpreted languages like Python or Node.js). |
| **Dependencies**      | Installed during the image build process.                                         |
| **Libraries**         | Installed if missing or required externally.                                      |
| **Packages**          | Copies and uses the artifact as part of the image.                                |
| **Runtime**           | Always included (e.g., JVM, Python interpreter, or Node.js runtime).              |

### Example Breakdown for Java, Python, and Node.js

#### **Java (.jar)**
- **Artifact Contains**: Compiled source code, dependencies (if fat JAR), and packaged structure.
- **Docker Adds**: JVM runtime, OS-level dependencies, external libraries (if not included in the JAR).

#### **Python (.whl or .tar.gz)**
- **Artifact Contains**: Source code or compiled `.pyc` files, metadata for dependencies.
- **Docker Adds**: Python runtime, installs dependencies using `pip`.

#### **Node.js (.tgz)**
- **Artifact Contains**: Source code (JavaScript files), metadata (`package.json`) listing dependencies.
- **Docker Adds**: Node.js runtime, installs dependencies using `npm install`.

---

## Nexus and Docker in a CI/CD Pipeline

### Nexus Repository

- **What Goes into Nexus?**
  - **Build Artifacts**: Outputs of your build process, like `.jar`, `.war`, `.dll`, `.whl`, or other binaries.
  - **Dependencies**: Third-party libraries or packages downloaded during the build process.
  - **Custom Libraries**: Reusable libraries developed by your team.

- **Purpose**:
  - Acts as a centralized artifact repository.
  - Enables reusability and consistency of libraries/artifacts across environments.
  - Ensures traceability of artifacts in production.

### Docker

- **What Goes into Docker?**
  - **Runtime Environment**: Docker images bundle everything needed to run the program, including:
    - Base OS (e.g., `alpine`, `ubuntu`).
    - Application runtime (e.g., JVM for Java, Python interpreter).
    - Your **application** (build artifact from Nexus).
    - Any required dependencies.

- **Purpose**:
  - Provides a containerized environment for consistent application execution.
  - Ensures the application works the same way in all environments (development, staging, production).

### Combining Nexus and Docker

1. **Build Phase**:
   - Source code is compiled, and dependencies are resolved.
   - Build artifacts (e.g., `.jar`, `.war`, `.dll`) are created and pushed to **Nexus**.
2. **Docker Image Creation**:
   - A Dockerfile is created, which fetches the build artifact from **Nexus** and integrates it with the runtime environment.
   - The Docker image is built and contains:
     - Build artifact (from Nexus).
     - Runtime environment and dependencies.
3. **Deploy Phase**:
   - The Docker image is pushed to a Docker registry (like Docker Hub or Nexus if it’s configured for Docker).
   - The container is deployed to the target environment (e.g., Kubernetes, AWS ECS).

---

## Runtime Environments for Various Languages

| **Language**     | **Runtime Environment**               | **Description**                                                                                  |
|-------------------|---------------------------------------|--------------------------------------------------------------------------------------------------|
| **Java**         | JVM (Java Virtual Machine)            | Executes Java bytecode. Part of the JRE (Java Runtime Environment).                             |
| **Python**       | Python Interpreter                    | Executes Python scripts (`CPython` is the most common implementation).                          |
| **Node.js**      | Node.js Runtime                       | Executes JavaScript code outside the browser, built on Chrome's V8 JavaScript engine.           |
| **.NET (C#)**    | CLR (Common Language Runtime)         | Executes .NET bytecode (MSIL). Part of the .NET Framework or .NET Core.                         |
| **JavaScript**   | Browser JavaScript Engine             | Executes JavaScript code inside the browser (e.g., V8 for Chrome, SpiderMonkey for Firefox).    |
| **Ruby**         | Ruby Interpreter                      | Executes Ruby scripts (e.g., MRI for CRuby or JRuby for JVM).                                   |
| **PHP**          | PHP Interpreter                       | Executes PHP scripts, typically used with web servers like Apache or Nginx.                    |
| **C/C++**        | Native Machine Code (via Compiler)    | Executed directly by the OS; no specific runtime environment but may link to shared libraries.  |
| **Go**           | Native Machine Code (via Compiler)    | Compiled to native code; no separate runtime required beyond system libraries.                  |
| **Rust**         | Native Machine Code (via Compiler)    | Compiled to native code; no separate runtime required beyond system libraries.                  |
| **Kotlin**       | JVM (Java Virtual Machine)            | Executes Kotlin bytecode, often alongside Java.                                                 |
| **Scala**        | JVM (Java Virtual Machine)            | Executes Scala bytecode, fully interoperable with Java.                                         |
| **Perl**         | Perl Interpreter                      | Executes Perl scripts (`perl` command-line tool).                                               |
| **Swift**        | Swift Runtime (for macOS/iOS/Linux)   | Executes Swift code, often compiled to native machine code for execution.                       |
| **R**            | R Interpreter                        | Executes R scripts, primarily for statistical computing and visualization.                      |
| **Elixir**       | BEAM (Erlang VM)                     | Executes Elixir code, a high-level language built on the Erlang VM.                             |

