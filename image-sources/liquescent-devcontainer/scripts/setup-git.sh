#!/bin/bash

# Git setup script for devcontainer
# Handles both host-mounted and isolated git configurations

echo "🔧 Setting up Git configuration..."

# Check for .env file in workspace and source it if it exists
if [ -f "/workspace/.env" ]; then
    echo "📋 Loading configuration from .env file..."
    export $(cat /workspace/.env | grep -v '^#' | xargs)
fi

# Always copy host gitconfig if it exists (to have a writable version)
if [ -f "/home/node/.gitconfig.host" ]; then
    cp /home/node/.gitconfig.host /home/node/.gitconfig
    echo "✅ Created writable .gitconfig from host"
    
    # Check if git config uses 1Password for SSH signing
    if grep -q "/Applications/1Password.app" /home/node/.gitconfig 2>/dev/null; then
        # Get the current signing key from the config
        signing_key=$(git config --global user.signingkey 2>/dev/null || true)
        
        # If we have a signing key and SSH agent is available, configure for SSH agent signing
        if [ -n "$signing_key" ] && [ -S "$SSH_AUTH_SOCK" ]; then
            # Remove the 1Password-specific program path
            git config --global --unset gpg.ssh.program 2>/dev/null || true
            echo "✅ Configured git to use SSH agent for signing (removed 1Password desktop path)"
            echo "   SSH agent forwarding detected at: $SSH_AUTH_SOCK"
        else
            # If no SSH agent, disable signing to avoid errors
            git config --global commit.gpgsign false
            echo "⚠️  No SSH agent detected, disabled commit signing"
            echo "   To enable: ensure SSH agent forwarding is configured on your host"
        fi
    fi
fi

# Check for SSH agent forwarding
if [ -S "$SSH_AUTH_SOCK" ]; then
    echo "🔑 SSH agent forwarding detected at: $SSH_AUTH_SOCK"
    echo "   Git operations for private repos will use the forwarded agent"
    
    # Create .ssh directory with proper permissions
    mkdir -p /home/node/.ssh
    chmod 700 /home/node/.ssh
    
    # Copy known_hosts from host if available (for host key verification)
    if [ -f "/home/node/.ssh-host/known_hosts" ]; then
        cp /home/node/.ssh-host/known_hosts /home/node/.ssh/known_hosts
        chmod 644 /home/node/.ssh/known_hosts
        echo "✅ Copied known_hosts from host for SSH verification"
    fi
    
    # Create SSH config to ensure agent is used
    cat > /home/node/.ssh/config << EOF
Host *
    ForwardAgent yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly no
EOF
    chmod 600 /home/node/.ssh/config
    echo "✅ Configured SSH to use forwarded agent for all git operations"
else
    echo "⚠️  No SSH agent forwarding detected"
    
    # Check if we should use host git config
    if [ "${MOUNT_HOST_GIT_CONFIG}" = "true" ]; then
        echo "📂 Using host git configuration..."
        
        # Symlink SSH directory (fallback to key files if no agent)
        if [ -d "/home/node/.ssh-host" ]; then
            # Remove existing .ssh if it exists
            rm -rf /home/node/.ssh
            ln -sf /home/node/.ssh-host /home/node/.ssh
            echo "✅ Linked host .ssh directory (read-only)"
        else
            echo "⚠️  Host .ssh directory not found"
        fi
    else
        echo "🔒 Host git configuration is isolated."
        echo "   You'll need to configure git manually in this container:"
        echo "     git config --global user.name 'Your Name'"
        echo "     git config --global user.email 'your.email@example.com'"
        echo ""
        
        # Ensure .ssh directory exists with correct permissions
        mkdir -p /home/node/.ssh
        chmod 700 /home/node/.ssh
    fi
fi

# Check if git user.name is set
if [ -z "$(git config --global user.name)" ]; then
    echo "⚠️  Git user.name is not configured."
    if [ "${MOUNT_HOST_GIT_CONFIG:-true}" = "true" ]; then
        echo "   Your .gitconfig may not be mounted correctly."
        echo "   You can set it manually with: git config --global user.name 'Your Name'"
    else
        echo "   Configure git with: git config --global user.name 'Your Name'"
    fi
else
    echo "✅ Git user.name: $(git config --global user.name)"
fi

# Check if git user.email is set
if [ -z "$(git config --global user.email)" ]; then
    echo "⚠️  Git user.email is not configured."
    if [ "${MOUNT_HOST_GIT_CONFIG:-true}" = "true" ]; then
        echo "   Your .gitconfig may not be mounted correctly."
        echo "   You can set it manually with: git config --global user.email 'your.email@example.com'"
    else
        echo "   Configure git with: git config --global user.email 'your.email@example.com'"
    fi
else
    echo "✅ Git user.email: $(git config --global user.email)"
fi

# Configure git to use delta for better diffs (already installed)
# Only set if not already configured and not using read-only host config
if [ "$(git config --global core.pager)" != "delta" ]; then
    if [ "${MOUNT_HOST_GIT_CONFIG}" = "true" ]; then
        echo "ℹ️  Using host git configuration (read-only)"
        echo "   Delta is installed in the container but not configured."
        echo "   To use delta on your host, install it first:"
        echo "     brew install git-delta  # macOS with Homebrew"
        echo "   Then add to your host's .gitconfig:"
        echo "     [core]"
        echo "         pager = delta"
        echo "     [interactive]"
        echo "         diffFilter = delta --color-only"
    else
        echo "📝 Configuring delta for enhanced git diffs..."
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.light false
        git config --global delta.side-by-side false
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default
        echo "✅ Delta configured for git diffs"
    fi
else
    echo "✅ Delta already configured"
fi

# Check SSH keys
if [ -d "/home/node/.ssh" ] && [ "$(ls -A /home/node/.ssh 2>/dev/null)" ]; then
    echo "✅ SSH keys mounted from host"
else
    echo "ℹ️  No SSH keys found. You may need to set up SSH keys if using git over SSH."
fi

# Check GitHub CLI authentication
echo ""
echo "🔐 Checking GitHub CLI authentication..."
if ! gh auth status >/dev/null 2>&1; then
    echo "ℹ️  GitHub CLI is not authenticated."
    echo "   Run 'gh auth login' to authenticate when needed."
else
    echo "✅ GitHub CLI is authenticated"
fi

echo ""
echo "✨ Git setup verification complete!"