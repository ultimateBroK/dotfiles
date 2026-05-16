-- =============================================================================
-- Monitors — đọc monitors.conf (nwg-displays ghi đè file này)
--
-- Không cần sửa Lua khi đổi màn hình: chỉnh trong nwg-displays → nó cập nhật
-- ~/.config/hypr/monitors.conf; Hyprland đọc lại khi khởi động / reload config.
--
-- Định dạng dòng (hyprlang): monitor=OUT,mode,pos,scale[,bitdepth,N][,...]
-- =============================================================================

local h = require("hyprland.helpers")

local function strip_comment(line)
  return h.trim(line:gsub("#.*$", ""))
end

local function parse_monitor_csv(rest)
  local parts = {}
  for seg in rest:gmatch("([^,]+)") do
    parts[#parts + 1] = h.trim(seg)
  end
  -- Chuẩn nwg-displays: OUT,mode,pos,scale[,bitdepth,N,...]
  -- Dòng dạng monitor=NAME,disable để Hyprland tự xử lý — thêm sau nếu cần
  if #parts < 4 then return nil end

  local spec = {
    output = parts[1],
    mode = parts[2],
    position = parts[3],
    scale = parts[4],
  }
  local i = 5
  while i <= #parts do
    if parts[i] == "bitdepth" and parts[i + 1] then
      spec.bitdepth = tonumber(parts[i + 1])
      i = i + 2
    elseif parts[i] == "transform" and parts[i + 1] then
      spec.transform = tonumber(parts[i + 1])
      i = i + 2
    else
      i = i + 1
    end
  end
  return spec
end

local dir = h.hypr_layout_root()
if not dir then return end

local path = dir .. "/monitors.conf"
local f = io.open(path, "r")
if not f then return end

for raw in f:lines() do
  local line = strip_comment(raw)
  if line ~= "" then
    local rest = line:match("^monitor%s*=%s*(.+)$")
    if rest then
      local spec = parse_monitor_csv(rest)
      if spec then
        hl.monitor(spec)
      end
    end
  end
end
f:close()
