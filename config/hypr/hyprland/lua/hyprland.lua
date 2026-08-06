-- Hyprland Lua entry (0.55+).
-- File mặc định khi deploy: $XDG_CONFIG_HOME/hypr/hyprland.lua (~/.config/hypr/hyprland.lua).
--
-- Thứ tự tìm config (Hyprland): nếu tồn tại hyprland.lua thì dùng Lua; *chỉ khi không có .lua*
-- mới dùng hyprlang hyprland.conf.
--
-- Hyprlang fallback: `hyprland.conf` (và hyprland/*.conf) vẫn giữ trong repo để tham chiếu /
-- rollback. Muốn chỉ hyprlang: đổi tên/xóa `hyprland.lua`.
--
--   • helpers.quickshell_profile = "ii" (tương đương $qsConfig trong conf cũ)
--   • monitors.lua / workspaces.lua (cạnh hyprland.lua) do nwg-displays SINH RA —
--     require thẳng, không parse conf nữa. Apply trong nwg-displays tự chạy hyprctl reload.
--   • Submap bootstrap trong keybinds.lua (exec submap global)
--
-- Thứ tự require khớp hyprland.conf source=…:
--   env → execs → general → rules → colors → keybinds → layouts → workspaces → monitors

require("hyprland.env")          -- environment variables
require("hyprland.execs")        -- autostart (exec-once parity)
require("hyprland.general")      -- general, decoration, animations, gestures, plugins
require("hyprland.rules")        -- window / layer / workspace rules
require("hyprland.colors")       -- misc background, pin bordercolor
require("hyprland.keybinds")     -- binds + initial submap
require("hyprland.layouts")      -- dwindle, master, scrolling
require("workspaces")            -- workspace → monitor (nwg-displays generates)
require("monitors")              -- hl.monitor entries (nwg-displays generates)
