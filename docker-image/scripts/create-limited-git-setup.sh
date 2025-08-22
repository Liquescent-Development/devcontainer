#!/bin/bash

# Script to create a limited-scope git configuration for the devcontainer
# This is useful when you don't want to mount your host's git config

echo "🔐 Creating Limited Git Setup for DevContainer"
echo "=============================================="
echo ""
echo "This will create a git configuration specific to this devcontainer"
echo "with optional limited-scope GitHub access."
echo ""

# Get git user information
echo "📝 Git Configuration"
echo "-------------------"
read -p "Enter your name for git commits: " git_name
read -p "Enter your email for git commits: " git_email

# Configure git
git config --global user.name "$git_name"
git config --global user.email "$git_email"

# Configure delta for better diffs
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.side-by-side false
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default

echo "✅ Git configured with:"
echo "   Name: $git_name"
echo "   Email: $git_email"
echo ""

# Ask about GitHub setup
echo "🔑 GitHub Access Setup"
echo "----------------------"
echo "Would you like to set up GitHub access? (y/n)"
read -p "> " setup_github

if [[ "$setup_github" == "y" || "$setup_github" == "Y" ]]; then
    echo ""
    echo "Choose authentication method:"
    echo "1) GitHub Personal Access Token (recommended for limited scope)"
    echo "2) SSH Key (will be generated in container)"
    echo "3) GitHub CLI authentication"
    read -p "Enter choice (1-3): " auth_choice
    
    case $auth_choice in
        1)
            echo ""
            echo "📋 To create a Personal Access Token:"
            echo "   1. Go to https://github.com/settings/tokens/new"
            echo "   2. Give it a descriptive name (e.g., 'DevContainer-ProjectName')"
            echo "   3. Set expiration as needed"
            echo "   4. Select scopes:"
            echo "      - repo (for private repos)"
            echo "      - public_repo (for public repos only)"
            echo "      - workflow (if you need to push workflow changes)"
            echo ""
            echo "   You can use this token with HTTPS URLs:"
            echo "   git clone https://<token>@github.com/user/repo.git"
            echo ""
            read -p "Press Enter when you have your token ready..."
            
            echo ""
            echo "You can configure your remote to use the token:"
            echo "git remote set-url origin https://<YOUR_TOKEN>@github.com/<USER>/<REPO>.git"
            echo ""
            echo "⚠️  Note: Store tokens securely and never commit them!"
            ;;
            
        2)
            echo ""
            echo "Generating SSH key for this container..."
            ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519_devcontainer -N ""
            
            echo ""
            echo "📋 Add this public key to your GitHub account:"
            echo "   1. Go to https://github.com/settings/keys"
            echo "   2. Click 'New SSH key'"
            echo "   3. Title: 'DevContainer-$(hostname)'"
            echo "   4. Key type: Authentication key"
            echo "   5. Paste this key:"
            echo ""
            cat ~/.ssh/id_ed25519_devcontainer.pub
            echo ""
            
            # Configure SSH to use this key
            cat > ~/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_devcontainer
    IdentitiesOnly yes
EOF
            chmod 600 ~/.ssh/config
            
            echo "✅ SSH key generated and configured"
            ;;
            
        3)
            echo ""
            echo "Starting GitHub CLI authentication..."
            echo "Choose the minimal scopes needed for your work."
            gh auth login
            ;;
            
        *)
            echo "Invalid choice. Skipping GitHub setup."
            ;;
    esac
fi

echo ""
echo "🎉 Git setup complete!"
echo ""
echo "Tips:"
echo "- This configuration is container-specific"
echo "- For production work, consider using your host's git config"
echo "- Remember to clean up any tokens/keys when destroying the container"