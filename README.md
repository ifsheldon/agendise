# Ubuntu SSH Development Environment

This project sets up a persistent, Dockerized Ubuntu 24.04 development environment accessible via SSH. It is designed to provide a consistent workspace with pre-installed tools and persistence.

## Project Structure

- **`Dockerfile`**: Builds the image based on Ubuntu 24.04. It installs system dependencies (Git, Vim, Python, Zsh), renames the default user to `evolve`, and configures the OpenSSH server.
- **`docker-compose.yml`**: Orchestrates the `ubuntu-ssh` container.
  - **SSH Access**: Host port `17788` -> Container port `22`.
  - **Dev Ports**: Host ports `17790-17799` -> Container ports `17790-17799` (for running web servers, etc.).
  - **Persistence**: A named volume `ubuntu_home` persists the `/home/evolve` directory.
- **`entrypoint.sh`**: The startup script that ensures the environment is ready on every boot.
  - Sets/Resets the user password.
  - Fixes file permissions for the persistent home directory.
  - Auto-installs **Rust** and **Bun** if they are missing.
  - Starts the SSH daemon.

## Usage

### Starting the Container

To start the environment in the background:

```bash
docker-compose up -d
```

### Connecting via SSH

You can connect to the container using the configured port (`17788`) and user (`evolve`).

```bash
ssh -p 17788 evolve@localhost
```

- **Default Password**: `evolve@NAS!` (defined in `docker-compose.yml`)

### Development

- **Language Support**: Python 3 is pre-installed. Rust and Bun are installed automatically upon first startup.
- **Port Forwarding**: Applications running on ports `17790` through `17799` inside the container are accessible on the same ports on your host machine.
