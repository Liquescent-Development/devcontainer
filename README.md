<p align="center">
  <img src="https://liquescent.dev/liquescent.png" alt="Liquescent Development" width="400">
</p>

# Liquescent Development DevContainer

A secure, polyglot development container with network isolation, comprehensive language support, and enterprise-grade secret management.

## 📦 Distribution Methods

This repository provides two ways to use our development container:

### 1. **Pre-built Docker Image** (Recommended for speed)
- Ready-to-use image from GitHub Container Registry
- No build time required
- Automatic updates when we publish new versions
- Image: `ghcr.io/liquescent-development/devcontainer:latest`

### 2. **Dev Container Template** (Recommended for customization)
- Spec-compliant template you can add to any project
- Customize the configuration for your specific needs
- Located in `src/polyglot-devcontainer/`
- Can be distributed via OCI registry as a template

## 🔒 Key Features

### Security & Network Isolation
- **Firewall-enforced network isolation** using iptables and ipset
- **Allowlisted domains only** - blocks unauthorized network access
- **Custom domain support** via environment variables or project configuration
- **SOCKS5 proxy support** for controlled external access
- **Non-root user execution** with selective sudo permissions

### Language & Tool Support
- **Polyglot development** - Go, Python, Rust, .NET, Node.js via Dev Container Features
- **Modern shell environment** - Zsh with Oh-My-Zsh and Oh-My-Posh theming
- **Development tools** - Git, GitHub CLI, FZF, Git Delta, direnv
- **AI assistance** - Claude Code CLI pre-installed
- **Secret management** - 1Password CLI with Connect Server and Service Account support

### Developer Experience
- **Instant startup** - Pre-built image from GitHub Container Registry
- **Persistent history** - Shell history preserved across container rebuilds
- **SSH agent forwarding** - Seamless git operations and commit signing
- **Automatic environment loading** - direnv integration for `.env` files
- **VS Code optimized** - Pre-configured extensions and settings

## 🚀 Quick Start

### Prerequisites
- Docker Desktop, OrbStack, Colima, or Rancher Desktop
- VS Code with Dev Containers extension
- Git

### Option 1: Using Pre-built Image (Fastest)

1. **Copy the `.devcontainer` folder** from this repository to your project

2. **Configure your environment**:
   ```bash
   cp .devcontainer/.env.example .devcontainer/.env
   # Edit .devcontainer/.env with your settings
   ```

3. **Open in VS Code**:
   ```bash
   code .
   ```
   Then use the command palette: `Dev Containers: Reopen in Container`

The container will automatically pull from `ghcr.io/liquescent-development/devcontainer:latest`.

### Option 2: Using as a Template (Most Flexible)

1. **Install the Dev Container CLI** (if not using VS Code):
   ```bash
   npm install -g @devcontainers/cli
   ```

2. **Apply the template to your project**:
   ```bash
   devcontainer templates apply \
     --workspace-folder . \
     --template-id ./src/polyglot-devcontainer
   ```

3. **Configure and customize** as needed

4. **Open in your preferred tool** (VS Code, CLI, etc.)

## ⚙️ Configuration

### Environment Variables

The devcontainer uses Docker Compose to automatically load environment variables from `.devcontainer/.env`.

Key configuration options in `.devcontainer/.env`:

```bash
# Timezone
TZ=America/Phoenix

# Custom allowed domains (comma-separated)
CUSTOM_ALLOWED_DOMAINS=api.mycompany.com,staging.myapp.io

# 1Password Configuration (optional)
OP_SERVICE_ACCOUNT_TOKEN=ops_...
# OR use Connect Server
OP_CONNECT_HOST=https://connect.mycompany.com
OP_CONNECT_TOKEN=...

# Git configuration mounting
MOUNT_HOST_GIT_CONFIG=true
```

See `.env.example` for all available options.

### Network Access

By default, only these domains are accessible:
- GitHub (github.com, api.github.com, etc.)
- npm registry (registry.npmjs.org)
- Anthropic API (api.anthropic.com)
- Docker Hub (hub.docker.com)
- 1Password (*.1password.com, *.1password.eu, *.1password.ca, *.1passwordservices.com)

#### Adding Custom Domains

**Method 1: Environment Variable** (personal/temporary)
```bash
# In .devcontainer/.env
CUSTOM_ALLOWED_DOMAINS=api.example.com,db.internal.net
```

**Method 2: Project Configuration** (team/permanent)
Create an `allowed-domains.txt` file in `.devcontainer/`:
```bash
# In .devcontainer/allowed-domains.txt
api.example.com
staging.example.com
192.168.1.0/24
```

### Secret Management

#### 1Password Integration

The 1Password CLI is pre-installed but requires authentication configuration.

**Option 1: Service Account** (Recommended for DevContainers)

Service accounts provide secure, non-interactive authentication perfect for development containers.

```bash
# On your host machine:
# 1. Install 1Password CLI: https://developer.1password.com/docs/cli/get-started
# 2. Sign in: op signin
# 3. Create a service account:
op service-account create "devcontainer-$(basename $(pwd))" --expires-in 30d

# 4. Copy the token (starts with 'ops_') to .devcontainer/.env:
OP_SERVICE_ACCOUNT_TOKEN=ops_YOUR_TOKEN_HERE

# For vault-specific access (more secure):
op service-account create "my-dev" --expires-in 30d --vault Development:read_items
```

**Option 2: Connect Server** (For Teams/Enterprise)
```bash
# In .devcontainer/.env:
OP_CONNECT_HOST=https://connect.company.com
OP_CONNECT_TOKEN=your-connect-token
```

**Usage in container**:
```bash
# Inject environment variables from 1Password
op run --env-file=prod.env -- npm start

# Read specific secrets
export API_KEY=$(op read "op://vault/item/field")

# Use with git for secure commit signing
op plugin init git
```

## 🏗️ Architecture

### Container Structure
- **Base**: Node.js 20 on Debian
- **Languages**: Installed via Dev Container Features (not in base image)
- **User**: Runs as `node` user with selective sudo
- **Shell**: Zsh with extensive plugin support
- **Network**: iptables rules applied at startup

### File Mounts
- `/workspace` - Your project files
- `/commandhistory` - Persistent shell history
- `/home/node/.claude` - Claude configuration (if using Claude Code)
- `/ssh-agent` - SSH agent socket forwarding

### Security Model
1. Network traffic blocked by default
2. DNS resolution allowed for domain lookup
3. Specific IPs/domains added to allowlist
4. All outbound traffic must pass through firewall rules
5. Container runs as non-root user

## 📚 Advanced Usage

### Using SOCKS5 Proxy

The container supports configurable SOCKS5 proxy access for routing traffic through VPNs or corporate proxies.

Configuration in `.devcontainer/.env`:
```bash
SOCKS5_ENABLED=true                    # Enable/disable proxy access
SOCKS5_HOST=host.docker.internal       # Proxy host (hostname or IP)
SOCKS5_PORT=1080                        # Proxy port
```

Using the proxy in the container:
```bash
# Configure git
git config --global http.proxy socks5://${SOCKS5_HOST}:${SOCKS5_PORT}

# Use with curl
curl --socks5 ${SOCKS5_HOST}:${SOCKS5_PORT} https://example.com

# Use with Python
export HTTP_PROXY=socks5://${SOCKS5_HOST}:${SOCKS5_PORT}
export HTTPS_PROXY=socks5://${SOCKS5_HOST}:${SOCKS5_PORT}
```

Common proxy scenarios:
- **Local SSH tunnel**: `ssh -D 1080 user@jumphost` then use default settings
- **Corporate proxy**: Set `SOCKS5_HOST` to your proxy server
- **VPN client**: Many VPN clients provide SOCKS5 on localhost:1080
- **Disable proxy**: Set `SOCKS5_ENABLED=false` if not needed

### Debugging Network Issues

```bash
# Check firewall rules
sudo iptables -L -v -n

# View allowed domains
sudo ipset list allowed-domains

# Test connectivity
curl -v https://example.com
```

### Performance Tuning

The container is configured with:
- 2 CPU cores minimum
- 4GB RAM minimum
- 32GB storage recommended
- Node.js max memory: 4GB

Adjust in `devcontainer.json` under `hostRequirements` if needed.

## 🔧 Customization

### Building Your Own Image

If you need to customize the base image:

```bash
cd docker-image
./build.sh
```

See [docker-image/README.md](docker-image/README.md) for detailed build instructions.

### Adding VS Code Extensions

Edit `devcontainer.json`:
```json
"customizations": {
  "vscode": {
    "extensions": [
      "your.extension-id"
    ]
  }
}
```

## 📖 Documentation

- [Docker Image Build Guide](docker-image/README.md)
- [Environment Variables Reference](.env.example)
- [Dev Container Specification](https://containers.dev)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

*Developed by [Liquescent Development](https://github.com/liquescent-development)*