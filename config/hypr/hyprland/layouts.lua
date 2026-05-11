-- =============================================================================
-- Layouts Configuration (hyprland/layouts/*.conf → Lua)
-- Dwindle, Master, Scrolling layouts
-- NOTE: Hyprland 0.55+ required for Lua config
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dwindle (layouts/dwindle-layout.conf)
-- https://wiki.hypr.land/Configuring/Dwindle-Layout/
--
-- Dwindle is a BSPWM-like layout where every window on a workspace
-- is a member of a binary tree. Splits are determined dynamically
-- by the W/H ratio of the parent node (W > H = side-by-side, H > W = top-bottom).
-- -----------------------------------------------------------------------------
hl.config({
    dwindle = {
        -- Hyprland 0.55+: dwindle:pseudotile removed — use per-window `pseudo` dispatcher
        -- (e.g. bind = Super, P, pseudo) instead of a layout-wide toggle.

        -- Split direction behavior:
        -- 0 = split follows mouse position
        -- 1 = always split to the left (new window = left or top)
        -- 2 = always split to the right (new window = right or bottom)
        force_split = 2,

        -- If enabled, the split (side/top) will not change regardless of container changes
        -- This makes splits PERMANENT instead of dynamic
        preserve_split = true,

        -- If enabled, allows precise split control based on cursor position
        -- The window is divided into four triangles, cursor's triangle determines split direction
        -- This also turns on preserve_split automatically
        smart_split = true,

        -- If enabled, resizing direction is based on mouse position on the window (nearest corner)
        -- Otherwise, it's based on the window's tiling position
        smart_resizing = true,

        -- If enabled, makes the preselect direction persist until:
        -- - This mode is turned off
        -- - Another direction is specified
        -- - A non-direction is specified (anything other than l,r,u/t,d/b)
        permanent_direction_override = false,

        -- Scale factor for windows on the special workspace [0.0 - 1.0]
        -- 1.0 = full size, 0.5 = half size, etc.
        special_scale_factor = 1.0,

        -- Auto-split width multiplier
        -- Useful on widescreen monitors where window W > H even after several splits
        -- Higher values = more vertical splits on wide monitors
        split_width_multiplier = 1.0,

        -- Whether to prefer the active window or the mouse position for splits
        -- true = use active window, false = use mouse position
        use_active_for_splits = true,

        -- Default split ratio on window open [0.1 - 1.9]
        -- 1.0 = even 50/50 split
        -- <1.0 = smaller new window, >1.0 = larger new window
        default_split_ratio = 1.0,

        -- Specifies which window receives the split ratio
        -- 0 = directional (the top or left window gets the ratio)
        -- 1 = the current window gets the ratio
        split_bias = 0,

        -- bindm movewindow will drop the window more precisely based on mouse position
        -- More accurate window placement when dragging
        precise_mouse_move = false,

        -- Removed in Hyprland 0.54+: single_window_aspect_ratio, single_window_aspect_ratio_tolerance
    },
})

-- -----------------------------------------------------------------------------
-- Master (layouts/master-layout.conf)
-- https://wiki.hypr.land/Configuring/Master-Layout/
-- -----------------------------------------------------------------------------
hl.config({
    master = {
        -- Allow adding additional master windows in a horizontal split style
        allow_small_split = false,

        -- Scale of special workspace windows [0.0 - 1.0]
        special_scale_factor = 1.0,

        -- Master window size as percentage [0.0 - 1.0]
        -- 0.55 = 55% master, 45% slave
        mfact = 0.50,

        -- New window behavior: master, slave, or inherit
        new_status = "slave",

        -- Whether newly opened window should be on top of stack
        new_on_top = false,

        -- Place new window relative to focused: before, after, or none
        new_on_active = "none",

        -- Default master area placement: left, right, top, bottom, or center
        orientation = "left",

        -- Inherit fullscreen when cycling/swapping windows
        -- inherit_fullscreen = true

        -- Minimum slave windows needed for center master layout
        slave_count_for_center_master = 2,

        -- Fallback orientation when slaves < slave_count_for_center_master
        -- Options: left, right, top, bottom
        center_master_fallback = "left",

        -- Smart resizing based on mouse position vs tiling position
        smart_resizing = true,

        -- Drag & drop windows at cursor position
        drop_at_cursor = true,

        -- Keep master in configured position when no slave windows
        always_keep_position = false,
    },
})

-- -----------------------------------------------------------------------------
-- Scrolling (layouts/scrolling-layout.conf)
-- https://wiki.hypr.land/Configuring/Scrolling-Layout/
--
-- Scrolling là layout nơi các cửa sổ được đặt trên một "băng" vô hạn
-- và bạn cuộn qua các cột bằng layout messages (layoutmsg).
--
-- Các option bên dưới dùng giá trị gần với mặc định trên wiki,
-- có thể tinh chỉnh thêm trong quá trình sử dụng.
--
-- Scrolling layout is built-in in Hyprland 0.54+. No hyprscrolling plugin needed.
--
-- To use: general { layout = scrolling } or: hyprctl keyword general:layout scrolling
--
-- Example binds (when layout = scrolling):
--   bind = $mainMod, period,  layoutmsg, move +col
--   bind = $mainMod, comma,   layoutmsg, move -col
--   bind = $mainMod SHIFT, period, layoutmsg, movewindowto r
--   bind = $mainMod SHIFT, comma,  layoutmsg, movewindowto l
-- -----------------------------------------------------------------------------
hl.config({
    scrolling = {
        -- Khi chỉ có một cột trên workspace, cho cột đó full màn hình
        -- (true giống PaperWM khi chỉ còn 1 column).
        fullscreen_on_one_column = true,

        -- Độ rộng mặc định của mỗi cột [0.1 - 1.0]
        -- 0.5 = mỗi cột chiếm 50% chiều rộng màn hình.
        column_width = 0.50,

        -- Cách đưa cột được focus vào tầm nhìn:
        -- 0 = center (đặt cột giữa màn hình)
        -- 1 = fit   (cố gắng "vừa khít" trong vùng nhìn được)
        focus_fit_method = 0,

        -- Khi focus window, layout tự động cuộn để đưa window vào vùng nhìn thấy.
        follow_focus = true,

        -- Tỉ lệ tối thiểu của window phải hiện trên màn hình
        -- để follow_focus kích hoạt [0.0 - 1.0].
        follow_min_visible = 0.4,

        -- Các độ rộng cột preset, dùng với layoutmsg colresize +conf/-conf
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",

        -- Hướng cột mới xuất hiện và hướng "cuộn" của layout
        -- Các giá trị hợp lệ: left/right/down/up
        direction = "right",
    },
})
