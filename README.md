# Agendise - AI Agent Development Environment

A persistent, Dockerized Fedora 43 environment for AI agents, accessible via SSH. Features resource limits, sparse image storage, host networking, and pre-installed development tools.

**Default Password**: `evolve@NAS!`

## Pre-installed Tools

On first boot, the entrypoint automatically installs:

- **Oh-My-Zsh** — Enhanced shell experience
- **Rust** — Via rustup (auto-updates on boot)
- **Bun** — JavaScript runtime (auto-updates on boot)
- **Homebrew** — Package manager with:
  - `node`, `codex`, `gemini-cli`, `helix`, `dufs`, `uv`, `zellij`
- **NPM Global Packages**:
  - `openclaw`, `agent-browser`
- **agent-browser** — Browser automation with Chromium

## Resource Limits

| Resource | Limit |
|----------|-------|
| CPU | 8 cores |
| RAM | 8 GB |
| Storage | 512 GB (sparse image) |

## Configuration

The `evolve` user has:

- Passwordless sudo (`NOPASSWD:ALL`)
- Git configured (`evolve` / `evolve@reify.ing`)
- SSH key auto-generated (printed in logs for GitHub)

## Project Structure

```
├── Dockerfile         # Fedora 43 image with system deps
├── docker-compose.yml # Container orchestration
├── entrypoint.sh      # Boot script (tool installation, updates)
└── agent_docs/        # Files copied to ~/
    └── README.md      # Agent instructions
```

## Network

Uses **host network mode** — container shares the host's network stack directly. Use port 18888 for SSH.

- Container can access host services via `localhost`
- No port mapping needed; ports bind directly to host

## Commands

Manage the container using [just](https://github.com/casey/just):

| Command | Description |
|---------|-------------|
| `just setup` | Initial setup — creates sparse image, mounts storage, builds & starts container |
| `just start` | Mount storage and start container |
| `just stop` | Stop container |
| `just restart` | Restart container |
| `just restart-clean` | Full reset — recreates sparse image and rebuilds container |
| `just logs` | Follow container logs |
| `just ssh` | SSH into container (auto-skips host key check) |
| `just status` | Show container status and storage usage |

## Persistence

Storage is a sparse image mounted at `/mnt/agent_storage` on the host:

- Location: `/opt/agent/storage.img`
- Add to `/etc/fstab` for auto-mount: `/opt/agent/storage.img /mnt/agent_storage ext4 loop 0 0`
