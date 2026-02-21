local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-------------------------------------------------
-- 默认进入 WSL 环境
-------------------------------------------------
config.default_prog = { 'wsl.exe', '~' }
-- 如果有多个 WSL 发行版，可指定：
-- config.default_prog = { 'wsl.exe', '-d', 'Ubuntu-22.04', '--cd', '~' }

-------------------------------------------------
-- 字体：Nerd Font + 连字 + CJK 回退
-------------------------------------------------
config.font = wezterm.font_with_fallback {
  {
    family = 'UbuntuMono Nerd Font',
  },
  { family = 'Sarasa Term SC' },         -- 中文等宽回退（更纱黑体）
  { family = 'Source Han Sans SC' },      -- 思源黑体回退
}
config.font_size = 14.0
config.line_height = 1

-------------------------------------------------
-- 配色
-------------------------------------------------
config.color_scheme = 'Catppuccin Mocha'
config.window_background_opacity = 1.0

-------------------------------------------------
-- 标签栏：Fancy 圆角风格 + Catppuccin 配色
-------------------------------------------------
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.window_frame = {
  font = wezterm.font { family = 'JetBrainsMono Nerd Font', weight = 'Bold' }
}

-------------------------------------------------
-- 窗口布局
-------------------------------------------------
config.initial_cols = 110
config.initial_rows = 25
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }
config.hide_tab_bar_if_only_one_tab = false

-------------------------------------------------
-- 终端能力：真彩色 + Unicode + CSI u 键盘编码
-------------------------------------------------
config.term = 'xterm-256color'
config.set_environment_variables = {
  COLORTERM = 'truecolor',
}
config.unicode_version = 14
config.enable_csi_u_key_encoding = true

-------------------------------------------------
-- 性能优化
-------------------------------------------------
config.front_end = 'OpenGL'
config.max_fps = 120
config.animation_fps = 1
config.cursor_blink_rate = 0
config.scrollback_lines = 10000
config.enable_scroll_bar = true

-------------------------------------------------
-- 快捷键：直接组合键，避免与 Claude Code 冲突
-------------------------------------------------
config.keys = {
  -- Shift+Enter 换行（修复 Claude Code 多行输入）
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendString '\x1b[13;2u' },
  -- 标签页：与浏览器习惯一致
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL',       action = wezterm.action.CloseCurrentTab { confirm = true } },
  { key = 'Tab', mods = 'CTRL',       action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
}

return config
