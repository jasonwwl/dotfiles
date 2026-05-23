#!/usr/bin/env bash
# Claude Code status line —— 两行 · 左竖条侧栏风格

input=$(cat)

# ── 颜色常量（用 $'...' 让 \033 成为真实 ESC 字节，便于当数据传递）──
C_RESET=$'\033[0m'
C_BAR=$'\033[38;5;75m'    # 左竖条：柔蓝（对齐锚点）
C_SESSION=$'\033[1;97m'   # 会话名：亮白加粗
C_DIR=$'\033[34m'         # 工作目录：蓝
C_GIT=$'\033[32m'         # Git 分支：绿
C_DIRTY=$'\033[31m'       # 未提交标记：红
C_MODEL=$'\033[36m'       # 模型：青
C_DIM=$'\033[90m'         # 次要信息（effort/分隔符/倒计时）：暗灰
C_RED=$'\033[31m'
C_YEL=$'\033[33m'
C_CYN=$'\033[36m'
SEP="${C_DIM}·${C_RESET}"

# 按百分比取色：低于黄阈值青、达到黄阈值黄、达到红阈值红
pct_color() { # $1=百分比 $2=黄阈值 $3=红阈值
  if   [ "$1" -ge "$3" ]; then printf '%s' "$C_RED"
  elif [ "$1" -ge "$2" ]; then printf '%s' "$C_YEL"
  else printf '%s' "$C_CYN"; fi
}

# 当前为 20x 额度。20x 用量 ≥25% 时（=5x 满 100%），换算成 5x 等效百分比（×4）红色提示
x5_note() { # $1=20x 用量百分比
  [ "$1" -ge 25 ] && printf ' %s(5x %d%%)%s' "$C_RED" "$(( $1 * 4 ))" "$C_RESET"
}

# ── 基础数据 ────────────────────────────────────────────────
session_name=$(echo "$input" | jq -r '.session_name // empty')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$dir" ] && dir=$(pwd)
home="$HOME"
# 家目录缩写为 ~（不用 ${dir/#$home/~}：bash 会对替换串里的 ~ 做波浪号扩展，导致不缩写）
case "$dir" in
  "$home"/*) short_dir="~${dir#$home}" ;;
  "$home")   short_dir="~" ;;
  *)         short_dir="$dir" ;;
esac

model=$(echo "$input" | jq -r '.model.display_name // empty')
model="${model#Claude }"   # 去掉 "Claude " 前缀，更紧凑
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hr=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ── Git 分支（有未提交变更时跟红色 *）──────────────────────
git_str=""
if git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # 分支名（有未提交变更跟红色 *）
    if [ -n "$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
      git_str="${C_GIT}${branch}${C_DIRTY}*${C_RESET}"
    else
      git_str="${C_GIT}${branch}${C_RESET}"
    fi
    # 未 push 提交数（领先上游），>0 黄色显示 ↑N
    ahead=$(git -C "$dir" --no-optional-locks rev-list --count @{u}..HEAD 2>/dev/null)
    if [ -n "$ahead" ] && [ "$ahead" -gt 0 ]; then
      git_str="${git_str} ${C_YEL}↑ ${ahead}${C_RESET}"
    fi
    # stash 数，>0 暗灰显示 ⚑N
    stash_n=$(git -C "$dir" --no-optional-locks stash list 2>/dev/null | wc -l | tr -d ' ')
    if [ -n "$stash_n" ] && [ "$stash_n" -gt 0 ]; then
      git_str="${git_str} ${C_DIM}⚑ ${stash_n}${C_RESET}"
    fi
  fi
fi

# ── 上下文进度条（10 格）────────────────────────────────────
ctx_str=""
if [ -n "$used" ]; then
  used_int=${used%.*}
  filled=$(( used_int * 10 / 100 ))
  [ "$filled" -gt 10 ] && filled=10
  empty=$(( 10 - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty;  i++)); do bar="${bar}░"; done
  c=$(pct_color "$used_int" 60 85)
  ctx_str="${c}${bar} ${used_int}%${C_RESET}"
fi

# ── 5 小时用量（≥70% 附带重置倒计时）───────────────────────
five_str=""
if [ -n "$five_hr" ]; then
  five_int=${five_hr%.*}
  c=$(pct_color "$five_int" 50 80)
  five_str="${c}5h ${five_int}%${C_RESET}$(x5_note "$five_int")"
  if [ "$five_int" -ge 70 ] && [ -n "$five_reset" ]; then
    diff=$(( five_reset - $(date +%s) ))
    if [ "$diff" -gt 0 ]; then
      h=$(( diff / 3600 )); m=$(( (diff % 3600) / 60 ))
      if [ "$h" -gt 0 ]; then left="${h}h${m}m"; else left="${m}m"; fi
      five_str="${five_str} ${C_DIM}↻ ${left}${C_RESET}"
    fi
  fi
fi

# ── 7 天用量 ───────────────────────────────────────────────
seven_str=""
if [ -n "$seven_day" ]; then
  seven_int=${seven_day%.*}
  c=$(pct_color "$seven_int" 50 80)
  seven_str="${c}7d ${seven_int}%${C_RESET}$(x5_note "$seven_int")"
  # 用量 ≥70% 时，灰色显示 7d 窗口重置时刻（周X HH:MM）
  if [ "$seven_int" -ge 70 ] && [ -n "$seven_reset" ]; then
    dow=$(date -d "@$seven_reset" +%u 2>/dev/null)
    hm=$(date -d "@$seven_reset" +%H:%M 2>/dev/null)
    case "$dow" in
      1) wd="周一" ;; 2) wd="周二" ;; 3) wd="周三" ;; 4) wd="周四" ;;
      5) wd="周五" ;; 6) wd="周六" ;; 7) wd="周日" ;; *) wd="" ;;
    esac
    [ -n "$hm" ] && seven_str="${seven_str} ${C_DIM}↻ ${wd} ${hm}${C_RESET}"
  fi
fi

# ── 模型 + effort（effort 跟在模型后，暗灰）──────────────────
model_str=""
if [ -n "$model" ]; then
  if [ -n "$effort" ]; then
    model_str="${C_MODEL}${model}${C_RESET} ${C_DIM}${effort}${C_RESET}"
  else
    model_str="${C_MODEL}${model}${C_RESET}"
  fi
fi

# ── 拼装两行（左竖条侧栏 + 中点分隔）────────────────────────
join_parts() {
  local out="" p
  for p in "$@"; do
    if [ -z "$out" ]; then out="$p"; else out="${out} ${SEP} ${p}"; fi
  done
  printf '%s' "$out"
}

line1=()
[ -n "$session_name" ] && line1+=("${C_SESSION}${session_name}${C_RESET}")
line1+=("${C_DIR}${short_dir}${C_RESET}")
[ -n "$git_str" ] && line1+=("$git_str")

line2=()
[ -n "$model_str" ] && line2+=("$model_str")
[ -n "$ctx_str" ]   && line2+=("$ctx_str")
[ -n "$five_str" ]  && line2+=("$five_str")
[ -n "$seven_str" ] && line2+=("$seven_str")

VBAR="${C_BAR}▌${C_RESET}"
printf '%s %s\n%s %s' "$VBAR" "$(join_parts "${line1[@]}")" "$VBAR" "$(join_parts "${line2[@]}")"
