# SonarQube `sonar-project.properties` Configuration Guide

The `sonar-project.properties` file configures the analysis of a project with SonarQube. Below is a detailed breakdown of the properties, grouped by type, and including examples for Java and Python projects.

---

## **1. General Required Metadata**

These properties are **mandatory** for all projects, regardless of the programming language.

- **`sonar.projectKey`**  
  - A unique identifier for the project in SonarQube.  
  - Example:  
    - For Java: `boardgame`  
    - For Python: `python-project`

- **`sonar.projectName`**  
  - The name displayed in the SonarQube UI for the project.  
  - Example:  
    - For Java: `Boardgame`  
    - For Python: `Python-project`

- **`sonar.projectVersion`**  
  - The version of the project. Increment this for every release.  
  - Example: `1.0`

---

## **2. Source Code Configuration**

These properties specify the location of the source code and are **mandatory**.

- **`sonar.sources`**  
  - Comma-separated paths to the directories containing the source code.  
  - Example:  
    - For Java: `src/main/java`  
    - For Python: `.` (current directory)

- **`sonar.exclusions`** (Optional)  
  - Paths or files to exclude from the analysis.  
  - Example for Python: `IbtisamOps/**` (Excludes all files in the `IbtisamOps` directory)

---

## **3. Language-Specific Properties**

These properties apply to specific programming languages.

### **For Java Projects**
- **`sonar.java.binaries`**  
  - The directory containing compiled `.class` files.  
  - Example: `target`

- **`sonar.java.libraries`**  
  - The directory containing external library `.jar` files.  
  - Example: `target/dependency`

- **`sonar.tests`**  
  - Path to the test source code.  
  - Example: `src/test/java`

- **`sonar.test.binaries`**  
  - Path to the compiled test classes.  
  - Example: `target/test-classes`

### **For Python Projects**
- **`sonar.python.coverage.reportPaths`** (Optional)  
  - Path to the Python coverage report.  
  - Example: `coverage.xml`

---

## **4. Encoding**

This property is **mandatory** for all projects.

- **`sonar.sourceEncoding`**  
  - Specifies the encoding of the source files.  
  - Example: `UTF-8`

---

## **5. Language**

This property specifies the primary language of the project. It is **optional** but helpful.

- **`sonar.language`**  
  - Language code for the project.  
  - Example:  
    - For Java: `java`  
    - For Python: `py`

---

## **6. SonarQube Server Configuration**

These properties are **mandatory** for connecting to the SonarQube server.

- **`sonar.host.url`**  
  - The URL of the SonarQube server.  
  - Example: `http://localhost:9000`

- **`sonar.login`**  
  - The authentication token for the project.

---

## **Mandatory vs. Optional Properties**

### **Mandatory**
- `sonar.projectKey`
- `sonar.projectName`
- `sonar.projectVersion`
- `sonar.sources`
- `sonar.sourceEncoding`
- `sonar.host.url`
- `sonar.login`

### **Optional**
- `sonar.exclusions`
- `sonar.language`
- `sonar.python.coverage.reportPaths` (Python)
- `sonar.java.binaries`, `sonar.java.libraries`, `sonar.tests`, `sonar.test.binaries` (Java)

---

## **Example Configurations**

### **Java Project**
```properties
# Java Project Configuration
sonar.projectKey=boardgame
sonar.projectName=Boardgame
sonar.projectVersion=1.0
sonar.sources=src/main/java
sonar.java.binaries=target
sonar.java.libraries=target/dependency
sonar.tests=src/test/java
sonar.test.binaries=target/test-classes
sonar.sourceEncoding=UTF-8
sonar.language=java
sonar.host.url=http://localhost:9000
sonar.login=<SONAR_AUTHENTICATION_TOKEN>
```
### **Python Project**
```properties
# Python Project Configuration
sonar.projectKey=python-project
sonar.projectName=Python-project
sonar.projectVersion=1.0
sonar.sources=.
sonar.exclusions=IbtisamOps/**
sonar.python.coverage.reportPaths=coverage.xml
sonar.sourceEncoding=UTF-8
sonar.language=py
sonar.host.url=http://localhost:9000
sonar.login=<SONAR_AUTHENTICATION_TOKEN>
```

### **Nodejs Project**
```properties
sonar.projectName==Nodejs-jest
sonar.projectKey==Nodejs-jest
sonar.javascript.lcov.reportPaths==coverage/lcov.info
sonar.test.inclusions==**/*.test.js
sonar.sources==.
sonar.tests==.
sonar.sourceEncoding==UTF-8
sonar.language==js
```
---

## **Key Differences Between Java and Python**

### **Source Path (`sonar.sources`)**
- **Java**: Points to the `src/main/java` directory.  
- **Python**: Typically points to the current directory (`.`).

---

### **Binaries Path**
- **Java**: Requires `sonar.java.binaries` and `sonar.test.binaries` to specify paths to compiled `.class` and test classes.  
- **Python**: Does not require these properties.

---

### **Coverage Report**
- **Java**: Coverage reports are generally managed by external tools like Jacoco and integrated manually.  
- **Python**: Supports `sonar.python.coverage.reportPaths` to specify the path to the `coverage.xml` file.


