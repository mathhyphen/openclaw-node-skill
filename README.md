# OpenClaw Node Setup

A comprehensive skill and toolkit for configuring OpenClaw nodes with Tailscale networking and security allowlists.

## Features

- 🔐 **Secure by Default**: Uses allowlist-based command execution
- 🌐 **Tailscale Integration**: Encrypted VPN connections between nodes
- 🤖 **Automated Setup**: One-command node configuration
- 🔧 **Systemd Support**: Persistent connections with auto-restart
- 🛡️ **Windows Firewall**: Automated firewall configuration

## Quick Start

### Prerequisites

1. OpenClaw Gateway installed on Windows/macOS/Linux
2. Tailscale installed on both gateway and node
3. OpenClaw CLI installed on the node

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/openclaw-node-setup.git

# Or install as OpenClaw skill
openclaw skills install github.com/yourusername/openclaw-node-setup
```

### Setup Steps

1. **Configure Windows Firewall** (on Gateway):
   ```powershell
   # Run as Administrator
   .\scripts\configure-firewall.ps1
   ```

2. **Run Node Setup** (on Linux Server):
   ```bash
   bash scripts/setup-node.sh
   ```

3. **Verify Connection**:
   The node should appear as connected in your OpenClaw Gateway.

## Repository Structure

```
openclaw-node-setup/
├── README.md                          # Main documentation
├── SKILL.md                           # OpenClaw skill definition
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── scripts/
│   ├── setup-node.sh                 # Linux node setup script
│   └── configure-firewall.ps1        # Windows firewall config
└── examples/
    ├── gateway-config.example.json   # Gateway configuration example
    └── node-allowlist.example.json   # Node allowlist example
```

## Security Considerations

⚠️ **Important**: This tool configures remote command execution. Always:

1. **Use Tailscale or VPN**: Never expose OpenClaw Gateway directly to the internet
2. **Strong Passwords**: Use randomly generated passwords for gateway authentication
3. **Allowlist Mode**: Keep `security: "allowlist"` enabled to restrict commands
4. **File Permissions**: Ensure `exec-approvals.json` has `chmod 600` permissions
5. **Regular Audits**: Run `openclaw security audit` periodically

## Configuration

### Gateway Configuration

See `examples/gateway-config.example.json` for a minimal secure configuration.

Key settings:
- `bind: "lan"` - Listen on all interfaces (use with Tailscale)
- `auth.mode: "password"` - Password-based authentication
- `tools.exec.host: "node"` - Allow node command execution
- `tools.exec.security: "allowlist"` - Enforce command allowlists

### Node Allowlist

See `examples/node-allowlist.example.json` for a comprehensive allowlist.

The allowlist:
- Allows common system commands (`ls`, `cat`, `ps`, `df`, etc.)
- Allows development tools (`git`, `docker`, `python3`, etc.)
- Blocks dangerous commands (`rm`, `dd`, `mkfs` are in `/sbin`, not allowed)

## Troubleshooting

### Connection Refused (ECONNREFUSED)

**Cause**: Windows Firewall blocking the connection

**Solution**:
```powershell
netsh advfirewall firewall add rule name="OpenClaw" dir=in action=allow protocol=TCP localport=18789
```

### Command Execution Denied

**Cause**: Command not in allowlist or allowlist file not found

**Solution**:
1. Verify `~/.openclaw/exec-approvals.json` exists on the node
2. Check that the command path is in the allowlist
3. Ensure file has correct permissions: `chmod 600 ~/.openclaw/exec-approvals.json`

### Node Shows Offline

**Checklist**:
- [ ] Tailscale is connected on both sides (`tailscale status`)
- [ ] Gateway is running (`openclaw status`)
- [ ] Port is listening (`netstat -ano | findstr 18789`)
- [ ] Password is correct
- [ ] Linux node has internet access

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## References

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Tailscale Documentation](https://tailscale.com/kb)

## Disclaimer

This tool is provided as-is for educational and productivity purposes. The authors are not responsible for any security incidents resulting from misconfiguration. Always follow security best practices and keep your systems updated.
