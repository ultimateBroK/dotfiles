-- =============================================================================
-- General Configuration
-- Decoration, animations, input, misc, xwayland, gestures, plugins
-- NOTE: Hyprland 0.55+ required for Lua config
-- =============================================================================

-- Bezier curves (macOS-inspired)
hl.curve("macEaseOut",       { type = "bezier", points = { {0.16, 1},    {0.3, 1}       } })
hl.curve("macEaseIn",        { type = "bezier", points = { {0.7, 0},     {0.84, 0}      } })
hl.curve("macEaseInOut",     { type = "bezier", points = { {0.4, 0},     {0.2, 1}       } })
hl.curve("macSpring",        { type = "bezier", points = { {0.32, 0.94},  {0.6, 1.16}    } })
hl.curve("macSharp",         { type = "bezier", points = { {0.33, 0},     {0.1, 1}       } })
hl.curve("macSmooth",        { type = "bezier", points = { {0.25, 0.46},  {0.45, 0.94}   } })
hl.curve("macOvershoot",    { type = "bezier", points = { {0.13, 0.99},  {0.29, 1.09}   } })
hl.curve("macFluid",         { type = "bezier", points = { {0.23, 1},     {0.32, 1}      } })
hl.curve("macWindowOpen",   { type = "bezier", points = { {0.25, 0.1},   {0.25, 1}      } })
hl.curve("macWindowClose",  { type = "bezier", points = { {0.3, 0},      {0.8, 0.15}    } })
hl.curve("macWindowMove",   { type = "bezier", points = { {0.4, 0},      {0.2, 1}       } })
hl.curve("macUIFast",       { type = "bezier", points = { {0.2, 0},      {0, 1}         } })
hl.curve("macUISmooth",     { type = "bezier", points = { {0.4, 0.0},    {0.2, 1.0}      } })
hl.curve("macGenie",        { type = "bezier", points = { {0.25, 1.0},   {0.25, 1.0}    } })
hl.curve("macScale",         { type = "bezier", points = { {0.36, 0},     {0.66, -0.56}  } })

-- Main config: general, decoration, misc, etc.
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 3,
        gaps_workspaces = 20,
        border_size = 2,
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true,
        layout = "dwindle",
        col = {
            active_border   = { colors = {0x000000EE, 0x30343AFF, 0x00FFCCEE, 0x000000EE}, angle = 45 },
            inactive_border = { colors = {0x000000CC, 0x30343AEE, 0x00FFCC66, 0x000000CC}, angle = 45 },
        },
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
            ignore_window = true,
            range = 30,
            offset = {0, 2},
            render_power = 4,
            color = 0x00000010,
        },
        dim_inactive = true,
        dim_strength = 0.015,
        dim_special = 0.07,
    },

    animations = {
        enabled = true,
        -- Window animations
        { leaf = "windowsIn",      enabled = true, speed = 2.5,  bezier = "macWindowOpen" },
        { leaf = "windowsOut",     enabled = true, speed = 2,    bezier = "macWindowClose" },
        { leaf = "windowsMove",    enabled = true, speed = 2,    bezier = "macFluid" },
        -- Layer animations
        { leaf = "layersIn",       enabled = true, speed = 3,    bezier = "macEaseOut" },
        { leaf = "layersOut",      enabled = true, speed = 2.5,  bezier = "macEaseIn" },
        { leaf = "fadeLayersIn",   enabled = true, speed = 2.5,  bezier = "macUISmooth" },
        { leaf = "fadeLayersOut",  enabled = true, speed = 2,    bezier = "macUISmooth" },
        -- Fade animations
        { leaf = "fadeIn",         enabled = true, speed = 3,    bezier = "macSmooth" },
        { leaf = "fadeOut",        enabled = true, speed = 2.5,  bezier = "macSmooth" },
        { leaf = "fadeSwitch",     enabled = true, speed = 3,    bezier = "macEaseInOut" },
        { leaf = "fadeShadow",     enabled = true, speed = 3,    bezier = "macEaseOut" },
        { leaf = "fadeDim",        enabled = true, speed = 3,    bezier = "macFluid" },
        -- Workspace animations
        { leaf = "workspaces",            enabled = true, speed = 3, bezier = "macEaseInOut" },
        { leaf = "specialWorkspaceIn",    enabled = true, speed = 3, bezier = "macOvershoot" },
        { leaf = "specialWorkspaceOut",   enabled = true, speed = 2.5, bezier = "macSharp" },
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

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vfr = true,
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

    xwayland = {
        force_zero_scaling = true,
        use_nearest_neighbor = true,
    },
})

-- Gestures
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

-- Plugins: hyprexpo
hl.config({
    plugin = {
        hyprexpo = {
            columns = 4,
            gap_size = 10,
            bg_col = 0x000000,
            workspace_method = { "first", 1 },
        },
    },
})
