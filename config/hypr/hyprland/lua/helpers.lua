-- =============================================================================
-- Hyprland Keybinds Helpers
-- Helper functions cho keybinds.lua
-- =============================================================================

local h = {}

-- Quickshell helper - gọi qs nếu alive, fallback nếu not
function h.qs(cmd)
  return "qs -c $qsConfig ipc call TEST_ALIVE || " .. cmd
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
  return "qs -c $qsConfig ipc call TEST_ALIVE || " .. fallback_cmd
end

return h