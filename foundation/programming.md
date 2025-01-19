# Key Points

## Interpreter vs Compiler

### Interpreter
- Executes code directly without needing a compilation step.
- Examples: Python, Ruby, PHP, JavaScript, Perl, R, Lua.
- Requires runtime environments like Python Interpreter or Node.js because they are not compiled into machine code beforehand.

### Compiler
- Translates code into machine language or bytecode before execution.
- Examples: Java, C/C++, Go, Rust, Scala, Haskell, Elixir.
- Compiles into machine code first, so they don't need a runtime environment for execution, but they do require standard libraries at runtime.

---

## Programming Language Comparison

| **Language**       | **Interpreter/Compiler** | **Package Manager** | **Type**   | **Base Image**            |
|--------------------|--------------------------|---------------------|------------|---------------------------|
| Python            | Interpreter              | pip3                | Interpreter| python:3.x                |
| Java              | Compiler                 | maven/gradle        | Compiler   | openjdk:11                |
| PHP               | Interpreter              | composer            | Interpreter| php:7.x-apache            |
| C/C++             | Compiler                 | N/A                 | Compiler   | N/A                       |
| JavaScript (Node.js) | Interpreter             | npm                 | Interpreter| node:alpine               |
| Go                | Compiler                 | go get              | Compiler   | golang:1.x-alpine         |

---

## Runtime Environment Overview

A runtime environment is the software infrastructure that provides the necessary tools, libraries, and services to execute code written in a specific programming language.

| **Language** | **Runtime Environment**               | **Purpose**                                 |
|--------------|---------------------------------------|---------------------------------------------|
| JavaScript  | Node.js                               | Executes JavaScript outside a browser      |
| Python      | Python Interpreter                    | Runs Python scripts                        |
| Java        | Java Virtual Machine (JVM)            | Runs Java bytecode                         |
| Ruby        | Ruby Interpreter                      | Executes Ruby code                         |
| C/C++       | OS & Libraries (e.g., libc)           | Runs compiled binaries                     |
| PHP         | PHP Runtime                           | Executes PHP scripts on servers            |
| C#          | .NET Runtime                          | Executes intermediate language             |

### Node.js
- Node.js is a runtime environment that allows developers to run JavaScript code outside the browser. 
- Traditionally, JavaScript was only executed in web browsers, but Node.js makes it possible to use JavaScript for server-side development, enabling you to build entire applications (both client and server) using one language.
- It uses Google's V8 engine (the same engine that powers the Chrome browser) to compile and execute JavaScript code.
- The Node.js image is a containerized environment that comes with the Node.js runtime and npm (Node Package Manager) pre-installed. It eliminates the need to install Node.js and its dependencies manually on your local machine or server.

---

## Architecture

### Architecture Types
- **amd64**: 64-bit x86 architecture (also known as x86_64)
- **i386**: 32-bit x86 architecture

### Port Configuration
- If your container only has port 80 configured but you want to use port 443 for HTTPS, you will need to modify your Apache/Nginx configuration to include SSL settings and ensure that Apache/Nginx is set up to listen on port 443.

---

## Client, Server, and Host

- **Host**: Any computer or device connected to a network that has an IP address. It acts as a node, capable of sending and receiving data across the network. A host can function as either a client or a server, depending on its configuration and purpose.
- **Client**: A client is always dependent. It relies on the server to perform tasks or provide resources.
- **Server**: A server is always independent. It provides resources or services to clients.

### Examples:
- Web browsers (e.g., Chrome, Firefox) requesting web pages from servers.
- Email clients like Microsoft Outlook fetching emails from mail servers.
- Mobile apps accessing cloud-based resources.

