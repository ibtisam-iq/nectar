### Docker Port Mapping

In Docker, mapping a host port to a container port is a common practice. The host machine receives external requests, while the container provides an isolated environment where the application runs. The mapping ensures external users can access services running inside the container through the host.

#### Example:
When you specify `-p 8080:80`, Docker forwards incoming traffic from **port 8080** on the **host** to **port 80** inside the **container**. 

This configuration allows:
- The service inside the container (listening on port 80) to be accessed via the host's port 8080.

#### Port Binding and Protocol Separation:
A container can bind successfully even if a port (e.g., 5353) is already in use by another service, provided:
- The service uses a different protocol (e.g., UDP vs. TCP).
- Ports can be shared between different protocols (e.g., TCP and UDP) on the same port number without conflict.

For instance:
- A service using **port 5353 for UDP** does not block Docker from binding **port 5353 for TCP**, as the protocols are distinct and separate.

