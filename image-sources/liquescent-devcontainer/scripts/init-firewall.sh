#!/bin/bash
#
# DevContainer Firewall Configuration Script
# ===========================================
# Configures iptables firewall rules and ipset for network isolation
# in development containers. Allows connections only to specific
# allowlisted services while maintaining Docker's internal DNS.
#
# Features:
# - Network isolation with allowlisted domains
# - GitHub IP ranges support
# - 1Password CLI domain support
# - SOCKS5 proxy configuration
# - Host machine development port access
# - Custom domain configuration via environment/file
#

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

# ============================================================================
# CONFIGURATION
# ============================================================================

# Built-in allowed domains
readonly BUILTIN_DOMAINS=(
    "registry.npmjs.org"
    "api.anthropic.com"
    "sentry.io"
    "statsig.anthropic.com"
    "statsig.com"
    # Python package repositories
    "pypi.org"
    "files.pythonhosted.org"
    "pypi.python.org"
)

# 1Password configuration
# Based on: https://support.1password.com/ports-domains/
readonly ONEPASSWORD_SUBDOMAINS=("1password" "my.1password" "app.1password" "api.1password" "events.1password" "b5n.1password")
readonly ONEPASSWORD_TLDS=("com" "eu" "ca")
readonly ONEPASSWORD_ADDITIONAL=(
    "cache.agilebits.com"
    "c.1passwordservices.com"
    "app.1passwordusercontent.com"
)

# Development ports allowed to host machine
readonly HOST_ALLOWED_PORTS=(
    80    # HTTP
    8080  # HTTP alt
    443   # HTTPS
    8443  # HTTPS alt
    5432  # PostgreSQL
    3306  # MySQL/MariaDB
    27017 # MongoDB
    6379  # Redis
    9200  # Elasticsearch
    3000  # Node.js/React
    4200  # Angular
    5000  # Flask/other
    8000  # Django/other
    9000  # PHP/other
)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Log an informational message
log_info() {
    echo "$@"
}

# Log an error message
log_error() {
    echo "ERROR: $@" >&2
}

# Log a warning message
log_warning() {
    echo "WARNING: $@" >&2
}

# Validate an IP address format
is_valid_ip() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

# Validate a CIDR range format
is_valid_cidr() {
    local cidr="$1"
    [[ "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]
}

# Validate an IP or CIDR format
is_valid_ip_or_cidr() {
    local entry="$1"
    is_valid_ip "$entry" || is_valid_cidr "$entry"
}

# Add an IP or CIDR to the ipset
add_to_ipset() {
    local entry="$1"
    local context="${2:-}"
    
    if ipset add allowed-domains "$entry" 2>/dev/null; then
        log_info "  Added $entry${context:+ for $context}"
    else
        # Already exists is not an error
        :
    fi
}

# Resolve a domain and add its IPs to ipset
resolve_and_add_domain() {
    local domain="$1"
    local optional="${2:-false}"  # If true, don't fail on resolution errors
    
    log_info "Resolving $domain..."
    
    local ips
    if [ "$optional" = "true" ]; then
        ips=$(timeout 2 dig +noall +answer A "$domain" 2>/dev/null | awk '$4 == "A" {print $5}')
    else
        ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
        if [ -z "$ips" ]; then
            log_error "Failed to resolve $domain"
            return 1
        fi
    fi
    
    if [ -n "$ips" ]; then
        while read -r ip; do
            if is_valid_ip "$ip"; then
                add_to_ipset "$ip" "$domain"
            else
                log_warning "Invalid IP from DNS for $domain: $ip"
            fi
        done < <(echo "$ips")
    elif [ "$optional" != "true" ]; then
        return 1
    fi
}

# Process a single entry (domain or IP/CIDR)
process_entry() {
    local entry="$1"
    local source="${2:-manual}"  # Where this entry came from (env/file/manual)
    
    # Trim whitespace
    entry=$(echo "$entry" | xargs)
    
    if [ -z "$entry" ]; then
        return 0
    fi
    
    # Check if it's an IP/CIDR or domain
    if is_valid_ip_or_cidr "$entry"; then
        log_info "Adding IP/CIDR from $source: $entry"
        add_to_ipset "$entry"
    else
        # It's a domain name, resolve it
        log_info "Resolving domain from $source: $entry"
        resolve_and_add_domain "$entry" "true"  # Optional resolution for custom domains
    fi
}

# ============================================================================
# DOCKER DNS PRESERVATION
# ============================================================================

preserve_docker_dns() {
    log_info "Preserving Docker DNS configuration..."
    
    # Extract Docker DNS info BEFORE any flushing
    local docker_dns_rules
    docker_dns_rules=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)
    
    # Flush existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    # Clean up old ipset if it exists
    ipset destroy allowed-domains 2>/dev/null || true
    
    # Selectively restore ONLY internal Docker DNS resolution
    if [ -n "$docker_dns_rules" ]; then
        log_info "Restoring Docker DNS rules..."
        iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
        iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
        echo "$docker_dns_rules" | xargs -L 1 iptables -t nat
    else
        log_info "No Docker DNS rules to restore"
    fi
}

# ============================================================================
# IPSET CONFIGURATION
# ============================================================================

setup_ipset() {
    log_info "Creating ipset for allowed domains..."
    ipset create allowed-domains hash:net
}

# ============================================================================
# SERVICE CONFIGURATION FUNCTIONS
# ============================================================================

configure_github() {
    log_info "Configuring GitHub access..."
    log_info "Fetching GitHub IP ranges..."
    
    local gh_ranges
    gh_ranges=$(curl -s https://api.github.com/meta)
    
    if [ -z "$gh_ranges" ]; then
        log_error "Failed to fetch GitHub IP ranges"
        return 1
    fi
    
    if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
        log_error "GitHub API response missing required fields"
        return 1
    fi
    
    log_info "Processing GitHub IPs..."
    while read -r cidr; do
        if ! is_valid_cidr "$cidr"; then
            log_error "Invalid CIDR range from GitHub meta: $cidr"
            return 1
        fi
        log_info "Adding GitHub range $cidr"
        add_to_ipset "$cidr" "GitHub"
    done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)
}

configure_builtin_domains() {
    log_info "Configuring built-in allowed domains..."
    
    for domain in "${BUILTIN_DOMAINS[@]}"; do
        if ! resolve_and_add_domain "$domain" "false"; then
            return 1
        fi
    done
}

configure_onepassword() {
    log_info "Configuring 1Password domains..."
    
    # Process common 1Password subdomains across all regions
    for subdomain in "${ONEPASSWORD_SUBDOMAINS[@]}"; do
        for tld in "${ONEPASSWORD_TLDS[@]}"; do
            local domain="${subdomain}.${tld}"
            resolve_and_add_domain "$domain" "true"  # Optional - not all regions exist
        done
    done
    
    # Process additional 1Password service domains
    for domain in "${ONEPASSWORD_ADDITIONAL[@]}"; do
        resolve_and_add_domain "$domain" "true"  # Optional
    done
}

configure_custom_domains_env() {
    if [ -z "${CUSTOM_ALLOWED_DOMAINS:-}" ]; then
        return 0
    fi
    
    log_info "Processing custom allowed domains from CUSTOM_ALLOWED_DOMAINS environment variable..."
    
    IFS=',' read -ra DOMAINS <<< "${CUSTOM_ALLOWED_DOMAINS}"
    for domain in "${DOMAINS[@]}"; do
        process_entry "$domain" "env"
    done
    
    log_info "Finished processing environment variable domains"
}

configure_custom_domains_file() {
    local domains_file="/workspace/.devcontainer/allowed-domains.txt"
    
    if [ ! -f "$domains_file" ]; then
        log_info "No .devcontainer/allowed-domains.txt file found (optional)"
        return 0
    fi
    
    log_info "Processing project-specific allowed domains from allowed-domains.txt..."
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        process_entry "$line" "file"
    done < "$domains_file"
    
    log_info "Finished processing project-specific allowed domains"
}

# ============================================================================
# HOST CONFIGURATION
# ============================================================================

detect_host_network() {
    log_info "Detecting host network configuration..."
    
    # Get host IP from default route
    HOST_IP=$(ip route | grep default | cut -d" " -f3)
    if [ -z "$HOST_IP" ]; then
        log_error "Failed to detect host IP"
        return 1
    fi
    
    HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
    log_info "Host network detected as: $HOST_NETWORK"
    
    # Also get host.docker.internal IP (may be different from gateway)
    HOST_DOCKER_IP=$(getent hosts host.docker.internal | awk '{print $1}')
    if [ -n "$HOST_DOCKER_IP" ] && [ "$HOST_DOCKER_IP" != "$HOST_IP" ]; then
        log_info "host.docker.internal detected as: $HOST_DOCKER_IP"
    fi
    
    # Export for use in other functions
    export HOST_IP HOST_NETWORK HOST_DOCKER_IP
}

# ============================================================================
# IPTABLES RULES CONFIGURATION
# ============================================================================

configure_basic_rules() {
    log_info "Configuring basic firewall rules..."
    
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
}

configure_socks5_proxy() {
    if [ "${SOCKS5_ENABLED:-true}" != "true" ]; then
        log_info "SOCKS5 proxy access disabled"
        return 0
    fi
    
    local socks5_host="${SOCKS5_HOST:-host.docker.internal}"
    local socks5_port="${SOCKS5_PORT:-1080}"
    
    log_info "Configuring SOCKS5 proxy access:"
    log_info "  Host: $socks5_host"
    log_info "  Port: $socks5_port"
    
    # Resolve SOCKS5 host if it's a hostname
    if is_valid_ip "$socks5_host"; then
        # It's already an IP
        iptables -A OUTPUT -p tcp -d "$socks5_host" --dport "$socks5_port" -j ACCEPT
    else
        # It's a hostname, resolve it
        local socks5_ip
        socks5_ip=$(getent hosts "$socks5_host" | awk '{print $1}')
        if [ -z "$socks5_ip" ]; then
            log_warning "Failed to resolve SOCKS5 host $socks5_host"
        else
            log_info "  Resolved to: $socks5_ip"
            iptables -A OUTPUT -p tcp -d "$socks5_ip" --dport "$socks5_port" -j ACCEPT
        fi
    fi
}

configure_host_ports() {
    log_info "Configuring host machine port access..."
    
    # Helper function to add rules for both IPs
    add_host_port_rule() {
        local port=$1
        iptables -A OUTPUT -p tcp -d "$HOST_IP" --dport "$port" -j ACCEPT
        if [ -n "${HOST_DOCKER_IP:-}" ] && [ "$HOST_DOCKER_IP" != "$HOST_IP" ]; then
            iptables -A OUTPUT -p tcp -d "$HOST_DOCKER_IP" --dport "$port" -j ACCEPT
        fi
    }
    
    for port in "${HOST_ALLOWED_PORTS[@]}"; do
        add_host_port_rule "$port"
    done
}

configure_ipset_rule() {
    log_info "Configuring ipset-based domain filtering..."
    
    # Allow specific outbound traffic to allowed domains
    iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT
}

set_default_policies() {
    log_info "Setting default firewall policies to DROP..."
    
    # Set default policies to DROP (MUST be last!)
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
}

# ============================================================================
# VERIFICATION
# ============================================================================

verify_firewall() {
    log_info "Verifying firewall configuration..."
    
    # Test that we cannot reach a blocked domain
    if curl --connect-timeout 5 https://example.com >/dev/null 2>&1; then
        log_error "Firewall verification failed - was able to reach https://example.com"
        return 1
    else
        log_info "✓ Firewall blocks unauthorized domains (example.com unreachable)"
    fi
    
    # Test that we can reach an allowed domain
    if ! curl --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
        log_error "Firewall verification failed - unable to reach https://api.github.com"
        return 1
    else
        log_info "✓ Firewall allows authorized domains (api.github.com reachable)"
    fi
    
    log_info "Firewall verification completed successfully"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_info "=== DevContainer Firewall Configuration Starting ==="
    
    # Step 1: Preserve Docker DNS and clean slate
    preserve_docker_dns
    
    # Step 2: Create ipset for allowed domains
    setup_ipset
    
    # Step 3: Configure allowed services
    configure_github || exit 1
    configure_builtin_domains || exit 1
    configure_onepassword
    configure_custom_domains_env
    configure_custom_domains_file
    
    # Step 4: Detect host network
    detect_host_network || exit 1
    
    # Step 5: Configure iptables rules
    configure_basic_rules
    configure_socks5_proxy
    configure_host_ports
    configure_ipset_rule
    
    # Step 6: Set restrictive default policies
    set_default_policies
    
    # Step 7: Verify configuration
    verify_firewall || exit 1
    
    log_info "=== Firewall Configuration Complete ==="
}

# Execute main function
main "$@"