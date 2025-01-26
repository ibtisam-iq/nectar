# Nexus and Artifact Management Guide

This guide provides an overview of artifacts, their types, and how they are managed using Nexus and Docker in a CI/CD pipeline.

## Table of Contents
1. [Artifact](#artifact)
    - [How Artifacts Differ from Regular Files](#how-artifacts-differ-from-regular-files)
    - [Artifact Types by Programming Language](#artifact-types-by-programming-language)
2. [Binaries, Libraries, and Packages](#binaries-libraries-and-packages)
    - [JAR File and run.py Classification](#jar-file-and-runpy-classification)
3. [Typical Project Contents](#typical-project-contents)
4. [Nexus and Docker in Pipeline Workflow](#nexus-and-docker-in-pipeline-workflow)
5. [Key Components Stored in Nexus vs Docker Image](#key-components-stored-in-nexus-vs-docker-image)
6. [Components Inside an Artifact File vs. Docker Image](#components-inside-an-artifact-file-vs-docker-image)
7. [Runtime Environments for Various Languages](#runtime-environments-for-various-languages)
8. [Installation and Configuration](#installation-and-configuration)
9. [Deploy to Nexus](#deploy-to-nexus)

---

## Artifact

An artifact is a file or collection of files produced during the build process of a software project. Artifacts are typically binaries, libraries, or packages that are deployed to repositories for distribution or consumption by other projects.

### How Artifacts Differ from Regular Files

Artifacts are different from regular files because:

- **Versioning**: Artifacts are usually versioned to ensure consistency and traceability in software builds.
- **Build Outputs**: They represent the final or intermediate products of a build pipeline.
- **Reusability**: Artifacts can be reused across multiple projects, making them essential for dependency management.


| **File Type**    | **Definition**                                                                                     |
|------------------|---------------------------------------------------------------------------------------------------|
| **Artifact**     | Packaged, versioned files used for distribution or deployment.                                     |
| **Source Code**  | Human-readable code written by developers.                                                        |
| **Binary**       | Machine-readable compiled files (e.g., `.exe`, `.class`).                                         |
| **Library**      | Reusable code components packaged for integration into other projects.                            |
| **Package**      | Bundled files, including source code, binaries, and metadata for easy distribution (e.g., `.jar`). |

### Artifact Types by Programming Language

| Programming Language | Common Artifact Types                   |
|----------------------|------------------------------------------|
| Java                 | .jar, .war, .ear                        |
| Python               | .whl (Wheel), .tar.gz (Source Distribution) |
| JavaScript           | .tgz (npm package archives)             |
| .NET (C#, VB.NET)    | .dll, .exe, .nupkg (NuGet Package)      |
| Ruby                 | .gem (RubyGems)                         |
| Go                   | Executable binaries (no specific extension) |
| C/C++                | .exe, .dll, .so (Shared Object), .a (Static Library) |
| Node.js              | .js (Built JavaScript Files)            |
| Rust                 | .rlib, Executable binaries              |
| PHP                  | .phar (PHP Archive)                     |

---

## Binaries, Libraries, and Packages

### Binaries
- **Definition**: An executable file compiled from source code that a computer can run directly. It’s machine-readable and doesn’t require further compilation or interpretation.
- **Difference**: 
    - Standalone; contains everything needed to run the program.
    - Purpose: Designed to perform a specific task or run an application.
- **Use Case Example**: `myapp.exe` on Windows or `./myapp` on Linux.
    - You’ve developed a C++ application that calculates interest rates. After compiling the code, the output is an executable binary file. Running it directly performs the calculations.


### Libraries
- **Definition**: A collection of pre-written code that developers can use to perform common tasks or add functionality to their programs. Libraries are not standalone; they’re included in other programs. 
- **Difference**: 
    - Reusable and often required by binaries to function properly.
    - Purpose: Provide modular, reusable code for specific tasks like database interaction or math operations.
- **Use Case Example**: `libmath.so` (Linux shared library) or `math.dll` (Windows dynamic library).
    - Your Python program needs advanced math functions. Instead of writing them yourself from scratch, you import a library like `numpy`, which provides these functions.

### Packages
- **Definition**: A structured collection of files (binaries, libraries, configuration files, etc.) bundled together for distribution. Packages make it easier to share and install software.
- **Difference**: 
    - Comprehensive; includes binaries, libraries, and metadata.
    - Purpose: Facilitate installation, distribution, and version management.
- **Use Case Example**: A `.deb` file (Debian package) or `.nupkg` (NuGet package).
    - You want to share your Python project with others. You create a package that includes your code, dependencies, and configuration files. This package can be easily installed on other systems.
    - Your project depends on several libraries. You create a package that includes these libraries along with your project’s code. This simplifies the installation process for users.
    - Your project has multiple versions. You create a package for each version, making it easy to manage and switch between versions.
    - Your project has dependencies that need to be installed separately. You create a package that includes these dependencies, ensuring they’re installed correctly with your project.
    - When you want to install a web server like Nginx on Linux, you download its .deb package. This package contains all necessary binaries, libraries, and configuration files to run Nginx.

#### Key Difference

| **Aspect**       | **Binary**             | **Library**                   | **Package**                     |
|-------------------|------------------------|--------------------------------|----------------------------------|
| **Standalone**    | Yes                    | No                             | Often includes binaries/libraries |
| **Purpose**       | Executes specific tasks| Provides reusable functionality| Simplifies software distribution |
| **Example Extension** | .exe, .bin            | .dll, .so, .jar               | .deb, .rpm, .nupkg              |
| **Use**          | Run directly           | Linked/integrated with software| Installed to enable functionality |
| **Management**    | No version management | Version management within software| Version management for distribution |
| **Distribution**  | Direct execution        | Included with software          | Bundled with dependencies and metadata |
| **Installation**  | No installation required| Linked/integrated with software| Requires installation process |
| **Reusability**   | Limited to specific task| Highly reusable across software| Highly reusablility across projects |
| **Complexity**    | Simple, direct execution| Complex, requires integration| Complex, requires installation process |
| **Size**          | Typically small         | Varies, often smaller than binaries| Can be large, depending on included files |
| **Dependency**   | No dependencies required| Often depends on other libraries| May depend on other packages or libraries |
| **Metadata**     | No metadata required    | May include metadata for integration| Includes metadata for distribution and version management |

### JAR File and run.py Classification

#### 1. JAR File
**What is it?**  
A JAR (Java Archive) file is a package format used to bundle Java class files and associated resources (like images or configuration files). It’s often used for distribution.

**Category:** Depends on Use Case  
- **Binary:** If the JAR is an executable file (contains a Main-Class in its MANIFEST.MF file), it’s considered a binary. You can run it directly with `java -jar myapp.jar`.  
    - *Example:* A Java application packaged as `app.jar` that launches a GUI calculator when run.  
- **Library:** If the JAR contains reusable code that other Java applications import (like `log4j.jar` for logging), it’s a library.  
    - *Example:* A JAR file that provides database drivers, such as `mysql-connector.jar`.  
- **Package:** JAR files are also technically packages because they bundle files for distribution.

#### 2. run.py
**What is it?**  
`run.py` is a Python script file containing source code written in Python. It’s a text file and not compiled into machine code.

**Category:** Binary-Like (Source Executable)  
- **Binary-Like:** When executed with the Python interpreter (`python run.py`), it behaves like a binary, as it performs a specific task. However, it’s technically not a compiled binary but a source file executed by Python.  
    - *Example:* A `run.py` script that starts a web server for a Python application.  
- **Not a Library or Package:** It’s not a library because it doesn’t provide reusable functionality, nor is it a package because it’s not a structured bundle.

### Key Difference Between the Two

| **Aspect**     | **JAR File**                               | **run.py**                   |
|----------------|--------------------------------------------|------------------------------|
| **Compiled?**  | Yes (Java bytecode)                        | No (Python source code)      |
| **Run Directly?** | Yes (`java -jar`) if executable           | Yes (`python run.py`)        |
| **Reusable?**  | Yes (as a library)                         | No (typically not reusable)  |
| **Category**   | Binary, Library, or Package (varies)       | Binary-Like                  |


---

## Typical Project Contents

A typical project might include:

1. **Source Code**  
   The human-readable instructions written by developers (e.g., Python, Java, JavaScript code).  

2. **Dependencies**  
   External libraries or modules the project relies on, often defined in files like:  
   - `pom.xml` (Maven)  
   - `requirements.txt` (Python)  
   - `package.json` (Node.js)  

3. **Libraries**  
   Pre-written code that provides functionality (e.g., `.jar`, `.dll` files).  

4. **Packages**  
   Bundled versions of your application or its dependencies (e.g., `.whl`, `.nupkg`).  

5. **Runtime**  
   The environment required to execute the program (e.g., JVM for Java, Python interpreter).  

---

## Nexus and Docker in Pipeline Workflow  

### 1. Build Phase  
1. Source code is compiled, and all dependencies are resolved.  
2. Build artifacts (e.g., `.jar`, `.war`, `.dll`) are created and pushed to **Nexus** for **versioning** and **storage**.  

### 2. Docker Image Creation Phase  
1. A `Dockerfile` is created, configured to fetch the build artifact from **Nexus**.  
2. The Docker image is built to include:  
   - The build artifact from Nexus.  
   - Required runtime environment and dependencies.  

### 3. Deploy Phase  
1. The Docker image is pushed to a Docker registry (e.g., Docker Hub or **Nexus configured as a Docker registry**).  
2. The image is deployed as a container to the target environment (e.g., Kubernetes, AWS ECS).  

---

## Key Components Stored in Nexus vs Docker Image

### Nexus

1. **Build Artifacts:**  
  Outputs of the build process, such as `.jar`, `.war`, `.dll`, `.whl`, or other binaries.  
  - These artifacts are versioned and stored to ensure consistency and availability across environments or teams.  
2. **Dependencies:**  
  Third-party libraries or packages required during the build process.  
  - *Example:* Maven dependencies in Java projects are cached in Nexus to improve build times and maintain consistency.  
3. **Custom Libraries:**  
  Internally developed reusable libraries that are shared across projects by uploading them to Nexus.  

#### Purpose of Nexus  
- Serves as a centralized repository for **managing** and **storing** artifacts.  
- Facilitates reusability and ensures consistency of libraries and artifacts across different environments.  
- Enables traceability of artifacts, especially for production deployments.
- Helps us to create a **private Docker registry** like ECR, and ACR etc.  

### Docker Images

1. **Runtime Environment:**  
  A Docker image bundles all essential components to run the application, such as:  
  - Base OS (e.g., `alpine`, `ubuntu`).  
  - Application runtime (e.g., JVM for Java, Python interpreter).  
  - Application (build artifact retrieved from Nexus).  
  - Any required dependencies.  
2. **Dockerfile:**  
  A file that defines the process for building the Docker image, including instructions for adding dependencies, configurations, and runtime requirements.  

#### Purpose of Docker  
- Provides a containerized environment to ensure applications run consistently across different environments (development, staging, production).  
- Eliminates environment-specific issues by bundling the application and its dependencies in a container.

### Key Differences Between Nexus and Docker  

| **Aspect**            | **Nexus**                                     | **Docker**                                   |
|------------------------|-----------------------------------------------|---------------------------------------------|
| **Primary Purpose**    | Store and manage build artifacts (e.g., `.jar`, `.dll`). | Build, ship, and run containerized applications. |
| **What It Stores**     | Build outputs, libraries, dependencies.       | Complete application, runtime, and dependencies inside a container. |
| **Pipeline Role**      | Artifact storage after the build phase.       | Containerization before deployment.         |

---

## Components Inside an Artifact File vs. Docker Image  

Let’s break down what components (source code, dependencies, libraries, packages, and runtime) are included in an artifact file (e.g., `.jar`, Python `.whl`, or Node.js `.tgz`) versus what is handled by Docker to make all components available.  

### Artifact File  
An **artifact file** is typically created during the build process and usually contains:  

1. **Source Code:**  
  - **Not included in most artifact files.**  
    - Instead, the source code is compiled into binaries (e.g., `.class` files for Java, `.pyc` files for Python).  
  - *Exception:* For interpreted languages (like Python or JavaScript), the artifact may include uncompiled source code (e.g., `.py` or `.js` files).  

2. **Dependencies:**  
  - **Partially included or referenced.**  
  - In Java (JAR files), dependencies can be included as part of the file (a "fat JAR") or referenced externally.  
  - For Python (Wheel or `.tar.gz`), dependencies are typically not included but are listed in metadata for package managers (like `pip`) to fetch.  

3. **Libraries:**  
  - **Partially included** (depends on the build process).  
  - For instance, a JAR file may contain compiled versions of reusable libraries if packaged as a "fat JAR," but this isn’t always the case.  

4. **Packages:**  
  - **Always included.**  
  - Artifact files are inherently packaged versions of your application or its components.  

5. **Runtime:**  
  - **Not included.**  
  - Artifacts do not bundle the runtime environment (e.g., JVM for Java, Python interpreter for Python). The runtime must be available separately.  


| **Component**        | **Presence in Artifact File**                                                                 |
|-----------------------|-----------------------------------------------------------------------------------------------|
| **Source Code**       | Rarely included (except for interpreted languages like Python or JavaScript).                |
| **Dependencies**      | Partially included (e.g., fat JARs or referenced metadata for dependency managers).          |
| **Libraries**         | Partially included (depends on the build process and packaging settings).                    |
| **Packages**          | Always included (artifacts are inherently packaged versions of the application).             |
| **Runtime**           | Not included; the runtime environment must be available separately.                          |

### Components Handled by Docker  
Docker addresses the **remaining components** to make the program fully functional:  

1. **Source Code:**  
  - If the artifact doesn’t include compiled code, Docker copies the source code into the image and ensures it’s runnable.  
  - *Example:* Docker can include a Python script (`run.py`) alongside a Python runtime.  

2. **Dependencies:**  
  - Docker can fetch and install dependencies during the image build process.  
  - *Example:* A Dockerfile may include `RUN pip install -r requirements.txt` for Python projects.  

3. **Libraries:**  
  - Libraries not bundled in the artifact can be installed using package managers (like `apt` for OS-level libraries or `maven` for Java).  
  - *Example:* `RUN apt-get install libssl-dev` for OpenSSL support.  

4. **Packages:**  
  - The artifact file (which is itself a package) is copied into the Docker image.  

5. **Runtime:**  
  - Docker images explicitly include the runtime environment.  
  - *Example:* A Java Docker image (`openjdk`) includes the JVM to run `.jar` files.  


| **Component**        | **Handled by Docker**                                                              |
|-----------------------|-----------------------------------------------------------------------------------|
| **Source Code**       | May include if not precompiled (e.g., interpreted languages like Python or Node.js). |
| **Dependencies**      | Installed during the image build process.                                         |
| **Libraries**         | Installed if missing or required externally.                                      |
| **Packages**          | Copies and uses the artifact as part of the image.                                |
| **Runtime**           | Always included (e.g., JVM, Python interpreter, or Node.js runtime).              |

### Example Breakdown for Java, Python, and Node.js  

- **Java (.jar):**  
  - *Artifact Contains:* Compiled source code, dependencies (if fat JAR), and packaged structure.  
  - *Docker Adds:* JVM runtime, OS-level dependencies, external libraries (if not included in the JAR).  

- **Python (.whl or .tar.gz):**  
  - *Artifact Contains:* Source code or compiled `.pyc` files, metadata for dependencies.  
  - *Docker Adds:* Python runtime, installs dependencies using `pip`.  

- **Node.js (.tgz):**  
  - *Artifact Contains:* Source code (JavaScript files), metadata (`package.json`) listing dependencies.  
  - *Docker Adds:* Node.js runtime, installs dependencies using `npm install`.  

#### Summary Table  

| **Component**      | **Artifact File**                                  | **Docker**                                     |
|---------------------|---------------------------------------------------|-----------------------------------------------|
| **Source Code**     | Rarely included (except for interpreted languages) | May include if not precompiled.               |
| **Dependencies**    | Sometimes included (e.g., fat JARs)               | Installed during the image build.             |
| **Libraries**       | Sometimes included (depends on build settings)    | Installed if missing or externally required.  |
| **Packages**        | Always included (artifacts are packaged files)    | Copies and uses the artifact.                 |
| **Runtime**         | Never included                                    | Always included (runtime environment).        |
| **Build Environment**| Rarely included (except for interpreted languages) | Always included (to build the artifact).     |
| **OS-Level Dependencies**| Rarely included (except for interpreted languages) | Installed if missing or externally required.  |
| **External Libraries**| Rarely included (except for interpreted languages) | Installed if missing or externally required.  |
| **Metadata**        | Sometimes included (e.g., `package.json`)        | Used to install dependencies and configure.  |
| **Build Tools**     | Rarely included (except for interpreted languages) | Installed if missing or externally required.  |
| **Versioning**      | Included in the artifact metadata (e.g., `pom.xml`) | Used to ensure consistent versions.           |
| **Security**        | Included in the artifact (e.g., encryption keys) | May bloat the image size.                     |
| **Configuration**   | Included in the artifact (e.g., `application.properties`) | May be used to configure the application.    |
| **Logging**         | Included in the artifact (e.g., `log.properties`) | May be used to configure logging.            |
| **Monitoring**      | Included in the artifact (e.g., `monitoring.properties`) | May be used to configure monitoring.         |
| **Testing**         | Included in the artifact (e.g., test classes)    | May be used to run tests during the build.    |

---

## Runtime Environments for Various Languages

| Language     | Runtime Environment                | Description                                                      |
|--------------|------------------------------------|------------------------------------------------------------------|
| Java         | JVM (Java Virtual Machine)         | Executes Java bytecode. Part of the JRE (Java Runtime Environment). |
| Python       | Python Interpreter                 | Executes Python scripts (CPython is the most common implementation). |
| Node.js      | Node.js Runtime                    | Executes JavaScript code outside the browser, built on Chrome's V8 JavaScript engine. |
| .NET (C#)    | CLR (Common Language Runtime)      | Executes .NET bytecode (MSIL). Part of the .NET Framework or .NET Core. |
| JavaScript   | Browser JavaScript Engine          | Executes JavaScript code inside the browser (e.g., V8 for Chrome, SpiderMonkey for Firefox). |
| Ruby         | Ruby Interpreter                   | Executes Ruby scripts (e.g., MRI for CRuby or JRuby for JVM).     |
| PHP          | PHP Interpreter                    | Executes PHP scripts, typically used with web servers like Apache or Nginx. |
| C/C++        | Native Machine Code (via Compiler) | Executed directly by the OS; no specific runtime environment but may link to shared libraries. |
| Go           | Native Machine Code (via Compiler) | Compiled to native code; no separate runtime required beyond system libraries. |
| Rust         | Native Machine Code (via Compiler) | Compiled to native code; no separate runtime required beyond system libraries. |
| Kotlin       | JVM (Java Virtual Machine)         | Executes Kotlin bytecode, often alongside Java.                  |
| Scala        | JVM (Java Virtual Machine)         | Executes Scala bytecode, fully interoperable with Java.          |
| Perl         | Perl Interpreter                   | Executes Perl scripts (perl command-line tool).                  |
| Swift        | Swift Runtime (for macOS/iOS/Linux)| Executes Swift code, often compiled to native machine code for execution. |
| R            | R Interpreter                      | Executes R scripts, primarily for statistical computing and visualization. |
| Elixir       | BEAM (Erlang VM)                   | Executes Elixir code, a high-level language built on the Erlang VM. |
| Haskell      | GHC (Glasgow Haskell Compiler Runtime) | Executes Haskell programs, often using the GHC runtime for lazy evaluation and threading. |
| Dart         | Dart VM (Dart Virtual Machine)     | Executes Dart code, particularly for Flutter apps, or compiled to native code. |
| Shell (Bash) | Bash Shell or Terminal             | Executes shell scripts on Unix-like systems.                     |

---

## Installation and Configuration 

### Installation Using Native Commands  
[Official Documentation](https://help.sonatype.com/en/download.html)  

#### Steps  
1. **Install Java Runtime**  
   ```bash
   sudo apt install openjdk-17-jdk-headless -y
   ```  

2. **Download and Extract Nexus**  
   ```bash
   cd /opt
   wget https://download.sonatype.com/nexus/3/nexus-3.76.1-01-unix.tar.gz
   tar -xvf nexus-3.76.1-01-unix.tar.gz
   ```  

3. **Create a Nexus User and Set Permissions**  
   ```bash
   adduser nexus
   chown -R nexus:nexus nexus-3.76.1-01/
   chown -R nexus:nexus sonatype-work/
   ```  

4. **Edit Nexus Configuration**  
   Open the configuration file:  
   ```bash
   vi nexus-3.76.1-01/bin/nexus.rc
   ```  
   Add the following line:  
   ```plaintext
   run_as_user="nexus"
   ```  

5. **Start Nexus**  
   ```bash
   /opt/nexus-3.76.1-01/bin/nexus start
   ```  

### Installation Using Docker (Easy Way)  

#### Step 1: Install Nexus 3 Using Docker  
Run the following command to pull and start the Nexus container:  
```bash
docker run -d -p 8081:8081 --name nexus sonatype/nexus3
```  
- **Flags Used:**  
  - `-d`: Run as a detached container.  
  - `-p 8081:8081`: Expose Nexus on port 8081.  
  - `--name nexus`: Assign the container the name "nexus."  

#### Step 2: Retrieve the Initial Admin Password  
Wait for Nexus to initialize, then retrieve the admin password:  
1. Check running containers:  
   ```bash
   docker ps
   ```  
   Note down the `container_ID`.  

2. Access the container and retrieve the password:  
   ```bash
   docker exec -it container_ID /bin/bash
   cat sonatype-work/nexus3/admin.password
   ```  

#### Step 3: Access Nexus Web Interface  
1. Open your browser and navigate to:  
   [http://localhost:8081](http://localhost:8081).  

2. Log in with:  
   - **Username:** `admin`  
   - **Password:** Retrieved in the previous step.  

#### Cleanup (Optional)  
To stop and remove the Nexus container after testing:  
```bash
docker stop nexus
docker rm nexus
```  

---

## Types of Nexus Repositories: Releases vs. Snapshots

In Nexus Repository, there are two primary types of repositories used for storing artifacts:

### 1. Release Repositories
- **Purpose**: Store stable, production-ready versions of artifacts.
- **Versioning**: Releases are versioned with a final version identifier (e.g., `1.0.0`, `2.1.3`).
- **Immutability**: Artifacts in release repositories should be immutable, meaning once published, they cannot be changed or overwritten.
  
### 2. Snapshot Repositories
- **Purpose**: Store development versions of artifacts that are still in progress and may change over time.
- **Versioning**: Snapshots are versioned with a `-SNAPSHOT` suffix (e.g., `1.0.0-SNAPSHOT`, `2.1.3-SNAPSHOT`).
- **Mutability**: Snapshot versions are mutable, allowing multiple versions of the same artifact to be published (e.g., `1.0.0-SNAPSHOT` can be replaced with `1.0.1-SNAPSHOT`).

---

## Types of Nexus Repositories: Hosted, Group, and Proxy

In Nexus Repository, there are three primary repository types:

### 1. Hosted Repositories
- **Purpose**: Hosted repositories store your artifacts, allowing you to upload, store, and manage them within Nexus.
- **Usage**: Used for storing your **own companies's artifacts**, such as those produced from CI/CD pipelines or manually uploaded packages.
- **Example Use Cases**:
  - Storing release or snapshot versions of artifacts.
  - Storing internal dependencies that you want to manage and share within your organization.

#### Example:
  - You may create a **hosted repository** for your `npm` packages or Java artifacts that you want to publish or retrieve from within your private network.

### 2. Group Repositories
- **Purpose**: A group repository aggregates multiple repositories (both hosted and proxy) under a single URL, providing a unified access point.
- **Usage**: It simplifies repository management by grouping related repositories together, so users can query them in one go.
- **Example Use Cases**:
  - Creating a **group repository** that includes both release and snapshot repositories for `npm` packages.
  - Aggregating multiple artifact types (e.g., Java and npm artifacts) into a single access point for ease of use.

#### Example:
  - You may create a **group repository** that includes:
    - A hosted repository for internal releases.
    - A proxy repository for external dependencies.

### 3. Proxy Repositories
- **Purpose**: Proxy repositories cache and store artifacts from external repositories. They allow you to access external dependencies more efficiently by caching them locally.
- **Usage**: Useful for retrieving and caching artifacts from remote repositories like Maven Central, npm registry, or Docker Hub. Proxy repositories improve reliability and performance by storing these artifacts locally, reducing the need to fetch them repeatedly from the external source.
- **Example Use Cases**:
  - Creating a **proxy repository** to cache artifacts from a public repository like npm, Maven Central, or Docker Hub.
  - Ensuring access to external artifacts even when the external source is down or slow by using the cached versions.

#### Example:
  - You can create a **proxy repository** for the `npm` registry so that you don't need to rely on the remote npm repository each time you build your application.


### Choosing Between Hosted, Group, and Proxy Repositories

- **Hosted Repositories**: Use for your own artifacts that you want to upload and manage.
- **Group Repositories**: Use to combine multiple repositories into one unified access point.
- **Proxy Repositories**: Use to cache and proxy artifacts from external repositories, improving performance and reliability.

Each repository type has its role in managing artifacts, whether they are internal, aggregated, or external.

---
## Use Cases
### 1. Deploy Artifact to Nexus Repository Using Jenkins

Please find the [detailed guide](nexus_jenkins.md) about deploying different types of artifacts to Nexus Repository using Jenkins.

### 2. Download Artifact from Nexus Repository Using Maven in Jenkins

Please find the [detailed guide](artifact_downloading.md) about downloading artifacts from Nexus Repository using Maven in Jenkins.

### 3. Create a Proxy Repository

Please find the [detailed guide](proxy_repo.md) about creating a proxy repository.

### 4. Setting up Nexus as a Docker Registry

Please find the [detailed guide](nexus_docker.md) about setting up Nexus as a Docker.

## OrientDB

**Nexus Repository Manager** utilizes **OrientDB** internally, but users typically won't need to interact with this database directly. It's used for storing system data and metadata, enabling Nexus to function efficiently. If you're managing a Nexus instance, you should focus on backing up and restoring the Nexus data rather than manipulating the internal OrientDB database directly.

## Important Considerations
- `Allow redeploy` in Deployment policy is not recommended as it can cause issues with the artifact versioning.
- If you're using a proxy repository, ensure that the external repository is accessible and not blocked by any firewall or network restrictions.
- Always test your Nexus setup and artifact deployment in a non-production environment before deploying it to production.
- Nexus supports various authentication methods, including username/password, LDAP, and Active Directory. Choose the method that best fits your organization's security policies.
- If you want to take the backup, take the back up of complete `sonatype-work` directory.

---

This guide provides a comprehensive overview of artifacts, their types, and how they are managed using Nexus and Docker in a CI/CD pipeline.