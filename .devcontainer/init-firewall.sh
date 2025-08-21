#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

# 1. Extract Docker DNS info BEFORE any flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Flush existing rules and delete existing ipsets
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

# 2. Selectively restore ONLY internal Docker DNS resolution
if [ -n "$DOCKER_DNS_RULES" ]; then
    echo "Restoring Docker DNS rules..."
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
else
    echo "No Docker DNS rules to restore"
fi

# Note: We'll add all rules after setting up ipset but before setting DROP policies

# Create ipset with CIDR support
ipset create allowed-domains hash:net

# Fetch GitHub meta information and aggregate + add their IP ranges
echo "Fetching GitHub IP ranges..."
gh_ranges=$(curl -s https://api.github.com/meta)
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi

if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
    echo "ERROR: GitHub API response missing required fields"
    exit 1
fi

echo "Processing GitHub IPs..."
while read -r cidr; do
    if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        echo "ERROR: Invalid CIDR range from GitHub meta: $cidr"
        exit 1
    fi
    echo "Adding GitHub range $cidr"
    ipset add allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)

# Resolve and add built-in allowed domains
for domain in \
    "registry.npmjs.org" \
    "api.anthropic.com" \
    "sentry.io" \
    "statsig.anthropic.com" \
    "statsig.com"; do
    echo "Resolving $domain..."
    ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
    if [ -z "$ips" ]; then
        echo "ERROR: Failed to resolve $domain"
        exit 1
    fi

    while read -r ip; do
        if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "ERROR: Invalid IP from DNS for $domain: $ip"
            exit 1
        fi
        echo "Adding $ip for $domain"
        ipset add allowed-domains "$ip"
    done < <(echo "$ips")
done

# Process user-defined allowed domains and IPs from allowed-domains.txt
if [ -f "/workspace/allowed-domains.txt" ]; then
    echo "Processing user-defined allowed domains and IPs..."
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Trim whitespace
        entry=$(echo "$line" | xargs)
        
        # Check if it's a CIDR range or single IP
        if [[ "$entry" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
            echo "Adding IP/CIDR: $entry"
            ipset add allowed-domains "$entry" 2>/dev/null || echo "  Already exists or invalid: $entry"
        else
            # It's a domain name, resolve it
            echo "Resolving custom domain: $entry"
            ips=$(dig +noall +answer A "$entry" | awk '$4 == "A" {print $5}')
            if [ -z "$ips" ]; then
                echo "  Warning: Failed to resolve $entry (skipping)"
            else
                while read -r ip; do
                    if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                        echo "  Adding $ip for $entry"
                        ipset add allowed-domains "$ip" 2>/dev/null || echo "    Already exists: $ip"
                    fi
                done < <(echo "$ips")
            fi
        fi
    done < "/workspace/allowed-domains.txt"
    echo "Finished processing user-defined allowed domains"
else
    echo "No custom allowed-domains.txt file found (optional)"
fi

# Get host IP from default route
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
    echo "ERROR: Failed to detect host IP"
    exit 1
fi

HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
echo "Host network detected as: $HOST_NETWORK"

# Also get host.docker.internal IP (may be different from gateway)
HOST_DOCKER_IP=$(getent hosts host.docker.internal | awk '{print $1}')
if [ -n "$HOST_DOCKER_IP" ] && [ "$HOST_DOCKER_IP" != "$HOST_IP" ]; then
    echo "host.docker.internal detected as: $HOST_DOCKER_IP"
fi

# Set up iptables rules - ORDER MATTERS!

# Allow established/related connections (this must come first)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT
iptables -A INPUT -p tcp --sport 53 -j ACCEPT

# Allow outbound SSH
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Allow specific ports to host machine for common development services
# Function to add rules for both IPs
add_host_port_rule() {
    local port=$1
    local comment=$2
    iptables -A OUTPUT -p tcp -d "$HOST_IP" --dport "$port" -j ACCEPT
    if [ -n "$HOST_DOCKER_IP" ] && [ "$HOST_DOCKER_IP" != "$HOST_IP" ]; then
        iptables -A OUTPUT -p tcp -d "$HOST_DOCKER_IP" --dport "$port" -j ACCEPT
    fi
}

# SOCKS5 proxy
add_host_port_rule 1080 "SOCKS5 proxy"
# HTTP
add_host_port_rule 80 "HTTP"
add_host_port_rule 8080 "HTTP alt"
# HTTPS
add_host_port_rule 443 "HTTPS"
add_host_port_rule 8443 "HTTPS alt"
# Database ports
add_host_port_rule 5432 "PostgreSQL"
add_host_port_rule 3306 "MySQL/MariaDB"
add_host_port_rule 27017 "MongoDB"
add_host_port_rule 6379 "Redis"
add_host_port_rule 9200 "Elasticsearch"
# Development servers (common ports)
add_host_port_rule 3000 "Node.js/React"
add_host_port_rule 4200 "Angular"
add_host_port_rule 5000 "Flask/other"
add_host_port_rule 8000 "Django/other"
add_host_port_rule 9000 "PHP/other"

# Allow specific outbound traffic to allowed domains (GitHub, npm, etc)
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Set default policies to DROP (MUST be last!)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

echo "Firewall configuration complete"
echo "Verifying firewall rules..."
if curl --connect-timeout 5 https://example.com >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - was able to reach https://example.com"
    exit 1
else
    echo "Firewall verification passed - unable to reach https://example.com as expected"
fi

# Verify GitHub API access
if ! curl --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - unable to reach https://api.github.com"
    exit 1
else
    echo "Firewall verification passed - able to reach https://api.github.com as expected"
fi