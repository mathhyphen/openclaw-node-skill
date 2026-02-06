#!/bin/bash
# Setup script for OpenClaw Node on Linux servers
# This script configures a Linux server as an OpenClaw node with security allowlists

set -e

echo "🔧 OpenClaw Node Setup Script"
echo "=============================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "⚠️  Please do not run as root. The script will use sudo when needed."
   exit 1
fi

# Get configuration from user
echo ""
read -p "Enter Gateway Tailscale IP: " GATEWAY_IP
read -p "Enter Gateway Password: " GATEWAY_PASSWORD
read -p "Enter Node Display Name [$(hostname)]: " NODE_NAME
NODE_NAME=${NODE_NAME:-$(hostname)}

echo ""
echo "📦 Step 1: Installing OpenClaw CLI..."
if ! command -v openclaw &> /dev/null; then
    echo "Installing OpenClaw via npm..."
    npm install -g openclaw
else
    echo "OpenClaw already installed: $(openclaw --version)"
fi

echo ""
echo "🔐 Step 2: Creating OpenClaw directory..."
mkdir -p ~/.openclaw
chmod 700 ~/.openclaw

echo ""
echo "📝 Step 3: Creating exec allowlist..."
cat > ~/.openclaw/exec-approvals.json << EOF
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
        {"pattern": "/usr/bin/ps"},
        {"pattern": "/usr/bin/top"},
        {"pattern": "/usr/bin/df"},
        {"pattern": "/usr/bin/du"},
        {"pattern": "/usr/bin/free"},
        {"pattern": "/usr/bin/uptime"},
        {"pattern": "/usr/bin/whoami"},
        {"pattern": "/usr/bin/hostname"},
        {"pattern": "/usr/bin/pwd"},
        {"pattern": "/usr/bin/echo"},
        {"pattern": "/usr/bin/grep"},
        {"pattern": "/usr/bin/awk"},
        {"pattern": "/usr/bin/sed"},
        {"pattern": "/usr/bin/find"},
        {"pattern": "/usr/bin/curl"},
        {"pattern": "/usr/bin/wget"},
        {"pattern": "/usr/bin/git"},
        {"pattern": "/usr/bin/docker"},
        {"pattern": "/usr/bin/python3"},
        {"pattern": "/usr/bin/node"},
        {"pattern": "/usr/bin/npm"},
        {"pattern": "/bin/*"},
        {"pattern": "/usr/bin/*"}
      ]
    }
  }
}
EOF
chmod 600 ~/.openclaw/exec-approvals.json
echo "✅ Allowlist created at ~/.openclaw/exec-approvals.json"

echo ""
echo "🔌 Step 4: Testing connection..."
export OPENCLAW_GATEWAY_PASSWORD="$GATEWAY_PASSWORD"
timeout 10 openclaw node run --host "$GATEWAY_IP" --port 18789 --display-name "$NODE_NAME" &
PID=$!
sleep 5

if ps -p $PID > /dev/null; then
    echo "✅ Connection successful!"
    kill $PID 2>/dev/null || true
else
    echo "❌ Connection failed. Please check:"
    echo "   - Is the gateway running?"
    echo "   - Is the password correct?"
    echo "   - Is Tailscale connected on both sides?"
    exit 1
fi

echo ""
echo "🔧 Step 5: Creating systemd service..."
sudo tee /etc/systemd/system/openclaw-node.service > /dev/null << EOF
[Unit]
Description=OpenClaw Node
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment="OPENCLAW_GATEWAY_PASSWORD=$GATEWAY_PASSWORD"
ExecStart=$(which openclaw) node run --host $GATEWAY_IP --port 18789 --display-name "$NODE_NAME"
Restart=always
RestartSec=5
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable openclaw-node
echo "✅ Systemd service created"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "To start the node service:"
echo "  sudo systemctl start openclaw-node"
echo ""
echo "To check status:"
echo "  sudo systemctl status openclaw-node"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u openclaw-node -f"
