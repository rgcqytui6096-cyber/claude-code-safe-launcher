# Claude Code Safe Launcher

给 Claude Code 终端版和 Claude 桌面端加一层启动前安全闸门。

Claude Code 不是普通聊天 App。它能读文件、跑命令、改仓库、调 MCP、碰浏览器和数据库工具。这样的工具不应该在你没注意的时候，静默继承本机的 API key、代理地址和 provider 路由变量。

这个项目只做一件事：

**Claude 启动前先检查本机环境。检查不过，就不启动。**

它不修改 Claude 官方二进制，不破坏签名，不绕过账号、地区或服务商规则。它是本机启动防护，不是破解工具。

## 快速安装

### 一行安装

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rgcqytui6096-cyber/claude-code-safe-launcher/main/scripts/install.sh)"
```

### 先下载再安装

```bash
git clone https://github.com/rgcqytui6096-cyber/claude-code-safe-launcher.git
cd claude-code-safe-launcher
bash scripts/install.sh
```

## 桌面端用户

安装完成后，不要再点原来的 Claude 图标。

改用：

```text
~/Applications/Claude Safe.app
```

建议把 `Claude Safe.app` 拖到 Dock，替换原来的 Claude 图标。

详细步骤看这里：

[桌面端和终端安装教程](docs/INSTALL.zh-CN.md)

## 它挡什么

启动前拦截这些 Anthropic 相关变量：

```text
ANTHROPIC_BASE_URL
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_API_KEY
```

启动 Claude 子进程前移除这些第三方 provider key：

```text
OPENROUTER_API_KEY
OPENAI_API_KEY
```

默认设置非必要流量/遥测关闭变量：

```text
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
DO_NOT_TRACK=1
DISABLE_TELEMETRY=1
DISABLE_ERROR_REPORTING=1
DISABLE_AUTOUPDATER=1
```

这些变量是否全部生效，取决于 Claude 当前版本支持情况。不要把它们当成唯一的隐私保证。

## 安装后会放哪些文件

```text
~/.local/bin/claude
~/.local/bin/claude.unprotected
~/.local/bin/claude-gui-guard
~/Library/LaunchAgents/local.claude.safe-env.plist
~/Applications/Claude Safe.app
```

原版 `/Applications/Claude.app` 不会被修改。

## 卸载

一行安装的用户，用这个卸载：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rgcqytui6096-cyber/claude-code-safe-launcher/main/scripts/uninstall.sh)"
```

如果你是先下载仓库再安装，用这个：

```bash
bash scripts/uninstall.sh
```

## 这个项目不能替你做什么

这不是完整沙箱。

它不会：

- 审计每一个网络请求
- 阻止所有 MCP 工具
- 改写 Claude 的系统提示词
- 修改 Claude 官方二进制
- 阻止你直接打开原版 `/Applications/Claude.app`
- 替你判断每一个 shell 命令是否安全

如果你需要更强防护，继续加：

- Claude Code permissions
- MCP deny rules
- sandbox
- 陌生 GitHub 仓库隔离环境
- 不自动执行未知安装脚本
- 不把数据库连接、SSH key、生产环境密钥暴露给 AI 工具

## 建议

不要把 AI 编程工具当普通编辑器。

它能跑命令，就应该被当成有执行权的本地代理看待。

能不给的环境变量就不给。能不继承的 key 就不继承。能在启动前挡住的风险，就不要等启动后再补救。

这个项目就是第一道闸门。

## 相关资料

- Anthropic docs: [environment variables](https://code.claude.com/docs/en/env-vars)
- Anthropic docs: [data usage](https://code.claude.com/docs/en/data-usage)
- Anthropic docs: [permissions](https://code.claude.com/docs/en/permissions)
- Anthropic docs: [sandboxing](https://code.claude.com/docs/en/sandboxing)
- GitHub Advisory: [GHSA-jh7p-qr78-84p7](https://github.com/anthropics/claude-code/security/advisories/GHSA-jh7p-qr78-84p7)

## License

MIT
