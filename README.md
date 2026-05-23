# dotfiles

个人配置文件（WSL2 + Windows 环境）。

## 内容

| 文件 | 安装位置 | 说明 |
|---|---|---|
| `.wezterm.lua` | Windows home：`C:\Users\<用户名>\.wezterm.lua` | WezTerm 终端配置 |
| `windows-terminal/settings.json` | `%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` | Windows Terminal 配置 |
| `.claude/statusline-command.sh` | WSL：`~/.claude/statusline-command.sh` | Claude Code 状态栏脚本 |

> WezTerm 与 Windows Terminal 都跑在 **Windows 端**，配置不在 WSL 的 `~` 里。
> 两者统一用 **Dracula** 配色 + **Maple Mono NF CN** 字体（需在 Windows 装好该字体）。

## Windows Terminal

把 `windows-terminal/settings.json` 复制到：

```
%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

在 WSL 里即（`<用户名>` 替换成你的 Windows 用户名）：

```bash
cp windows-terminal/settings.json \
  "/mnt/c/Users/<用户名>/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
```

特性：Shift+Enter 换行（配合 Claude Code 多行输入）、Ctrl+Shift+C/V 复制粘贴、Ctrl+Shift+F 查找、Alt+Shift+D 分屏。

## WezTerm

把 `.wezterm.lua` 复制到 Windows home：

```bash
cp .wezterm.lua /mnt/c/Users/<用户名>/.wezterm.lua
```

## Claude Code 状态栏

两行式状态栏（左竖条侧栏风格）。

```
▌ 会话名 · ~/工作目录 · 分支[*] [↑3] [⚑5]
▌ Opus 4.7 high · ███░░░░░░░ 30% · 5h 76% (5x 304%) ↻ 2h13m · 7d 31%
```

- **第一行**：会话名（`/rename` 设置后才显示）· 工作目录 · Git 分支（未提交跟 `*`、未 push 跟 `↑N`、有 stash 跟 `⚑N`）
- **第二行**：模型 + effort · 上下文进度条 · 5h 用量 · 7d 用量
- 5h 用量 ≥70% 显示**重置倒计时**（`↻ 2h13m`）；7d 用量 ≥70% 显示**重置时刻**（`↻ 周三 19:40`）
- 用量 ≥25% 显示 **5x 等效百分比**（`(5x 304%)`）——针对 Max 20x 订阅换算到 5x 的概念（20x 用量 ×4）
- 进度条/用量按阈值变色：青（低）→ 黄（中）→ 红（高）

### 安装（新机器）

```bash
# 1. 复制脚本到 ~/.claude/
mkdir -p ~/.claude
cp .claude/statusline-command.sh ~/.claude/statusline-command.sh

# 2. 在 ~/.claude/settings.json 里加上 statusLine 字段（已有 settings 则合并这一段）
```

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

重开 Claude Code 即生效。

### 依赖

- `jq`、`git`、GNU `date`
- macOS 的 BSD `date` 不支持 `date -d @<epoch>`，重置时间字段会**静默隐藏**（其余正常）；需要的话 `brew install coreutils` 并把脚本里的 `date` 换成 `gdate`。
