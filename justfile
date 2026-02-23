# Justfile for managing the agent container with sparse image storage

# Configuration
STORAGE_IMAGE := "/volume1/agent/storage2.img"
MOUNT_POINT := "/mnt/agent_storage2"
STORAGE_SIZE := "512G"

# Start the container (mount storage first if needed)
start:
    @echo "Mounting storage..."
    sudo mkdir -p {{MOUNT_POINT}}
    sudo mount -o loop {{STORAGE_IMAGE}} {{MOUNT_POINT}} 2>/dev/null || true
    @echo "Starting container..."
    sudo docker compose up -d

# Stop the container
stop:
    @echo "Stopping container..."
    sudo docker compose down

# Restart the container
restart:
    @echo "Restarting container..."
    sudo docker compose restart

# Full clean restart: recreate sparse image and restart container
restart-clean:
    @echo "Stopping container..."
    sudo docker compose down || true
    @echo "Unmounting storage..."
    sudo umount {{MOUNT_POINT}} 2>/dev/null || true
    @echo "Removing old sparse image..."
    sudo rm -f {{STORAGE_IMAGE}}
    @echo "Creating new sparse image ({{STORAGE_SIZE}})..."
    sudo mkdir -p $(dirname {{STORAGE_IMAGE}})
    sudo truncate -s {{STORAGE_SIZE}} {{STORAGE_IMAGE}}
    sudo mkfs.ext4 -F {{STORAGE_IMAGE}}
    @echo "Mounting storage..."
    sudo mkdir -p {{MOUNT_POINT}}
    sudo mount -o loop {{STORAGE_IMAGE}} {{MOUNT_POINT}}
    sudo chown 1000:1000 {{MOUNT_POINT}}
    @echo "Starting container..."
    sudo docker compose up -d --build
    @echo "Done! Container is running with fresh storage."

# Show container logs
logs:
    sudo docker compose logs -f

# SSH into the container (skip host key checking since container rebuilds change keys)
ssh:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 18889 evolve@localhost

# Show container status
status:
    sudo docker compose ps
    @echo ""
    @echo "Storage usage:"
    df -h {{MOUNT_POINT}} 2>/dev/null || echo "Storage not mounted"

# Initial setup (run once on new host)
setup:
    @echo "Creating sparse image ({{STORAGE_SIZE}})..."
    sudo mkdir -p $(dirname {{STORAGE_IMAGE}})
    sudo truncate -s {{STORAGE_SIZE}} {{STORAGE_IMAGE}}
    sudo mkfs.ext4 -F {{STORAGE_IMAGE}}
    @echo "Mounting storage..."
    sudo mkdir -p {{MOUNT_POINT}}
    sudo mount -o loop {{STORAGE_IMAGE}} {{MOUNT_POINT}}
    sudo chown 1000:1000 {{MOUNT_POINT}}
    @echo "Building and starting container..."
    sudo docker compose up -d --build
    @echo ""
    @echo "Setup complete! Add this to /etc/fstab for auto-mount on boot:"
    @echo "{{STORAGE_IMAGE}} {{MOUNT_POINT}} ext4 loop 0 0"
