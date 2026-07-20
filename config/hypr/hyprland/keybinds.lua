-- =============================================================================
-- Hyprland Keybinds (Lua) — đồng bộ 1:1 từ hyprland/keybinds.conf
-- - Comment `# [hidden]` → `-- [hidden]` (cheatsheet)
-- - `#!` / `##!` / `###` → tiêu đề section
-- API: hl.bind (Hyprland 0.55+/0.56+)
--
-- FIX: hyprlang `code:N` (X11 keycode) được map sang keysym (`1`..`0`, `KP_*`).
--      Trong Lua, `SUPER + code:10` được accept nhưng keycode=0 → bind chết
--      (Super+số không chuyển workspace).
-- =============================================================================

local h = require("hyprland.helpers")
local QSP = h.quickshell_profile
local QSD = h.quickshell_config_dir()

-- Mirrors hyprland.conf: exec = hyprctl dispatch submap global + submap = global
-- (hl.exec_cmd top-level = keyword `exec` — chạy mỗi lần reload)
-- legacy: hyprctl dispatch submap global (broken on Lua). Default submap is fine; VM uses define_submap.
hl.dispatch(hl.dsp.submap("reset"))

-- =============================================================================
-- Hyprland Keybinds
-- - Lines ending with `# [hidden]` won't be shown on cheatsheet
-- - Lines starting with #! are section headings
-- =============================================================================

--!
--!! Shell

--### Overview & Launcher
-- These absolutely need to be on top, or they won't work consistently
hl.bind("SUPER + SUPER_L", hl.dsp.global("quickshell:overviewToggleRelease"), { ignore_mods = true, description = "Toggle overview" }) -- Toggle overview/launcher
hl.bind("SUPER + SUPER_R", hl.dsp.global("quickshell:overviewToggleRelease"), { ignore_mods = true, description = "Toggle overview" }) -- [hidden] Toggle overview/launcher
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pkill fuzzel || fuzzel")) -- [hidden] Launcher (fallback)
hl.bind("SUPER + SUPER_R", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pkill fuzzel || fuzzel")) -- [hidden] Launcher (fallback)
-- catchall ngoài submap không hợp lệ trên Lua 0.55+; interrupt vẫn có mouse/Ctrl+SUPER
-- hl.bind("SUPER + catchall", ...) -- [hidden] was: binditn Super, catchall
hl.bind("CTRL + SUPER_L", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("CTRL + SUPER_R", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse:272", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse:273", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse:274", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse:275", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse:276", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse:277", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse_up", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
hl.bind("SUPER + mouse_down", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- [hidden]
-- bind = Super, Tab, global, quickshell:overviewWorkspacesToggle # [hidden] Toggle overview/launcher (alt)
hl.bind("SHIFT + SUPER + ALT + Slash", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/" .. QSP .. "/welcome.qml")) -- [hidden] Launch welcome app
hl.bind("SUPER + Tab", hl.dsp.focus({ last = true })) -- [hidden] Switch between 2 most recent apps (was: focuscurrentorlast)
-- bind = Alt, Space, exec, vicinae toggle


--### Quick Actions (Clipboard / Emoji / Workspace HUD)
hl.bind("SUPER_L", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true }) -- [hidden]
hl.bind("SUPER_R", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true }) -- [hidden]
hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"), { description = "Clipboard history >> clipboard" }) -- Clipboard history >> clipboard
hl.bind("SUPER + Period", hl.dsp.global("quickshell:overviewEmojiToggle"), { description = "Emoji >> clipboard" }) -- Emoji >> clipboard

--### Sidebars & Panels
--### Left sidebar
hl.bind("SUPER + A", hl.dsp.global("quickshell:sidebarLeftToggle"), { description = "Toggle left sidebar" }) -- Toggle left sidebar
hl.bind("SUPER + CTRL + A", hl.dsp.global("quickshell:sidebarLeftTogglePin"), { description = "Pin/unpin left sidebar" }) -- Pin/unpin left sidebar

--### Right sidebar
hl.bind("SUPER + N", hl.dsp.global("quickshell:sidebarRightToggle"), { description = "Toggle right sidebar" }) -- Toggle right sidebar
hl.bind("SUPER + CTRL + N", hl.dsp.global("quickshell:sidebarRightTogglePin"), { description = "Pin/unpin right sidebar" }) -- Pin/unpin right sidebar

--### Bar / Dock
hl.bind("SUPER + J", hl.dsp.global("quickshell:barToggle"), { description = "Toggle bar" }) -- Toggle bar
hl.bind("SUPER + CTRL + J", hl.dsp.global("quickshell:barAutoHideToggle"), { description = "Toggle bar auto-hide" }) -- Toggle bar auto-hide
hl.bind("SUPER + SHIFT + D", hl.dsp.global("quickshell:dockToggle"), { description = "Toggle dock" }) -- Toggle dock
hl.bind("SUPER + CTRL + D", hl.dsp.global("quickshell:dockTogglePin"), { description = "Pin/unpin dock" }) -- Pin/unpin dock

--### Panels & helpers
hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Toggle cheatsheet" }) -- Toggle cheatsheet
hl.bind("SUPER + K", hl.dsp.global("quickshell:oskToggle"), { description = "Toggle on-screen keyboard" }) -- Toggle on-screen keyboard
hl.bind("SUPER + G", hl.dsp.global("quickshell:overlayToggle")) -- Toggle overlay
hl.bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:sessionToggle"), { description = "Toggle session menu" }) -- Toggle session menu
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pkill wlogout || wlogout -p layer-shell")) -- [hidden] Session menu (fallback)
hl.bind("SUPER + M", hl.dsp.global("quickshell:mediaControlsToggle"), { description = "Toggle media controls" }) -- Toggle media controls

--### Hardware Keys & Audio
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call brightness increment || brightnessctl s 5%+"), { locked = true, repeating = true }) -- [hidden]
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call brightness decrement || brightnessctl s 5%-"), { locked = true, repeating = true }) -- [hidden]
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5 && ~/.config/hypr/hyprland/scripts/play_sound.sh audio-volume-change"), { locked = true, repeating = true }) -- [hidden]
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%- && ~/.config/hypr/hyprland/scripts/play_sound.sh audio-volume-change"), { locked = true, repeating = true }) -- [hidden]
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true }) -- [hidden]
hl.bind("SUPER + ALT + K", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/toggle_wayvibes.sh"), { description = "Toggle keyboard sounds" }) -- Toggle keyboard sounds (wayvibes)
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true, description = "Toggle mute" }) -- [hidden]
hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true }) -- [hidden]
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true }) -- [hidden]
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true, description = "Toggle mic" }) -- [hidden]

--### Performance Profiles
hl.bind("SUPER + ALT + O", hl.dsp.global("quickshell:powerProfileCycle"), { description = "Cycle performance profiles" }) -- Cycle: Performance → Balanced → Power Saver

--### Wallpaper / Appearance / Panels
hl.bind("CTRL + SUPER + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "Toggle wallpaper selector" }) -- Wallpaper selector
hl.bind("CTRL + SUPER + ALT + T", hl.dsp.global("quickshell:wallpaperSelectorRandom"), { description = "Select random wallpaper" }) -- Random wallpaper
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || ~/.config/quickshell/" .. QSP .. "/scripts/colors/switchwall.sh"), { description = "Change wallpaper" }) -- [hidden] Change wallpaper (fallback)
hl.bind("SUPER + ALT + W", hl.dsp.global("quickshell:panelFamilyCycle")) -- Cycle panel family
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall ags agsv1 gjs ydotool qs quickshell; qs -c " .. QSP .. " &")) -- Restart widgets

--!
--!! Utilities

--### Screenshots & Visual Capture
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"), { description = "Copy clipboard history entry" }) -- [hidden] Clipboard history >> clipboard (fallback)
hl.bind("SUPER + Period", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pkill fuzzel || ~/.config/hypr/hyprland/scripts/fuzzel-emoji.sh copy"), { description = "Copy an emoji" }) -- [hidden] Emoji >> clipboard (fallback)
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot")) -- Screen snip
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pidof slurp || ~/.config/hypr/hyprland/scripts/screenshot.sh --region --clipboard")) -- [hidden] Screen snip (fallback)
hl.bind("SUPER + SHIFT + A", hl.dsp.global("quickshell:regionSearch")) -- Google Lens
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pidof slurp || ~/.config/hypr/hyprland/scripts/snip_to_search.sh")) -- [hidden] Google Lens (fallback)
hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/screenshot.sh --fullscreen --clipboard"), { locked = true }) -- Screenshot >> clipboard
hl.bind("CTRL + Print", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/screenshot.sh --fullscreen --both"), { locked = true, non_consuming = true }) -- Screenshot >> clipboard & file
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/screenshot.sh --cursor --clipboard")) -- Screenshot at cursor >> clipboard
hl.bind("SHIFT + CTRL + Print", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/screenshot.sh --cursor --both")) -- Screenshot at cursor >> clipboard & file

--### OCR & Color Picker
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr")) -- Character recognition >> clipboard
hl.bind("SUPER + SHIFT + T", hl.dsp.global("quickshell:regionOcr")) -- [hidden]
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\\\n' '+' | sed 's/\\\\+$/\\\\n/') | wl-copy && rm \"/tmp/ocr_image.png\"")) -- [hidden]
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\\\n' '+' | sed 's/\\\\+$/\\\\n/') | wl-copy && rm \"/tmp/ocr_image.png\"")) -- [hidden]
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" }) -- Pick color (Hex) >> clipboard

--### Recording & Capture Automation
hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true }) -- Record region (no sound)
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || ~/.config/quickshell/" .. QSP .. "/scripts/videos/record.sh"), { locked = true }) -- [hidden] Record region (no sound) (fallback)
hl.bind("SUPER + ALT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true }) -- [hidden] Record region (no sound)
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || ~/.config/quickshell/" .. QSP .. "/scripts/videos/record.sh"), { locked = true }) -- [hidden] Record region (no sound) (fallback)
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("~/.config/quickshell/" .. QSP .. "/scripts/videos/record.sh --fullscreen"), { locked = true }) -- [hidden] Record screen (no sound)
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd("~/.config/quickshell/" .. QSP .. "/scripts/videos/record.sh --fullscreen --sound"), { locked = true }) -- Record screen (with sound)

--### AI Helpers
hl.bind("SUPER + SHIFT + ALT + mouse:273", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/ai/primary-buffer-query.sh"), { description = "Generate AI summary for selected text" }) -- [hidden] AI summary for selected text

--!
--!! Window
--### Mouse Interactions
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true }) -- Move
hl.bind("SUPER + mouse:274", hl.dsp.window.drag(), { mouse = true }) -- [hidden]
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- Resize

--### Focus & Window Movement
--/#/ bind = Super, ←/↑/→/↓,, # Focus in direction
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "left" })) -- [hidden]
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "right" })) -- [hidden]
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "up" })) -- [hidden]
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "down" })) -- [hidden]
hl.bind("SUPER + BracketLeft", hl.dsp.focus({ direction = "left" })) -- [hidden]
hl.bind("SUPER + BracketRight", hl.dsp.focus({ direction = "right" })) -- [hidden]
--/#/ bind = Super+Shift, ←/↑/→/↓,, # Swap window in direction
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.swap({ direction = "left" })) -- [hidden]
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.swap({ direction = "right" })) -- [hidden]
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.swap({ direction = "up" })) -- [hidden]
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.swap({ direction = "down" })) -- [hidden]
hl.bind("ALT + F4", hl.dsp.window.close()) -- [hidden] Close (Windows)
hl.bind("SUPER + Q", hl.dsp.window.close()) -- Close
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill")) -- Forcefully zap a window

--### Window Resize
hl.bind("SUPER + ALT + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true }) -- Grow width
hl.bind("SUPER + ALT + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true }) -- Shrink width
hl.bind("SUPER + ALT + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true }) -- Shrink height
hl.bind("SUPER + ALT + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true }) -- Grow height

--### Split Ratio / Modes / Pinning
--/#/ binde = Super, ;/',, # Adjust split ratio
hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true }) -- [hidden] dwindle: was splitratio dispatcher (removed 0.54+)
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true }) -- [hidden]
hl.bind("SUPER + ALT + Space", hl.dsp.window.float({ action = "toggle" })) -- Float/Tile
hl.bind("SUPER + D", hl.dsp.window.fullscreen({ mode = 1 })) -- Maximize
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = 0 })) -- Fullscreen
hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 3 })) -- Fullscreen spoof
hl.bind("SUPER + P", hl.dsp.window.pin()) -- Pin

--### Workspace Sends (Numeric)
--/#/ bind = Super+Alt, Hash,, # Send to workspace # (1, 2, 3,...)
-- We use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
hl.bind("SUPER + ALT + 1", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 1")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 2", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 2")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 3", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 3")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 4", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 4")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 5", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 5")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 6", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 6")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 7", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 7")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 8", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 8")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 9", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 9")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + 0", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 10")) -- [hidden] -- was: code in conf
-- keypad numbers
hl.bind("SUPER + ALT + KP_1", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 1")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_2", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 2")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_3", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 3")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_4", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 4")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_5", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 5")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_6", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 6")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_7", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 7")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_8", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 8")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_9", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 9")) -- [hidden] -- was: code in conf
hl.bind("SUPER + ALT + KP_0", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 10")) -- [hidden] -- was: code in conf

--### Workspace Sends (Scroll / Paging)
-- bind = Super+Shift, mouse_down, layoutmsg, move -col # [hidden] Hyprscrolling scroll left
-- bind = Super+Shift, mouse_up, layoutmsg, move +col # [hidden] Hyprscrolling scroll right
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = -1 })) -- [hidden]
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" })) -- [hidden]
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" })) -- [hidden]
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = -1 })) -- [hidden]
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "r+1" })) -- [hidden]
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "r-1" })) -- [hidden]
hl.bind("CTRL + SUPER + SHIFT + Right", hl.dsp.window.move({ workspace = "r+1" })) -- [hidden]
hl.bind("CTRL + SUPER + SHIFT + Left", hl.dsp.window.move({ workspace = "r-1" })) -- [hidden]
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special", silent = true })) -- Send to scratchpad
hl.bind("CTRL + SUPER + S", hl.dsp.workspace.toggle_special()) -- [hidden]

--!! Workspace
--### Switching (Number Row)
--/#/ bind = Super, Hash,, # Focus workspace # (1, 2, 3,...)
-- We use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
hl.bind("SUPER + 1", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 1")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 2", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 2")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 3", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 3")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 4", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 4")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 5", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 5")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 6", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 6")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 7", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 7")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 8", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 8")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 9", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 9")) -- [hidden] -- was: code in conf
hl.bind("SUPER + 0", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 10")) -- [hidden] -- was: code in conf

--### Switching (Keypad)
hl.bind("SUPER + KP_1", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 1")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_2", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 2")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_3", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 3")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_4", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 4")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_5", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 5")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_6", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 6")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_7", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 7")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_8", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 8")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_9", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 9")) -- [hidden] -- was: code in conf
hl.bind("SUPER + KP_0", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 10")) -- [hidden] -- was: code in conf

--!! Workspace 11-20 (for secondary monitor)
-- Switch to workspace 11-20 (using Ctrl modifier to avoid conflicts with Super+Shift)
-- We use raw keycodes because some keyboard layouts register number keys as different chars
hl.bind("CTRL + SUPER + 1", hl.dsp.focus({ workspace = 11 })) -- Switch to workspace 11 -- was: code in conf
hl.bind("CTRL + SUPER + 2", hl.dsp.focus({ workspace = 12 })) -- Switch to workspace 12 -- was: code in conf
hl.bind("CTRL + SUPER + 3", hl.dsp.focus({ workspace = 13 })) -- Switch to workspace 13 -- was: code in conf
hl.bind("CTRL + SUPER + 4", hl.dsp.focus({ workspace = 14 })) -- Switch to workspace 14 -- was: code in conf
hl.bind("CTRL + SUPER + 5", hl.dsp.focus({ workspace = 15 })) -- Switch to workspace 15 -- was: code in conf
hl.bind("CTRL + SUPER + 6", hl.dsp.focus({ workspace = 16 })) -- Switch to workspace 16 -- was: code in conf
hl.bind("CTRL + SUPER + 7", hl.dsp.focus({ workspace = 17 })) -- Switch to workspace 17 -- was: code in conf
hl.bind("CTRL + SUPER + 8", hl.dsp.focus({ workspace = 18 })) -- Switch to workspace 18 -- was: code in conf
hl.bind("CTRL + SUPER + 9", hl.dsp.focus({ workspace = 19 })) -- Switch to workspace 19 -- was: code in conf
hl.bind("CTRL + SUPER + 0", hl.dsp.focus({ workspace = 20 })) -- Switch to workspace 20 -- was: code in conf
-- Move window to workspace 11-20
hl.bind("CTRL + SUPER + ALT + 1", hl.dsp.window.move({ workspace = 11, silent = true })) -- Move window to workspace 11 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 2", hl.dsp.window.move({ workspace = 12, silent = true })) -- Move window to workspace 12 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 3", hl.dsp.window.move({ workspace = 13, silent = true })) -- Move window to workspace 13 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 4", hl.dsp.window.move({ workspace = 14, silent = true })) -- Move window to workspace 14 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 5", hl.dsp.window.move({ workspace = 15, silent = true })) -- Move window to workspace 15 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 6", hl.dsp.window.move({ workspace = 16, silent = true })) -- Move window to workspace 16 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 7", hl.dsp.window.move({ workspace = 17, silent = true })) -- Move window to workspace 17 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 8", hl.dsp.window.move({ workspace = 18, silent = true })) -- Move window to workspace 18 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 9", hl.dsp.window.move({ workspace = 19, silent = true })) -- Move window to workspace 19 -- was: code in conf
hl.bind("CTRL + SUPER + ALT + 0", hl.dsp.window.move({ workspace = 20, silent = true })) -- Move window to workspace 20 -- was: code in conf

--### Overview & Paging
-- Toggle hyprexpo (plugin). No-op if plugin not loaded.
hl.bind("SUPER + SHIFT + E", function()
  pcall(function()
    hl.exec_cmd([[hyprctl eval 'local p = hl.plugin and hl.plugin.hyprexpo; if p and p.expo then p.expo("toggle") end']])
  end)
end) -- Toggle expo
hl.bind("CTRL + SUPER + Right", hl.dsp.focus({ workspace = "r+1" })) -- [hidden]
hl.bind("CTRL + SUPER + Left", hl.dsp.focus({ workspace = "r-1" })) -- [hidden]
hl.bind("CTRL + SUPER + ALT + Right", hl.dsp.focus({ workspace = "m+1" })) -- [hidden]
hl.bind("CTRL + SUPER + ALT + Left", hl.dsp.focus({ workspace = "m-1" })) -- [hidden]
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" })) -- [hidden]
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = -1 })) -- [hidden]
hl.bind("CTRL + SUPER + Page_Down", hl.dsp.focus({ workspace = "r+1" })) -- [hidden]
hl.bind("CTRL + SUPER + Page_Up", hl.dsp.focus({ workspace = "r-1" })) -- [hidden]

--### Scroll & Mouse Based Switching
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" })) -- [hidden] Workspace up (vertical)
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = -1 })) -- [hidden] Workspace down (vertical)
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "r+1" })) -- [hidden]
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "r-1" })) -- [hidden]

--### Special / Scratchpad
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special()) -- Toggle scratchpad
hl.bind("SUPER + mouse:275", hl.dsp.workspace.toggle_special()) -- [hidden]
hl.bind("CTRL + SUPER + BracketLeft", hl.dsp.focus({ workspace = -1 })) -- [hidden]
hl.bind("CTRL + SUPER + BracketRight", hl.dsp.focus({ workspace = "+1" })) -- [hidden]
hl.bind("CTRL + SUPER + Up", hl.dsp.focus({ workspace = "r-5" })) -- [hidden]
hl.bind("CTRL + SUPER + Down", hl.dsp.focus({ workspace = "r+5" })) -- [hidden]

--!! Virtual machines
hl.bind("SUPER + ALT + F1", function() -- Disable keybinds
  hl.exec_cmd("notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. Hit Super+Alt+F1 to escape' -a 'Hyprland'")
  hl.dispatch(hl.dsp.submap("virtual-machine"))
end)
hl.define_submap("virtual-machine", function()
  hl.bind("SUPER + ALT + F1", function() -- [hidden]
    hl.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'")
    hl.dispatch(hl.dsp.submap("reset"))
  end)
end)


--!
-- Testing
hl.bind("SUPER + ALT + f11", hl.dsp.exec_cmd("bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | grep -v -i \"nipple\" | grep -v -i \"pussy\" | shuf -n 1); ACTION=$(notify-send \"Test notification with body image\" \"This notification should contain your user account <b>image</b> and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\\\"$RANDOM_IMAGE\\\" alt=\\\"Testing image\\\"/>\" -a \"Hyprland keybind\" -p -h \"string:image-path:/var/lib/AccountsService/icons/$USER\" -t 6000 -i \"discord\" -A \"openImage=Open profile image\" -A \"action2=Open the random image\" -A \"action3=Useless button\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"; [[ $ACTION == *action2 ]] && xdg-open \\\"$RANDOM_IMAGE\\\"'")) -- [hidden]
hl.bind("SUPER + ALT + f12", hl.dsp.exec_cmd("bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | grep -v -i \"nipple\" | grep -v -i \"pussy\" | shuf -n 1); ACTION=$(notify-send \"Test notification\" \"This notification should contain a random image in your <b>Pictures</b> folder and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>.\\n<i>Flick right to dismiss!</i>\" -a \"Discord (fake)\" -p -h \"string:image-path:$RANDOM_IMAGE\" -t 6000 -i \"discord\" -A \"openImage=Open profile image\" -A \"action2=Useless button\" -A \"action3=Cry more\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"'")) -- [hidden]
hl.bind("SUPER + ALT + Equal", hl.dsp.exec_cmd("notify-send \"Urgent notification\" \"Ah hell no\" -u critical -a 'Hyprland keybind'")) -- [hidden]

--!! Session
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock" }) -- Lock
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), { locked = true, description = "Suspend system" }) -- Sleep
-- bindl=,switch:on:Lid Switch, exec, systemctl suspend || loginctl suspend # [hidden] Suspend when laptop lid is closed, uncomment if for whatever reason it's not the default behavior
hl.bind("CTRL + SHIFT + ALT + SUPER + Delete", hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"), { description = "Shutdown" }) -- [hidden] Power off

--!! Screen
-- Zoom
hl.bind("SUPER + Minus", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call zoom zoomOut"), { repeating = true }) -- Zoom out
hl.bind("SUPER + Equal", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call zoom zoomIn"), { repeating = true }) -- Zoom in
hl.bind("SUPER + Minus", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.1"), { repeating = true }) -- [hidden] Zoom out
hl.bind("SUPER + Equal", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh increase 0.1"), { repeating = true }) -- [hidden] Zoom in
-- Zoom with keypad
hl.bind("SUPER + KP_Subtract", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call zoom zoomOut"), { repeating = true }) -- [hidden] Zoom out -- was: code in conf
hl.bind("SUPER + KP_Add", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call zoom zoomIn"), { repeating = true }) -- [hidden] Zoom in -- was: code in conf
hl.bind("SUPER + KP_Subtract", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.1"), { repeating = true }) -- [hidden] Zoom out -- was: code in conf
hl.bind("SUPER + KP_Add", hl.dsp.exec_cmd("qs -c " .. QSP .. " ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh increase 0.1"), { repeating = true }) -- [hidden] Zoom in -- was: code in conf

--!! Media
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`"), { locked = true }) -- Next track
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`"), { locked = true }) -- [hidden]
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true }) -- [hidden]
hl.bind("SUPER + SHIFT + ALT + mouse:275", hl.dsp.exec_cmd("playerctl previous")) -- [hidden]
hl.bind("SUPER + SHIFT + ALT + mouse:276", hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`")) -- [hidden]
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("playerctl previous"), { locked = true }) -- Previous track
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- Play/pause media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- [hidden]
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- [hidden]

--!! Apps
hl.bind("SUPER + Return", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"ghostty\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\"")) -- Terminal
hl.bind("SUPER + T", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh  \"${TERMINAL}\" \"ghostty\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\"")) -- [hidden] (terminal) (alt)
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"ghostty\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\"")) -- [hidden] (terminal) (for Ubuntu people)
hl.bind("SUPER + E", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"nautilus\" \"dolphin\" \"nemo\" \"thunar\" \"${TERMINAL}\" \"kitty -1 fish -c yazi\"")) -- File manager
hl.bind("SUPER + W", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh  \"google-chrome-stable\" \"floorp\" \"zen-browser\" \"microsoft-edge-stable\" \"firefox\" \"brave\" \"opera\" \"librewolf\" \"chromium\"")) -- Browser
hl.bind("SUPER + C", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"code\" \"codium\" \"cursor\" \"zed\" \"zedit\" \"zeditor\" \"kate\" \"gnome-text-editor\" \"emacs\" \"command -v nvim && kitty -1 nvim\" \"command -v micro && kitty -1 micro\"")) -- Code editor
hl.bind("CTRL + SUPER + SHIFT + ALT + W", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"wps\" \"onlyoffice-desktopeditors\" \"libreoffice\"")) -- Office software
hl.bind("SUPER + X", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"kate\" \"gnome-text-editor\" \"emacs\"")) -- Text editor
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"pavucontrol-qt\" \"pavucontrol\"")) -- Volume mixer
hl.bind("SUPER + I", hl.dsp.exec_cmd("XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh \"qs -p ~/.config/quickshell/" .. QSP .. "/settings.qml\" \"systemsettings\" \"gnome-control-center\" \"better-control\"")) -- Settings app
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/launch_first_available.sh \"gnome-system-monitor\" \"plasma-systemmonitor --page-name Processes\" \"command -v btop && kitty -1 fish -c btop\"")) -- Task manager

-- Cursed stuff
--# Make window not amogus large
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.resize({ x = 640, y = 480, relative = false })) -- [hidden]

--!! Custom

-- Open shell config
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json")) -- Edit shell config
-- Open Hyprland keybinds
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/hyprland/keybinds.conf")) -- Edit keybinds

-- ##! Hyprscrolling
-- # Move layout horizontally (using Y/U to avoid conflicts with Period/Comma)
-- bind = Super, Y, layoutmsg, move -col # Move layout left
-- bind = Super, U, layoutmsg, move +col # Move layout right
-- # Move window to column
-- bind = Super+Shift, Y, layoutmsg, movewindowto l # Move window left
-- bind = Super+Shift, U, layoutmsg, movewindowto r # Move window right
-- bind = Super+Shift, I, layoutmsg, movewindowto u # Move window up
-- bind = Super+Shift, O, layoutmsg, movewindowto d # Move window down
-- # Additional layout controls
-- bind = Super+Alt, Y, layoutmsg, colresize -0.1 # Resize column smaller
-- bind = Super+Alt, U, layoutmsg, colresize +0.1 # Resize column larger
-- bind = Super+Alt, P, layoutmsg, promote # Promote window to new column
-- bind = Super+Alt, I, layoutmsg, togglefit # Toggle fit method
-- # Fit helpers
-- bind = Super+Ctrl, F, layoutmsg, fit active # Fit focused column
-- bind = Super+Ctrl, G, layoutmsg, fit visible # Fit visible columns
-- bind = Super+Ctrl+Shift, F, layoutmsg, fit all # Fit all columns
-- # Focus helpers (wrap inside layout)
-- bind = Super+Ctrl, H, layoutmsg, focus l # Focus column left
-- bind = Super+Ctrl, L, layoutmsg, focus r # Focus column right
-- bind = Super+Ctrl, K, layoutmsg, focus u # Focus row up
-- bind = Super+Ctrl, J, layoutmsg, focus d # Focus row down
-- # Swap entire columns
-- bind = Super+Ctrl+Shift, H, layoutmsg, swapcol l # Swap current column left
-- bind = Super+Ctrl+Shift, L, layoutmsg, swapcol r # Swap current column right

