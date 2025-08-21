#!/bin/bash

# Setup direnv to automatically load .env files
# This script configures direnv to natively support .env files

echo "🔧 Setting up direnv for automatic .env loading..."

# Create direnv config directory for the user
mkdir -p /home/node/.config/direnv

# Enable native .env file loading in direnv
cat > /home/node/.config/direnv/direnv.toml << 'EOF'
[global]
# Enable automatic loading of .env files without needing .envrc
load_dotenv = true
EOF

# Set ownership
chown -R node:node /home/node/.config/direnv

echo "✅ direnv configured to automatically load .env files"
echo ""
echo "ℹ️  Security Note: direnv requires approval before loading .env files"
echo "   When you see 'direnv: error .env is blocked', run: direnv allow"
echo "   This protects you from loading untrusted environment variables"
echo "   You'll need to re-approve if the .env file changes"