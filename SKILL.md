# OpenClaw Node Setup

Skill for configuring OpenClaw nodes with secure allowlists.

## Description

Automates the setup of OpenClaw nodes on Linux servers, including:
- Tailscale VPN configuration
- Secure command execution with allowlists
- Systemd service for persistent connections
- Firewall configuration on Windows gateway

## Tools

### setup-node

Configure a new Linux server as an OpenClaw node.

**Usage:**
```
Setup a new OpenClaw node on my Linux server at 192.168.1.100
```

**Parameters:**
- `host` - The Tailscale IP or hostname of the gateway
- `password` - Gateway authentication password
- `displayName` - Display name for the node

### configure-allowlist

Set up the exec allowlist on a Linux node.

**Usage:**
```
Configure the allowlist on my node
```

### create-systemd-service

Create a systemd service for persistent node connection.

**Usage:**
```
Create a systemd service for the node connection
```

## Installation

1. Clone this repository to your OpenClaw skills directory
2. The skill will be automatically discovered

## Requirements

- OpenClaw CLI installed on the node
- Tailscale on both gateway and node
- SSH access to the node (for initial setup)

## Configuration

### Minimal Gateway Config

Add to your `openclaw.json`:

```json
{
  "gateway": {
    "port": 18789,
    "bind": "lan",
    "auth": {
      "mode": "password",
      "password": "${OPENCLAW_GATEWAY_PASSWORD}"
    }
  },
  "tools": {
    "exec": {
      "host": "node",
      "security": "allowlist"
    }
  }
}
```

### Node Allowlist Config

Place on the Linux node at `~/.openclaw/exec-approvals.json`:

```json
{
  "version": 1,
  "defaults": {
    "security": "allowlist",
    "ask": "off"
  },
  "agents": {
    "main": {
      "security": "allowlist",
      "ask": "off",
      "allowlist": [
        {"pattern": "/usr/bin/uname"},
        {"pattern": "/usr/bin/ls"},
        {"pattern": "/usr/bin/cat"},
        {"pattern": "/bin/*"},
        {"pattern": "/usr/bin/*"}
      ]
    }
  }
}
```

## Safety Notes

⚠️ This skill configures remote command execution. Always:
- Use Tailscale or other VPN for network security
- Configure allowlists to restrict executable commands
- Use strong, unique passwords for gateway auth
- Set proper file permissions (600) on exec-approvals.json

## Author

OpenClaw Community

## Version

1.0.0
