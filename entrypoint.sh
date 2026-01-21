#!/bin/bash
set -e

USER_NAME="evolve"
USER_PASS=${USER_PASSWORD:-evolve@NAS!}

echo "Starting up..."

# 1. Set Password (every boot, in case env var changes)
echo "$USER_NAME:$USER_PASS" | chpasswd

# 2. Fix Home Permissions
# (Crucial because Docker volume mounts often mess up ownership)
chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME"

# 3. Install Rust (if missing from persistent home)
if [ ! -d "/home/$USER_NAME/.cargo" ]; then
    echo "Rust not found. Installing..."
    su - "$USER_NAME" -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
else
    echo "Rust is already installed."
fi

# 4. Install Bun (if missing from persistent home)
if [ ! -d "/home/$USER_NAME/.bun" ]; then
    echo "Bun not found. Installing..."
    su - "$USER_NAME" -c "curl -fsSL https://bun.sh/install | bash"
else
    echo "Bun is already installed."
fi

# 5. Generate Host Keys
ssh-keygen -A

echo "Ready! SSH listening on port 22..."
exec "$@"

