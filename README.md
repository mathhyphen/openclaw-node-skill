# OpenClaw 节点配置工具

用于配置 OpenClaw 节点的一站式工具包，支持 Tailscale 网络和安全白名单。

## 功能特性

- 🔐 **默认安全**：使用白名单模式限制可执行命令
- 🌐 **Tailscale 集成**：节点间加密 VPN 连接
- 🤖 **自动化配置**：一键配置节点
- 🔧 **Systemd 支持**：持久连接，自动重启
- 🛡️ **Windows 防火墙**：自动配置防火墙规则

## 快速开始

### 前置要求

1. Windows/macOS/Linux 上安装 OpenClaw Gateway
2. 网关和节点都安装 Tailscale
3. 节点上安装 OpenClaw CLI

### 安装

```bash
# 克隆仓库
git clone https://github.com/yourusername/openclaw-node-setup.git

# 或作为 OpenClaw skill 安装
openclaw skills install github.com/yourusername/openclaw-node-setup
```

### 配置步骤

1. **配置 Windows 防火墙**（在网关上）：
   ```powershell
   # 以管理员身份运行
   .\scripts\configure-firewall.ps1
   ```

2. **运行节点配置**（在 Linux 服务器上）：
   ```bash
   bash scripts/setup-node.sh
   ```

3. **验证连接**：
   节点应该显示为已连接状态。

## 仓库结构

```
openclaw-node-setup/
├── README.md                          # 主文档
├── README_EN.md                       # 英文文档
├── SKILL.md                           # OpenClaw skill 定义
├── LICENSE                            # MIT 许可证
├── .gitignore                         # Git 忽略规则
├── scripts/
│   ├── setup-node.sh                 # Linux 节点配置脚本
│   └── configure-firewall.ps1        # Windows 防火墙配置
└── examples/
    ├── gateway-config.example.json   # 网关配置示例
    └── node-allowlist.example.json   # 节点白名单示例
```

## 安全注意事项

⚠️ **重要**：本工具配置远程命令执行，请务必：

1. **使用 Tailscale 或 VPN**：不要将 OpenClaw Gateway 直接暴露到公网
2. **强密码**：为网关认证使用随机生成的强密码
3. **白名单模式**：保持 `security: "allowlist"` 以限制可执行命令
4. **文件权限**：确保 `exec-approvals.json` 设置为 `chmod 600`
5. **定期审计**：定期运行 `openclaw security audit`

## 配置说明

### 网关配置

查看 `examples/gateway-config.example.json` 获取最小安全配置。

关键设置：
- `bind: "lan"` - 监听所有接口（配合 Tailscale 使用）
- `auth.mode: "password"` - 基于密码的认证
- `tools.exec.host: "node"` - 允许节点命令执行
- `tools.exec.security: "allowlist"` - 强制执行命令白名单

### 节点白名单

查看 `examples/node-allowlist.example.json` 获取完整的白名单示例。

白名单特点：
- 允许常用系统命令（`ls`, `cat`, `ps`, `df` 等）
- 允许开发工具（`git`, `docker`, `python3` 等）
- 阻止危险命令（`rm`, `dd`, `mkfs` 等在 `/sbin` 中，不允许）

## 故障排除

### 连接被拒绝 (ECONNREFUSED)

**原因**：Windows 防火墙阻止连接

**解决**：
```powershell
netsh advfirewall firewall add rule name="OpenClaw" dir=in action=allow protocol=TCP localport=18789
```

### 命令执行被拒绝

**原因**：命令不在白名单中或白名单文件不存在

**解决**：
1. 验证节点上存在 `~/.openclaw/exec-approvals.json`
2. 检查命令路径是否在白名单中
3. 确保文件权限正确：`chmod 600 ~/.openclaw/exec-approvals.json`

### 节点显示离线

**检查清单**：
- [ ] Tailscale 双方已连接（`tailscale status`）
- [ ] 网关正在运行（`openclaw status`）
- [ ] 端口正在监听（`netstat -ano | findstr 18789`）
- [ ] 密码正确
- [ ] Linux 节点有网络访问

## 贡献指南

欢迎贡献！请：
1. Fork 本仓库
2. 创建功能分支
3. 提交更改
4. 提交 Pull Request

## 许可证

MIT 许可证 - 详情见 [LICENSE](LICENSE) 文件。

## 参考资料

- [OpenClaw 文档](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Tailscale 文档](https://tailscale.com/kb)

## 免责声明

本工具按原样提供，用于教育和生产力目的。作者不对因配置错误导致的安全事件负责。请始终遵循安全最佳实践并保持系统更新。
