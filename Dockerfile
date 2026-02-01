FROM fedora:43

# 1. Install System Dependencies
RUN dnf group install -y development-tools \
    && dnf install -y \
    openssh-server sudo curl git vim htop \
    python3 python3-pip python3-virtualenv \
    pkg-config openssl-devel \
    zsh screen glibc-langpack-en unzip procps-ng \
    # Chromium/Playwright dependencies for Fedora
    alsa-lib atk at-spi2-atk cups-libs \
    dbus-libs libdrm mesa-libgbm gtk3 nspr nss \
    pango libXcomposite libXdamage libXfixes \
    libxkbcommon libXrandr xorg-x11-server-Xvfb \
    # Vulkan/wgpu support for Intel iGPU
    mesa-vulkan-drivers vulkan-tools vulkan-loader \
    && dnf clean all

# 2. Setup Locale
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 3. Create 'evolve' user with UID 1000 and add to video/render groups for GPU access
RUN useradd -m -u 1000 -s /bin/zsh -G video,render evolve \
    && echo "evolve ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. SSH Configuration (port and password auth handled in entrypoint.sh)
RUN mkdir -p /var/run/sshd /run/sshd

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

