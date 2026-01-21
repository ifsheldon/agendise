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

# 3.1 Install uv (Python dependency manager) globally
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# 3.2 Install Homebrew
# Create the directory for Homebrew and give ownership to 'evolve'
RUN mkdir -p /home/linuxbrew/.linuxbrew \
    && chown -R evolve:evolve /home/linuxbrew/.linuxbrew
# Install Homebrew as 'evolve'
RUN su - evolve -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
# Add Homebrew to system-wide PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# 4. SSH Configuration
RUN mkdir /var/run/sshd
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 5. Copy Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

