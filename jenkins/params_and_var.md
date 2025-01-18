# Parameters and Variables in Jenkins

Both **parameters** and **variables** are used in Jenkins to handle dynamic and reusable values during builds. However, they serve distinct purposes, have different scopes, and are used in specific scenarios.

---

## **1. Parameters in Jenkins**

### **Definition**:
Parameters allow you to provide inputs to a build at runtime. These inputs can control how the build behaves and enable customization without altering the pipeline code.

### **Key Features**:
- Defined at the **job level** in Jenkins.
- Available for users to input when triggering a build manually.
- Examples include string, choice, boolean, password, and file parameters.

### **Use Case**:
- Customizing builds, such as deploying to different environments (`dev`, `staging`, `prod`).
- Selecting specific configurations or features for a build.
- Passing credentials securely as parameters (e.g., `password` or `file`).

### **When to Use**:
- When you need user input or control over how the build should execute.
- If a build process needs flexibility for different conditions or environments.

### **Example**:
A parameterized build with a string parameter `Environment`:
```groovy
parameters {
    string(name: 'Environment', defaultValue: 'dev', description: 'Target environment for deployment')
}
```
Use the parameter in the pipeline:
```groovy
echo "Deploying to environment: ${params.Environment}"
```

---

## **2. Variables in Jenkins**

### **Definition**:
Variables are used to store and reference dynamic values within a Jenkins build. These can include:
- **Environment Variables**: Predefined by Jenkins or the build environment (e.g., `BUILD_NUMBER`, `WORKSPACE`).
- **Pipeline Variables**: Custom variables defined within the pipeline code.

### **Key Features**:
- Available within the scope of the job or script.
- Not exposed to users directly.
- Can be static or dynamic based on the build process.

### **Use Case**:
- Storing and reusing intermediate values during the build process.
- Managing values such as file paths, URLs, or build-specific data.

### **When to Use**:
- For internal calculations, intermediate values, or managing runtime configurations.
- When you do not require user input and the value can be derived within the build.

### **Example**:
Using environment and pipeline variables:
```groovy
def artifactPath = "${WORKSPACE}/build/artifact.jar"
sh "cp ${artifactPath} /deployments"
```

---

## **Key Differences**

| Feature               | Parameters                                | Variables                                |
|-----------------------|------------------------------------------|------------------------------------------|
| **Definition**         | Inputs provided by users at build time. | Values used within the build or pipeline. |
| **Scope**              | Exposed to users triggering the build.  | Internal to the build or pipeline.       |
| **Customization**      | Allows user-specific build behavior.     | Enables dynamic behavior without user input. |
| **Examples**           | `Environment`, `Version`                | `BUILD_NUMBER`, `WORKSPACE`              |

---

## **Choosing Between Parameters and Variables**

| Scenario                                     | Use Parameters                | Use Variables                |
|---------------------------------------------|-------------------------------|------------------------------|
| User needs to control build behavior        | ✅                            | ❌                           |
| Build process depends on dynamic user input | ✅                            | ❌                           |
| Values are derived during the build         | ❌                            | ✅                           |
| Intermediate values needed internally       | ❌                            | ✅                           |

---

## **Conclusion**

- Use **parameters** when you need user input or flexibility for different builds.
- Use **variables** for internal build logic and runtime data manipulation.

Both play complementary roles in making Jenkins pipelines more dynamic and reusable.
