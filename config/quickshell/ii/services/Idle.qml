import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland
pragma Singleton

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    property int selectedPresetIndex: 0
    // Use real (double) to safely store epoch milliseconds.
    property real inhibitUntilEpochMs: 0
    property int countdownRemainingMs: 0
    readonly property var inhibitPresets: [
        { "label": Translation.tr("Current"), "durationMs": 0 },
        { "label": Translation.tr("15 minutes"), "durationMs": 15 * 60 * 1000 },
        { "label": Translation.tr("30 minutes"), "durationMs": 30 * 60 * 1000 },
        { "label": Translation.tr("1 hour"), "durationMs": 60 * 60 * 1000 },
        { "label": Translation.tr("2 hours"), "durationMs": 2 * 60 * 60 * 1000 },
        { "label": Translation.tr("4 hours"), "durationMs": 4 * 60 * 60 * 1000 }
    ]
    readonly property string selectedPresetLabel: inhibitPresets[selectedPresetIndex].label
    readonly property int selectedDurationMs: inhibitPresets[selectedPresetIndex].durationMs
    readonly property string countdownText: formatDuration(countdownRemainingMs)
    readonly property string activeLabel: selectedDurationMs <= 0 ? selectedPresetLabel : Translation.tr("%1 left").arg(countdownText)
    readonly property string statusText: {
        if (!inhibit) return Translation.tr("Inactive")
        if (selectedDurationMs <= 0) return Translation.tr("Active")
        return Translation.tr("Active (%1)").arg(countdownText)
    }
    inhibit: false

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance) {
                const persistedPresetIndex = Persistent.states.idle.presetIndex
                root.selectedPresetIndex = Math.min(
                    Math.max(persistedPresetIndex !== undefined ? persistedPresetIndex : 0, 0),
                    root.inhibitPresets.length - 1
                )
                root.setInhibit(Persistent.states.idle.inhibit)
            } else {
                Persistent.states.idle.inhibit = root.inhibit
                Persistent.states.idle.presetIndex = root.selectedPresetIndex
            }
        }
    }

    function setInhibit(enabled) {
        root.inhibit = enabled
        if (!enabled) {
            inhibitUntilEpochMs = 0
            countdownRemainingMs = 0
        } else if (selectedDurationMs > 0) {
            inhibitUntilEpochMs = Date.now() + selectedDurationMs
            countdownRemainingMs = selectedDurationMs
        } else {
            inhibitUntilEpochMs = 0
            countdownRemainingMs = 0
        }
        Persistent.states.idle.inhibit = root.inhibit
    }

    function cyclePreset() {
        root.selectedPresetIndex = (root.selectedPresetIndex + 1) % root.inhibitPresets.length
        Persistent.states.idle.presetIndex = root.selectedPresetIndex
        if (root.inhibit) {
            if (root.selectedDurationMs > 0) {
                inhibitUntilEpochMs = Date.now() + root.selectedDurationMs
                countdownRemainingMs = root.selectedDurationMs
            } else {
                inhibitUntilEpochMs = 0
                countdownRemainingMs = 0
            }
        }
    }

    function toggleInhibit() {
        setInhibit(!root.inhibit)
    }

    function formatDuration(ms) {
        const totalSeconds = Math.max(0, Math.floor(ms / 1000))
        const hours = Math.floor(totalSeconds / 3600)
        const minutes = Math.floor((totalSeconds % 3600) / 60)
        const seconds = totalSeconds % 60

        if (hours > 0)
            return `${hours}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
        return `${minutes}:${String(seconds).padStart(2, "0")}`
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.inhibit
        onTriggered: {
            if (!root.inhibit) return
            if (root.inhibitUntilEpochMs > 0) {
                const remainingMs = Math.max(0, Math.floor(root.inhibitUntilEpochMs - Date.now()))
                root.countdownRemainingMs = remainingMs
            }
            if (root.inhibitUntilEpochMs > 0 && root.countdownRemainingMs <= 0) {
                root.setInhibit(false)
            }
        }
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow { // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }    

}
