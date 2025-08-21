# Template Customization Guide

This guide helps you customize the devcontainer template for your specific project needs after using it as a template.

## Common Customizations

### 1. Change Node.js Version
Edit `.devcontainer/Dockerfile`:
```dockerfile
# Change from Node 20 to another version
FROM node:18  # or node:22, node:16, etc.
```

### 2. Add Additional Allowed Domains
Edit `.devcontainer/init-firewall.sh` to add more domains to the allowed list:
```bash
# Add your domain to this list
for domain in \
    "registry.npmjs.org" \
    "api.anthropic.com" \
    "your-api.example.com" \  # Add your domain here
    "sentry.io" \
    ...
```

### 3. Install Additional Development Tools
Edit `.devcontainer/Dockerfile` to add more tools:
```dockerfile
# Add to the apt-get install section
RUN apt-get update && apt-get install -y --no-install-recommends \
  ... existing packages ... \
  postgresql-client \  # Add database clients
  redis-tools \        # Add Redis tools
  && apt-get clean && rm -rf /var/lib/apt/lists/*
```

Note: Go, Rust, .NET, and Python are already included in the base template.

### 4. Customize oh-my-zsh Plugins
Edit `.devcontainer/Dockerfile` in the zsh configuration section:
```bash
# The template includes language-specific plugins by default:
# plugins=(git docker docker-compose npm node golang rust python dotnet fzf ...)
# You can add additional plugins like kubectl, terraform, etc.
echo 'plugins=(git fzf npm docker golang rust python dotnet kubectl terraform)' >> ~/.zshrc
```

### 5. Add Project-Specific VS Code Extensions
Edit `.devcontainer/devcontainer.json`:
```json
"extensions": [
  "dbaeumer.vscode-eslint",
  "esbenp.prettier-vscode",
  "eamodio.gitlens",
  "your.extension-id"  // Add your extensions
]
```

### 6. Set Project-Specific Environment Variables
Edit `.devcontainer/devcontainer.json`:
```json
"containerEnv": {
  "NODE_OPTIONS": "--max-old-space-size=4096",
  "CLAUDE_CONFIG_DIR": "/home/node/.claude",
  "YOUR_ENV_VAR": "value"  // Add your variables
}
```

### 7. Customize the oh-my-posh Theme
Modify `.devcontainer/liquescent.omp.json` or create your own theme file and update the Dockerfile:
```bash
# Copy your theme in Dockerfile
COPY your-theme.omp.json /usr/local/share/
# Then update the zshrc configuration to point to it
echo 'eval "$(oh-my-posh init zsh --config /usr/local/share/your-theme.omp.json)"' >> ~/.zshrc
```

### 8. Add Database or Service Containers
Create a `.devcontainer/docker-compose.yml`:
```yaml
version: '3.8'
services:
  devcontainer:
    build:
      context: .
      dockerfile: Dockerfile
    # ... existing config ...
  
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: postgres
    # ... additional config ...
```

Then update `devcontainer.json`:
```json
{
  "dockerComposeFile": "docker-compose.yml",
  "service": "devcontainer",
  // ... rest of config
}
```

### For .NET Projects
- .NET SDK 8.0 is already installed with telemetry disabled
- Install C# and .NET-specific VS Code extensions
- Configure project templates and NuGet sources as needed
- DOTNET_ROOT is pre-configured at `/usr/local/dotnet`

## Project-Specific Configurations

### For React/Next.js Projects
- Add port forwarding in `devcontainer.json`:
  ```json
  "forwardPorts": [3000, 3001]
  ```
- Install React DevTools extension

### For Python Projects
- Python 3 is already included with common tools (pipenv, poetry, black, pylint, pytest)
- Install Python-specific VS Code extensions
- Configure virtual environments as needed
- Add pip package caching if needed

### For Go Projects
- Go 1.25.0 is already installed with GOPATH configured
- Install Go-specific VS Code extensions (Go extension by Google)
- Configure module proxy if needed for private modules
- GOPATH is pre-configured at `/home/node/go`

### For Rust Projects
- Rust is already installed with common cargo tools (cargo-watch, cargo-edit, cargo-audit, cargo-outdated)
- Install Rust-specific VS Code extensions (rust-analyzer)
- Configure cargo caching if needed
- All Rust tools are available in PATH

## Removing Features

### Remove Network Isolation
If you don't need the firewall:
1. Remove `postCreateCommand` from `devcontainer.json`
2. Remove `runArgs` for NET_ADMIN and NET_RAW capabilities
3. Delete `init-firewall.sh`

### Remove SOCKS5 Proxy Support
Remove the `--add-host=host.docker.internal:host-gateway` line from `runArgs` in `devcontainer.json`

### Use Different Shell Configuration
Replace the oh-my-zsh/oh-my-posh setup in the Dockerfile with your preferred shell configuration.

## Testing Your Customizations

1. **Build locally first**:
   ```bash
   docker build -t my-devcontainer .devcontainer/
   ```

2. **Test in VS Code**:
   - Open your project
   - Run "Dev Containers: Rebuild Container"

3. **Verify customizations**:
   - Check installed tools
   - Test network access
   - Verify environment variables

## Maintaining Your Fork

If you want to stay updated with the upstream template:

1. Add the original template as upstream:
   ```bash
   git remote add upstream https://github.com/original/devcontainer.git
   ```

2. Fetch and merge updates:
   ```bash
   git fetch upstream
   git merge upstream/main --allow-unrelated-histories
   ```

3. Resolve any conflicts with your customizations

## Getting Help

- Check the main README.md for troubleshooting
- Review CLAUDE.md for architecture details
- Open an issue in your repository for project-specific problems
- Refer to the [VS Code Dev Containers documentation](https://code.visualstudio.com/docs/devcontainers/containers)