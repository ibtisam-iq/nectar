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

```
ibtisam@mint-dell:/media/ibtisam/L-Mint/git/jenkins_shared_library$ tree
.
├── resources
│   └── config.txt
├── src
│   └── org
│       └── example
│           └── myLibrary.groovy
└── vars
    ├── install.groovy
    ├── myFunction.groovy
    ├── pkgwithskiptest.groovy
    └── sonar-analysis.groovy

6 directories, 6 files

ibtisam@mint-dell:/media/ibtisam/L-Mint/git/jenkins_shared_library$ cat vars/myFunction.groovy 
// vars/myFunction.groovy
def call(name) {
    echo "Hello ${name} from myFunction!"
    
}

ibtisam@mint-dell:/media/ibtisam/L-Mint/git/jenkins_shared_library$ cat vars/pkgwithskiptest.groovy 
def call() {   
     sh 'mvn package -DskipTests=true'      
    
}

```

---

## Steps

1. Configure the Github repo as following:

![](./images/Shared%20Lib.png)

2. Write the `pipeline` as following:

```groovy
@Library ("it_can_be_any_name")_

pipeline {
    agent any
    
    tools { 
        maven "maven3"
    } 

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'master', url: 'https://github.com/ibtisamops/secretsanta-generator.git'
            }
        }
        
        stage('Hello') {
            steps {
                script {
                    myFunction("Ibtisam")
                    pkgwithskiptest
                }
            }
        }
    }
}
```

