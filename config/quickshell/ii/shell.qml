//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma Env QT_QUICK_ANTIALIASING=1

// Performance optimization environment variables
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QSG_ATLAS_SIZE_LIMIT=256
//@ pragma Env QT_ENABLE_GLYPH_CACHE_WORKAROUND=1


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
import Quickshell.Services.UPower
import qs.services

ShellRoot {
    id: root
    readonly property double _startupT0: Date.now()
    function _startupLog(msg) {
        const dt = Math.round(Date.now() - _startupT0)
        console.info(`[Startup +${dt}ms] ${msg}`)
    }

    // Force initialization of some singletons
    Component.onCompleted: {
        _startupLog("ShellRoot Component.onCompleted")
        MaterialThemeLoader.reapplyTheme()
        _startupLog("Theme applied; scheduling deferred startup")
        // Event-driven startup: Wait until Config is ready
        if (Config.ready) {
            Qt.callLater(root.runDeferredStartup)
        }
    }

    QtObject {
        id: startupState
        property bool executed: false
    }

    function runDeferredStartup() {
        if (startupState.executed) return;
        startupState.executed = true;

        root._startupLog("Event-driven deferred startup triggered")
        
        // Critical services - load immediately
        const criticalServices = [
            { name: "Hyprsunset", action: () => Hyprsunset.load() },
            { name: "ConflictKiller", action: () => ConflictKiller.load() },
            { name: "Cliphist", action: () => Cliphist.refresh() },
            { name: "PowerProfileHyprlandSync", action: () => { PowerProfileHyprlandSync; } }
        ]

        // Non-critical services - load after delay
        const deferredServices = [
            { name: "FirstRunExperience", action: () => FirstRunExperience.load() },
            { name: "Wallpapers", action: () => Wallpapers.load() },
            { name: "Updates", action: () => Updates.load() }
        ]

        // Load critical services immediately
        for (const service of criticalServices) {
            try {
                service.action()
            } catch(e) {
                console.error(`${service.name} initialization failed:`, e)
            }
        }
        
        // Load deferred services after 2 seconds
        Qt.callLater(() => {
            Qt.setTimeout(() => {
                for (const service of deferredServices) {
                    try {
                        service.action()
                    } catch(e) {
                        console.error(`${service.name} initialization failed:`, e)
                    }
                }
                root._startupLog("Deferred startup finished")
            }, 2000)
        })
        
        root._startupLog("Critical services loaded; deferred services scheduled")
    }

    // Periodic memory cleanup timer
    Timer {
        id: memoryCleanupTimer
        interval: 60000  // 1 minute
        running: true
        repeat: true
        onTriggered: {
            // Only run GC if no user activity
            if (!GlobalStates.sidebarLeftOpen && !GlobalStates.sidebarRightOpen 
                && !GlobalStates.mediaControlsOpen && !GlobalStates.overlayOpen) {
                gc()
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            root._startupLog(`Config.ready=${Config.ready}`)
            if (Config.ready) {
                Qt.callLater(root.runDeferredStartup)
            }
        }
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

        onActiveChanged: {
            if (!active) {
                // Ensure unused components are freed from JS memory (Improvement D)
                gc();
            }
        }
    }

    // Panel families
    property list<string> families: ["ii", "adhd"]
    property list<string> basePanels: [
        "iiBackground", 
        "iiCheatsheet", 
        "iiDock", 
        "iiLock", 
        "iiMediaControls", 
        "iiNotificationPopup", 
        "iiOnScreenDisplay", 
        "iiOnScreenKeyboard", 
        "iiOverlay", 
        "iiOverview", 
        "iiPolkit", 
        "iiRegionSelector", 
        "iiReloadPopup", 
        "iiScreenCorners", 
        "iiSessionScreen", 
        "iiSidebarLeft", 
        "iiSidebarRight",
        "iiWallpaperSelector"
    ]

    property var panelFamilies: ({
        "ii": ["iiBar", "iiVerticalBar"].concat(Array.from(basePanels)),
        "adhd": ["adhdBar"].concat(Array.from(basePanels))
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
        
        // Explicitly collect garbage after panel switching to free unused QML DOM
        gc()
    }

    function cyclePowerProfile() {
        if (PowerProfiles.hasPerformanceProfile) {
            switch (PowerProfiles.profile) {
            case PowerProfile.PowerSaver:
                PowerProfiles.profile = PowerProfile.Balanced
                break
            case PowerProfile.Balanced:
                PowerProfiles.profile = PowerProfile.Performance
                break
            case PowerProfile.Performance:
                PowerProfiles.profile = PowerProfile.PowerSaver
                break
            default:
                PowerProfiles.profile = PowerProfile.Balanced
                break
            }
        } else {
            PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced
                    ? PowerProfile.PowerSaver
                    : PowerProfile.Balanced
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

    GlobalShortcut {
        name: "powerProfileCycle"
        description: "Cycles power profiles"

        onPressed: root.cyclePowerProfile()
    }
}

