-- =============================================================================
-- Hyprland Keybinds (Lua)
-- Rút gọn bằng loops, functions, table constructors
-- Yêu cầu: Hyprland 0.55+
-- =============================================================================

local h = require("helpers")
local qs = h.qs -- Quickshell helper

--! =============================================================================
--! SHELL: Overview & Launcher
--! =============================================================================

-- Toggle overview
bindid("Super", "Super_L", "Toggle overview", "global", "quickshell:overviewToggleRelease")
bindid("Super", "Super_R", "Toggle overview", "global", "quickshell:overviewToggleRelease") -- [hidden]

-- Launcher fallback (fuzzel)
bind("Super", "Super_L", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || fuzzel") -- [hidden]
bind("Super", "Super_R", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || fuzzel") -- [hidden]

-- Catchall for overview interrupt
binditn("Super", "catchall", "global", "quickshell:overviewToggleReleaseInterrupt") -- [hidden]
bind("Ctrl", "Super_L", "global", "quickshell:overviewToggleReleaseInterrupt") -- [hidden]
bind("Ctrl", "Super_R", "global", "quickshell:overviewToggleReleaseInterrupt") -- [hidden]

-- Mouse buttons for overview
for _, btn in ipairs({272, 273, 274, 275, 276, 277}) do
  bind("Super", "mouse:" .. btn, "global", "quickshell:overviewToggleReleaseInterrupt") -- [hidden]
end
bind("Super", "mouse_up",  "global", "quickshell:overviewToggleReleaseInterrupt") -- [hidden]
bind("Super", "mouse_down","global", "quickshell:overviewToggleReleaseInterrupt") -- [hidden]

-- Switch between 2 most recent apps
bind("Super", "Tab", "focuscurrentorlast") -- [hidden]

--! Quick Actions
bindit("Super_L", "global", "quickshell:workspaceNumber") -- [hidden]
bindit("Super_R", "global", "quickshell:workspaceNumber") -- [hidden]

--! Sidebars & Panels
bindd("Super", "A", "Toggle left sidebar", "global", "quickshell:sidebarLeftToggle")
bindd("Super+Ctrl", "A", "Pin/unpin left sidebar", "global", "quickshell:sidebarLeftTogglePin")

bindd("Super", "N", "Toggle right sidebar", "global", "quickshell:sidebarRightToggle")
bindd("Super+Ctrl", "N", "Pin/unpin right sidebar", "global", "quickshell:sidebarRightTogglePin")

--! Bar / Dock
bindd("Super", "J", "Toggle bar", "global", "quickshell:barToggle")
bindd("Super+Ctrl", "J", "Toggle bar auto-hide", "global", "quickshell:barAutoHideToggle")
bindd("Super+Shift", "D", "Toggle dock", "global", "quickshell:dockToggle")
bindd("Super+Ctrl", "D", "Pin/unpin dock", "global", "quickshell:dockTogglePin")

--! Hardware Keys & Audio
local vol_scripts = {
  raise   = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5 && ~/.config/hypr/hyprland/scripts/play_sound.sh audio-volume-change",
  lower   = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%- && ~/.config/hypr/hyprland/scripts/play_sound.sh audio-volume-change",
}
local bright_scripts = {
  up   = "qs -c $qsConfig ipc call brightness increment || brightnessctl s 5%+",
  down = "qs -c $qsConfig ipc call brightness decrement || brightnessctl s 5%-",
}

bindle("XF86MonBrightnessUp",   "exec", bright_scripts.up)
bindle("XF86MonBrightnessDown", "exec", bright_scripts.down)
bindle("XF86AudioRaiseVolume",  "exec", vol_scripts.raise)
bindle("XF86AudioLowerVolume",  "exec", vol_scripts.lower)
bindl("XF86AudioMute",          "exec", "wpctl set-mute @DEFAULT_SINK@ toggle")
bindl("XF86AudioMicMute",       "exec", "wpctl set-mute @DEFAULT_SOURCE@ toggle")

-- Mute toggles
bindld("Super+Shift", "M", "Toggle mute",         "exec", "wpctl set-mute @DEFAULT_SINK@ toggle")
bindld("Super+Alt",   "M", "Toggle mic",         "exec", "wpctl set-mute @DEFAULT_SOURCE@ toggle")
bindl("Alt",          "XF86AudioMute",            "exec", "wpctl set-mute @DEFAULT_SOURCE@ toggle")
bindd("Super+Alt",   "K", "Toggle keyboard sounds","exec", "~/.config/hypr/hyprland/scripts/toggle_wayvibes.sh")

--! Screenshots & Visual Capture
bind("Super+Shift", "S", "global", "quickshell:regionScreenshot")
bind("Super+Shift", "S", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || ~/.config/hypr/hyprland/scripts/screenshot.sh --region --clipboard") -- [hidden]

bind("Super+Shift", "A", "global", "quickshell:regionSearch")
bind("Super+Shift", "A", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || ~/.config/hypr/hyprland/scripts/snip_to_search.sh") -- [hidden]

-- Screenshot binds
bindl("Print",              "exec", "~/.config/hypr/hyprland/scripts/screenshot.sh --fullscreen --clipboard")
bindln("Ctrl", "Print",     "exec", "~/.config/hypr/hyprland/scripts/screenshot.sh --fullscreen --both")
bind("Shift", "Print",      "exec", "~/.config/hypr/hyprland/scripts/screenshot.sh --cursor --clipboard")
bind("Shift+Ctrl", "Print", "exec", "~/.config/hypr/hyprland/scripts/screenshot.sh --cursor --both")

--! OCR & Color Picker
bind("Super+Shift", "X", "global", "quickshell:regionOcr")
bind("Super+Shift", "T", "global", "quickshell:regionOcr") -- [hidden]
bind("Super+Shift", "X", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\\\n' '+' | sed 's/\\\\+$/\\\\n/') | wl-copy && rm \"/tmp/ocr_image.png\"") -- [hidden]
bind("Super+Shift", "T", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\\\n' '+' | sed 's/\\\\+$/\\\\n/') | wl-copy && rm \"/tmp/ocr_image.png\"") -- [hidden]
bindd("Super+Shift", "C", "Color picker", "exec", "hyprpicker -a")

--! Recording
bindl("Super+Shift", "R", "global", "quickshell:regionRecord")
bindl("Super+Shift", "R", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/quickshell/$qsConfig/scripts/videos/record.sh") -- [hidden]
bindl("Super+Alt", "R", "global", "quickshell:regionRecord") -- [hidden]
bindl("Super+Alt", "R", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/quickshell/$qsConfig/scripts/videos/record.sh") -- [hidden]
bindl("Ctrl+Alt", "R", "exec", "~/.config/quickshell/$qsConfig/scripts/videos/record.sh --fullscreen") -- [hidden]
bindl("Super+Shift+Alt", "R", "exec", "~/.config/quickshell/$qsConfig/scripts/videos/record.sh --fullscreen --sound")

--! Panels & Helpers
bindd("Super", "Slash", "Toggle cheatsheet", "global", "quickshell:cheatsheetToggle")
bindd("Super", "K", "Toggle on-screen keyboard", "global", "quickshell:oskToggle")
bind("Super", "G", "global", "quickshell:overlayToggle")
bindd("Ctrl+Alt", "Delete", "Toggle session menu", "global", "quickshell:sessionToggle")
bind("Ctrl+Alt", "Delete", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || pkill wlogout || wlogout -p layer-shell") -- [hidden]
bindd("Super", "M", "Toggle media controls", "global", "quickshell:mediaControlsToggle")
bindd("Super+Alt", "O", "Cycle performance profiles", "global", "quickshell:powerProfileCycle")

-- Wallpaper
bindd("Ctrl+Super", "T", "Toggle wallpaper selector", "global", "quickshell:wallpaperSelectorToggle")
bindd("Ctrl+Super+Alt", "T", "Select random wallpaper", "global", "quickshell:wallpaperSelectorRandom")
bind("Ctrl+Super", "T", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/quickshell/$qsConfig/scripts/colors/switchwall.sh") -- [hidden]
bind("Super+Alt", "W", "global", "quickshell:panelFamilyCycle")

-- Restart widgets
bind("Ctrl+Super", "R", "exec", "killall ags agsv1 gjs ydotool qs quickshell; qs -c $qsConfig &")

--! =============================================================================
--! WINDOW
--! =============================================================================

-- Mouse interactions (move/resize)
bindm("Super", "mouse:272", "movewindow")
bindm("Super", "mouse:274", "movewindow") -- [hidden]
bindm("Super", "mouse:273", "resizewindow")

-- Focus in direction (looped)
local dirs = {Left = "l", Right = "r", Up = "u", Down = "d"}
for key, dir in pairs(dirs) do
  bind("Super", key, "movefocus", dir) -- [hidden]
end
for key, dir in pairs(dirs) do
  bind("Super", "Bracket" .. key, "movefocus", dir) -- [hidden]
end

-- Swap window in direction (looped)
for key, dir in pairs(dirs) do
  bind("Super+Shift", key, "swapwindow", dir) -- [hidden]
end

-- Close
bind("Alt", "F4", "killactive") -- [hidden]
bind("Super", "Q", "killactive")
bind("Super+Shift+Alt", "Q", "exec", "hyprctl kill")

-- Resize (looped)
local resize = {right = "20 0", left = "-20 0", up = "0 -20", down = "0 20"}
for dir, val in pairs(resize) do
  binde("Super+Alt", dir, "resizeactive", val)
end

-- Split ratio
binde("Super", "Semicolon", "splitratio", "-0.1") -- [hidden]
binde("Super", "Apostrophe", "splitratio", "+0.1") -- [hidden]

-- Float/Tile, Maximize, Fullscreen, Pin
bind("Super+Alt", "Space", "togglefloating")
bind("Super", "D", "fullscreen", "1")
bind("Super", "F", "fullscreen", "0")
bind("Super+Alt", "F", "fullscreenstate", "0 3")
bind("Super", "P", "pin")

--! =============================================================================
--! WORKSPACE: Send to workspace (Super+Alt + number row)
--! =============================================================================

-- Main number row (code:10 = 1, code:19 = 10)
for i = 1, 10 do
  bind("Super+Alt", "code:" .. (9 + i), "exec", "~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent " .. i)
end

-- Keypad numbers
local keypad = {87, 88, 89, 83, 84, 85, 79, 80, 81, 90} -- 1-10
for i, code in ipairs(keypad) do
  bind("Super+Alt", "code:" .. code, "exec", "~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent " .. i)
end

-- Workspace paging (mouse/Page)
bind("Super+Alt", "mouse_down", "movetoworkspace", "-1") -- [hidden]
bind("Super+Alt", "mouse_up", "movetoworkspace", "+1") -- [hidden]
bind("Super+Alt", "Page_Down", "movetoworkspace", "+1") -- [hidden]
bind("Super+Alt", "Page_Up", "movetoworkspace", "-1") -- [hidden]
bind("Super+Shift", "Page_Down", "movetoworkspace", "r+1") -- [hidden]
bind("Super+Shift", "Page_Up", "movetoworkspace", "r-1") -- [hidden]
bind("Ctrl+Super+Shift", "Right", "movetoworkspace", "r+1") -- [hidden]
bind("Ctrl+Super+Shift", "Left", "movetoworkspace", "r-1") -- [hidden]
bind("Super+Alt", "S", "movetoworkspacesilent", "special")
bind("Ctrl+Super", "S", "togglespecialworkspace") -- [hidden]

--! =============================================================================
--! WORKSPACE: Switch (Super + number row)
--! =============================================================================

-- Main number row
for i = 1, 10 do
  bind("Super", "code:" .. (9 + i), "exec", "~/.config/hypr/hyprland/scripts/workspace_action.sh workspace " .. i)
end

-- Keypad
for i, code in ipairs(keypad) do
  bind("Super", "code:" .. code, "exec", "~/.config/hypr/hyprland/scripts/workspace_action.sh workspace " .. i)
end

--! =============================================================================
--! WORKSPACE: 11-20 (Ctrl+Super)
--! =============================================================================

for i = 11, 20 do
  bind("Ctrl+Super", "code:" .. (i - 1), "workspace", tostring(i))
end
for i = 11, 20 do
  bind("Ctrl+Super+Alt", "code:" .. (i - 1), "movetoworkspacesilent", tostring(i))
end

--! Overview & Paging
bind("Super+Shift", "E", "exec", "hyprctl dispatch hyprexpo:expo toggle")
bind("Ctrl+Super", "Right", "workspace", "r+1") -- [hidden]
bind("Ctrl+Super", "Left", "workspace", "r-1") -- [hidden]
bind("Ctrl+Super+Alt", "Right", "workspace", "m+1") -- [hidden]
bind("Ctrl+Super+Alt", "Left", "workspace", "m-1") -- [hidden]
bind("Super", "Page_Down", "workspace", "+1") -- [hidden]
bind("Super", "Page_Up", "workspace", "-1") -- [hidden]
bind("Ctrl+Super", "Page_Down", "workspace", "r+1") -- [hidden]
bind("Ctrl+Super", "Page_Up", "workspace", "r-1") -- [hidden]

-- Mouse-based workspace scroll
bind("Super", "mouse_up", "workspace", "+1") -- [hidden]
bind("Super", "mouse_down", "workspace", "-1") -- [hidden]
bind("Ctrl+Super", "mouse_up", "workspace", "r+1") -- [hidden]
bind("Ctrl+Super", "mouse_down", "workspace", "r-1") -- [hidden]

-- Special / Scratchpad
bind("Super", "S", "togglespecialworkspace")
bind("Super", "mouse:275", "togglespecialworkspace") -- [hidden]
bind("Ctrl+Super", "BracketLeft", "workspace", "-1") -- [hidden]
bind("Ctrl+Super", "BracketRight", "workspace", "+1") -- [hidden]
bind("Ctrl+Super", "Up", "workspace", "r-5") -- [hidden]
bind("Ctrl+Super", "Down", "workspace", "r+5") -- [hidden]

--! =============================================================================
--! VIRTUAL MACHINES
--! =============================================================================

bind("Super+Alt", "F1", "exec", "notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. Hit Super+Alt+F1 to escape' -a 'Hyprland' && hyprctl dispatch submap virtual-machine")
submap("virtual-machine")
bind("Super+Alt", "F1", "exec", "notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland' && hyprctl dispatch submap global") -- [hidden]
submap("global")

--! =============================================================================
--! SESSION & SCREEN
--! =============================================================================

-- Lock / Suspend / Shutdown
bindd("Super", "L", "Lock", "exec", "loginctl lock-session")
bindld("Super+Shift", "L", "Suspend system", "exec", "systemctl suspend || loginctl suspend")
bindd("Ctrl+Shift+Alt+Super", "Delete", "Shutdown", "exec", "systemctl poweroff || loginctl poweroff") -- [hidden]

-- Zoom (quickshell + fallback)
binde("Super", "Minus", "exec", "qs -c $qsConfig ipc call zoom zoomOut")
binde("Super", "Equal",  "exec", "qs -c $qsConfig ipc call zoom zoomIn")
binde("Super", "Minus", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.1") -- [hidden]
binde("Super", "Equal",  "exec", "qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh increase 0.1") -- [hidden]
binde("Super", "code:82", "exec", "qs -c $qsConfig ipc call zoom zoomOut") -- [hidden] keypad 0
binde("Super", "code:86", "exec", "qs -c $qsConfig ipc call zoom zoomIn")   -- [hidden] keypad +
binde("Super", "code:82", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.1") -- [hidden]
binde("Super", "code:86", "exec", "qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh increase 0.1") -- [hidden]

--! =============================================================================
--! MEDIA
--! =============================================================================

-- Volume keys
bindl("XF86AudioPlay",  "exec", "playerctl play-pause")
bindl("XF86AudioPause", "exec", "playerctl play-pause")
bindl("XF86AudioNext",  "exec", "playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`")
bindl("XF86AudioPrev",  "exec", "playerctl previous")

-- Media keybinds
bindl("Super+Shift", "N", "exec", "playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`")
bindl("Super+Shift", "B", "exec", "playerctl previous")
bindl("Super+Shift", "P", "exec", "playerctl play-pause")

-- Mouse buttons for media (AI mousebind also uses these)
for _, btn in ipairs({275, 276}) do
  bind("Super+Shift+Alt", "mouse:" .. btn, "exec",
    btn == 275 and "playerctl previous"
    or "playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`")
end

--! =============================================================================
--! APPS
--! =============================================================================

-- Terminal (looped launch)
bind("Super", "Return", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"ghostty\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\"")
bind("Super", "T", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"ghostty\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\"") -- [hidden]
bind("Ctrl+Alt", "T", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"ghostty\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\"") -- [hidden]

-- Other apps
bind("Super", "E", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"nautilus\" \"dolphin\" \"nemo\" \"thunar\" \"${TERMINAL}\" \"kitty -1 fish -c yazi\"")
bind("Super", "W", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"floorp\" \"zen-browser\" \"microsoft-edge-stable\" \"firefox\" \"brave\" \"opera\" \"librewolf\" \"google-chrome-stable\" \"chromium\"")
bind("Super", "C", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"code\" \"codium\" \"cursor\" \"zed\" \"zedit\" \"zeditor\" \"kate\" \"gnome-text-editor\" \"emacs\" \"command -v nvim && kitty -1 nvim\" \"command -v micro && kitty -1 micro\"")
bind("Ctrl+Super+Shift+Alt", "W", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"wps\" \"onlyoffice-desktopeditors\" \"libreoffice\"")
bind("Super", "X", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"kate\" \"gnome-text-editor\" \"emacs\"")
bind("Ctrl+Super", "V", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"pavucontrol-qt\" \"pavucontrol\"")
bind("Super", "I", "exec", "XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh \"qs -p ~/.config/quickshell/$qsConfig/settings.qml\" \"systemsettings\" \"gnome-control-center\" \"better-control\"")
bind("Ctrl+Shift", "Escape", "exec", "~/.config/hypr/hyprland/scripts/launch_first_available.sh \"gnome-system-monitor\" \"plasma-systemmonitor --page-name Processes\" \"command -v btop && kitty -1 fish -c btop\"")

--! =============================================================================
--! TESTING
--! =============================================================================

bind("Super+Alt", "f11", "exec", "bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | grep -v -i \"nipple\" | grep -v -i \"pussy\" | shuf -n 1); ACTION=$(notify-send \"Test notification with body image\" \"This notification should contain your user account <b>image</b> and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\\\"$RANDOM_IMAGE\\\" alt=\\\"Testing image\\\"/>\" -a \"Hyprland keybind\" -p -h \"string:image-path:/var/lib/AccountsService/icons/$USER\" -t 6000 -i \"discord\" -A \"openImage=Open profile image\" -A \"action2=Open the random image\" -A \"action3=Useless button\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"; [[ $ACTION == *action2 ]] && xdg-open \\\"$RANDOM_IMAGE\\\"'") -- [hidden]
bind("Super+Alt", "f12", "exec", "bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | grep -v -i \"nipple\" | grep -v -i \"pussy\" | shuf -n 1); ACTION=$(notify-send \"Test notification\" \"This notification should contain a random image in your <b>Pictures</b> folder and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>.\\n<i>Flick right to dismiss!</i>\" -a \"Discord (fake)\" -p -h \"string:image-path:$RANDOM_IMAGE\" -t 6000 -i \"discord\" -A \"openImage=Open profile image\" -A \"action2=Useless button\" -A \"action3=Cry more\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"'") -- [hidden]
bind("Super+Alt", "Equal", "exec", "notify-send \"Urgent notification\" \"Ah hell no\" -u critical -a 'Hyprland keybind'") -- [hidden]

--! Custom
bind("Ctrl+Super", "Backslash", "resizeactive", "exact 640 480") -- [hidden] Make window not amogus large
bind("Ctrl+Super", "Slash", "exec", "xdg-open ~/.config/illogical-impulse/config.json")
bind("Ctrl+Super+Alt", "Slash", "exec", "xdg-open ~/.config/hypr/hyprland/keybinds.conf")
