-- Hyprland Lua entry (0.55+).
-- File mặc định: $XDG_CONFIG_HOME/hypr/hyprland.lua (~/.config/hypr/hyprland.lua).
--
-- Thứ tự tìm config (Hyprland): nếu tồn tại hyprland.lua thì dùng Lua; *chỉ khi không có .lua*
-- mới dùng hyprlang hyprland.conf.
--
-- Hyprlang fallback: `hyprland.conf` (và hyprland/*.conf) vẫn giữ để tham chiếu / rollback.
-- Muốn chỉ hyprlang: đổi tên hoặc xóa file này.
--
--   • helpers.quickshell_profile = "ii" (tương đương $qsConfig trong conf cũ)
--   • monitors.lua + workspaces.lua đọc monitors.conf & workspaces.conf
--   • Submap bootstrap trong keybinds.lua
--
-- Thứ tự require khớp hyprland.conf source=…:
--   env → execs → general → rules → colors → keybinds → layouts → workspaces → monitors
--
-- This file sources modules in `hyprland/` (same role as source= in hyprland.conf).
-- You wanna add your stuff in files under `hyprland/` or custom modules here.

-- Defaults
require("hyprland.env")
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")

-- Layouts
require("hyprland.layouts")

-- nwg-displays support (reads workspaces.conf + monitors.conf)
require("hyprland.workspaces")
require("hyprland.monitors")
