-- =============================================================================
-- Window Rules, Layer Rules, Workspace Rules
-- Floating presets, app rules, xwayland, gaming, PiP, layer styling
-- NOTE: Hyprland 0.55+ required for Lua config
-- =============================================================================

-- Helper: batch window rules
local function window_rules(rules)
    for _, r in ipairs(rules) do hl.window_rule(r) end
end

-- =============================================================================
-- PRESET FLOATING RULES
-- =============================================================================
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

-- =============================================================================
-- FILE DIALOGS
-- =============================================================================
window_rules({
    { match = { title = "^(Open File)" },         float = true, center = true },
    { match = { title = "^(Select a File)" },      float = true, center = true },
    { match = { title = "^(Open Folder)" },        float = true, center = true },
    { match = { title = "^(Save As)" },            float = true, center = true },
    { match = { title = "^(File Upload)" },        float = true, center = true },
    { match = { title = "(.*)(wants to save)" },   float = true, center = true },
    { match = { title = "(.*)(wants to open)" },   float = true, center = true },
    { match = { title = "^(Choose wallpaper)" },    float = true, center = true, size = {"monitor_w*0.6", "monitor_h*0.65"} },
    { match = { title = "^(Library)" },            float = true, center = true, tag = "+fp_45x45" },
})

-- =============================================================================
-- SYSTEM UTILITIES
-- =============================================================================
window_rules({
    { match = { class = "^(pavucontrol)$" },              tag = "+fp_45x45" },
    { match = { class = "^(org.pulseaudio.pavucontrol)$" }, tag = "+fp_45x45" },
    { match = { class = "^(pavucontrol-qt)$" },            tag = "+fp_55x70" },
    { match = { class = "^(nm-connection-editor)$" },      tag = "+fp_45x45" },
    { match = { class = "^(kcm_bluetooth)$" },             tag = "+fp_45x45" },
    { match = { class = "^(org.kde.bluedevilwizard)$" },   tag = "+fp_45x55" },
    { match = { class = "^(blueberry\\.py)$" },            float = true },
})

-- =============================================================================
-- KDE/PLASMA
-- =============================================================================
window_rules({
    { match = { class = ".*plasmawindowed.*" },           float = true },
    { match = { class = "kcm_.*" },                       float = true },
    { match = { class = ".*bluedevilwizard" },            float = true },
    { match = { class = "org.freedesktop.impl.portal.desktop.kde" }, tag = "+fp_60x65" },
    { match = { class = "^(plasma-changeicons)$" },        float = true, no_initial_focus = true },
    { match = { class = "^(plasma-changeicons)$" },        move = {"monitor_w*0.999999", "monitor_h*0.999999"} },
})

-- =============================================================================
-- SPECIFIC APPS
-- =============================================================================
window_rules({
    { match = { class = "^(protonvpn-app)$" },    tag = "+fp_top_right" },
    { match = { class = "^(Zotero)$" },            tag = "+fp_45x45" },
    { match = { class = "guifetch" },              float = true },
    { match = { title = ".*Welcome" },              float = true },
    { match = { title = ".*Shell conflicts.*" },    float = true },
    { match = { class = "^dev\\.warp\\.Warp$" },   tile = true },
    { match = { title = "^(Copying — Dolphin)$" },  move = {"monitor_w*0.4", "monitor_h*0.8"} },
})

-- =============================================================================
-- XWAYLAND / WINE
-- =============================================================================
window_rules({
    { match = { xwayland = true, class = "^$", title = "^$" }, no_blur = true },
    { match = { xwayland = true }, immediate = true, no_blur = true, no_shadow = true, no_anim = true },
    { match = { title = ".*\\.exe" },             immediate = true },
    { match = { class = "^wine.*$", xwayland = true }, immediate = true, no_blur = true, no_shadow = true, no_anim = true },
})

-- =============================================================================
-- GAMING
-- =============================================================================
window_rules({
    { match = { title = ".*minecraft.*" }, immediate = true },
    { match = { class = "^(steam_app).*" }, immediate = true },
})

-- =============================================================================
-- TRADINGVIEW
-- =============================================================================
window_rules({
    { match = { title = "^(.*TradingView.*)$" },  float = true },
    { match = { class = "^(?i)tradingview.*" },   immediate = true, no_blur = true, no_shadow = true, no_anim = true },
})

-- =============================================================================
-- WORKSPACE RULES
-- =============================================================================
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- =============================================================================
-- LAYER RULES
-- =============================================================================
-- Global
hl.layer_rule({ match = { namespace = ".*" }, xray = true })

-- Launchers/utilities
local launchers = { "walker", "anyrun", "selection", "hyprpicker", "noanim", "gtk4-layer-shell" }
for _, ns in ipairs(launchers) do
    hl.layer_rule({ match = { namespace = ns }, no_anim = true })
end

-- GTK layer shell
local gtk_ns = { "gtk-layer-shell", "launcher", "notifications", "logout_dialog" }
for _, ns in ipairs(gtk_ns) do
    hl.layer_rule({ match = { namespace = ns }, blur = true })
end
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "launcher" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" }, ignore_alpha = 0.69 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

-- AGS
hl.layer_rule({ match = { namespace = "sideleft.*" },  animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "overview" },    no_anim = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "osk" },         no_anim = true })

-- AGS bars/docks with patterns
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

-- Quickshell
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

-- Special cases
hl.layer_rule({ match = { namespace = "quickshell:popupTop" },    xray = false, ignore_alpha = 0.3, animation = "slide top" })
hl.layer_rule({ match = { namespace = "quickshell:popupBottom" }, xray = false, ignore_alpha = 0.3, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:popup" },       xray = false, ignore_alpha = 0.3 })
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true, ignore_alpha = 0 })
