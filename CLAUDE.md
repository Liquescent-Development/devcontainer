# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Liquescent Development DevContainer configuration - a secure, polyglot development environment with network isolation and comprehensive tooling support. The container supports Node.js, Go, Rust, .NET, and Python development with network isolation and specific allowlisted domains for security purposes.

## Architecture

### Authentication & Secrets Management

The devcontainer uses a dual approach for 1Password integration:

1. **SSH Operations (Git/Commit Signing)**: Uses SSH agent forwarding from the host
   - Automatically detects and forwards the host's SSH agent (including 1Password SSH agent)
   - No additional authentication needed in the container
   - Handles both repository access and commit signing

2. **Environment Variables/Secrets**: Uses 1Password CLI with Service Accounts
   - **Primary (Auto-creation)**: Set `OP_CREATE_SERVICE_ACCOUNT=true` to auto-generate a token
     - Requires 1Password CLI on host and being signed in
     - Configure with: `OP_SA_EXPIRES_IN`, `OP_SA_VAULTS`, `OP_SA_NAME`
     - Token is created at container startup and saved for the container's lifetime
   - **Manual Service Account**: Set `OP_SERVICE_ACCOUNT_TOKEN` directly
   - **Connect Server (for larger teams)**: Use `OP_CONNECT_HOST` and `OP_CONNECT_TOKEN`
   - Use `op run --env-file` to inject secrets into applications
   - Example: `op run --env-file=prod.env -- python app.py`

### Repository Structure

This repository follows the Dev Container template specification:
- **Templates** in `src/<template-id>/` - Self-contained, ready-to-use templates
- **Image sources** in `image-sources/<template-id>/` - Dockerfiles for building pre-built images
- Templates use pre-built images from GitHub Container Registry for fast startup
- The `liquescent-devcontainer` template is our primary offering

### Core Components

1. **DevContainer Configuration** (`src/liquescent-devcontainer/.devcontainer/devcontainer.json`)
   - Configures a complete polyglot development environment
   - Uses `containerEnv` for static configuration (NODE_OPTIONS, paths)
   - Uses `remoteEnv` for runtime configuration (1Password tokens, custom domains)
   - Parallel execution of setup scripts via `postCreateCommand` object
   - Mounts Claude configuration directory and bash history
   - Installs VS Code extensions for JavaScript/TypeScript development

2. **Dockerfile** (`image-sources/liquescent-devcontainer/Dockerfile`)
   - Base image: Node.js 20 with multi-language support
   - **Go 1.25.0**: Official installation with GOPATH configured
   - **Rust (stable)**: Installed via rustup with cargo tools (cargo-watch, cargo-edit, cargo-audit, cargo-outdated)
   - **.NET SDK 8.0**: Full development support with telemetry disabled
   - **Python 3**: With pip, venv, and essential tools (pipenv, poetry, black, pylint, pytest, requests, ipython)
   - **Shell configuration**: oh-my-zsh with language-specific plugins and PATH configurations
   - Installs development tools (git, zsh, fzf, etc.)
   - Installs Claude Code CLI globally
   - Configures non-root user with sudo access for firewall script

3. **Firewall Script** (`image-sources/liquescent-devcontainer/scripts/init-firewall.sh`)
   - Implements network isolation using iptables and ipset
   - Allows connections only to:
     - GitHub (dynamically fetched IP ranges)
     - npm registry
     - Anthropic API endpoints
     - Host network (for local development)
   - Preserves Docker's internal DNS resolution
   - Verifies firewall configuration after setup

## Using the Template

To use this devcontainer template in your project:

1. Copy the entire `src/liquescent-devcontainer/.devcontainer/` folder to your project root
2. Customize `.devcontainer/.env` with your settings
3. Open in VS Code with the Dev Containers extension
4. The container will build from the included Dockerfile and initialize automatically

## Security Model

The container operates with restricted network access:
- Outbound connections are limited to allowlisted domains via ipset
- DNS queries are allowed for domain resolution
- SSH connections are permitted
- SOCKS5 proxy connections to host machine on port 1080 are allowed
- All other network traffic is blocked by default

## Using SOCKS5 Proxy

The devcontainer can access the host machine's SOCKS5 proxy running on port 1080:

```bash
# Using curl with SOCKS5 proxy
curl https://example.com --socks5 host.docker.internal:1080

# Using git with SOCKS5 proxy
git config --global http.proxy socks5://host.docker.internal:1080
git config --global https.proxy socks5://host.docker.internal:1080

# To unset git proxy
git config --global --unset http.proxy
git config --global --unset https.proxy
```

The host machine is accessible via the hostname `host.docker.internal` from within the container.