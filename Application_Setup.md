# Multi-Language Application Setup

This document provides commands to set up and run applications written in Java, Node.js, Python, and .NET on a Linux system. Ensure you have administrative privileges for package installation and follow the instructions for each language carefully.

---

# Running Java Programs
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

# Package the project without running tests
mvn package -DskipTests=true

# If using Maven Wrapper
./mvnw package
```

---

# Running Node.js Application
```bash
# Install Node.js and npm
sudo apt update
sudo apt install -y nodejs npm

# Verify Node.js and npm installation
node -v
npm -v

# Navigate to the client folder and install dependencies
cd client
npm install --omit=dev # Skips installing development dependencies for production setup

# Navigate to the server folder and install dependencies
cd ../server
npm install --omit=dev

# Install a development dependency
npm install <package-name> --save-dev # In recent npm versions, --save-dev is optional

# Start the application
npm start
```

---

# Running Python Application
```bash
# Install Python and pip
sudo apt update
sudo apt install -y python3-pip python3.12-venv

# Verify Python and pip installation
python3 --version
pip --version

# Create a virtual environment
python3 -m venv IbtisamOps

# Activate the virtual environment
source IbtisamOps/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the application
python app.py

# Deactivate the virtual environment
deactivate
```

---

# Running .NET Application
```bash
# Install .NET Core SDK
sudo apt update
sudo apt-get install -y dotnet-sdk-8.0

# Install ASP.NET Core runtime
sudo apt-get install -y aspnetcore-runtime-8.0

# Verify .NET SDK installation
dotnet --info

# Navigate to the root directory of your .NET project
cd /path/to/project

# Restore dependencies
dotnet restore

# Build the project
dotnet build

# Run the application
dotnet run
```


