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

    // Track current profile to detect changes
    property int lastProfile: -1
    property bool initialized: false

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                // Re-apply current profile after Hypr reload to avoid falling back
                const currentProfile = PowerProfiles.profile
                root.lastProfile = currentProfile
                root.syncHyprlandConfig(currentProfile, /*silent=*/true)
            }
        }
    }

    /**
     * Apply Hyprland config for a given power profile.
     *
     * This is a direct in-QML port of the previous
     * `switch_performance_profile.sh` script, without
     * modifying the actual system power profile
     * (that part is handled by PowerProfiles).
     */
    function applyHyprConfig(profile) {
        let commands = []

        switch (profile) {
        case PowerProfile.Performance:
            // Performance: Maximum performance for intensive tasks
            commands = [
                'hyprctl keyword "animations:enabled" "false"',
                'hyprctl keyword "decoration:blur:enabled" "false"',
                'hyprctl keyword "decoration:drop_shadow" "false"',
                'hyprctl keyword "misc:vfr" "1"',
                'hyprctl keyword "misc:vrr" "2"',
                'hyprctl keyword "misc:animate_manual_resizes" "false"',
                'hyprctl keyword "misc:animate_mouse_windowdragging" "false"',
                'hyprctl keyword "render:damage_tracking" "monitor"'
            ]
            break

        case PowerProfile.Balanced:
            // Balanced: use Hyprland's config defaults, don't override keywords.
            // Reloading config resets any runtime tweaks from Performance / PowerSaver.
            commands = [
                "hyprctl reload"
            ]
            break

        case PowerProfile.PowerSaver:
            // Power saver: Power saving mode, minimal visual effects
            commands = [
                'hyprctl keyword "animations:enabled" "false"',
                'hyprctl keyword "decoration:blur:enabled" "false"',
                'hyprctl keyword "decoration:drop_shadow" "false"',
                'hyprctl keyword "misc:vfr" "0"',
                'hyprctl keyword "misc:vrr" "0"',
                'hyprctl keyword "misc:animate_manual_resizes" "false"',
                'hyprctl keyword "misc:animate_mouse_windowdragging" "false"',
                'hyprctl keyword "render:damage_tracking" "monitor"'
            ]
            break

        default:
            // Fallback: also just reload to restore config defaults
            commands = [
                "hyprctl reload"
            ]
            break
        }

        // Run all hyprctl commands in a single detached shell
        const script = commands.join(" && ")
        Quickshell.execDetached(["bash", "-lc", script])
    }

    function profileLabel(profile) {
        switch (profile) {
        case PowerProfile.Performance: return "Performance"
        case PowerProfile.Balanced: return "Balanced"
        case PowerProfile.PowerSaver: return "Power Saver"
        default: return "Balanced"
        }
    }

    function notifyProfile(profile) {
        const label = profileLabel(profile)
        Quickshell.execDetached([
            "notify-send",
            "Power Profile",
            `Switched to ${label}`,
            "-a", "Hyprland",
            "-t", "2000"
        ])
    }

    // Apply Hyprland config when power profile changes
    function syncHyprlandConfig(profile, silent = false) {
        root.applyHyprConfig(profile)
        if (root.initialized && !silent) {
            root.notifyProfile(profile)
        }
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
        root.initialized = true
    }
}
