# FROM <image>[:<tag>]
# Specifies the base image to use for the subsequent instructions.

FROM alpine

# MAINTAINER my Ibtisam

# Adds metadata to an image (key-value pairs).

LABEL version="1.0" description="My application" maintainer="mylove@ibtisam.com"

# Define build-time argument which can be used in builds.
# Defines a variable that users can pass at build-time to the builder with the docker build command.
# After the image is built, the ARG value is no longer available.
# 
# You can set it during the build process with the --build-arg flag. 
# If not specified, it defaults to the value you provided (in this case, 8000).
# docker build --build-arg PORT=4000 -t myapp .

ARG VERSION=1.0
AGR PORT=8000

# Set environment variables that can be accessed by the application.
# ENV <key> <value>
# Application in the container is configured to listen on this port, so you should EXPOSE the same port
ENV APP_ENV=production
ENV PORT=8000
ENV PORT=$PORT

# Set the working directory in the container where the application code will reside.
# Sets the working directory for any RUN, CMD, ENTRYPOINT, COPY, and ADD instructions that follow it.
WORKDIR /app

# Copy all files from the current directory on the host to the /app directory in the container.
#COPY <src> <dest>
COPY . /app

# ADD <src> <dest>
# Similar to COPY, but can also extract TAR files and supports remote URLs.
ADD myapp.tar.gz /app/


# Executes linux commands to install necessary packages or dependencies
# CMD, to run any command like systemctl; RUN, to install anything
# RUN <command> # Executes commands in a new layer on top of the current image and commits the results.

RUN echo "Hey sweetheart" 
RUN echo "This is Ibtisam."
RUN echo $(pwd)
RUN touch file.txt
RUN apt-get update 
RUN cd /tmp && touch abc.txt
RUN echo "Hey sweetheart" && echo "This is Ibtisam." && echo $(pwd) && touch file.txt && apt-get update && cd /tmp && touch abc.txt


# Make port 8000 available to the world outside this container
# Informs Docker that the container listens on port 8000 at runtime.
# While it does not actually publish the port, it serves as documentation and helps with network configuration.
# You still need to use the -p option when running the container to make that port accessible from your host.
# This instruction doesn't automatically make the port accessible from outside the container, 
# but it signals to tools like Docker Compose or Kubernetes that port 8000 is the expected point of access.
# So, the EXPOSE instruction is a way to declare which ports your application uses, 
# and it works hand-in-hand with the -p option when running the container to establish the actual port mapping.
# docker run -p 4000:8000 my-app
# container=8000, host=4000, curl http://localhost:4000  -p 4000:8000
# Make it sure that the application is configured to listen on the same port.
# Not mentioning EXPOSE during the image build doesn’t prevent the container from being able to listen on a port at runtime, 
# the image can still listen on ports if you map them during docker run.
# containerPort=service's targetPort=8000,  hostPort=4000

EXPOSE 8000
EXPOSE $PORT

# Create a mount point for external storage
VOLUME ["/app/data"]

# Define the entry point for the container
# Sets the command to execute when the container starts, making it executable.
# the ENTRYPOINT is the command that always gets executed when a container starts.
#The ENTRYPOINT command defines the default program that runs when the container is started. 
#In this case, it specifies that the python3 interpreter will always be used.
#python3: This is the executable. It's the command that will always be executed when the container starts.
ENTRYPOINT ["executable"]	
ENTRYPOINT ["python3"]


# Specifies the default argument for the entry point, which runs app.py.
# app.py: This is the parameter to the python3 executable.
# The CMD provides the default arguments for the ENTRYPOINT executable. 
# In this case, app.py is passed as an argument to python3, meaning that the container will run python3 app.py by default.
CMD ["app.py"]

# CMD ["executable","param1","param2"]
# Specifies the default command to run when the container/application starts.
# No, a Dockerfile cannot have multiple CMD instructions that are executed simultaneously. Only one CMD instruction is allowed 
# in a Dockerfile, and if there are multiple CMD instructions, only the last one will take effect. 
# The CMD provides the default command that will be executed when a container is started from the image.
# Only one CMD instruction can be used; if multiple are specified, the last one takes effect.

# CMD npm start                         # ENTRYPOINT [ "npm" ] CMD [ "start" ]
# CMD ["python3", "app.py"] 
# CMD ["echo", "Hello, sweetheart"]     # ENTRYPOINT [ "echo" ] CMD [ "Hello Sweetheart" ]               

# Option 1: Use shell form (sh -c)
CMD ["sh", "-c", "npm start && python3 app.py && echo 'Hello, sweetheart' && python3 app.py"]

# Option 2: Combine commands into an entrypoint script
# You can also create a shell script (entrypoint.sh), copy it into the container, and use it as the CMD:

#!/bin/sh
npm start;  python3 app.py; echo "Hello, sweetheart"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]

COPY run_commands.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/run_commands.sh
CMD ["/usr/local/bin/run_commands.sh"]

# Set the user to run the application (non-root for security)
# RUN useradd -m appuser
USER appuser

# Add a health check to monitor the application's status
# Defines a command to check the health of the application, ensuring it is running properly.
HEALTHCHECK --interval=30s CMD curl -f http://localhost:80/ || exit 1

# Allows the default shell used for the shell form of commands to be overridden.
# Changing the default shell to PowerShell in Windows container
SHELL ["executable", "parameters"]
SHELL ["powershell", "-command"]
