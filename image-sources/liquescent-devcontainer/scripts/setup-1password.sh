#!/bin/bash
# Setup 1Password CLI in the devcontainer
# This script verifies 1Password CLI authentication status

set -e

echo "🔐 Checking 1Password CLI authentication..."

# Unset empty Connect variables to prevent interference with service account token
# The 1Password CLI checks if these variables exist, not if they have values
if [ -z "$OP_CONNECT_HOST" ]; then
    unset OP_CONNECT_HOST
fi
if [ -z "$OP_CONNECT_TOKEN" ]; then
    unset OP_CONNECT_TOKEN
fi

# Also update the shell RC files to ensure they're unset in new shells
if [ -z "${OP_CONNECT_HOST:-}" ]; then
    echo "unset OP_CONNECT_HOST 2>/dev/null || true" >> ~/.bashrc
    echo "unset OP_CONNECT_HOST 2>/dev/null || true" >> ~/.zshrc
fi
if [ -z "${OP_CONNECT_TOKEN:-}" ]; then
    echo "unset OP_CONNECT_TOKEN 2>/dev/null || true" >> ~/.bashrc
    echo "unset OP_CONNECT_TOKEN 2>/dev/null || true" >> ~/.zshrc
fi

# Check if we already have a service account token
if [ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]; then
    echo "✅ Using 1Password service account token"
    # Test the token
    if op vault list &>/dev/null; then
        echo "✅ 1Password CLI authenticated successfully"
        exit 0
    else
        echo "⚠️  Service account token appears invalid"
        echo "   Please verify your OP_SERVICE_ACCOUNT_TOKEN is correct"
    fi
fi

# Check for Connect Server configuration (only if both values are non-empty)
if [ -n "${OP_CONNECT_HOST:-}" ] && [ -n "${OP_CONNECT_TOKEN:-}" ]; then
    echo "✅ Using 1Password Connect Server at $OP_CONNECT_HOST"
    # Test the connection
    if op vault list &>/dev/null; then
        echo "✅ 1Password Connect authenticated successfully"
        exit 0
    else
        echo "⚠️  Connect Server authentication failed"
        echo "   Please verify your OP_CONNECT_HOST and OP_CONNECT_TOKEN are correct"
    fi
fi

# If we get here, 1Password is not configured
echo ""
echo "ℹ️  1Password CLI is not authenticated. To use it:"
echo ""
echo "Option 1: Create a service account (recommended for devcontainers):"
echo "  1. On your host machine, run:"
echo "     op service-account create \"devcontainer-\$(basename \$(pwd))\" --expires-in 30d"
echo "  2. Copy the token (starts with 'ops_')"
echo "  3. Add to your .devcontainer/.env file:"
echo "     OP_SERVICE_ACCOUNT_TOKEN=ops_YOUR_TOKEN_HERE"
echo "  4. Rebuild the devcontainer"
echo ""
echo "Option 2: Use 1Password Connect Server (for teams):"
echo "  Add to your .devcontainer/.env file:"
echo "     OP_CONNECT_HOST=https://your-connect-server.example.com"
echo "     OP_CONNECT_TOKEN=your-connect-token"
echo ""
echo "Once configured, you can use commands like:"
echo "  op run --env-file=.env.prod -- npm start"
echo "  op read \"op://vault/item/field\""
echo ""