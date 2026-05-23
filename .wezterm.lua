local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-------------------------------------------------
-- 默认进入 WSL 环境
-------------------------------------------------
config.default_prog = { 'wsl.exe', '~' }
-- 如果有多个 WSL 发行版，可指定：
-- config.default_prog = { 'wsl.exe', '-d', 'Ubuntu-22.04', '--cd', '~' }

-------------------------------------------------
-- 字体
-------------------------------------------------
config.font = wezterm.font_with_fallback {
  { family = 'Maple Mono NF CN' },
}
config.font_size = 13.0
config.line_height = 1

-------------------------------------------------
-- 配色
-------------------------------------------------
config.color_scheme = 'Dracula'
config.window_background_opacity = 1.0

-------------------------------------------------
-- 标签栏
-------------------------------------------------
config.use_fancy_tab_bar = true
config.tab_max_width = 32
config.window_frame = {
  font = wezterm.font { family = 'Maple Mono NF CN', weight = 'Bold' },
  font_size = 12.0,
}

-------------------------------------------------
-- 窗口布局
-------------------------------------------------
config.initial_cols = 110
config.initial_rows = 25
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }
config.hide_tab_bar_if_only_one_tab = false

-------------------------------------------------
-- 终端能力
-------------------------------------------------
config.term = 'xterm-256color'
config.set_environment_variables = {
  COLORTERM = 'truecolor',
}
config.unicode_version = 14
-- config.enable_kitty_keyboard = true
-- config.use_ime = true

-------------------------------------------------
-- 性能优化
-------------------------------------------------
config.front_end = 'WebGpu'
config.max_fps = 120
config.animation_fps = 1
config.cursor_blink_rate = 0
config.scrollback_lines = 10000
config.enable_scroll_bar = true
config.colors = {
  scrollbar_thumb = '#6272a4',
}

-------------------------------------------------
-- 快捷键
-------------------------------------------------
config.keys = {
  -- Shift+Enter 换行（Claude Code 多行输入）
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x1b[13;2u' },

  -- 复制粘贴
  { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- 标签页
  { key = 't', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL', action = act.CloseCurrentTab { confirm = true } },
  { key = 'Tab', mods = 'CTRL',       action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },

  -- Ctrl+数字 直接切换标签页
  { key = '1', mods = 'CTRL', action = act.ActivateTab(0) },
  { key = '2', mods = 'CTRL', action = act.ActivateTab(1) },
  { key = '3', mods = 'CTRL', action = act.ActivateTab(2) },
  { key = '4', mods = 'CTRL', action = act.ActivateTab(3) },
  { key = '5', mods = 'CTRL', action = act.ActivateTab(4) },

}

return config
