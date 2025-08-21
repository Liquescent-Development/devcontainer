<div align="center">
  <img src="https://liquescent.dev/liquescent.png" alt="Liquescent Logo" width="400">
</div>

# Secure DevContainer Template

A comprehensive development container template that provides a consistent, secure, and isolated development environment using VS Code Dev Containers. This template implements network isolation with allowlisted domains to create a sandboxed environment suitable for secure development workflows.

## 🚀 Quick Start - Using as a Template

### Option 1: GitHub Template (Recommended)
1. Click the "Use this template" button on GitHub
2. Create a new repository from the template
3. Clone your new repository
4. Customize the configuration for your project needs
5. Open in VS Code and select "Reopen in Container"

### Option 2: Direct Copy
```bash
# Clone this template
git clone https://github.com/yourusername/devcontainer.git temp-devcontainer

# Copy the .devcontainer folder to your project
cp -r temp-devcontainer/.devcontainer /path/to/your/project/
cp temp-devcontainer/liquescent.omp.json /path/to/your/project/

# Clean up
rm -rf temp-devcontainer
```

## Project Overview

This devcontainer template creates a complete polyglot development environment with:

- **Multi-language support** for Node.js, Go, Rust, .NET, and Python out of the box
- **Network isolation** using iptables and ipset with allowlisted domains
- **Modern shell experience** with oh-my-zsh and oh-my-posh theming
- **SOCKS5 proxy support** for accessing external resources through the host
- **Claude Code CLI** pre-installed for AI-assisted development
- **Essential development tools** including git, fzf, and VS Code extensions

## Prerequisites

To use this devcontainer template, you'll need:

### Container Runtime (in order of recommendation)
1. **OrbStack** - Fastest and most efficient Docker alternative for macOS
2. **Colima** - Lightweight Docker alternative with minimal resource usage
3. **Rancher Desktop** - Full-featured Kubernetes and container management
4. **Podman** - Daemonless container engine with enhanced security
5. **Docker Desktop** - Traditional Docker solution (higher resource usage)

### Development Environment
- **VS Code** with the **Dev Containers extension** installed
- **Git** for version control

## Features

### Shell and Terminal Experience
- **oh-my-zsh** with language-specific plugins (git, fzf, npm, docker, golang, rust, python, dotnet)
- **oh-my-posh** with custom liquescent theme
- **fzf** for fuzzy finding and enhanced command-line experience
- Persistent bash/zsh history across container rebuilds
- Pre-configured PATH for all development languages

### Network Security
- **Network isolation** using iptables firewall rules
- **Allowlisted domains** for secure external access
- **DNS resolution** preserved for domain lookups
- **SSH access** maintained for git operations

### Development Tools
- **Claude Code CLI** for AI-assisted development
- **Git Delta** for enhanced git diff visualization
- **GitHub CLI** for repository management
- **Node.js 20** with npm global package support
- **Go 1.25.0** with GOPATH configured and module support
- **Rust (latest stable)** with cargo and common tools (cargo-watch, cargo-edit, cargo-audit, cargo-outdated)
- **.NET SDK 8.0** with full development support and telemetry disabled
- **Python 3** with pip, venv, and essential tools (pipenv, poetry, black, pylint, pytest, requests, ipython)

### Git Integration
- **Automatic Git Configuration**: Mounts your host's `.gitconfig` and `.ssh` directory
- **Delta Integration**: Automatically configured for enhanced git diffs
- **GitHub CLI**: Pre-installed and ready for authentication
- **Configuration Verification**: Runs setup script on container creation to verify git settings

### VS Code Integration
- Pre-configured extensions for JavaScript/TypeScript development
- Ready for language-specific extensions (Go, Rust, .NET, Python)
- Prettier and ESLint integration with format-on-save
- GitLens for enhanced git capabilities
- Optimized settings for container development

## Installation and Usage

### 1. Clone or Copy the Template

```bash
# Clone this repository
git clone <repository-url> my-project
cd my-project

# Or copy the .devcontainer directory to your existing project
cp -r .devcontainer /path/to/your/project/
```

### 2. Open in VS Code

```bash
# Open the project in VS Code
code .
```

### 3. Reopen in Container

When prompted, click **"Reopen in Container"** or use the Command Palette:
1. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
2. Type "Dev Containers: Reopen in Container"
3. Wait for the container to build and initialize

### 4. Verify Setup

Once the container is running, verify the setup:

```bash
# Check firewall status
sudo iptables -L

# Verify allowed domains
sudo ipset list allowed-domains

# Test Claude Code CLI
claude --help

# Check shell configuration
echo $SHELL
```

## Security Model

The devcontainer implements a restrictive network security model:

### Allowed Network Access
- **GitHub** (dynamically fetched IP ranges for web, API, and git operations)
- **npm registry** (registry.npmjs.org)
- **Anthropic APIs** (api.anthropic.com, statsig.anthropic.com, statsig.com, sentry.io)
- **Host network** (for local development and services)
- **DNS resolution** (UDP port 53)
- **SSH connections** (port 22)
- **SOCKS5 proxy** (host.docker.internal:1080)

### Security Features
- Default DROP policy for all traffic
- Allowlist-based network access using ipset
- Preserved Docker DNS resolution
- Automatic firewall verification on startup
- Network isolation from unauthorized external resources

## Firewall Configuration

The firewall is automatically configured during container creation and includes:

### Allowed Domains and Services
```bash
# GitHub (all web, API, and git IP ranges)
# Dynamically fetched from https://api.github.com/meta

# npm registry
registry.npmjs.org

# Anthropic services
api.anthropic.com
sentry.io
statsig.anthropic.com
statsig.com

# Host network (detected automatically)
# Example: 192.168.1.0/24
```

### Firewall Rules Structure
1. **DNS and localhost** - Allowed before restrictions
2. **SSH connections** - For git operations
3. **Host network** - Full access to host machine
4. **SOCKS5 proxy** - Port 1080 on host
5. **Allowlisted domains** - Only specified IPs/ranges
6. **Default deny** - All other traffic blocked

## SOCKS5 Proxy Support

The devcontainer can route traffic through a SOCKS5 proxy running on your host machine:

### Setup Host Proxy
Ensure you have a SOCKS5 proxy running on port 1080 of your host machine.

### Using the Proxy

```bash
# Configure git to use SOCKS5 proxy
git config --global http.proxy socks5://host.docker.internal:1080
git config --global https.proxy socks5://host.docker.internal:1080

# Use curl with SOCKS5 proxy
curl https://example.com --socks5 host.docker.internal:1080

# Configure npm to use proxy
npm config set proxy socks5://host.docker.internal:1080
npm config set https-proxy socks5://host.docker.internal:1080
```

### Removing Proxy Configuration

```bash
# Remove git proxy settings
git config --global --unset http.proxy
git config --global --unset https.proxy

# Remove npm proxy settings
npm config delete proxy
npm config delete https-proxy
```

## Customization Options

### Adding New Allowed Domains

Edit `.devcontainer/init-firewall.sh` and add domains to the resolution loop:

```bash
for domain in \
    "registry.npmjs.org" \
    "api.anthropic.com" \
    "your-new-domain.com"; do  # Add your domain here
    # ... rest of the loop
done
```

### Modifying Shell Configuration

The shell is configured in the Dockerfile. To customize:

1. **oh-my-posh theme**: Replace `liquescent.omp.json` with your preferred theme
2. **zsh plugins**: Modify the plugins list in the Dockerfile
3. **Additional tools**: Add package installations to the Dockerfile

### VS Code Extensions

Modify `.devcontainer/devcontainer.json` to add or remove extensions:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "eamodio.gitlens",
        "your-extension-id"
      ]
    }
  }
}
```

### Environment Variables

Add custom environment variables to the devcontainer configuration:

```json
{
  "containerEnv": {
    "NODE_OPTIONS": "--max-old-space-size=4096",
    "CLAUDE_CONFIG_DIR": "/home/node/.claude",
    "YOUR_CUSTOM_VAR": "value"
  }
}
```

## Troubleshooting

### Container Won't Start

**Problem**: Container fails to build or start
**Solution**: 
```bash
# Rebuild the container without cache
# In VS Code Command Palette: "Dev Containers: Rebuild Container"
# Or manually:
docker system prune
# Then reopen in container
```

### Network Access Issues

**Problem**: Cannot reach allowed domains
**Solution**:
```bash
# Check firewall status
sudo iptables -L -n

# Verify allowed domains are in ipset
sudo ipset list allowed-domains

# Test DNS resolution
nslookup api.github.com

# Restart firewall script
sudo /usr/local/bin/init-firewall.sh
```

### Permission Errors

**Problem**: Permission denied errors
**Solution**:
```bash
# Check user and permissions
whoami
groups

# Verify sudo access for firewall script
sudo -l

# Fix ownership if needed (run as root)
chown -R node:node /workspace /home/node
```

### SOCKS5 Proxy Not Working

**Problem**: Cannot connect through proxy
**Solution**:
```bash
# Test host connectivity
ping host.docker.internal

# Check if proxy port is accessible
nc -zv host.docker.internal 1080

# Verify proxy is running on host
# On host machine:
netstat -an | grep :1080
```

### Shell or Theme Issues

**Problem**: oh-my-zsh or oh-my-posh not working
**Solution**:
```bash
# Check shell configuration
echo $SHELL
cat ~/.zshrc

# Reload shell configuration
source ~/.zshrc

# Verify oh-my-posh installation
oh-my-posh --version

# Check theme file exists
ls -la /workspace/liquescent.omp.json
```

### Claude Code CLI Issues

**Problem**: Claude CLI not working
**Solution**:
```bash
# Check Claude installation
claude --version
which claude

# Verify npm global path
echo $PATH
npm config get prefix

# Reinstall if needed
npm install -g @anthropic-ai/claude-code@latest
```

## Development Tips

### Persistent Data
- Bash history is persisted across container rebuilds
- Claude configuration is mounted from host `~/.claude` directory
- Workspace files are bind-mounted for real-time editing

### Performance Optimization
- Use `NODE_OPTIONS="--max-old-space-size=4096"` for memory-intensive operations
- Font rendering is optimized with host font mounting
- Container uses delegated consistency for better macOS performance

### Security Best Practices
- Regularly update the base image and packages
- Review firewall rules before adding new domains
- Use SOCKS5 proxy for accessing restricted resources
- Monitor network traffic during development

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes in a devcontainer environment
4. Submit a pull request with detailed description

For issues or feature requests, please open an issue in the repository.