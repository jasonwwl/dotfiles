# dotfiles

个人配置文件。

## 内容

| 文件 | 对应位置 | 说明 |
|---|---|---|
| `.wezterm.lua` | `~/.wezterm.lua` | WezTerm 终端配置 |
| `.claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Claude Code 状态栏脚本 |

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
