# FROM <image>[:<tag>]
# Specifies the base image for subsequent instructions in the Dockerfile.
FROM alpine

# LABEL <key>=<value>
# Adds metadata to the image. This is often used for versioning and author details.
LABEL version="1.0" description="My application" maintainer="mylove@ibtisam.com"

# ARG <name>[=<default>]
# Defines a build-time variable, which can be overridden with --build-arg during the build process.
# docker build --build-arg PORT=4000 -t myapp .
# The port is now changed to 4000 from 8000.
# ARG values are only available during the image build and not at runtime.
ARG VERSION=1.0
ARG PORT=8000

# ENV <key>=<value>
# Sets environment variables, available during runtime. These variables are used by the application inside the container.
ENV APP_ENV=production
ENV PORT=8000

# WORKDIR <path>
# Sets the working directory for subsequent instructions like RUN, CMD, ENTRYPOINT, COPY, and ADD.
# Set the working directory in the container where the application code will reside.
WORKDIR /app

# COPY <src> <dest>
# Copies files from the host system to the container at the specified destination.
COPY . /app

# ADD <src> <dest>
# Similar to COPY but also supports extracting TAR files and downloading remote URLs.
ADD myapp.tar.gz /app/

# RUN <command>
# Executes commands (to install necessary packages or dependencies) in the container, creating a new layer for each instruction.
# Don't forget to run `apt-get update` if you're installing any package, also install a package with `-y` flag.
RUN echo "Hey sweetheart" 
RUN echo "This is Ibtisam."
RUN echo $(pwd)
RUN touch file.txt
RUN apt-get update && apt-get install -y python3
RUN cd /tmp && touch abc.txt

# Consolidating multiple RUN instructions into a single layer for better image optimization.
RUN echo "Hey sweetheart" && echo "This is Ibtisam." && echo $(pwd) && touch file.txt && apt-get update && cd /tmp && touch abc.txt

# EXPOSE <port>
# Documents the ports that the application will listen on. This does not publish the port; use -p during `docker run` to map the port.
# It is a way to declare which ports your application uses, and it works hand-in-hand with the -p option when running container to establish actual port mapping.
# Not mentioning EXPOSE during the image build doesn’t prevent the container from being able to listen on a port at runtime, 
# the image can still listen on ports if you map them during docker run.
EXPOSE 8000
EXPOSE $PORT

# VOLUME <path>
# Creates a mount point for external storage, allowing data persistence.
VOLUME ["/app/data"]

# ENTRYPOINT ["executable"]
# Defines the default executable that always runs when the container starts.
ENTRYPOINT ["python3"]

# CMD ["param1", "param2"]
# Specifies default arguments for ENTRYPOINT or the default command to run if ENTRYPOINT is not set.
 
CMD ["app.py"]

CMD ["sh", "-c", "python app.py"]
# This form runs your script via a shell — but that’s usually not needed unless:
# You want shell features like variable substitution, pipes, or && operators.
# Example: CMD ["sh", "-c", "echo $MY_ENV && python app.py"]
# So, using ["sh", "-c", "app.py"] is unnecessary and inefficient unless you actually need a shell.


# A Dockerfile cannot have multiple CMD instructions that are executed simultaneously. Only one CMD instruction is allowed in a Dockerfile, 
# and if there are multiple CMD instructions, only the last one will take effect.

# Alternative CMD examples:
# Example 1: Run multiple commands using shell form.
CMD ["sh", "-c", "npm start && python3 app.py && echo 'Hello, sweetheart'"]

# Example 2: Use an entrypoint script.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]

# Set a non-root user to improve container security.
USER appuser

# HEALTHCHECK <options> CMD <command>
# Monitors the application’s health status by periodically running the specified command.
HEALTHCHECK --interval=30s CMD curl -f http://localhost:80/ || exit 1

# SHELL ["executable", "parameters"]
# Overrides the default shell for executing commands. Useful for Windows containers or custom shells.
SHELL ["powershell", "-command"]
