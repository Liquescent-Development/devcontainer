#!/bin/bash
# Wrapper script for git signing in devcontainer
# Helps users authenticate with 1Password CLI or set up alternative signing methods

setup_ssh_signing() {
    echo ""
    echo "🔐 Setting up SSH commit signing in the container..."
    echo ""
    
    # Check for existing SSH keys
    if [ -d "$HOME/.ssh" ] && [ "$(ls -A $HOME/.ssh/*.pub 2>/dev/null)" ]; then
        echo "Found existing SSH public keys:"
        echo ""
        ls -1 $HOME/.ssh/*.pub 2>/dev/null | while read -r key; do
            echo "  • $(basename "$key")"
        done
        echo ""
        echo "Would you like to:"
        echo "  1) Use an existing SSH key for signing"
        echo "  2) Create a new SSH key for signing"
        echo "  3) Disable commit signing for this repository"
        echo "  4) Cancel"
        echo ""
        read -p "Select an option (1-4): " choice
    else
        echo "No SSH keys found in the container."
        echo ""
        echo "Would you like to:"
        echo "  1) Create a new SSH key for signing"
        echo "  2) Disable commit signing for this repository"
        echo "  3) Cancel"
        echo ""
        read -p "Select an option (1-3): " choice
        if [ "$choice" = "1" ]; then
            choice="2"  # Map to create new key option
        elif [ "$choice" = "2" ]; then
            choice="3"  # Map to disable signing option
        else
            choice="4"  # Map to cancel option
        fi
    fi
    
    case $choice in
        1)
            # Use existing SSH key
            echo ""
            echo "Available SSH keys:"
            select key_file in $HOME/.ssh/*.pub; do
                if [ -n "$key_file" ]; then
                    key_path="${key_file%.pub}"
                    echo ""
                    echo "Configuring git to use: $(basename "$key_path")"
                    git config --global user.signingkey "$key_path"
                    git config --global gpg.format ssh
                    git config --global commit.gpgsign true
                    
                    echo ""
                    echo "✅ Git configured to use SSH key for signing!"
                    echo ""
                    echo "📋 Add this public key to GitHub:"
                    echo "   1. Go to https://github.com/settings/keys"
                    echo "   2. Click 'New SSH key'"
                    echo "   3. Select 'Signing Key' as the key type"
                    echo "   4. Paste the following key:"
                    echo ""
                    cat "$key_file"
                    echo ""
                    echo "Press Enter to continue..."
                    read
                    break
                fi
            done
            ;;
        2)
            # Create new SSH key
            echo ""
            read -p "Enter your email for the SSH key: " email
            if [ -z "$email" ]; then
                email="$(git config --global user.email || echo 'user@devcontainer')"
            fi
            
            key_name="id_ed25519_signing"
            key_path="$HOME/.ssh/$key_name"
            
            echo ""
            echo "Creating new SSH signing key..."
            ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N ""
            
            if [ -f "$key_path" ]; then
                git config --global user.signingkey "$key_path"
                git config --global gpg.format ssh
                git config --global commit.gpgsign true
                
                echo ""
                echo "✅ New SSH key created and configured for signing!"
                echo ""
                echo "📋 Add this public key to GitHub:"
                echo "   1. Go to https://github.com/settings/keys"
                echo "   2. Click 'New SSH key'"
                echo "   3. Select 'Signing Key' as the key type"
                echo "   4. Paste the following key:"
                echo ""
                cat "${key_path}.pub"
                echo ""
                echo "Press Enter to continue..."
                read
            else
                echo "❌ Failed to create SSH key"
                exit 1
            fi
            ;;
        3)
            # Disable signing for this repository
            echo ""
            echo "Disabling commit signing for this repository..."
            git config --local commit.gpgsign false
            echo "✅ Commit signing disabled for this repository"
            echo ""
            echo "Note: You can re-enable it later with:"
            echo "  git config --local commit.gpgsign true"
            ;;
        *)
            echo "Cancelled."
            exit 1
            ;;
    esac
}

# Check if we're trying to use 1Password for signing
if [[ "$1" == "sign" ]]; then
    # First, check if 1Password CLI is authenticated
    if ! /usr/local/bin/op account list &>/dev/null; then
        echo ""
        echo "🔐 1Password CLI is not authenticated."
        echo ""
        echo "Would you like to:"
        echo "  1) Sign in to 1Password CLI (recommended - use your existing SSH keys)"
        echo "  2) Set up alternative SSH key signing"
        echo "  3) Disable commit signing for this repository"
        echo "  4) Cancel"
        echo ""
        read -p "Select an option (1-4): " choice
        
        case $choice in
            1)
                echo ""
                echo "📝 Signing in to 1Password CLI..."
                echo "   You'll need your 1Password account email and Secret Key"
                echo ""
                /usr/local/bin/op signin
                
                if /usr/local/bin/op account list &>/dev/null; then
                    echo ""
                    echo "✅ Successfully authenticated with 1Password!"
                    echo "   Your SSH signing keys from 1Password are now available."
                    
                    # Now try to execute the sign command with 1Password CLI
                    exec /usr/local/bin/op "$@"
                else
                    echo ""
                    echo "❌ Authentication failed. Falling back to alternative methods..."
                    setup_ssh_signing
                fi
                ;;
            2)
                setup_ssh_signing
                ;;
            3)
                # Disable signing for this repository
                echo ""
                echo "Disabling commit signing for this repository..."
                git config --local commit.gpgsign false
                echo "✅ Commit signing disabled for this repository"
                echo ""
                echo "Note: You can re-enable it later with:"
                echo "  git config --local commit.gpgsign true"
                exit 1
                ;;
            *)
                echo "Cancelled."
                exit 1
                ;;
        esac
    else
        # 1Password CLI is authenticated, use it for signing
        exec /usr/local/bin/op "$@"
    fi
    
    # After setup, try to sign again with the new configuration
    if [ "$(git config --get commit.gpgsign)" = "true" ] && [ "$(git config --get gpg.format)" = "ssh" ]; then
        ssh_key=$(git config --get user.signingkey)
        if [ -n "$ssh_key" ] && [ -f "$ssh_key" ]; then
            # Use ssh-keygen for signing instead
            shift  # Remove 'sign' argument
            exec ssh-keygen -Y sign "$@"
        fi
    fi
    
    # If we get here, signing is disabled or failed
    exit 1
fi

# If we get here, try to execute the actual op command
# This will likely fail in a container, but we try anyway
exec /usr/local/bin/op "$@"