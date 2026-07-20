-- =============================================================================
-- Autostart (hyprland/execs.conf → Lua)
--
-- QUAN TRỌNG: hl.exec_cmd() ở top-level = chạy mỗi lần hyprctl reload (giống
-- keyword `exec` trong hyprlang). Gọi qs / wl-paste / fcitx5 như vậy sẽ nhân
-- bản process → quickshell & IPC spam → có thể treo máy.
-- Dùng hl.on("hyprland.start", ...) cho mọi thứ chỉ cần một lần mỗi phiên
-- (tương đương exec-once). Xem ví dụ upstream:
-- https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
--
-- Quickshell profile: helpers.quickshell_profile (khớp $qsConfig trong conf cũ)
-- Thứ tự lệnh khớp execs.conf
-- =============================================================================

local h = require("hyprland.helpers")

hl.on("hyprland.start", function()
  local function run(cmd)
    hl.exec_cmd(cmd)
  end

  -- Bar, wallpaper
  run("~/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")

  -- Core components (authentication, lock screen, notification daemon) - must be before Quickshell for D-Bus
  run("gnome-keyring-daemon --start --components=secrets")
  run("hypridle")
  run("dbus-update-activation-environment --all")
  run("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

  -- Quickshell - start after D-Bus is ready to avoid PolkitAgent registration delays
  run("qs -c " .. h.quickshell_profile .. " &")
  -- run("~/.config/hypr/hyprland/scripts/__restore_video_wallpaper.sh")

  -- Input method (merged from custom/execs.conf)
  run("fcitx5")
  run("hyprpm reload -n")
  run("vicinae server")

  -- Play login sound (merged from custom/execs.conf)
  run("sleep 1 && ~/.config/hypr/hyprland/scripts/play_sound.sh desktop-login")

  -- Audio
  run("easyeffects --gapplication-service")

  -- Clipboard: history
  -- run("wl-paste --watch cliphist store &3")
  run("wl-paste --type text --watch bash -c 'cliphist store && qs -c " .. h.quickshell_profile .. " ipc call cliphistService update'")
  run("wl-paste --type image --watch bash -c 'cliphist store && qs -c " .. h.quickshell_profile .. " ipc call cliphistService update'")

  -- Cursor
  run("hyprctl setcursor Bibata-Modern-Ice 24")

  -- Fix dock pinned apps not launching properly (https://github.com/end-4/dots-hyprland/issues/2200)
  -- This causes https://github.com/end-4/dots-hyprland/issues/2427
  -- run("sleep 3.5 && hyprctl reload && sleep 0.5 && touch ~/.config/quickshell/ii/shell.qml")
end)
