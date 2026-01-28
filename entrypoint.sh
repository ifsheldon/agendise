#!/bin/bash
set -e

USER_NAME="evolve"
USER_PASS=${USER_PASSWORD:-evolve@NAS!}

# Homebrew packages to install (add more here)
BREW_PACKAGES=(
    node
    codex
    gemini-cli
    helix
    dufs
    uv
)

# NPM packages to install globally (add more here)
NPM_PACKAGES=(
    moltbot@latest
    agent-browser
)

echo "Starting up..."

# 1. Set Password (every boot, in case env var changes)
echo "$USER_NAME:$USER_PASS" | chpasswd

# 2. Fix Home Permissions
# (Crucial because Docker volume mounts often mess up ownership)
chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME"

# 2.5 Initialize home directory (copy staged files if not present)
INIT_DIR="/opt/agent_init"
HOME_DIR="/home/$USER_NAME"
if [ -d "$INIT_DIR" ]; then
    # Copy setup_files if not present
    if [ ! -d "$HOME_DIR/setup_files" ]; then
        echo "Copying setup_files..."
        cp -r "$INIT_DIR/setup_files" "$HOME_DIR/"
    fi
    # Copy README.md if not present
    if [ ! -f "$HOME_DIR/README.md" ] && [ -f "$INIT_DIR/README.md" ]; then
        echo "Copying README.md..."
        cp "$INIT_DIR/README.md" "$HOME_DIR/"
    fi
    # Create NAME, MEMORIES, SKILLS if not present
    [ ! -f "$HOME_DIR/NAME" ] && touch "$HOME_DIR/NAME"
    [ ! -d "$HOME_DIR/MEMORIES" ] && mkdir -p "$HOME_DIR/MEMORIES"
    [ ! -d "$HOME_DIR/SKILLS" ] && mkdir -p "$HOME_DIR/SKILLS"
    # Fix ownership
    chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR"
fi

# 3. Configure Git
echo "Configuring Git..."
su - "$USER_NAME" -c "git config --global user.name '$USER_NAME'"
su - "$USER_NAME" -c "git config --global user.email '$USER_NAME@reify.ing'"
su - "$USER_NAME" -c "git config --global pull.rebase false"

# 4. Generate SSH key for GitHub (if missing)
SSH_KEY="/home/$USER_NAME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo "SSH key not found. Generating..."
    su - "$USER_NAME" -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    su - "$USER_NAME" -c "ssh-keygen -t ed25519 -C '$USER_NAME@reify.ing' -f ~/.ssh/id_ed25519 -N ''"
fi
echo ""
echo "=========================================="
echo "SSH Public Key (add to GitHub):"
echo "=========================================="
cat "${SSH_KEY}.pub"
echo "=========================================="
echo ""

# 5. Install Oh-My-Zsh (if missing from persistent home)
if [ ! -d "/home/$USER_NAME/.oh-my-zsh" ]; then
    echo "Oh-My-Zsh not found. Installing..."
    su - "$USER_NAME" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
else
    echo "Oh-My-Zsh is already installed."
fi

# 6. Install Rust (if missing from persistent home)
if [ ! -d "/home/$USER_NAME/.cargo" ]; then
    echo "Rust not found. Installing..."
    su - "$USER_NAME" -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
else
    echo "Rust is already installed. Updating..."
    su - "$USER_NAME" -c "source ~/.cargo/env && rustup update stable"
fi

# 7. Install Bun (if missing from persistent home)
if [ ! -d "/home/$USER_NAME/.bun" ]; then
    echo "Bun not found. Installing..."
    su - "$USER_NAME" -c "curl -fsSL https://bun.sh/install | bash"
else
    echo "Bun is already installed. Upgrading..."
    su - "$USER_NAME" -c "~/.bun/bin/bun upgrade"
fi

# 8. Install Homebrew (if missing from persistent home)
if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
    echo "Homebrew not found. Installing..."
    # Create linuxbrew directory with proper permissions
    mkdir -p /home/linuxbrew
    chown "$USER_NAME:$USER_NAME" /home/linuxbrew
    # Install Homebrew non-interactively
    su - "$USER_NAME" -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    # Install packages with brew
    echo "Installing Homebrew packages: ${BREW_PACKAGES[*]}..."
    su - "$USER_NAME" -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew install '"${BREW_PACKAGES[*]}"
    # Add brew to .zshrc for future sessions
    BREW_SHELLENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    ZSHRC="/home/$USER_NAME/.zshrc"
    if ! grep -qF "$BREW_SHELLENV" "$ZSHRC" 2>/dev/null; then
        echo "Adding brew to .zshrc..."
        echo "" >> "$ZSHRC"
        echo "# Homebrew" >> "$ZSHRC"
        echo "$BREW_SHELLENV" >> "$ZSHRC"
        chown "$USER_NAME:$USER_NAME" "$ZSHRC"
    fi
else
    echo "Homebrew is already installed. Upgrading..."
    su - "$USER_NAME" -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew upgrade'
fi

# 9. Install/Update global NPM packages
if command -v /home/linuxbrew/.linuxbrew/bin/node &> /dev/null; then
    echo "Installing/Updating global NPM packages: ${NPM_PACKAGES[*]}..."
    for pkg in "${NPM_PACKAGES[@]}"; do
        su - "$USER_NAME" -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && npm install -g '"$pkg"
    done
else
    echo "Node.js not found, skipping NPM packages."
fi

# 10. Setup agent-browser (install Chromium + Linux deps)
if command -v /home/linuxbrew/.linuxbrew/bin/node &> /dev/null; then
    echo "Setting up agent-browser..."
    su - "$USER_NAME" -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && agent-browser install --with-deps' || echo "agent-browser setup skipped or failed"
fi

# 11. Generate Host Keys
ssh-keygen -A

echo "Ready! SSH listening on port 22..."
exec "$@"

