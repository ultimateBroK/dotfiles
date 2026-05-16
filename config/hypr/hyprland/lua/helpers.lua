-- =============================================================================
-- Hyprland Keybinds Helpers
-- Helper functions cho keybinds.lua
-- =============================================================================

local h = {}

-- Must match hyprland.conf: $qsConfig = ii (hyprlang vars are not set in pure Lua)
h.quickshell_profile = "ii"

-- Directory containing hyprland.conf, monitors.conf, workspaces.conf (usually ~/.config/hypr).
-- Used by monitors.lua / workspaces.lua to read files written by nwg-displays.
function h.hypr_config_dir()
  local home = os.getenv("HOME")
  local xdg = os.getenv("XDG_CONFIG_HOME")
  local root = xdg or (home and (home .. "/.config") or nil)
  return root and (root .. "/hypr") or nil
end

function h.trim(s)
  if not s then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Thư mục .../hypr chứa monitors.conf / workspaces.conf (cạnh thư mục hyprland/).
-- Caller: hyprland/monitors.lua hoặc hyprland/workspaces.lua → parent của .../hyprland = .../hypr.
-- (Bố cục cũ hyprland/lua/*.lua cần 3 bước dirname; layout hiện tại chỉ cần 1 bước từ thư mục file.)
function h.hypr_layout_root()
  local info = debug.getinfo(2, "S")
  local src = info and info.source
  if type(src) == "string" and src:sub(1, 1) == "@" then
    src = src:sub(2)
    local hyprland_dir = src:match("^(.*)/[^/]+$")
    if hyprland_dir and hyprland_dir:match("/hyprland$") then
      local hypr_root = hyprland_dir:match("^(.*)/[^/]+$")
      if hypr_root then return hypr_root end
    end
  end
  return h.hypr_config_dir()
end

function h.quickshell_config_dir()
  return "~/.config/quickshell/" .. h.quickshell_profile
end

-- Quickshell helper - gọi qs nếu alive, fallback nếu not
function h.qs(cmd)
  return "qs -c " .. h.quickshell_profile .. " ipc call TEST_ALIVE || " .. cmd
end

-- Launcher helper - thử qs, fallback đến next available
function h.launch(...)
  local apps = {...}
  local script = "~/.config/hypr/hyprland/scripts/launch_first_available.sh"
  local cmd = script .. ' "' .. table.concat(apps, '" "') .. '"'
  return cmd
end

-- Workspace action helper
function h.ws(action, ws)
  return "~/.config/hypr/hyprland/scripts/workspace_action.sh " .. action .. " " .. ws
end

-- exec wrapper cho sound effects
function h.exec_sound(cmd)
  return cmd .. " && ~/.config/hypr/hyprland/scripts/play_sound.sh audio-volume-change"
end

-- Quick action - kiểm tra qs alive trước, fallback
function h.qs_or_fallback(qs_action, fallback_cmd)
  return "qs -c " .. h.quickshell_profile .. " ipc call TEST_ALIVE || " .. fallback_cmd
end

return h