1️⃣ Using Different Images for Build and Runtime
The first stage uses a larger image (e.g., golang, maven, node) to compile/build the application.
The second stage uses a lighter image (e.g., alpine, nginx, scratch) to run the application.
Use case: When the build process requires additional dependencies (compilers, build tools) that aren’t needed at runtime.
Example: A Golang app builds in golang:latest and runs in alpine.
2️⃣ Using the First Stage as a Base for the Final Image
The second stage inherits from the first, but removes or adds dependencies based on the environment.
Use case: When the same base image is required across different stages, but with different dependencies (e.g., dev tools in one stage, production-ready minimal setup in another).
Example: A Node.js app starts with node:alpine, installs dev dependencies in the first stage, and only keeps prod dependencies in the final stage.