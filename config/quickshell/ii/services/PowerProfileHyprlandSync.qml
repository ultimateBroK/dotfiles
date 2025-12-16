pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.UPower
import QtQuick

/**
 * Service to automatically sync Hyprland config when power profile changes
 * Simple and reliable: monitors PowerProfiles.profile property via Timer
 */
Singleton {
    id: root

    readonly property string hyprScript: `${Quickshell.env("HOME")}/.config/hypr/hyprland/scripts/switch_performance_profile.sh`
    
    // Track current profile to detect changes
    property int lastProfile: -1

    // Map PowerProfile enum to script profile name
    function getHyprProfile(powerProfile) {
        switch(powerProfile) {
            case PowerProfile.Performance: return "performance"
            case PowerProfile.Balanced: return "balanced"
            case PowerProfile.PowerSaver: return "power-saver"
            default: return "balanced"
        }
    }

    // Apply Hyprland config when power profile changes
    function syncHyprlandConfig(profile) {
        const hyprProfile = root.getHyprProfile(profile)
        Quickshell.execDetached([
            "bash", "-c",
            `SKIP_POWER_PROFILE=1 "${root.hyprScript}" "${hyprProfile}"`
        ])
    }

    // Simple polling approach - check every 0.5 seconds
    // This is lightweight and reliable
    Timer {
        id: monitorTimer
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            const currentProfile = PowerProfiles.profile
            if (currentProfile !== root.lastProfile) {
                root.syncHyprlandConfig(currentProfile)
                root.lastProfile = currentProfile
            }
        }
    }

    // Initialize on startup
    Component.onCompleted: {
        const initialProfile = PowerProfiles.profile
        root.lastProfile = initialProfile
        root.syncHyprlandConfig(initialProfile)
    }
}
