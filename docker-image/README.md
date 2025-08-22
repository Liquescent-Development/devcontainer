# Liquescent Development DevContainer Base Image

This directory contains the Docker image definition for the Liquescent Development polyglot devcontainer.

## 🏗️ Architecture

The image is built on Node.js 20 and includes:
- Base development tools (git, zsh, fzf, vim, etc.)
- Network isolation tools (iptables, ipset)
- Claude Code CLI
- Git Delta for enhanced diffs
- Oh-My-Zsh with plugins
- Oh-My-Posh for terminal theming

Languages and additional tools are installed via Dev Container Features when the container is created.

## 📦 Pre-built Image

The image is automatically built and published to GitHub Container Registry:

```
ghcr.io/liquescent-development/devcontainer:latest
```

## 🔨 Building Locally

### Quick Build

```bash
./build.sh
```

### Custom Build

```bash
# With custom registry and tag
REGISTRY=docker.io IMAGE_NAME=myorg/devcontainer IMAGE_TAG=v1.0.0 ./build.sh

# With specific versions
CLAUDE_CODE_VERSION=1.2.3 GIT_DELTA_VERSION=0.18.2 ./build.sh
```

## 🚀 Publishing

### GitHub Container Registry (Automated)

The image is automatically built and published when:
- Changes are pushed to `main` branch
- Any files in `docker-image/` are modified

### Manual Publishing

```bash
# Build the image
./build.sh

# Login to registry
docker login ghcr.io -u YOUR_USERNAME

# Push the image
docker push ghcr.io/liquescent-development/devcontainer:latest
```

## 📁 Directory Structure

```
docker-image/
├── Dockerfile           # Main container definition
├── build.sh            # Local build script
├── README.md           # This file
└── scripts/            # Scripts baked into the image
    ├── init-firewall.sh           # Network isolation setup
    ├── setup-git.sh               # Git configuration
    ├── setup-1password.sh         # 1Password CLI setup
    ├── create-limited-git-setup.sh # Limited git config helper
    └── liquescent.omp.json        # Oh-My-Posh theme
```

## 🔧 Environment Variables

The scripts in the image respond to various environment variables passed from `devcontainer.json`:

### Network Configuration
- `CUSTOM_ALLOWED_DOMAINS`: Comma-separated list of additional domains to allow

### Git Configuration
- `MOUNT_HOST_GIT_CONFIG`: Whether to use host git configuration

### 1Password Configuration
- `OP_SERVICE_ACCOUNT_TOKEN`: 1Password service account token
- `OP_CONNECT_HOST`: 1Password Connect server URL
- `OP_CONNECT_TOKEN`: 1Password Connect token
- `OP_CREATE_SERVICE_ACCOUNT`: Auto-create service account
- `OP_SA_EXPIRES_IN`: Service account expiration
- `OP_SA_VAULTS`: Vault restrictions
- `OP_SA_NAME`: Custom service account name

## 🔄 Updating the Image

1. Make changes to `Dockerfile` or scripts in `scripts/`
2. Test locally with `./build.sh`
3. Commit and push to trigger automated build
4. Update `devcontainer.json` if changing the tag

## 📝 Version Strategy

- `latest`: Always points to the most recent build from `main`
- `vX.Y.Z`: Semantic versioning for stable releases
- `main`: Tracks the main branch
- `pr-N`: Temporary builds for pull requests

## 🔐 Security Notes

- The image runs as non-root user (`node`) by default
- Scripts requiring elevated permissions use sudo with specific allowlists
- Network isolation is enforced via iptables/ipset
- Sensitive data should be passed as environment variables, not baked into the image