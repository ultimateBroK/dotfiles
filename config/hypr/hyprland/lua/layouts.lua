-- =============================================================================
-- Layouts Configuration
-- Dwindle, Master, Scrolling layouts
-- NOTE: Hyprland 0.55+ required for Lua config
-- =============================================================================

-- Dwindle layout
hl.config({
    dwindle = {
        pseudotile = true,
        force_split = 2,
        preserve_split = true,
        smart_split = true,
        smart_resizing = true,
        permanent_direction_override = false,
        special_scale_factor = 1.0,
        split_width_multiplier = 1.0,
        use_active_for_splits = true,
        default_split_ratio = 1.0,
        split_bias = 0,
        precise_mouse_move = false,
    },
})

-- Master layout
hl.config({
    master = {
        allow_small_split = false,
        special_scale_factor = 1.0,
        mfact = 0.50,
        new_status = "slave",
        new_on_top = false,
        new_on_active = "none",
        orientation = "left",
        slave_count_for_center_master = 2,
        center_master_fallback = "left",
        smart_resizing = true,
        drop_at_cursor = true,
        always_keep_position = false,
    },
})

-- Scrolling layout
hl.config({
    scrolling = {
        column_width = 0,
        fullscreen_on_one_column = true,
        scroll_delay = 10,
        scroll_delta = 50,
        scroll_increment = 0,
    },
})
