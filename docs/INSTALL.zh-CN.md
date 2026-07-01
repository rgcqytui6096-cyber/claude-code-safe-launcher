# 安装教程

这份教程给两类人：

- 只用 Claude 桌面端的人
- 同时用 Claude Code 终端版的人

如果你只想保护桌面端，也需要先运行一次安装命令。安装完成后，以后点 `Claude Safe.app` 即可。

## 安装前确认

macOS 用户建议先确认原版 Claude 在这里：

```text
/Applications/Claude.app
```

如果你没有安装 Claude 桌面端，也可以只安装终端版 wrapper。

## 方式一：一行安装

打开“终端”，复制执行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rgcqytui6096-cyber/claude-code-safe-launcher/main/scripts/install.sh)"
```

安装脚本会自动完成：

- 给终端版 `claude` 加启动前检查
- 创建 `~/Applications/Claude Safe.app`
- 安装 `claude-gui-guard`
- 注册登录时自动清理 GUI 环境的 LaunchAgent
- 给 `Claude Safe.app` 使用原版 Claude 图标

## 方式二：先下载再安装

如果你不想直接执行远程脚本，用这个方式：

```bash
git clone https://github.com/rgcqytui6096-cyber/claude-code-safe-launcher.git
cd claude-code-safe-launcher
bash scripts/install.sh
```

## 桌面端怎么用

安装完成后，会出现：

```text
~/Applications/Claude Safe.app
```

以后桌面端从它启动。

推荐设置方式：

1. 打开 Finder
2. 菜单栏点“前往”
3. 点“个人”
4. 打开 `Applications`
5. 找到 `Claude Safe.app`
6. 双击它，确认能正常打开 Claude
7. 把 Dock 里原来的 Claude 图标移除
8. 把 `Claude Safe.app` 拖到 Dock

以后你点 Dock 里的 Claude 图标，实际走的是安全入口。

## 为什么不能继续点原版 Claude

原版 `/Applications/Claude.app` 仍然能直接打开。

但直接点原版 Claude，会绕过“每次启动前检查”这一层。

所以建议：

- Dock 里只保留 `Claude Safe.app`
- 不要再从 `/Applications/Claude.app` 直接启动
- 如果图标没刷新，先从 Dock 移除，再重新拖入 `Claude Safe.app`

## 终端版怎么用

安装后继续正常使用：

```bash
claude
```

启动前会自动检查：

```text
ANTHROPIC_BASE_URL
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_API_KEY
```

只要其中任何一个存在，就直接拦截，不启动。

## 怎么确认安装成功

### 检查桌面端守卫

```bash
~/.local/bin/claude-gui-guard check
```

正常会看到：

```text
[claude-gui-guard] no Anthropic API/base URL variables are present in the macOS GUI environment.
```

### 检查终端版 wrapper

```bash
claude --version
```

如果能显示 Claude Code 版本，说明 wrapper 能找到原始 Claude。

### 测试拦截是否生效

```bash
ANTHROPIC_BASE_URL=https://blocked.invalid claude --version
```

正常应该被拦截。

## 如果启动失败

### 提示 `ANTHROPIC_BASE_URL is set`

说明你的当前 shell 或 GUI 环境里还有 `ANTHROPIC_BASE_URL`。

如果你是官方订阅用户，一般不应该设置这个变量。先清掉它再启动。

### 找不到 `Claude Safe.app`

重新运行安装脚本：

```bash
bash scripts/install.sh
```

然后检查：

```bash
ls -ld ~/Applications/Claude\ Safe.app
```

### Dock 图标还是旧的

macOS 有时会缓存图标。

处理方式：

1. 从 Dock 移除旧图标
2. 重新把 `~/Applications/Claude Safe.app` 拖到 Dock
3. 必要时重启 Finder 或重新登录

## 卸载

如果你是一行命令安装的，用这个卸载：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rgcqytui6096-cyber/claude-code-safe-launcher/main/scripts/uninstall.sh)"
```

如果你是先下载仓库再安装的，进入项目目录执行：

```bash
bash scripts/uninstall.sh
```

卸载后：

- 移除 `Claude Safe.app`
- 移除 `claude-gui-guard`
- 移除登录清理项
- 尽量恢复原始 `claude` 命令

## 更强防护

这个项目只是启动前闸门，不是完整沙箱。

如果你经常打开陌生仓库，建议继续配置：

- Claude Code permissions
- MCP deny rules
- sandbox
- 容器或虚拟机
- 禁止自动执行未知安装脚本
