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
-- =============================================================================

local h = require("hyprland.helpers")

hl.on("hyprland.start", function()
  local function run(cmd)
    hl.exec_cmd(cmd)
  end

  local function run_after_1s(cmd)
    run("sleep 1 && " .. cmd)
  end

  run("~/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")

  run("gnome-keyring-daemon --start --components=secrets")
  run("hypridle")
  run("qs -c " .. h.quickshell_profile .. " &")
  run("dbus-update-activation-environment --all")
  run("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  -- run("~/.config/hypr/hyprland/scripts/__restore_video_wallpaper.sh")

  run("fcitx5")
  run("hyprpm reload -n")
  run("vicinae server")

  run_after_1s("~/.config/hypr/hyprland/scripts/play_sound.sh desktop-login")

  run("easyeffects --gapplication-service")

  run("wl-paste --type text --watch bash -c 'cliphist store && qs -c " .. h.quickshell_profile .. " ipc call cliphistService update'")
  run("wl-paste --type image --watch bash -c 'cliphist store && qs -c " .. h.quickshell_profile .. " ipc call cliphistService update'")

  run("hyprctl setcursor Bibata-Modern-Ice 24")
end)
