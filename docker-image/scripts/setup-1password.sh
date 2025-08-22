#!/bin/bash
# Setup 1Password CLI in the devcontainer
# This script handles service account token creation and configuration

set -e

echo "🔐 Setting up 1Password CLI..."

# Check if we already have a service account token
if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
    echo "✅ Using existing 1Password service account token"
    # Test the token
    if op vault list &>/dev/null; then
        echo "✅ 1Password CLI authenticated successfully"
        exit 0
    else
        echo "⚠️  Existing service account token appears invalid"
    fi
fi

# Check for Connect Server configuration (secondary option)
if [ -n "$OP_CONNECT_HOST" ] && [ -n "$OP_CONNECT_TOKEN" ]; then
    echo "✅ Using 1Password Connect Server at $OP_CONNECT_HOST"
    # Test the connection
    if op vault list &>/dev/null; then
        echo "✅ 1Password Connect authenticated successfully"
        exit 0
    else
        echo "⚠️  Connect Server authentication failed"
    fi
fi

# If we get here, we need to create a service account token
# Check if the host has 1Password CLI available and authenticated
if [ -n "$OP_CREATE_SERVICE_ACCOUNT" ] && [ "$OP_CREATE_SERVICE_ACCOUNT" = "true" ]; then
    echo ""
    echo "📝 Attempting to create a new 1Password service account..."
    echo ""
    
    # Use environment variables to configure the service account
    EXPIRES_IN="${OP_SA_EXPIRES_IN:-30d}"  # Default 30 days
    VAULTS="${OP_SA_VAULTS:-}"  # Comma-separated list of vault names
    
    # Generate a unique name with repository info if not provided
    if [ -n "$OP_SA_NAME" ]; then
        ACCOUNT_NAME="$OP_SA_NAME"
    else
        # Try to get repository name from git
        REPO_NAME=""
        if [ -d "/workspace/.git" ]; then
            # Get the repository name from the remote URL
            REMOTE_URL=$(git -C /workspace config --get remote.origin.url 2>/dev/null || echo "")
            if [ -n "$REMOTE_URL" ]; then
                # Extract repo name from URL (works with both HTTPS and SSH URLs)
                REPO_NAME=$(basename -s .git "$REMOTE_URL" 2>/dev/null || echo "")
            fi
        fi
        
        # If we couldn't get repo name, try workspace folder name
        if [ -z "$REPO_NAME" ]; then
            REPO_NAME=$(basename "/workspace" 2>/dev/null || echo "workspace")
        fi
        
        # Create unique name: repo-name-YYYYMMDD-HHMMSS
        TIMESTAMP=$(date +%Y%m%d-%H%M%S)
        ACCOUNT_NAME="devcontainer-${REPO_NAME}-${TIMESTAMP}"
    fi
    
    # Check if we can run op on the host
    if ! command -v op &> /dev/null; then
        echo "⚠️  1Password CLI not found on host system"
        echo "   Please install 1Password CLI on your host to auto-create service accounts"
        echo "   Or set OP_SERVICE_ACCOUNT_TOKEN manually"
        exit 0
    fi
    
    # Check if user is signed in on the host
    if ! op account list &>/dev/null; then
        echo "⚠️  Not signed in to 1Password CLI on host"
        echo "   Please run 'op signin' on your host first"
        echo "   Or set OP_SERVICE_ACCOUNT_TOKEN manually"
        exit 0
    fi
    
    echo "Creating service account with:"
    echo "  • Name: $ACCOUNT_NAME"
    echo "  • Expires: $EXPIRES_IN"
    if [ -n "$VAULTS" ]; then
        echo "  • Vaults: $VAULTS"
    else
        echo "  • Vaults: All vaults (no restriction)"
    fi
    
    # Build the op command
    OP_CMD="op service-account create $ACCOUNT_NAME --expires-in $EXPIRES_IN"
    
    # Add vault restrictions if specified
    if [ -n "$VAULTS" ]; then
        IFS=',' read -ra VAULT_ARRAY <<< "$VAULTS"
        for vault in "${VAULT_ARRAY[@]}"; do
            OP_CMD="$OP_CMD --vault $vault:read_items"
        done
    fi
    
    # Create the service account and capture the token
    if SERVICE_ACCOUNT_OUTPUT=$(eval $OP_CMD 2>&1); then
        # Extract the token from the output
        TOKEN=$(echo "$SERVICE_ACCOUNT_OUTPUT" | grep -oP 'ops_[A-Za-z0-9_-]+' | head -1)
        
        if [ -n "$TOKEN" ]; then
            # Save the token to a file in the container
            echo "$TOKEN" > /home/node/.op_service_account_token
            chmod 600 /home/node/.op_service_account_token
            
            # Export for current session
            export OP_SERVICE_ACCOUNT_TOKEN="$TOKEN"
            
            echo ""
            echo "✅ Service account created successfully!"
            echo "   Token saved to container (will persist for this container's lifetime)"
            echo ""
            echo "   To use this token in future containers, add to your host environment:"
            echo "   export OP_SERVICE_ACCOUNT_TOKEN=\"$TOKEN\""
            echo ""
        else
            echo "⚠️  Failed to extract service account token from output"
        fi
    else
        echo "⚠️  Failed to create service account: $SERVICE_ACCOUNT_OUTPUT"
    fi
fi

# Final check - if we still don't have authentication, provide instructions
if ! op vault list &>/dev/null 2>&1; then
    echo ""
    echo "ℹ️  1Password CLI is not authenticated. To use it, you can:"
    echo ""
    echo "Option 1: Create a service account on your host and set the token:"
    echo "  op service-account create my-dev-account --expires-in 30d"
    echo "  export OP_SERVICE_ACCOUNT_TOKEN=\"<token>\""
    echo ""
    echo "Option 2: Use 1Password Connect Server:"
    echo "  export OP_CONNECT_HOST=\"https://your-connect-server.example.com\""
    echo "  export OP_CONNECT_TOKEN=\"<your-connect-token>\""
    echo ""
    echo "Option 3: Enable auto-creation in your next container:"
    echo "  export OP_CREATE_SERVICE_ACCOUNT=true"
    echo "  export OP_SA_EXPIRES_IN=7d  # Optional: token lifetime"
    echo "  export OP_SA_VAULTS=Development,Staging  # Optional: vault restrictions"
    echo ""
else
    echo "✅ 1Password CLI is ready to use!"
    echo "   Example: op run --env-file=.env.prod -- npm start"
fi