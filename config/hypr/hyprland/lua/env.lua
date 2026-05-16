-- =============================================================================
-- Environment Variables (hyprland/env.conf → Lua)
-- NOTE: Hyprland 0.55+ required for Lua config
-- =============================================================================

-- ######### Input method ##########
-- See https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
-- Merged from custom/env.conf
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "fcitx")
hl.env("INPUT_METHOD", "fcitx")

-- ############ Wayland / Electron / Chromium #############
-- Ép toàn bộ ứng dụng dính đến Chromium/Electron (Chrome, Edge, Discord, VSCode, Spotify...) chạy native Wayland thay vì qua XWayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("OZONE_PLATFORM", "wayland")
-- Ép buộc sử dụng Graphic/Hardware Acceleration dưới nền Wayland để xả tải cho CPU, đỡ ngốn RAM và tránh xé hình (Tearing)
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("MOZ_WEBRENDER", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- Chromium specific flags (Có thể một số app cần truyền thẳng cờ vào file .desktop, nhưng cắm ở đây sẽ cover được các trường hợp process spawn)
hl.env("CHROME_EXECUTABLE", "wayland")

-- ############ Wine / XWayland #############
-- Giữ font nét cho ứng dụng chạy bằng Wine (XWayland):
-- - FREETYPE_PROPERTIES bật hinting ClearType (v40) để hạn chế blur
-- - WINE_FULLSCREEN_INTEGER_SCALING đảm bảo Wine dùng integer scaling thay vì fractional
-- hl.env("FREETYPE_PROPERTIES", "truetype:interpreter-version=40")
-- hl.env("WINE_FULLSCREEN_INTEGER_SCALING", "1")

-- Performance optimizations for Wine (DXVK/VKD3D)
-- hl.env("DXVK_STATE_CACHE_PATH", "$HOME/.cache/dxvk-state-cache")
-- hl.env("DXVK_LOG_LEVEL", "none")
-- hl.env("VKD3D_SHADER_CACHE_PATH", "$HOME/.cache/vkd3d-shader-cache")

-- Wine stability & interaction on Wayland/XWayland:
-- - WINEDEBUG=-all giảm overhead, tránh lag khi tương tác
-- - Quan trọng: chạy winecfg → Graphics → bỏ chọn "Emulate a virtual desktop"
--   (virtual desktop gây lỗi focus/input trên XWayland)
-- hl.env("WINEDEBUG", "-all")
-- hl.env("WINE_LARGE_ADDRESS_AWARE", "1")
-- hl.env("WINEDLLOVERRIDES", "winemenubuilder.exe=d")

-- XWayland: bật GLAMOR (0 = use glamor) để hardware acceleration
-- hl.env("XWAYLAND_NO_GLAMOR", "0")

-- ############ Themes #############
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")
-- Icon & sound themes (merged from custom/env.conf)
hl.env("GTK_ICON_THEME", "kora")
hl.env("XDG_SOUND_THEME_PATH", "/home/ultimatebrok/.local/share/sounds")

-- ######## Wayland #########
-- Tearing
-- hl.env("WLR_DRM_NO_ATOMIC", "1")
-- ?
-- hl.env("WLR_NO_HARDWARE_CURSORS", "1")

-- ######## Virtual envrionment #########
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "~/.local/state/quickshell/.venv")

-- ######## Terminal application #########
hl.env("TERMINAL", "ghostty")

-- Cursor
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
