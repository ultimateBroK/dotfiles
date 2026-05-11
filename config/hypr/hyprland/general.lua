-- =============================================================================
-- General Configuration (hyprland/general.conf → Lua)
-- Decoration, animations, input, misc, xwayland, gestures, plugins
-- NOTE: Hyprland 0.55+ required for Lua config
-- Bezier + animation entries below mirror the active subset of general.conf;
-- port any additional bezier / animation = lines from .conf if you need full parity.
-- =============================================================================

-- MONITOR CONFIG
-- HDMI on the left, eDP-1 on the right - 2880x1800
-- NOTE: Monitor configs are now managed by nwg-displays in monitors.conf
-- Commented out to avoid conflicts with monitors.conf
--
-- monitor = eDP-1, 1920x1200@120, 1920x0, 1, bitdepth, 10, vrr, 2
-- monitor = HDMI-A-1, 1920x1080@75, 0x0, 1, bitdepth, 10, vrr, 2
-- monitor=,addreserved, 0, 0, 0, 0 # Custom reserved area
--
-- HDMI port: mirror display. To see device name, use `hyprctl monitors`
-- monitor=HDMI-A-1,1920x1080@60,1920x0,1,mirror,eDP-1

-- --- VISUAL APPEARANCE --- (see general.conf)
--
-- ### --- AMOLED GLASS BORDER PRESETS --- ###
-- Chủ đề: glassmorphism trên nền AMOLED (đen sâu, viền neon/màu kẹo).
-- Gợi ý dùng với background rất tối + blur.
--
-- Cách dùng:
--   col.active_border   = <một trong các preset dưới>
--   col.inactive_border = <phiên bản mờ hơn / ít bão hòa hơn>
--
-- Lưu ý:
-- - Màu đầu và cuối thường gần đen để viền hòa vào nền.
-- - Màu giữa là accent sáng để tạo hiệu ứng phát sáng quanh cửa sổ.
--
-- AG‑1 … AG‑10 preset lines are kept in general.conf (commented rgba examples); Lua uses AG‑10 values in general.col below.

-- ============================================================================
-- MACOS-INSPIRED SMOOTH BEZIER CURVES (animations { bezier = … } in general.conf)
-- ============================================================================
-- These bezier curves replicate macOS's fluid, natural motion
--
-- Primary macOS curves - ultra-smooth deceleration
hl.curve("macEaseOut",       { type = "bezier", points = { {0.16, 1},    {0.3, 1}       } }) -- Main deceleration curve
hl.curve("macEaseIn",        { type = "bezier", points = { {0.7, 0},     {0.84, 0}      } }) -- Acceleration curve
hl.curve("macEaseInOut",     { type = "bezier", points = { {0.4, 0},     {0.2, 1}       } }) -- Balanced ease
-- Advanced macOS motion curves
hl.curve("macSpring",        { type = "bezier", points = { {0.32, 0.94},  {0.6, 1.16}    } }) -- Spring-like bounce
hl.curve("macSharp",         { type = "bezier", points = { {0.33, 0},     {0.1, 1}       } }) -- Sharp, precise movement
hl.curve("macSmooth",        { type = "bezier", points = { {0.25, 0.46},  {0.45, 0.94}   } }) -- Ultra-smooth flow
hl.curve("macOvershoot",    { type = "bezier", points = { {0.13, 0.99},  {0.29, 1.09}   } }) -- Subtle overshoot
hl.curve("macFluid",         { type = "bezier", points = { {0.23, 1},     {0.32, 1}      } }) -- Fluid, organic motion
-- Window-specific curves
hl.curve("macWindowOpen",   { type = "bezier", points = { {0.25, 0.1},   {0.25, 1}      } }) -- Window opening
hl.curve("macWindowClose",  { type = "bezier", points = { {0.3, 0},      {0.8, 0.15}    } }) -- Window closing
hl.curve("macWindowMove",   { type = "bezier", points = { {0.4, 0},      {0.2, 1}       } }) -- Window drag/move
-- Layer and UI curves
hl.curve("macUIFast",       { type = "bezier", points = { {0.2, 0},      {0, 1}         } }) -- Fast UI elements
hl.curve("macUISmooth",     { type = "bezier", points = { {0.4, 0.0},    {0.2, 1.0}      } }) -- Smooth UI transitions
-- Special effect curves
hl.curve("macGenie",        { type = "bezier", points = { {0.25, 1.0},   {0.25, 1.0}    } }) -- Genie effect inspired
hl.curve("macScale",         { type = "bezier", points = { {0.36, 0},     {0.66, -0.56}  } }) -- Scale with slight bounce

-- ============================================================================
-- OLD BEZIER CURVES (COMMENTED FOR ROLLBACK) — see general.conf
-- ============================================================================
-- bezier = expressiveFastSpatial, 0.42, 1.67, 0.21, 0.90
-- bezier = expressiveSlowSpatial, 0.39, 1.29, 0.35, 0.98
-- … (remaining rollback curves in general.conf lines 187–199)

-- Main config: general { }, decoration { }, animations { }, input, debug, misc, binds, cursor, xwayland
hl.config({
    general = {
        -- layout = scrolling
        -- layout = master
        layout = "dwindle",

        -- AG‑10 : Noir Accent (tối giản, ít neon hơn) — see general.conf col.active_border / col.inactive_border
        col = {
            active_border   = { colors = {0x000000EE, 0x30343AFF, 0x00FFCCEE, 0x000000EE}, angle = 45 },
            inactive_border = { colors = {0x000000CC, 0x30343AEE, 0x00FFCC66, 0x000000CC}, angle = 45 },
        },

        -- Gaps and border
        gaps_in  = 3,
        gaps_out = 3,
        gaps_workspaces = 20,

        border_size = 2,
        resize_on_border = true,

        no_focus_fallback = true,

        -- allow_tearing = true # This just allows the `immediate` window rule to work
        allow_tearing = true,

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
            -- Hyprland 0.55+: decoration:shadow:ignore_window removed (was in general.conf)
            range = 30,
            offset = {0, 2},
            render_power = 4,
            color = 0x00000010,
        },

        -- Dim
        dim_inactive = true,
        dim_strength = 0.015,
        dim_special = 0.07,
    },

    animations = {
        enabled = true,

        -- ============================================================================
        -- MACOS-STYLE WINDOW ANIMATIONS (subset of general.conf animation = …)
        -- ============================================================================
        -- Smooth scale and fade for window opening/closing
        { leaf = "windowsIn",      enabled = true, speed = 2.5,  bezier = "macWindowOpen" },
        { leaf = "windowsOut",     enabled = true, speed = 2,    bezier = "macWindowClose" },
        { leaf = "windowsMove",    enabled = true, speed = 2,    bezier = "macFluid" },
        -- animation = border, 1, 2, macUISmooth
        -- animation = borderangle, 1, 150, macUISmooth, loop
        -- OLD WINDOW ANIMATIONS (rollback lines in general.conf 211–222)

        -- ============================================================================
        -- MACOS-STYLE LAYER ANIMATIONS
        -- ============================================================================
        -- Smooth popups and overlays
        { leaf = "layersIn",       enabled = true, speed = 3,    bezier = "macEaseOut" },
        { leaf = "layersOut",      enabled = true, speed = 2.5,  bezier = "macEaseIn" },
        { leaf = "fadeLayersIn",   enabled = true, speed = 2.5,  bezier = "macUISmooth" },
        { leaf = "fadeLayersOut",  enabled = true, speed = 2,    bezier = "macUISmooth" },
        -- OLD LAYER ANIMATIONS (general.conf 233–241)

        -- ============================================================================
        -- MACOS-STYLE FADE ANIMATIONS
        -- ============================================================================
        -- Buttery smooth fades
        { leaf = "fadeIn",         enabled = true, speed = 3,    bezier = "macSmooth" },
        { leaf = "fadeOut",        enabled = true, speed = 2.5,  bezier = "macSmooth" },
        { leaf = "fadeSwitch",     enabled = true, speed = 3,    bezier = "macEaseInOut" },
        { leaf = "fadeShadow",     enabled = true, speed = 3,    bezier = "macEaseOut" },
        { leaf = "fadeDim",        enabled = true, speed = 3,    bezier = "macFluid" },
        -- OLD FADE ANIMATIONS (general.conf 253–262)

        -- ============================================================================
        -- MACOS-STYLE WORKSPACE ANIMATIONS
        -- ============================================================================
        -- Smooth workspace switching like Mission Control
        { leaf = "workspaces",            enabled = true, speed = 3, bezier = "macEaseInOut" },
        { leaf = "specialWorkspaceIn",    enabled = true, speed = 3, bezier = "macOvershoot" },
        { leaf = "specialWorkspaceOut",   enabled = true, speed = 2.5, bezier = "macSharp" },
        -- OLD WORKSPACE ANIMATIONS (general.conf 272–279)
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
        vrr = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|alacritty|Alacritty)",
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

-- Gestures (see general.conf gesture = … and gestures { })
-- gesture = 3, vertical, move …
-- 4-finger horizontal: Hyprscrolling layout (move columns)
-- gesture = 4, left, dispatcher, layoutmsg, move +col
-- gesture = 4, right, dispatcher, layoutmsg, move -col
-- 4-finger vertical: workspaces
-- 4-finger pinch: toggle fullscreen
hl.gesture({ fingers = 3, direction = "vertical",   action = "move" })
hl.gesture({ fingers = 3, direction = "left",       action = "dispatcher", arg = "swapwindow,l" })
hl.gesture({ fingers = 3, direction = "right",      action = "dispatcher", arg = "swapwindow,r" })
hl.gesture({ fingers = 3, direction = "pinch",      action = "dispatcher", arg = "togglefloating" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "pinch",      action = "fullscreen" })

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

-- Overview / plugin (general.conf plugin { hyprexpo { } })
-- hyprscrolling { … } block is commented in general.conf
hl.config({
    plugin = {
        hyprexpo = {
            columns = 4,
            gap_size = 10,
            bg_col = 0x000000,
            -- [center/first] [workspace] e.g. first 1 or center m+1
            workspace_method = { "first", 1 },

            -- gesture_distance, enable_gesture, gesture_positive removed - conflicted with
            -- Hyprland 0.54+ gesture parser (caused "Invalid value for finger count").
            -- Use hyprexpo-gesture keyword for touchpad gestures, e.g.:
            --   hyprexpo-gesture = 4, down, expo
        },
    },
})
