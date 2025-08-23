# Liquescent Polyglot Development Container Template

A secure, polyglot development container template with network isolation, comprehensive language support, and enterprise-grade secret management.

## 🚀 Quick Start

This template can be used to add a development container to your existing project.

### Using with VS Code

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open your project in VS Code
3. Press `F1` and select `Dev Containers: Add Dev Container Configuration Files...`
4. Search for "Liquescent Polyglot"
5. Select the options you want
6. Reopen in container when prompted

### Using with the Dev Container CLI

```bash
# Install the CLI
npm install -g @devcontainers/cli

# Apply the template to your project
devcontainer templates apply \
  --template-id ghcr.io/liquescent-development/templates/polyglot-devcontainer \
  --template-args '{"timezone": "America/Phoenix", "enableSocks5": true}'
```

## 📋 Template Options

When adding this template to your project, you can configure:

- **Image Source**: Use pre-built image (fast) or build from Dockerfile (customizable)
- **Timezone**: Set your container timezone (e.g., `America/Phoenix`, `Europe/London`)
- **SOCKS5 Proxy**: Enable/disable SOCKS5 proxy support for VPN/corporate networks
- **Git Config Mounting**: Mount host Git configuration and SSH keys

## 🔧 Configuration

After adding the template, customize your environment by:

1. Copy `.devcontainer/.env.example` to `.devcontainer/.env`
2. Configure your settings (1Password tokens, custom domains, etc.)
3. Rebuild the container

## 🌟 Features

- **Languages**: Node.js, Go, Python, Rust, .NET
- **Security**: Network isolation with iptables firewall
- **Secret Management**: 1Password CLI integration
- **Developer Tools**: Git, GitHub CLI, FZF, direnv
- **Shell**: Zsh with Oh-My-Zsh and Oh-My-Posh

## 📚 Learn More

- [Full Documentation](https://github.com/Liquescent-Development/devcontainer)
- [Dev Container Specification](https://containers.dev/)