# OpenClaw Node Configuration (Linux)

## Overview
This guide documents the setup of an OpenClaw Node on a Linux server using a **User-level Systemd service**. This method allows the node to run automatically without requiring root/sudo permissions for daily operations.

## Configuration Steps

1. **Prerequisites**
   - Ensure `openclaw` is installed and accessible in your shell.
   - Tailscale is running on both Gateway (host) and Node (server).

2. **Create Service Directory**
   ```bash
   mkdir -p ~/.config/systemd/user/
   ```

3. **Create Service File**
   Create `~/.config/systemd/user/openclaw-node.service`:
   ```ini
   [Unit]
   Description=OpenClaw Node Host
   After=network.target

   [Service]
   # Set Path to Node v24+ and Inject Gateway Token
   Environment="PATH=/home/ssddata/wanghaifeng/.nvm/versions/node/v24.12.0/bin:/usr/local/bin:/usr/bin:/bin"
   Environment="OPENCLAW_GATEWAY_TOKEN=YOUR_TOKEN_HERE"

   # Execute Path
   ExecStart=/home/ssddata/wanghaifeng/.nvm/versions/node/v24.12.0/bin/openclaw node run --host YOUR_HOST_MAGICDNS --port 443 --tls --display-name "3002-server"
   
   Restart=always
   RestartSec=5

   [Install]
   WantedBy=default.target
   ```

4. **Enable & Start**
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable openclaw-node.service
   systemctl --user start openclaw-node.service
   loginctl enable-linger <your-username>
   ```

## Security
- Do not commit your `OPENCLAW_GATEWAY_TOKEN` to public repositories.
- Use `Environment` files for secrets if sharing this configuration.
