# Running Java Programs

## Table of Contents
1. [Overview](#overview)
2. [Running Java Programs](#running-java-programs)
    - [Using the Command Line](#using-the-command-line)
    - [Using an IDE](#using-an-ide)
    - [Using a Build Tool](#using-a-build-tool)
3. [Example: Running `HelloWorld.java`](#example-running-helloworldjava)
4. [Best Practices](#best-practices)
5. [Maven Commands Cheat Sheet](#maven-commands-cheat-sheet)
6. [POM File Structure](#pom-file-structure)

## Overview
This guide explains how to run Java programs using the command line, an IDE, or a build tool. It includes an example use case, best practices, and commonly used Maven commands for Java projects.

---

## Running Java Programs

### Using the Command Line
To run a Java program from the command line:

1. Open a terminal or command prompt.
2. Navigate to the directory containing your Java file.
3. Compile the program using the `javac` command:
   ```bash
   javac MyClass.java
   ```
   *(Replace `MyClass` with your Java class name.)*
4. Execute the program using the `java` command:
   ```bash
   java MyClass
   ```

### Using an IDE
Follow these steps to run Java programs in an IDE:

1. Open the IDE and create a new project.
2. Add a new Java class and write your code.
3. Compile the program by clicking **Compile** or using the IDE's shortcut.
4. Run the program by clicking **Run** or using the appropriate shortcut.

### Using a Build Tool
Steps to run Java programs with tools like Maven or Gradle:

1. Set up a new project in your build tool.
2. Add your Java code to the project directory.
3. Compile the program using the tool's command (e.g., `mvn clean compile` for Maven).
4. Run the program using the tool's command (e.g., `mvn exec:java` or `gradle run`).

---

## Example: Running `HelloWorld.java`

Suppose you have a program `HelloWorld.java` that prints "Hello, World!" to the console. Here’s how to run it:

1. Open a terminal.
2. Navigate to the directory containing the file.
3. Compile the file:
   ```bash
   javac HelloWorld.java
   ```
4. Execute the program:
   ```bash
   java HelloWorld
   ```

---

## Best Practices

1. **Compilation**: Always compile your Java program before running it.
2. **Tools**: Use IDEs and build tools to simplify the compilation and execution process.
3. **Testing**: Test thoroughly using unit and integration tests.
4. **Version Control**: Track changes with Git or other version control systems.
5. **Automation**: Set up CI/CD pipelines to automate builds and deployments.
6. **Analysis**: Use code analysis and formatting tools to ensure quality and consistency.
7. **Code Reviews**: Conduct code reviews to enhance maintainability.
8. **Mocking**: Use mocking frameworks (e.g., Mockito) to write isolated tests.

---

## Maven Commands Cheat Sheet

Here’s a list of essential Maven commands for managing Java projects:

```bash
# Install Maven
sudo apt update
sudo apt install -y maven

# Verify Maven installation
mvn -v

# Compile the project
mvn clean compile

# Run tests
mvn clean test

# Package the project
mvn clean package

# Skip tests while packaging
mvn package -DskipTests=true

# Use Maven Wrapper for packaging
./mvnw package
```

---

## POM File Structure
```xml

<!-- 
    Root element defining the project configuration and metadata.
    The 'project' element is required and adheres to the Maven POM (Project Object Model) standard.
    The namespace and schema details ensure the XML conforms to the Maven specification.
-->

<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    
    <!-- 
        Model Version: Specifies the version of the POM model used.
        For Maven 2.x and 3.x, this value should always be 4.0.0.
    -->
    <modelVersion>4.0.0</modelVersion>

    <!-- 
        Group ID: Specifies the unique identifier for the project's group or organization.
        Typically represents a domain or company name in reverse format.
    -->
    <groupId>com.example</groupId>
    
    <!-- 
        Artifact ID: The unique name of the project or module.
        Used to identify the artifact within the group.
    -->
    <artifactId>bankapp</artifactId>
    
    <!-- 
        Version: Specifies the version of the project.
        - Use 'SNAPSHOT' in the version (e.g., 0.0.1-SNAPSHOT) to publish to the snapshot repository.
        - Use a specific version number (e.g., 1.0.0) to publish to the release repository.
        This decision determines whether the artifact is considered a development version (SNAPSHOT) 
        or a stable release version.
    -->
    <version>0.0.1-SNAPSHOT</version>
    
    <!-- 
        Name: A human-readable name for the project.
        This is purely for informational purposes and does not affect repository selection.
    -->
    <name>bankapp</name>
    
    <!-- 
        Description: A brief description providing details about the project.
        This is useful for documentation or repository indexing.
    -->
    <description>Banking Web Application</description>

    <dependencies>
        <!-- Add your dependencies here -->
    </dependencies>

    <build>
        <plugins>
            <!-- Add your plugins here -->
        </plugins>
    </build>
</project>
```