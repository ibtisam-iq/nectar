# ENTRYPOINT and CMD

## ENTRYPOINT

The `ENTRYPOINT` directive in a Dockerfile is used to define the executable that always runs when the container starts. This ensures consistent behavior for the container's main process.

- **Purpose:** Sets the command to execute when the container starts.
- **Behavior:** The `ENTRYPOINT` command is mandatory and always executed.
- **Example:**
  ```dockerfile
  # Define the entry point for the container
  ENTRYPOINT ["executable"]

  # Example: Always run the Python3 interpreter when the container starts
  ENTRYPOINT ["python3"]
  ```

## CMD

The `CMD` directive specifies the default arguments or commands to pass to the `ENTRYPOINT`. If `ENTRYPOINT` is not defined, `CMD` directly runs as the container's command.

- **Purpose:** Defines the default command or arguments for the container's executable.
- **Behavior:** Only one `CMD` instruction is allowed in a Dockerfile. If multiple are present, only the last one takes effect.
- **Example:**
  ```dockerfile
  # Specifies the default argument for ENTRYPOINT or the default command to execute
  CMD ["app.py"]

  # Run specific commands
  CMD ["executable", "param1", "param2"]

  # Example with Python3 and a script
  ENTRYPOINT ["python3"]
  CMD ["app.py"]

  # Another example with npm start
  ENTRYPOINT ["npm"]
  CMD ["start"]
  ```

---

## Notes

### 1. ENTRYPOINT and CMD Together

- **ENTRYPOINT** specifies the executable.
- **CMD** provides the arguments for the executable.

**Example:**
```dockerfile
ENTRYPOINT ["echo"]
CMD ["Hello, sweetheart"]
```
When the container starts, it will execute:
```bash
echo Hello, sweetheart
```

### 2. Multiple CMDs

- A Dockerfile cannot have multiple `CMD` instructions executed simultaneously.
- Only the last `CMD` instruction will take effect.

---

## Combining Commands in CMD

### Option 1: Use Shell Form

You can use the shell form of `CMD` to chain multiple commands:
```dockerfile
CMD ["sh", "-c", "npm start && python3 app.py && echo 'Hello, sweetheart'"]
```

### Option 2: Use an Entrypoint Script

You can create a shell script to handle multiple commands, copy it into the container, and set it as the `CMD`:

1. **Create the script:**
```bash
# entrypoint.sh
npm start
python3 app.py
echo "Hello, sweetheart"
```

2. **Use the script in the Dockerfile:**
```dockerfile
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
```

3. Alternatively, use a different script:
```dockerfile
COPY run_commands.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/run_commands.sh
CMD ["/usr/local/bin/run_commands.sh"]
```

This guide provides a comprehensive overview of the `ENTRYPOINT` and `CMD` directives in Dockerfiles, including their purposes, behaviors, and examples of how to use them effectively.
```