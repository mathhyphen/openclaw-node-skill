# OpenClaw Node 配置指南

> 本文档描述如何通过 Tailscale 将 Linux 服务器配置为 OpenClaw Gateway 的 Node。

## 架构概览

```
┌─────────────────┐                      ┌─────────────────┐
│ Windows (Gateway)│  Tailscale Mesh VPN  │  Linux (Node)   │
│  - Gateway       │  <=================> │  - Node Runner  │
│  - Central Brain │    (WireGuard)       │  - Executor     │
└─────────────────┘                      └─────────────────┘
```

## 前置要求

1. Windows 机器上已安装并运行 OpenClaw Gateway
2. Linux 服务器上已安装 OpenClaw CLI (`npm install -g openclaw`)
3. Windows 和 Linux 都已加入同一个 Tailscale 网络
4. 确认双方可以互相 ping 通（通过 Tailscale IP 或 MagicDNS）

## 配置步骤

### 步骤 1：配置 Windows Gateway (Serve 模式)

编辑 `~/.openclaw/openclaw.json`：

```json5
{
  gateway: {
    mode: "local",
    bind: "loopback",        // 必须：只监听本地，通过 Tailscale Serve 暴露
    port: 18789,
    
    auth: {
      mode: "token",
      token: "<YOUR_GATEWAY_TOKEN>",  // 替换为强密码
      allowTailscale: true             // 允许 Tailscale 网络身份验证
    },
    
    tailscale: {
      mode: "serve",         // 启用 Tailscale Serve
      resetOnExit: false
    },
    
    nodes: {
      allowCommands: ["*"]   // 允许 Node 执行所有命令
    }
  }
}
```

**启动 Gateway：**
```powershell
openclaw gateway restart

# 验证 Serve 状态
tailscale serve status
# 应显示：https://<YOUR_TAILSCALE_HOST>.ts.net (tailnet only)
#          |-- / proxy http://127.0.0.1:18789
```

### 步骤 2：配置 Linux Node

#### 方法 A：使用环境变量（推荐）

```bash
# 设置环境变量
export OPENCLAW_GATEWAY_TOKEN="<YOUR_GATEWAY_TOKEN>"

# 启动 Node
openclaw node run \
  --host <YOUR_TAILSCALE_HOST>.ts.net \
  --port 443 \
  --tls \
  --display-name "<NODE_NAME>"
```

#### 方法 B：使用配置文件

创建 `~/.openclaw/node.json`：

```json
{
  "version": 1,
  "displayName": "<NODE_NAME>",
  "gateway": {
    "host": "<YOUR_TAILSCALE_HOST>.ts.net",
    "port": 443,
    "tls": true
  }
}
```

**注意：** `node.json` 不会自动读取 token，仍需设置环境变量或 CLI 参数。

### 步骤 3：配对批准

1. 在 Linux 上执行 `openclaw node run` 后，会显示 `pairing required`
2. 在 Windows Gateway 上查看待批准请求：
   ```powershell
   openclaw devices list
   # 或
   openclaw nodes pending
   ```
3. 批准 Node：
   ```powershell
   openclaw devices approve <REQUEST_ID>
   ```
4. 验证连接：
   ```powershell
   openclaw nodes status
   # 应显示：paired · connected
   ```

### 步骤 4：配置执行权限（关键）

Node 默认有安全沙箱，需要显式授权才能执行命令。

在 **Linux Node** 上执行：

```bash
# 创建执行权限配置文件
mkdir -p ~/.openclaw
cat > ~/.openclaw/exec-approvals.json << 'EOF'
{
  "version": 1,
  "defaults": {
    "security": "full",
    "ask": "off"
  }
}
EOF
```

**安全级别说明：**
- `security: "deny"` - 拒绝所有命令
- `security: "allowlist"` - 只允许白名单命令
- `security: "full"` - 允许所有命令（Node 模式下推荐）

### 步骤 5：设置开机自启（可选）

创建 systemd 服务 `/etc/systemd/system/openclaw-node.service`：

```ini
[Unit]
Description=OpenClaw Node
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
Type=simple
User=<USERNAME>
Environment="OPENCLAW_GATEWAY_TOKEN=<YOUR_GATEWAY_TOKEN>"
Environment="PATH=<NODE_PATH>:/usr/local/bin:/usr/bin:/bin"
ExecStart=<OPENCLAW_PATH> node run \
  --host <YOUR_TAILSCALE_HOST>.ts.net \
  --port 443 \
  --tls \
  --display-name "<NODE_NAME>"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw-node.service
sudo systemctl start openclaw-node.service
```

## 故障排查

### 错误：400 Bad Request

**原因：** Token 未正确传递

**解决：** 确保设置了 `OPENCLAW_GATEWAY_TOKEN` 环境变量或使用 `--token` 参数

### 错误：pairing required

**原因：** Node 未在 Gateway 上批准

**解决：** 在 Windows 上执行 `openclaw devices approve <ID>`

### 错误：SYSTEM_RUN_DENIED: allowlist miss

**原因：** Node 未配置执行权限

**解决：** 在 Linux 上创建 `~/.openclaw/exec-approvals.json`，设置 `security: "full"`

### 错误：ECONNREFUSED

**原因：** 无法连接到 Gateway

**解决：**
1. 检查 Tailscale 状态：`tailscale status`
2. 检查 Gateway 是否运行：`openclaw gateway status`
3. 检查防火墙是否放行

## 安全最佳实践

1. **Token 管理：** 使用强密码，定期更换
2. **网络隔离：** 利用 `allowTailscale: true` 限制只有 Tailscale 网络可访问
3. **权限最小化：** 生产环境建议使用 `allowlist` 而非 `full` 权限
4. **日志审计：** 定期检查 `~/.openclaw/logs/` 目录

## 资源占用

Node 进程资源消耗极低：
- CPU: ~0.1-0.5% (空闲时)
- 内存: ~50-100 MB
- 网络: ~1-5 KB/s (维持心跳)

适合长期运行在服务器上。

## 参考

- OpenClaw 官方文档: https://docs.openclaw.ai
- Tailscale Serve: https://tailscale.com/kb/1242/tailscale-serve
