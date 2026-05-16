-- =============================================================================
-- Workspace → monitor — đọc workspaces.conf (thường do nwg-displays hoặc tay)
--
-- Dòng: workspace = N, monitor:OUTPUT  (khoảng trắng linh hoạt)
-- Cập nhật file conf rồi reload Hyprland; không cần đồng bộ tay sang Lua.
-- =============================================================================

local h = require("hyprland.helpers")

local function strip_comment(line)
  return h.trim(line:gsub("#.*$", ""))
end

local dir = h.hypr_layout_root()
if not dir then return end

local path = dir .. "/workspaces.conf"
local f = io.open(path, "r")
if not f then return end

for raw in f:lines() do
  local line = strip_comment(raw)
  if line ~= "" then
    local ws, mon = line:match("^workspace%s*=%s*(%d+)%s*,%s*monitor:([^%s,]+)")
    if ws and mon then
      hl.workspace_rule({ workspace = ws, monitor = mon })
    end
  end
end
f:close()
