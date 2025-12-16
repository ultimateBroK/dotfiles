//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the shell smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1


import qs.modules.common
import qs.modules.ii.background
import qs.modules.ii.bar
import qs.modules.ii.cheatsheet
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector
import qs.modules.adhd.bar

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

ShellRoot {
    id: root

    // Force initialization of some singletons
    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
        // Ensure PowerProfileHyprlandSync is initialized
        PowerProfileHyprlandSync
    }

    // Load enabled stuff
    // Well, these loaders only *allow* them to be loaded, to always load or not is defined in each component
    // The media controls for example is not loaded if it's not opened
    PanelLoader { identifier: "iiBar"; extraCondition: !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { identifier: "iiBackground"; component: Background {} }
    PanelLoader { identifier: "iiCheatsheet"; component: Cheatsheet {} }
    PanelLoader { identifier: "iiDock"; extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { identifier: "iiLock"; component: Lock {} }
    PanelLoader { identifier: "iiMediaControls"; component: MediaControls {} }
    PanelLoader { identifier: "iiNotificationPopup"; component: NotificationPopup {} }
    PanelLoader { identifier: "iiOnScreenDisplay"; component: OnScreenDisplay {} }
    PanelLoader { identifier: "iiOnScreenKeyboard"; component: OnScreenKeyboard {} }
    PanelLoader { identifier: "iiOverlay"; component: Overlay {} }
    PanelLoader { identifier: "iiOverview"; component: Overview {} }
    PanelLoader { identifier: "iiPolkit"; component: Polkit {} }
    PanelLoader { identifier: "iiRegionSelector"; component: RegionSelector {} }
    PanelLoader { identifier: "iiReloadPopup"; component: ReloadPopup {} }
    PanelLoader { identifier: "iiScreenCorners"; component: ScreenCorners {} }
    PanelLoader { identifier: "iiSessionScreen"; component: SessionScreen {} }
    PanelLoader { identifier: "iiSidebarLeft"; component: SidebarLeft {} }
    PanelLoader { identifier: "iiSidebarRight"; component: SidebarRight {} }
    PanelLoader { identifier: "iiVerticalBar"; extraCondition: Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { identifier: "iiWallpaperSelector"; component: WallpaperSelector {} }
    PanelLoader { identifier: "adhdBar"; extraCondition: !Config.options.bar.vertical && Config.options.adhd.enable; component: AdhdBar {} }

    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.enabledPanels.includes(identifier) && extraCondition
    }

    // Panel families
    property list<string> families: ["ii", "adhd"]
    property var panelFamilies: ({
        "ii": ["iiBar", "iiBackground", "iiCheatsheet", "iiDock", "iiLock", "iiMediaControls", "iiNotificationPopup", "iiOnScreenDisplay", "iiOnScreenKeyboard", "iiOverlay", "iiOverview", "iiPolkit", "iiRegionSelector", "iiReloadPopup", "iiScreenCorners", "iiSessionScreen", "iiSidebarLeft", "iiSidebarRight", "iiVerticalBar", "iiWallpaperSelector"],
        "adhd": ["adhdBar", "iiBackground", "iiCheatsheet", "iiDock", "iiLock", "iiMediaControls", "iiNotificationPopup", "iiOnScreenDisplay", "iiOnScreenKeyboard", "iiOverlay", "iiOverview", "iiPolkit", "iiRegionSelector", "iiReloadPopup", "iiScreenCorners", "iiSessionScreen", "iiSidebarLeft", "iiSidebarRight", "iiWallpaperSelector"],
    })
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        const nextFamily = families[nextIndex]
        Config.options.panelFamily = nextFamily
        Config.options.enabledPanels = panelFamilies[nextFamily]
        
        // Auto-enable/disable adhd when switching families
        if (nextFamily === "adhd") {
            Config.options.adhd.enable = true
        } else if (nextFamily === "ii") {
            Config.options.adhd.enable = false
        }
    }

    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }

    GlobalShortcut {
        name: "dockToggle"
        description: "Toggles the dock on/off"

        onPressed: {
            Config.options.dock.enable = !Config.options.dock.enable;
        }
    }

    GlobalShortcut {
        name: "dockTogglePin"
        description: "Pins/unpins the dock (persistent)"

        onPressed: {
            Config.options.dock.pinnedOnStartup = !Config.options.dock.pinnedOnStartup;
        }
    }

    GlobalShortcut {
        name: "barAutoHideToggle"
        description: "Toggles auto-hide for the bar"

        onPressed: {
            Config.options.bar.autoHide.enable = !Config.options.bar.autoHide.enable;
        }
    }
}

