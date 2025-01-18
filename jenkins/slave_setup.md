# Adding a Slave Node to Jenkins

This guide details the steps to configure a slave node for Jenkins. Follow the instructions below:

---

## Prerequisites

1. Jenkins must be installed and running on the master machine.
2. Ensure network connectivity between the master and the slave.
3. Verify SSH access is possible from the master to the slave.

---

## Steps to Configure the Slave Node

### 1. On the Slave Machine

1. **Install Java**  
   Jenkins slave requires Java to run. Install it using the following command:  
   ```bash
   apt install openjdk-17-jre-headless
   ```

2. **Create a Workspace Directory**  
   Create a directory to serve as the Jenkins workspace on the slave machine:  
   ```bash
   mkdir /home/ibtisam/slave-workplace
   ```
![](./images/Slave%20Label.png)
---

### 2. On the Master Machine

1. **Switch to the Jenkins User**  
   To perform the setup, switch to the Jenkins user:  
   ```bash
   sudo su - jenkins
   ```

2. **Generate an SSH Key Pair**  
   Generate an SSH key pair to enable password-less authentication between the master and slave:  
   ```bash
   ssh-keygen -t ed25519 -C "jenkins@mint-dell"
   ```
   - Save the key pair as `/var/lib/jenkins/.ssh/id_ed25519`.

3. **Copy the Public Key to the Slave Machine**  
   Copy the public key to the slave machine to enable password-less SSH authentication:  
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519 ibtisam@192.168.1.16
   ```
   - This command adds the public key to the `~/.ssh/authorized_keys` file on the slave.  
   - Ensure that the permissions on the `~/.ssh` directory and `authorized_keys` file are correct:  
     ```bash
     chmod 700 ~/.ssh
     chmod 600 ~/.ssh/authorized_keys
     ```

4. **Test Password-less SSH Login**  
   Verify that the master can log in to the slave without a password:  
   ```bash
   ssh ibtisam@192.168.1.16
   ```
   - Ensure you can successfully log in without entering a password.

5. **Set SSH Credentials in Jenkins**  
   Add the SSH credentials in Jenkins to establish a connection to the slave:
   - **Username**: `ibtisam`  
   - **Private Key**: `/var/lib/jenkins/.ssh/id_ed25519`

![](./images/Slave%20Credentials.png)
---

### Summary

By following these steps, the Jenkins master will securely communicate with the slave over SSH, enabling distributed builds and improved resource utilization.

### Additional Notes

- If the slave node still cannot connect, ensure the SSH port (default: 22) is open and not blocked by a firewall.  
- Double-check the hostname or IP address in the `ssh` commands.

---

