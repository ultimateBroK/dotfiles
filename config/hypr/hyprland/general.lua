-- =============================================================================
-- General Configuration (hyprland/general.conf → Lua)
-- Decoration, animations, input, misc, xwayland, gestures, plugins
-- NOTE: Hyprland 0.55+ required for Lua config
-- Đồng bộ 1:1 comment + giá trị từ general.conf (không bỏ comment)
-- =============================================================================

-- MONITOR CONFIG
-- HDMI on the left, eDP-1 on the right - 2880x1800
-- NOTE: Monitor configs are now managed by nwg-displays in monitors.conf
-- Commented out to avoid conflicts with monitors.conf

-- monitor = eDP-1, 1920x1200@120, 1920x0, 1, bitdepth, 10, vrr, 2
-- monitor = HDMI-A-1, 1920x1080@75, 0x0, 1, bitdepth, 10, vrr, 2
-- monitor=,addreserved, 0, 0, 0, 0 # Custom reserved area

-- HDMI port: mirror display. To see device name, use `hyprctl monitors`
-- monitor=HDMI-A-1,1920x1080@60,1920x0,1,mirror,eDP-1


-- gesture = 3, vertical, move
-- gesture = 3, left,  dispatcher, swapwindow, l
-- gesture = 3, right, dispatcher, swapwindow, r
-- gesture = 3, pinch, dispatcher, togglefloating
-- 4-finger horizontal: Hyprscrolling layout (move columns)
-- gesture = 4, left, dispatcher, layoutmsg, move +col
-- gesture = 4, right, dispatcher, layoutmsg, move -col
-- 4-finger vertical: workspaces
-- gesture = 4, horizontal, workspace
-- 4-finger pinch: toggle fullscreen
-- gesture = 4, pinch, fullscreen
hl.gesture({ fingers = 3, direction = "vertical", action = "move" })
hl.gesture({ fingers = 3, direction = "left", action = function()
  hl.dispatch(hl.dsp.window.swap({ direction = "left" }))
end })
hl.gesture({ fingers = 3, direction = "right", action = function()
  hl.dispatch(hl.dsp.window.swap({ direction = "right" }))
end })
hl.gesture({ fingers = 3, direction = "pinch", action = function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "pinch", action = "fullscreen" })

hl.config({
  gestures = {
    workspace_swipe_distance = 700,
    workspace_swipe_cancel_ratio = 0.2,
    workspace_swipe_min_speed_to_force = 5,
    workspace_swipe_direction_lock = true,
    workspace_swipe_direction_lock_threshold = 10,
    workspace_swipe_create_new = true,
  },
})

hl.config({
  general = {
    -- layout = scrolling
    layout = "dwindle",
    -- layout = master

    -- AG‑10 : Noir Accent (tối giản, ít neon hơn)
    -- Dùng chuỗi rgba(): Lua number 0x000000EE bị cắt thành 0xEE (mất byte cao)
    col = {
      active_border   = { colors = { "rgba(000000ee)", "rgba(30343aff)", "rgba(00ffccee)", "rgba(000000ee)" }, angle = 45 },
      inactive_border = { colors = { "rgba(000000cc)", "rgba(30343aee)", "rgba(00ffcc66)", "rgba(000000cc)" }, angle = 45 },
    },

    -- Gaps and border
    gaps_in = 3,
    gaps_out = 3,
    gaps_workspaces = 20,

    border_size = 2,
    resize_on_border = true,

    no_focus_fallback = true,

    allow_tearing = true, -- This just allows the `immediate` window rule to work

    snap = {
      enabled = true,
      window_gap = 4,
      monitor_gap = 5,
      respect_gaps = true,
    },
  },

  decoration = {
    rounding = 15,

    blur = {
      enabled = true,
      xray = false,
      special = true,
      new_optimizations = true,
      size = 1,
      passes = 1,
      brightness = 1,
      noise = 0,
      contrast = 1,
      popups = false,
      popups_ignorealpha = 0.6,
      input_methods = false,
      input_methods_ignorealpha = 0.8,
    },

    shadow = {
      enabled = false,
      range = 30,
      offset = { 0, 2 },
      render_power = 4,
      color = "rgba(00000010)", -- string: 0x00000010 bị Lua cắt thành 0x10
    },

    -- Dim
    dim_inactive = true,
    dim_strength = 0.015,
    dim_special = 0.07,
  },

  animations = {
    enabled = true,
  },

  input = {
    kb_layout = "us",
    numlock_by_default = true,
    repeat_delay = 250,
    repeat_rate = 35,

    follow_mouse = 1,
    off_window_axis_events = 2,

    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      clickfinger_behavior = true,
      scroll_factor = 1.2,
    },
  },

  -- Hyprland 0.55+: VFR moved from misc:vfr to debug:vfr (see hl.meta.lua)
  debug = {
    vfr = true,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 1,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    animate_manual_resizes = false,
    animate_mouse_windowdragging = false,
    enable_swallow = false,
    swallow_regex = "(foot|kitty|allacritty|Alacritty)", -- giữ đúng conf (allacritty)
    on_focus_under_fullscreen = 2,
    allow_session_lock_restore = true,
    session_lock_xray = true,
    initial_workspace_tracking = false,
    focus_on_activate = true,
  },

  binds = {
    scroll_event_delay = 0,
    hide_special_on_workspace_change = true,
  },

  cursor = {
    zoom_factor = 1,
    zoom_rigid = false,
    hotspot_padding = 1,
  },

  -- XWayland configuration
  -- force_zero_scaling forces XWayland apps to use integer scaling
  -- This can help with font rendering issues in apps like Spotify
  -- use_nearest_neighbor = true improves performance for pixelated apps/games
  xwayland = {
    force_zero_scaling = true,
    use_nearest_neighbor = true,
  },
})

-- ============================================================================
-- MACOS-INSPIRED SMOOTH BEZIER CURVES
-- ============================================================================
-- These bezier curves replicate macOS's fluid, natural motion

-- Primary macOS curves - ultra-smooth deceleration
hl.curve("macEaseOut", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } }) -- Main deceleration curve
hl.curve("macEaseIn", { type = "bezier", points = { {0.7, 0}, {0.84, 0} } }) -- Acceleration curve
hl.curve("macEaseInOut", { type = "bezier", points = { {0.4, 0}, {0.2, 1} } }) -- Balanced ease

-- Advanced macOS motion curves
hl.curve("macSpring", { type = "bezier", points = { {0.32, 0.94}, {0.6, 1.16} } }) -- Spring-like bounce
hl.curve("macSharp", { type = "bezier", points = { {0.33, 0}, {0.1, 1} } }) -- Sharp, precise movement
hl.curve("macSmooth", { type = "bezier", points = { {0.25, 0.46}, {0.45, 0.94} } }) -- Ultra-smooth flow
hl.curve("macOvershoot", { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.09} } }) -- Subtle overshoot
hl.curve("macFluid", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } }) -- Fluid, organic motion

-- Window-specific curves
hl.curve("macWindowOpen", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } }) -- Window opening
hl.curve("macWindowClose", { type = "bezier", points = { {0.3, 0}, {0.8, 0.15} } }) -- Window closing
hl.curve("macWindowMove", { type = "bezier", points = { {0.4, 0}, {0.2, 1} } }) -- Window drag/move

-- Layer and UI curves
hl.curve("macUIFast", { type = "bezier", points = { {0.2, 0}, {0, 1} } }) -- Fast UI elements
hl.curve("macUISmooth", { type = "bezier", points = { {0.4, 0.0}, {0.2, 1.0} } }) -- Smooth UI transitions

-- Special effect curves
hl.curve("macGenie", { type = "bezier", points = { {0.25, 1.0}, {0.25, 1.0} } }) -- Genie effect inspired
hl.curve("macScale", { type = "bezier", points = { {0.36, 0}, {0.66, -0.56} } }) -- Scale with slight bounce

-- ============================================================================
-- OLD BEZIER CURVES (COMMENTED FOR ROLLBACK)
-- ============================================================================
-- bezier = expressiveFastSpatial, 0.42, 1.67, 0.21, 0.90
-- bezier = expressiveSlowSpatial, 0.39, 1.29, 0.35, 0.98
-- bezier = expressiveDefaultSpatial, 0.38, 1.21, 0.22, 1.00
-- bezier = emphasizedDecel, 0.05, 0.7, 0.1, 1
-- bezier = emphasizedAccel, 0.3, 0, 0.8, 0.15
-- bezier = standardDecel, 0, 0, 0, 1
-- bezier = menu_decel, 0.1, 1, 0, 1
-- bezier = menu_accel, 0.52, 0.03, 0.72, 0.08
-- bezier = easeOutQuart, 0.25, 1, 0.5, 1
-- bezier = easeInOutSine, 0.37, 0, 0.63, 1
-- bezier = modernBounce, 0.18, 0.99, 0, 1.15
-- bezier = easeInOutBack, 0.68, -0.55, 0.27, 1.55
-- bezier = neonPulse, 0.15, 0.85, 0.1, 1.0

-- ============================================================================
-- MACOS-STYLE WINDOW ANIMATIONS
-- ============================================================================
-- Smooth scale and fade for window opening/closing
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "macWindowOpen", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "macWindowClose", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2, bezier = "macFluid", style = "slide" })
-- animation = border, 1, 2, macUISmooth
-- animation = borderangle, 1, 150, macUISmooth, loop

-- ============================================================================
-- OLD WINDOW ANIMATIONS (COMMENTED FOR ROLLBACK)
-- ============================================================================
-- animation = border, 1, 2, macUISmooth
-- animation = borderangle, 1, 150, macUISmooth, loop
-- animation = border, 1, 1, neonPulse
-- animation = borderangle, 1, 30, neonPulse, loop
-- animation = windowsIn, 1, 3, emphasizedDecel, popin 80%
-- animation = windowsOut, 1, 2, emphasizedDecel, popin 90%
-- animation = windowsMove, 1, 3, emphasizedDecel, slide
-- animation = border, 1, 10, emphasizedDecel
-- animation = windowsIn, 1, 2, standardDecel, slide
-- animation = windowsOut, 1, 2, standardDecel, slide
-- animation = windowsMove, 1, 3, easeInOutSine
-- animation = layersIn, 1, 2.7, emphasizedDecel, popin 93%
-- animation = layersOut, 1, 2.4, menu_accel, popin 94%
-- animation = layersIn, 1, 4, easeOutQuart, slide
-- animation = layersOut, 1, 3, easeOutQuart, fade
-- animation = fadeLayersIn, 1, 4, easeOutQuart
-- animation = fadeLayersOut, 1, 3, easeOutQuart
-- animation = fadeLayersIn, 1, 0.5, menu_decel
-- animation = fadeLayersOut, 1, 2.7, menu_accel
-- animation = fadeIn, 1, 3, easeInOutSine
-- animation = fadeOut, 1, 3, easeInOutSine
-- animation = fadeSwitch, 1, 3, easeInOutSine
-- animation = fadeShadow, 1, 3, easeInOutSine
-- animation = fadeDim, 1, 3, easeInOutSine
-- animation = workspaces, 1, 2, standardDecel, slidefadevert 70%
-- animation = specialWorkspace, 1, 4, easeOutQuart, slidefade 70%
-- animation = workspaces, 1, 7, menu_decel, slidevert
-- animation = specialWorkspaceIn, 1, 1.5, emphasizedDecel, slidefadevert 70%
-- animation = specialWorkspaceOut, 1, 1.5, emphasizedAccel, slidefadevert 70%

-- Active layer/fade/workspace animations (from conf, not commented)
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "macEaseOut", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.5, bezier = "macEaseIn", style = "slide" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "macUISmooth" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2, bezier = "macUISmooth" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "macSmooth" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "macSmooth" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "macEaseInOut" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 3, bezier = "macEaseOut" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 3, bezier = "macFluid" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "macEaseInOut", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "macOvershoot", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2.5, bezier = "macSharp", style = "slidevert" })

-- Overview / plugin (general.conf plugin { hyprexpo { } })
-- hyprscrolling { … } block is commented in general.conf
--
-- QUAN TRỌNG (Lua): `hl.config({ plugin = { hyprexpo = … } })` báo
-- "unknown config key" nếu plugin chưa load (kể cả trong pcall — Hyprland
-- không throw). Chỉ set khi plugin có trong hl.get_loaded_plugins().
--
-- conf values:
--   hyprexpo { columns = 4, gap_size = 10, bg_col = rgb(000000), workspace_method = first 1 }
--   -- gesture_distance, enable_gesture, gesture_positive removed (Hyprland 0.54+)
--   -- Use hyprexpo-gesture keyword for touchpad gestures, e.g.:
--   --   hyprexpo-gesture = 4, down, expo
-- hyprscrolling = { column_width = 0.9, fullscreen_on_one_column = true }  -- conf: comment

local function plugin_is_loaded(needle)
  local ok, plugins = pcall(function() return hl.get_loaded_plugins() end)
  if not ok or type(plugins) ~= "table" then return false end
  local n = needle:lower()
  for _, p in pairs(plugins) do
    local name = type(p) == "table" and (p.name or p.handle or p.path or "") or tostring(p)
    if type(name) == "string" and name:lower():find(n, 1, true) then
      return true
    end
  end
  return false
end

local function apply_hyprexpo_config()
  if not plugin_is_loaded("hyprexpo") then return false end
  hl.config({
    plugin = {
      hyprexpo = {
        columns = 4,
        gap_size = 10,
        bg_col = "rgb(000000)",
        workspace_method = { "first", 1 }, -- [center/first] [workspace] e.g. first 1 or center m+1
      },
    },
  })
  return true
end

-- Apply when present; retry after hyprpm reload (execs.lua)
if not apply_hyprexpo_config() then
  hl.on("hyprland.start", function()
    hl.timer(function()
      apply_hyprexpo_config()
    end, { timeout = 2500, type = "oneshot" })
  end)
end

