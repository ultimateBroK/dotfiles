-- =============================================================================
-- Autostart Executions
-- Commands that run once on Hyprland startup
-- NOTE: Hyprland 0.55+ required for Lua config
-- =============================================================================

-- Helper: exec a command directly
local function exec(cmd)
    hl.exec_cmd(cmd)
end

-- Helper: exec after a short delay (avoids race conditions)
local function execonce(cmd)
    exec("sleep 1 && " .. cmd)
end

-- Geoclue agent for location services
execonce("~/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")

-- GNOME Keyring for secrets storage
exec("gnome-keyring-daemon --start --components=secrets")

-- Idle detection and screen locking
exec("hypridle")

-- Propagate environment variables to D-Bus
exec("dbus-update-activation-environment --all")
exec("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

-- Quickshell (ags/quickshell sidebar/panel system)
exec("qs -c $qsConfig &")

-- Fcitx5 input method
exec("fcitx5")

-- Hyprland plugin manager
exec("hyprpm reload -n")

-- Vicinae - local network file sharing
exec("vicinae server")

-- Login sound notification
execonce("~/.config/hypr/hyprland/scripts/play_sound.sh desktop-login")

-- EasyEffects for pipewire audio processing
exec("easyeffects --gapplication-service")

-- Text clipboard watcher with cliphist integration
exec("wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

-- Image clipboard watcher
exec("wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

-- Set cursor
exec("hyprctl setcursor Bibata-Modern-Ice 24")
