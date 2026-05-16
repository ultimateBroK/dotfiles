-- Hyprland Lua entry (0.55+). File mặc định: $XDG_CONFIG_HOME/hypr/hyprland.lua (~/.config/hypr/hyprland.lua).
--
-- Thứ tự tìm config (Hyprland): nếu tồn tại hyprland.lua thì dùng Lua; *chỉ khi không có .lua*
-- mới dùng hyprlang hyprland.conf. Vì vậy đừng để stub hyprlang là file *duy nhất* trong repo
-- deploy — và đừng set HYPRLAND_CONFIG hay `Hyprland -c` trỏ tới file .conf nếu muốn Lua.
--
-- Hyprlang (không dùng khi có file này): trong repo vẫn có `hyprland.conf` đầy đủ source=… để tham chiếu / fallback;
-- muốn chỉ hyprlang: đổi tên hoặc xóa `hyprland.lua` rồi chỉ giữ `hyprland.conf`.
--   • helpers.quickshell_profile = "ii" (tương đương $qsConfig trong conf cũ)
--   • monitors.lua + workspaces.lua đọc monitors.conf & workspaces.conf cạnh thư mục hyprland/
--   • Submap bootstrap trong keybinds.lua

require("hyprland.colors")       -- misc background, hyprbars, pin bordercolor
require("hyprland.env")          -- environment variables
require("hyprland.workspaces")   -- workspace → monitor (workspaces.conf)
require("hyprland.monitors")     -- monitor= lines (monitors.conf)
require("hyprland.execs")        -- autostart (exec-once parity)
require("hyprland.general")     -- general, decoration, animations, gestures, plugins
require("hyprland.layouts")     -- dwindle, master, scrolling
require("hyprland.rules")       -- window / layer / workspace rules
require("hyprland.keybinds")    -- binds + initial submap
