FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install System Dependencies
RUN apt-get update && apt-get install -y \
    openssh-server sudo curl git vim htop \
    build-essential python3 python3-pip python3-venv \
    pkg-config libssl-dev \
    zsh screen locales unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Setup Locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 3. FIX: Rename existing 'ubuntu' user (UID 1000) to 'evolve'
# Ubuntu 24.04 base image comes with a user 'ubuntu' (UID 1000).
# We rename it to 'evolve' and change its home directory.
RUN usermod -l evolve -d /home/evolve -m ubuntu \
    && groupmod -n evolve ubuntu \
    && echo "evolve ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && chsh -s /bin/zsh evolve

# 4. SSH Configuration
RUN mkdir /var/run/sshd
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 5. Stage files for copying to home at runtime (after volume mount)
RUN mkdir -p /opt/agent_init/setup_files
COPY --chown=evolve:evolve Dockerfile README.md docker-compose.yml entrypoint.sh /opt/agent_init/setup_files/
COPY --chown=evolve:evolve agent_docs/ /opt/agent_init/

# 6. Copy Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

