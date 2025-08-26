# Firewall Logging Configuration

## Overview

The Liquescent DevContainer includes an optional firewall logging feature that helps diagnose network connectivity issues by logging blocked connection attempts. This feature is disabled by default to avoid cluttering system logs during normal operation.

## Configuration

Firewall logging is configured through environment variables that can be set in your `.env` file or passed directly to the container.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FIREWALL_LOG_ENABLED` | `false` | Enable/disable firewall logging |
| `FIREWALL_LOG_PREFIX` | `FW-BLOCKED` | Prefix for log messages to make filtering easier |
| `FIREWALL_LOG_LEVEL` | `warning` | Kernel log level (debug, info, warning, error) |
| `FIREWALL_LOG_RATE_LIMIT` | `10/min` | Maximum log messages per minute to prevent log flooding |
| `FIREWALL_LOG_BURST` | `5` | Initial burst of messages allowed before rate limiting |

## Enabling Firewall Logging

### Method 1: Environment File (Persistent)

Create a `.env` file in your `.devcontainer` directory:

```bash
# Enable firewall logging
FIREWALL_LOG_ENABLED=true

# Optional: Customize logging parameters
FIREWALL_LOG_PREFIX=BLOCKED
FIREWALL_LOG_LEVEL=info
FIREWALL_LOG_RATE_LIMIT=20/min
FIREWALL_LOG_BURST=10
```

### Method 2: Docker Compose Override (Per-Session)

Set the environment variable when starting the container:

```bash
FIREWALL_LOG_ENABLED=true docker-compose up
```

### Method 3: VS Code DevContainer Settings

Add to your `.devcontainer/devcontainer.json`:

```json
{
  "remoteEnv": {
    "FIREWALL_LOG_ENABLED": "true"
  }
}
```

## Viewing Firewall Logs

Once logging is enabled, blocked connections will be logged to the kernel message buffer. You can view these logs using:

### View Recent Logs
```bash
# Show all firewall blocks
sudo dmesg | grep 'FW-BLOCKED'

# Show only outbound blocks
sudo dmesg | grep 'FW-BLOCKED-OUT'

# Show only inbound blocks
sudo dmesg | grep 'FW-BLOCKED-IN'
```

### Follow Logs in Real-Time
```bash
# Watch for new blocked connections
sudo dmesg -w | grep 'FW-BLOCKED'

# With timestamps
sudo dmesg -wT | grep 'FW-BLOCKED'
```

### Save Logs to File
```bash
# Export logs for analysis
sudo dmesg | grep 'FW-BLOCKED' > /tmp/firewall-blocks.log
```

## Understanding Log Messages

Log messages follow this format:
```
[timestamp] FW-BLOCKED-<direction>: IN=<interface> OUT=<interface> SRC=<source_ip> DST=<destination_ip> ...
```

### Log Message Components

- **Direction**:
  - `IN`: Incoming connections blocked
  - `OUT`: Outgoing connections blocked
  - `FWD`: Forwarded connections blocked

- **Key Fields**:
  - `SRC`: Source IP address
  - `DST`: Destination IP address
  - `DPT`: Destination port
  - `PROTO`: Protocol (TCP, UDP, ICMP)

### Example Log Entries

```
# Blocked outbound HTTPS connection
[12345.678] FW-BLOCKED-OUT: IN= OUT=eth0 SRC=172.17.0.2 DST=93.184.216.34 PROTO=TCP DPT=443

# Blocked incoming connection
[12346.789] FW-BLOCKED-IN: IN=eth0 OUT= SRC=192.168.1.100 DST=172.17.0.2 PROTO=TCP DPT=3000
```

## Troubleshooting Network Issues

### Step 1: Enable Logging
```bash
echo "FIREWALL_LOG_ENABLED=true" >> .devcontainer/.env
# Restart the container
```

### Step 2: Reproduce the Issue
Try the network operation that's failing.

### Step 3: Check Logs
```bash
# See what was blocked
sudo dmesg -T | grep 'FW-BLOCKED' | tail -20
```

### Step 4: Identify Blocked Domains
```bash
# Extract unique destination IPs
sudo dmesg | grep 'FW-BLOCKED-OUT' | grep -oP 'DST=\K[^ ]+' | sort -u

# Resolve IPs to domains (if possible)
for ip in $(sudo dmesg | grep 'FW-BLOCKED-OUT' | grep -oP 'DST=\K[^ ]+' | sort -u); do
  echo -n "$ip: "
  nslookup $ip 2>/dev/null | grep 'name =' | cut -d'=' -f2
done
```

### Step 5: Add Required Domains

If you identify legitimate domains being blocked, add them to the allowlist:

```bash
# Method 1: Environment variable
CUSTOM_ALLOWED_DOMAINS="example.com,api.service.com"

# Method 2: Project file
echo "example.com" >> .devcontainer/allowed-domains.txt
echo "api.service.com" >> .devcontainer/allowed-domains.txt
```

## Performance Considerations

- **Rate Limiting**: The default rate limit (10/min) prevents log flooding while still capturing enough data for debugging
- **Log Level**: Using `warning` level ensures logs appear in standard system log queries
- **Overhead**: Logging adds minimal overhead due to rate limiting, but should be disabled in production

## Security Notes

- Firewall logs may contain sensitive information (IP addresses, connection patterns)
- Logs are stored in kernel memory and cleared on container restart
- Consider log retention policies if exporting logs for analysis

## Best Practices

1. **Enable Only When Debugging**: Keep logging disabled during normal development
2. **Use Specific Prefixes**: Customize `FIREWALL_LOG_PREFIX` for easier filtering
3. **Monitor Log Volume**: Adjust rate limits if you need more/fewer log entries
4. **Document Findings**: When you identify blocked domains, document why they're needed
5. **Clean Up**: Disable logging once issues are resolved

## Common Scenarios

### NPM Package Installation Failures
```bash
# Enable logging
FIREWALL_LOG_ENABLED=true

# Try npm install
npm install some-package

# Check what was blocked
sudo dmesg | grep 'FW-BLOCKED' | grep ':443'
```

### API Connection Issues
```bash
# Enable verbose logging
FIREWALL_LOG_ENABLED=true
FIREWALL_LOG_LEVEL=info

# Make API request
curl https://api.example.com

# Analyze blocks
sudo dmesg -T | grep 'FW-BLOCKED-OUT'
```

### Debugging CI/CD Pipelines
```bash
# Enable with higher rate limit for CI
FIREWALL_LOG_ENABLED=true
FIREWALL_LOG_RATE_LIMIT=50/min

# Run CI pipeline
./run-ci.sh

# Export logs for analysis
sudo dmesg | grep 'FW-BLOCKED' > firewall-debug.log
```