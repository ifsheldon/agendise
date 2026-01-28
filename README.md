# Agendise - AI Agent Development Environment

A persistent, Dockerized Ubuntu 24.04 environment for AI agents, accessible via SSH. Features resource limits, sparse image storage, and pre-installed development tools.

**Default Password**: `evolve@NAS!`

## Pre-installed Tools

On first boot, the entrypoint automatically installs:

- **Oh-My-Zsh** — Enhanced shell experience
- **Rust** — Via rustup (auto-updates on boot)
- **Bun** — JavaScript runtime (auto-updates on boot)
- **Homebrew** — Package manager with:
  - `node`, `codex`, `gemini-cli`, `helix`, `dufs`, `uv`
- **NPM Global Packages**:
  - `moltbot`, `agent-browser`
- **agent-browser** — Browser automation with Chromium

## Resource Limits

| Resource | Limit |
|----------|-------|
| CPU | 8 cores |
| RAM | 16 GB |
| Storage | 512 GB (sparse image) |

## Configuration

The `evolve` user has:

- Passwordless sudo (`NOPASSWD:ALL`)
- Git configured (`evolve` / `evolve@reify.ing`)
- SSH key auto-generated (printed in logs for GitHub)

## Project Structure

```
├── Dockerfile        # Ubuntu 24.04 image with system deps
├── docker-compose.yml # Container orchestration
├── entrypoint.sh     # Boot script (tool installation, updates)
└── agent_docs/       # Files copied to ~/
    └── README.md     # Agent instructions
```

## Ports

| Host | Container | Purpose |
|------|-----------|---------|
| 17788 | 22 | SSH |
| 17790-17799 | 17790-17799 | Dev servers |

## Persistence

Storage is a sparse image mounted at `/mnt/agent_storage` on the host:

- Location: `/opt/agent/storage.img`
- Add to `/etc/fstab` for auto-mount: `/opt/agent/storage.img /mnt/agent_storage ext4 loop 0 0`
