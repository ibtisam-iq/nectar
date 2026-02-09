## Where Should USER appuser Be Placed?

`USER appuser` should be placed after creating the user but before running the application. However, we must be careful when copying files because:

- If we switch to `appuser` before copying files, we might run into permission issues (since the user doesn’t own the `/usr/src/app` directory yet).
- If we copy files before setting the user, the files will be owned by `root`, and `appuser` might not have the necessary permissions.

### Corrected Dockerfile

```dockerfile
# Stage 1: Build the application
FROM node:18-alpine AS build

# Set environment variable for the application home directory
ENV APP_HOME=/usr/src/app

# Set the working directory inside the container
WORKDIR $APP_HOME

# Copy package.json & package-lock.json (if exists)
COPY package*.json ./

# Install dependencies (production only)
RUN npm ci --only=production

# Copy the rest of the application code
COPY . .

# Stage 2: Run the application in a smaller image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /usr/src/app

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy files from the build stage **before switching users**
COPY --from=build /usr/src/app ./

# Change ownership to appuser (to prevent permission issues)
RUN chown -R appuser:appgroup /usr/src/app

# Now switch to non-root user
USER appuser

# Expose port 3000 for the app
EXPOSE 3000

# Start the application
CMD ["node", "app.js"]
```

### Why This Fix?

✅ Files are copied as `root` (avoids permission errors).
✅ Ownership is changed to `appuser` before switching users.
✅ Ensures the application runs without permission issues.


