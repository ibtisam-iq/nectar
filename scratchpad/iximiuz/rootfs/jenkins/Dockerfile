# syntax=docker/dockerfile:1.4

# Jenkins LTS Custom Rootfs for iximiuz Labs
# Base: Official iximiuz Labs Ubuntu 24.04 rootfs
# Java: OpenJDK 21
# Jenkins: LTS (latest stable)
# Nginx: Reverse proxy pre-configured

FROM ghcr.io/iximiuz/labs/rootfs:ubuntu-24-04

USER root

# Build arguments for flexibility
ARG JENKINS_VERSION=lts
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=1000
ARG JENKINS_PORT=8080
ARG BUILD_DATE
ARG VCS_REF

# OCI image labels
LABEL org.opencontainers.image.title="SilverStack Jenkins Rootfs" \
      org.opencontainers.image.description="Jenkins LTS with Java 21, Nginx, and systemd for iximiuz Labs" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.base.name="ghcr.io/iximiuz/labs/rootfs:ubuntu-24-04" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://github.com/ibtisam-iq/silver-stack" \
      org.opencontainers.image.source="https://github.com/ibtisam-iq/silver-stack" \
      org.opencontainers.image.documentation="https://blog.ibtisam-iq.com" \
      org.opencontainers.image.vendor="Ibtisam IQ" \
      org.opencontainers.image.authors="Muhammad Ibtisam <contact@ibtisam-iq.com>"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    JENKINS_HOME=/var/lib/jenkins \
    JENKINS_PORT=${JENKINS_PORT} \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    PATH="/usr/lib/jvm/java-21-openjdk-amd64/bin:${PATH}" \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install base system packages and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Essential tools
        curl \
        wget \
        git \
        vim \
        nano \
        gnupg \
        ca-certificates \
        software-properties-common \
        apt-transport-https \
        lsb-release \
        # User and permissions
        sudo \
        # Init system
        systemd \
        systemd-sysv \
        # Web server
        nginx \
        # SSH server
        openssh-server \
        # Utilities
        net-tools \
        iputils-ping \
        dnsutils \
        netcat-openbsd \
        htop \
        tree \
        # Locales
        locales && \
    # Generate locale
    locale-gen en_US.UTF-8 && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy installation scripts
COPY scripts/ /opt/setup-scripts/
RUN chmod +x /opt/setup-scripts/*.sh

# Install Jenkins using script
RUN /opt/setup-scripts/install-jenkins.sh ${JENKINS_VERSION} ${JENKINS_PORT}

# Copy configuration files
COPY configs/nginx.conf /etc/nginx/sites-available/jenkins
COPY configs/jenkins.service /etc/systemd/system/jenkins.service
COPY configs/sshd_config /etc/ssh/sshd_config
COPY configs/sudoers.d/jenkins-user /etc/sudoers.d/jenkins-user
COPY configs/profile.d/jenkins-env.sh /etc/profile.d/jenkins-env.sh

# Configure Nginx
RUN /opt/setup-scripts/configure-nginx.sh

# Setup user account
RUN /opt/setup-scripts/setup-user.sh ${USERNAME} ${USER_UID} ${USER_GID}

# Configure SSH server
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Enable systemd services
RUN systemctl enable ssh && \
    systemctl enable nginx && \
    systemctl enable jenkins

# Verify installations and configurations
ENV INTERACTIVE_USER=${USERNAME}
RUN /opt/setup-scripts/healthcheck.sh

# Create maintenance directory for logs and backups
RUN mkdir -p /var/log/jenkins-setup && \
    chown jenkins:jenkins /var/log/jenkins-setup

# Install cloudflared for tunneling
RUN /opt/setup-scripts/install-cloudflared.sh

# Expose ports (informational - iximiuz Labs handles actual networking)
EXPOSE 22 80 ${JENKINS_PORT}

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy custom shell wrapper (shows only our message on login)
COPY scripts/custom-shell.sh /usr/local/bin/custom-shell.sh
RUN chmod +x /usr/local/bin/custom-shell.sh && \
    echo "/usr/local/bin/custom-shell.sh" >> /etc/shells && \
    usermod -s /usr/local/bin/custom-shell.sh "${USERNAME}"

# Entrypoint for initialization
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command: systemd init
CMD ["/lib/systemd/systemd"]
