# dotfiles

个人配置文件（WSL2 + Windows 环境）。

## 内容

| 文件 | 安装位置 | 说明 |
|---|---|---|
| `.wezterm.lua` | Windows home：`C:\Users\<用户名>\.wezterm.lua` | WezTerm 终端配置 |
| `windows-terminal/settings.json` | `%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` | Windows Terminal 配置 |
| `.tmux.conf` | WSL：`~/.tmux.conf` | tmux 配置（面向 Claude Code 优化） |
| `.oh-my-zsh/custom/claude.zsh` | WSL：`~/.oh-my-zsh/custom/claude.zsh` | Claude Code × tmux 工作流（`91` 系列命令） |
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

## tmux

面向 Claude Code 优化的 tmux 配置。安装：

```bash
cp .tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf   # 或重开终端
```

要点：

- **扩展按键 + 序列穿透**（`extended-keys` / `allow-passthrough`）：Shift+Enter 换行、Claude Code 的完成通知与进度条能穿过 tmux —— 不配这几行，在 tmux 里跑 cc 时这些全失效。
- **真彩色**（`tmux-256color` + `RGB`）：diff / 语法高亮配色更准。
- **标题模板** `#{pane_title} · #S:#I:#W`：tab 标题优先显示 **cc 当前任务**，后面跟「会话:窗口:进程」。
- 另含：`escape-time 10`（ESC 近零延迟）、`focus-events`、5 万行回滚、鼠标。

> 在 Windows Terminal 里跑：Shift+Enter 需要外层终端 + tmux 两边都支持扩展按键。Windows Terminal 1.25+ 已内置 Kitty 键盘协议（CSI-u），配合上面的 tmux 配置即可。

## Claude Code × tmux 工作流（`91` 系列）

在 tmux 里**并行跑多个 Claude Code**：每个任务一个独立会话（一个 Windows Terminal tab），可拽成独立窗口并排盯；关 tab / 断线不丢活，随时接回。

### 为什么叫 `91`？

`9` 谐音「就」、`1` 谐音「要」—— `91` 念出来就是「**就要**」。

敲下 `91`，潜台词是「**就要工作了**」：别刷手机、别纠结，光标一闪，说干就干。
不是被 996 推着走，是自己主动 `91` —— 一个键给自己喊「**就要开干**」。

（`a` = attach 接回，`k` = kill 结束，于是是 `91` / `91a` / `91k`。）

### 命令

| 命令 | 作用 |
|---|---|
| `91` | 在**当前项目目录**新开一个独立 cc 会话（`cc-<目录>-N`，N 自动递增，可并行多个）。`91 ~/path` 指定目录 |
| `91a` | **接回**一个后台会话。弹交互菜单（Tab/↑↓ 选 · 数字直选 · 回车确认 · Esc 取消），或 `91a 片段` 按任务名/会话名模糊匹配直连 |
| `91k` | **结束**一个后台会话。同样的交互菜单，或 `91k 片段` 直杀；自动排除你当前所在的会话 |

菜单里每项显示「**任务 · 会话名**」（任务取自 cc 写入的窗口标题），一眼看出哪个会话在干啥。

### 会话生命周期

| 动作 | 结果 |
|---|---|
| **退出 cc**（干完活） | 落回会话内 shell，**会话保留** —— 可跑 git、再 `claude`；敲一次 `exit` 关闭 tab |
| **关 tab** / `Ctrl+b d` | 会话**后台保活** → 之后 `91a` 接回 |
| 结束**别的**后台会话 | `91k`（菜单或片段） |

### 安装

```bash
mkdir -p ~/.oh-my-zsh/custom
cp .oh-my-zsh/custom/claude.zsh ~/.oh-my-zsh/custom/claude.zsh
exec zsh   # oh-my-zsh 会自动加载 custom/*.zsh
```

- **依赖**：`tmux`、`zsh`（oh-my-zsh）、`claude`（Claude Code CLI）。
- **前提**：函数里启动命令是裸 `claude`，依赖 `~/.claude/settings.json` 设了 `"permissions": { "defaultMode": "auto" }`（自动权限模式）。没设的话，把 `claude.zsh` 里的 `claude` 换成 `claude --dangerously-skip-permissions`。
- 同时建议装好上面的 **tmux 配置**（Shift+Enter / 通知 / 真彩色）。

### 实现小记

`91a` / `91k` 的菜单是自己用 `print` + 单键 `read` 画的，**没用 zsh `select`**：在 `C.UTF-8` locale 下 `select` 的多列宽度计算会把中文渲染成乱码。高亮用 ANSI 反显、刻意不做宽度对齐，以此绕开 `wcwidth` 对 CJK 的坑。

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
