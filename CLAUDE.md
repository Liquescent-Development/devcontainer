# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a development container configuration designed to provide a complete polyglot development environment for Claude Code. The container supports Node.js, Go, Rust, .NET, and Python development with network isolation and specific allowlisted domains for security purposes.

## Architecture

### Core Components

1. **DevContainer Configuration** (`.devcontainer/devcontainer.json`)
   - Configures a complete polyglot development environment
   - Mounts Claude configuration directory and bash history
   - Installs VS Code extensions for JavaScript/TypeScript development
   - Runs firewall initialization on container creation

2. **Dockerfile** (`.devcontainer/Dockerfile`)
   - Base image: Node.js 20 with multi-language support
   - **Go 1.25.0**: Official installation with GOPATH configured
   - **Rust (stable)**: Installed via rustup with cargo tools (cargo-watch, cargo-edit, cargo-audit, cargo-outdated)
   - **.NET SDK 8.0**: Full development support with telemetry disabled
   - **Python 3**: With pip, venv, and essential tools (pipenv, poetry, black, pylint, pytest, requests, ipython)
   - **Shell configuration**: oh-my-zsh with language-specific plugins and PATH configurations
   - Installs development tools (git, zsh, fzf, etc.)
   - Installs Claude Code CLI globally
   - Configures non-root user with sudo access for firewall script

3. **Firewall Script** (`.devcontainer/init-firewall.sh`)
   - Implements network isolation using iptables and ipset
   - Allows connections only to:
     - GitHub (dynamically fetched IP ranges)
     - npm registry
     - Anthropic API endpoints
     - Host network (for local development)
   - Preserves Docker's internal DNS resolution
   - Verifies firewall configuration after setup

## Development Commands

Since this is a devcontainer configuration project, there are no build/test commands. To use this devcontainer:

1. Open the project in VS Code with the Dev Containers extension
2. Reopen in container when prompted
3. The firewall will automatically initialize on container creation

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