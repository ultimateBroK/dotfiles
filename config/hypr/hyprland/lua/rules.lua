-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              HYPRLAND RULES                                  ║
-- ║                     (hyprland/rules.conf → Lua)                              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
--
-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                            1. GLOBAL SETTINGS                                │
-- └──────────────────────────────────────────────────────────────────────────────┘
--
-- Uncomment to apply global transparency to all windows:
-- hl.window_rule({ match = { class = ".*" }, opacity = … })  -- was: windowrule = opacity 0.89 …
--
-- No shadow for tiled windows (rules.conf: windowrule = no_shadow on, match:float false)

-- Helper: batch window rules
local function window_rules(rules)
    for _, r in ipairs(rules) do hl.window_rule(r) end
end

-- Global: no shadow on tiled windows (rules.conf §1)
hl.window_rule({
    name = "no-shadow-tiled",
    match = { float = false },
    no_shadow = true,
})

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                      3. FLOATING PRESETS (REUSABLE)                            │
-- │                                                                              │
-- │  Use `tag +<preset>` in per-app rules to apply these presets.                │
-- │  Docs: https://wiki.hypr.land/Configuring/Window-Rules/                      │
-- └──────────────────────────────────────────────────────────────────────────────┘
--
-- --- Centered presets --- / --- Corner presets --- (see rules.conf windowrule { name = … })
local floatPresets = {
    { name = "preset-float-center",     tag = "fp_center",      float = true, center = true },
    { name = "preset-float-45x45",      tag = "fp_45x45",      float = true, center = true, size = {"monitor_w*0.45", "monitor_h*0.45"} },
    { name = "preset-float-45x55",      tag = "fp_45x55",      float = true, center = true, size = {"monitor_w*0.45", "monitor_h*0.55"} },
    { name = "preset-float-55x70",      tag = "fp_55x70",      float = true, center = true, size = {"monitor_w*0.55", "monitor_h*0.7"} },
    { name = "preset-float-60x65",      tag = "fp_60x65",      float = true, center = true, size = {"monitor_w*0.6", "monitor_h*0.65"} },
    { name = "preset-float-top-right",  tag = "fp_top_right",  float = true, size = {"monitor_w*0.2", "monitor_h*0.5"}, move = {"monitor_w*0.795", "monitor_h*0.04"} },
    { name = "preset-float-bottom-right",tag = "fp_bottom_right", float = true, size = {"monitor_w*0.2", "monitor_h*0.5"}, move = {"monitor_w*0.795", "monitor_h*0.49"} },
}
for _, p in ipairs(floatPresets) do
    hl.window_rule({
        name  = p.name,
        match = { tag = p.tag },
        float = p.float,
        center = p.center,
        size = p.size,
        move = p.move,
    })
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                        4. FILE DIALOGS (FLOATING)                            │
-- └──────────────────────────────────────────────────────────────────────────────┘
window_rules({
    { match = { title = "^(Open File)(.*)$" },         float = true, center = true },
    { match = { title = "^(Select a File)(.*)$" },    float = true, center = true },
    { match = { title = "^(Open Folder)(.*)$" },      float = true, center = true },
    { match = { title = "^(Save As)(.*)$" },          float = true, center = true },
    { match = { title = "^(File Upload)(.*)$" },      float = true, center = true },
    { match = { title = "^(.*)(wants to save)$" },    float = true, center = true },
    { match = { title = "^(.*)(wants to open)$" },    float = true, center = true },
    { match = { title = "^(Choose wallpaper)(.*)$" }, float = true, center = true, size = {"monitor_w*0.6", "monitor_h*0.65"} },
    { match = { title = "^(Library)(.*)$" },          float = true, center = true, tag = "+fp_45x45" },
})

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                          5. APP-SPECIFIC RULES                               │
-- └──────────────────────────────────────────────────────────────────────────────┘
--
-- --- System utilities ---
window_rules({
    { match = { class = "^(pavucontrol)$" },              tag = "+fp_45x45" },
    { match = { class = "^(org.pulseaudio.pavucontrol)$" }, tag = "+fp_45x45" },
    { match = { class = "^(pavucontrol-qt)$" },            tag = "+fp_55x70" },
    { match = { class = "^(nm-connection-editor)$" },      tag = "+fp_45x45" },
    { match = { class = "^(kcm_bluetooth)$" },             tag = "+fp_45x45" },
    { match = { class = "^(org.kde.bluedevilwizard)$" },   tag = "+fp_45x55" },
    { match = { class = "^(blueberry\\.py)$" },            float = true },
    { match = { title = "^(illogical-impulse Settings)$" }, tag = "+fp_55x70" },
})

-- --- KDE/Plasma ---
window_rules({
    { match = { class = ".*plasmawindowed.*" },           float = true },
    { match = { class = "kcm_.*" },                       float = true },
    { match = { class = ".*bluedevilwizard" },            float = true },
    { match = { class = "org.freedesktop.impl.portal.desktop.kde" }, tag = "+fp_60x65" },
    { match = { class = "^(plasma-changeicons)$" },        float = true, no_initial_focus = true },
    { match = { class = "^(plasma-changeicons)$" },        move = {"monitor_w*0.999999", "monitor_h*0.999999"} },
})

-- --- Specific apps ---
window_rules({
    { match = { class = "^(protonvpn-app)$" },    tag = "+fp_top_right" },
    { match = { class = "^(Zotero)$" },            tag = "+fp_45x45" },
    { match = { class = "guifetch" },              float = true },
    { match = { title = ".*Welcome" },              float = true },
    { match = { title = ".*Shell conflicts.*" },    float = true },
    { match = { class = "^dev\\.warp\\.Warp$" },   tile = true },
    { match = { title = "^(Copying — Dolphin)$" },  move = {"monitor_w*0.4", "monitor_h*0.8"} },
})

-- --- JetBrains IDEs --- (rules.conf: no_initial_focus on float + empty title splash)
hl.window_rule({
    name = "jetbrains-no-initial-focus",
    match = { class = "^jetbrains-.*$", float = true, title = "^$|^\\s$|^win\\d+$" },
    no_initial_focus = true,
})

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                          6. PICTURE-IN-PICTURE                               │
-- └──────────────────────────────────────────────────────────────────────────────┘
window_rules({
    { match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true },
    { match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true },
    { match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = {"monitor_w*0.25", "monitor_h*0.25"} },
    { match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = {"monitor_w*0.73", "monitor_h*0.72"} },
    { match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true },
})

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                    7. XWAYLAND / WINE / PERFORMANCE                          │
-- └──────────────────────────────────────────────────────────────────────────────┘
--
-- Disable blur for empty XWayland context menus
-- XWayland performance optimizations (immediate, no_blur, no_shadow, no_anim)
--
-- Wine applications — ổn định tương tác trên XWayland:
-- - immediate: giảm input lag, hạn chế lỗi focus (cần allow_tearing trong general)
-- - no_blur/no_shadow/no_anim: giảm tải compositor, dialog/popup ít bị kẹt
-- Nếu dialog Wine không nhận click: trong winecfg tắt "Emulate a virtual desktop"
window_rules({
    { match = { xwayland = true, class = "^$", title = "^$" }, no_blur = true },
    { match = { xwayland = true }, immediate = true, no_blur = true, no_shadow = true, no_anim = true },
    { match = { title = ".*\\.exe" },             immediate = true },
    { match = { class = "^(?i)wine64.*" },       immediate = true },
    { match = { class = "^(?i)wine32.*" },       immediate = true },
    { match = { class = "^(?i)wine.*$", xwayland = true }, immediate = true, no_blur = true, no_shadow = true, no_anim = true },
})

-- Gaming
window_rules({
    { match = { title = ".*minecraft.*" }, immediate = true },
    { match = { class = "^(steam_app).*" }, immediate = true },
})

-- TradingView (Electron) - avoid compositor crashes
window_rules({
    { match = { title = "^(.*TradingView.*)$" },  float = true },
    { match = { class = "^(?i)tradingview.*" },   immediate = true, no_blur = true, no_shadow = true, no_anim = true },
})

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                            WORKSPACE RULES                                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                              LAYER RULES                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝
--
-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                              1. GLOBAL                                       │
-- └──────────────────────────────────────────────────────────────────────────────┘
-- layerrule = xray 1, match:namespace .*
-- layerrule = no_anim on, match:namespace .*   (optional rollback in rules.conf)
hl.layer_rule({ match = { namespace = ".*" }, xray = true })

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                         2. LAUNCHERS / UTILITIES                             │
-- └──────────────────────────────────────────────────────────────────────────────┘
local launchers = { "walker", "anyrun", "selection", "hyprpicker", "noanim", "gtk4-layer-shell" }
for _, ns in ipairs(launchers) do
    hl.layer_rule({ match = { namespace = ns }, no_anim = true })
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                           3. GTK LAYER SHELL                                 │
-- └──────────────────────────────────────────────────────────────────────────────┘
local gtk_ns = { "gtk-layer-shell", "launcher", "notifications", "logout_dialog" }
for _, ns in ipairs(gtk_ns) do
    hl.layer_rule({ match = { namespace = ns }, blur = true })
end
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "launcher" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" }, ignore_alpha = 0.69 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                                4. AGS                                        │
-- └──────────────────────────────────────────────────────────────────────────────┘
hl.layer_rule({ match = { namespace = "sideleft.*" },  animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "overview" },    no_anim = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "osk" },         no_anim = true })

-- AGS bars/docks with patterns (layerrule blur / ignore_alpha for session, bar, …)
local ags_patterns = {
    { ns = "session", blur = true },
    { ns = "bar",     blur = true, alpha = 0.6 },
    { ns = "barcorner", blur = true, alpha = 0.6 },
    { ns = "dock",    blur = true, alpha = 0.6 },
    { ns = "overview", blur = true, alpha = 0.6 },
    { ns = "cheatsheet", blur = true, alpha = 0.6 },
    { ns = "sideright", blur = true, alpha = 0.6 },
    { ns = "sideleft", blur = true, alpha = 0.6 },
    { ns = "osk",     blur = true, alpha = 0.6 },
}
for _, p in ipairs(ags_patterns) do
    hl.layer_rule({ match = { namespace = p.ns .. "[0-9]*" }, blur = true })
    if p.alpha then
        hl.layer_rule({ match = { namespace = p.ns .. "[0-9]*" }, ignore_alpha = p.alpha })
    end
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                             5. QUICKSHELL                                    │
-- └──────────────────────────────────────────────────────────────────────────────┘
--
-- Global quickshell / Specific components / No animation / Special cases
-- Bar hover popups (StyledPopup): force slide from the bar edge so all widgets (weather, battery, …) match.
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "quickshell:dock" }, ignore_alpha = 0.15 })
hl.layer_rule({ match = { namespace = "quickshell:bar" },           animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" },   animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" },    animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:dock" },          animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:osk" },           animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, animation = "slide top" })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" },   animation = "slide right" })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" },   animation = "slide left" })
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, animation = "popin 120%" })
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade" })

-- No animation
local noanim_ns = { "lockWindowPusher", "overlay", "overview", "polkit", "regionSelector", "screenshot", "session" }
for _, ns in ipairs(noanim_ns) do
    hl.layer_rule({ match = { namespace = "quickshell:" .. ns }, no_anim = true })
end

-- ┌──────────────────────────────────────────────────────────────────────────────┐
-- │                             6. DISABLED                                      │
-- └──────────────────────────────────────────────────────────────────────────────┘
--
-- Vicinae (optional layerrules — commented in rules.conf)
-- layerrule = blur on, match:namespace vicinae
-- layerrule = ignore_alpha 0, match:namespace vicinae
-- layerrule = no_anim on, match:namespace vicinae
hl.layer_rule({ match = { namespace = "quickshell:popupTop" },    xray = false, ignore_alpha = 0.3, animation = "slide top" })
hl.layer_rule({ match = { namespace = "quickshell:popupBottom" }, xray = false, ignore_alpha = 0.3, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:popup" },       xray = false, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true, ignore_alpha = 0 })
