```bash
# Docker `run` Command Use Cases

# The `docker run` command is used to create and start a container from a specified image. It is often the first step to interact with a containerized application.

# Basic Syntax:
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
# OPTIONS: Various flags to modify container behavior (e.g., -d, --name, --entrypoint).
# IMAGE: The image to use for creating the container.
# COMMAND: (Optional) The command to run inside the container.
# ARG: (Optional) Arguments for the specified command.

# Equivalent Commands:
docker container run is equivalent to:
docker container create + docker container start + docker container attach

# Key Concepts:
# CMD can be overridden when running the container.
# ENTRYPOINT cannot be overridden without using the --entrypoint flag.

# Use Case Examples:

# 1. Override ENTRYPOINT and CMD
docker run --name <container_name> --entrypoint sleep -d alpine infinity
# Explanation: This command sets the entrypoint to sleep and the argument to infinity, overriding the default entrypoint of the Alpine image.

# 2. Override ENTRYPOINT and CMD in Dockerfile
docker run --name <container_name> --entrypoint <entrypoint_command> nginx 10
# Explanation: This overrides both the ENTRYPOINT and CMD defined in the Dockerfile. For example, if the Dockerfile defined:
# ENTRYPOINT ["sleep"]
# CMD ["5"]
# Both ENTRYPOINT and CMD are overridden here.

# 3. Run and remove the container automatically on exit
docker container run --rm -d --name <container_name> REPOSITORY:v
# Explanation: Runs the container in detached mode and removes it automatically after it stops.

# 4. Run with a shell command
docker run -dit --name myfirstcon REPOSITORY:v /bin/sh
# Explanation: Runs the container with the command /bin/sh, allowing interaction with the shell.

# 5. Run with a custom command and arguments
docker run -dit --name myfirstcon REPOSITORY:v uname -a
# Explanation: Runs the container with the command uname and the argument -a to display system information.

# 6. Run with the sleep command
docker run -dit --name myfirstcon alpine sleep 10
# Explanation: Runs the container with the sleep command and the argument 10, making the container sleep for 10 seconds before stopping.

# 7. Run with a shell command to echo a message
docker run --name <container_name> alpine sh -c "echo hello"
# Explanation: Runs the container with the sh command and the argument -c "echo hello", which prints "hello" to the console.

# 8. Run with default command
docker run alpine ls -l
# Explanation: Runs the container with the ls -l command. By default, it lists the contents of the /root directory.

# 9. Run with custom mount
docker run --cap-add MAC_ADMIN ubuntu sleep 3600
# Explanation: Adds the MAC_ADMIN capability to the container and runs it for 3600 seconds (1 hour).

# 10. Run with capability drop
docker run --cap-drop KILL ubuntu
# Explanation: Drops the KILL capability from the container, restricting its ability to kill other processes.

# 11. Run with specific user
docker run --user=1000 ubuntu sleep 3600
# Explanation: Runs the container as the user with UID 1000.

# 12. Run with environment variable and bind mount
docker run -it -d --name <container_name> -e PORT=$MY_PORT -p 7600:$MY_PORT --mount type=bind,src=$PWD/src,dst=/app/src node:$MY_ENV
# Explanation: Runs the container interactively with environment variables, a port binding, and a bind mount.




```