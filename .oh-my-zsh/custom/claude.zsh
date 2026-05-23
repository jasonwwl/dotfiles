# ============================================================
#  Claude Code × tmux 启动助手
#  权限走 settings.json 的 permissions.defaultMode=auto,启动无需带 flag
#  命令: 91 起 / 91a 重连 / 91k 结束(后台);结束当前会话用 exit 或 Ctrl+b x
# ============================================================

# 91 [目录]  —— 在项目目录里【新开】一个独立 tmux 会话起 cc(可并行多个)
#   每敲一次 = 新会话 cc-<目录>-N(N 递增),互不干扰、可拽成独立窗口并排看
91() {
  local dir="${1:-$PWD}"; dir="${dir:A}"
  local base="cc-${dir:t}"; base="${base//[.: ]/_}"
  [[ -n "$TMUX" ]] && { cd "$dir"; claude; return }   # 已在 tmux 里就别套娃
  local n=1                                            # 找下一个空闲序号
  while tmux has-session -t "=${base}-${n}" 2>/dev/null; do ((n++)); done
  local name="${base}-${n}"
  # cc 退出后落回会话内 shell(exec zsh,会话保留 → 可跑 git/再起 cc),敲 exit 才结束会话
  # 外层 exec tmux attach 已替换 tab 的 shell,所以 exit 一次(退会话内 shell)即关 tab,不用退两层
  # zsh -ic 保证 PATH 且命令不回显
  tmux new-session -d -s "$name" -c "$dir" "exec zsh -ic 'claude; exec zsh'" || return 1
  exec tmux attach -t "$name"
}

# _cc_pick <prompt> <line...>  —— 交互选择器,结果写入全局 $_cc_pick_result
#   Tab/↓ 下一项, Shift+Tab/↑ 上一项(均轮转), 数字直选, 回车确认, Esc/q 取消
#   高亮用 ANSI 反显(\e[7m),不做宽度对齐——以此继续绕开 C.UTF-8 下 CJK 的 wcwidth 乱码
#   每行 line 形如 "name<TAB>title";UI 画到 stderr,结果走全局变量(不用子 shell)
_cc_pick() {
  emulate -L zsh
  local prompt=$1; shift
  local -a lines=("$@")
  local n=${#lines} active=1 key rest i first=1 label
  _cc_pick_result=""
  while true; do
    (( first )) || print -u2 -nr -- $'\e['"$n"$'A\r'    # 非首次:光标回到菜单首行(上移 n 行 + CR)
    first=0
    for (( i = 1; i <= n; i++ )); do
      label="  ${i}) ${lines[i]#*$'\t'} · ${lines[i]%%$'\t'*}"   # 任务 · 会话名
      if (( i == active )); then
        print -u2 -r -- $'\e[2K\e[7m'"${label}"$'\e[0m'
      else
        print -u2 -r -- $'\e[2K'"${label}"
      fi
    done
    print -u2 -nr -- $'\e[2K'"${prompt} [Tab/↑↓ 选 · 数字直选 · 回车确认 · Esc 取消] "
    read -s -k 1 key || { active=0; break }
    case $key in
      $'\t')        (( active = active % n + 1 )) ;;             # Tab 下一项
      $'\n'|$'\r')  break ;;                                     # 回车确认
      [1-9])        (( key <= n )) && { active=$key; break } ;;  # 数字直选
      q|Q)          active=0; break ;;
      $'\e')
        read -s -t 0.1 -k 2 rest 2>/dev/null
        case $rest in
          '[A'|'OA'|'[Z') (( active = (active + n - 2) % n + 1 )) ;;  # ↑ / Shift+Tab
          '[B'|'OB')      (( active = active % n + 1 )) ;;            # ↓
          *)              active=0; break ;;                          # 单独 Esc 取消
        esac ;;
    esac
  done
  print -u2 -r -- ""
  (( active == 0 )) && return 1
  _cc_pick_result=${lines[active]%%$'\t'*}
  return 0
}

# 91a [片段]  —— 关了 tab 后把某个 cc 会话接回来;列表显示「任务 · 会话名」
#   不带参数弹交互菜单(Tab/↑↓/数字);带片段则按 会话名/任务名 模糊匹配直接接回
91a() {
  [[ -n "$TMUX" ]] && { echo "已在 tmux 里,先 Ctrl+b d 再重连"; return 1 }
  local fmt=$'#{session_name}\t#{pane_title}'
  local lines=(${(f)"$(tmux list-sessions -F "$fmt" 2>/dev/null | grep '^cc-')"})
  (( ${#lines} == 0 )) && { echo "没有运行中的 cc 会话"; return 1 }
  local name
  if [[ -n "$1" ]]; then
    local match=${lines[(r)*$1*]}        # 会话名或任务名含片段都行
    name=${match%%$'\t'*}
  else
    _cc_pick "选要重连的 cc 会话" "${lines[@]}" || return 1
    name=$_cc_pick_result
  fi
  [[ -n "$name" ]] && tmux attach -t "=$name"
}

# 91k [片段]  —— 结束(kill)一个后台 cc 会话;交互菜单挑或按片段直接杀
#   不会列出你当前所在的会话(那个用 exit / Ctrl+b x);会话历史已存盘,事后 claude -c 可恢复
91k() {
  local cur=""
  [[ -n "$TMUX" ]] && cur=$(tmux display-message -p '#{session_name}' 2>/dev/null)
  local fmt=$'#{session_name}\t#{pane_title}'
  local lines=(${(f)"$(tmux list-sessions -F "$fmt" 2>/dev/null | grep '^cc-')"})
  [[ -n "$cur" ]] && lines=(${lines:#${cur}$'\t'*})   # 排除当前所在会话
  (( ${#lines} == 0 )) && { echo "没有可结束的 cc 会话"; return 1 }
  local name
  if [[ -n "$1" ]]; then
    local match=${lines[(r)*$1*]}        # 会话名或任务名含片段都行
    name=${match%%$'\t'*}
  else
    _cc_pick "选要【结束】的 cc 会话" "${lines[@]}" || return 1
    name=$_cc_pick_result
  fi
  [[ -z "$name" ]] && return 1
  tmux kill-session -t "=$name" && echo "已结束 $name"
}
