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
    property int inhibitUntilEpochMs: 0
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
    readonly property string statusText: {
        if (!inhibit) return Translation.tr("Inactive")
        if (selectedDurationMs <= 0) return Translation.tr("Active")
        return Translation.tr("Active (%1)").arg(selectedPresetLabel)
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
        if (!enabled) inhibitUntilEpochMs = 0
        else if (selectedDurationMs > 0) inhibitUntilEpochMs = Date.now() + selectedDurationMs
        else inhibitUntilEpochMs = 0
        Persistent.states.idle.inhibit = root.inhibit
    }

    function cyclePreset() {
        root.selectedPresetIndex = (root.selectedPresetIndex + 1) % root.inhibitPresets.length
        Persistent.states.idle.presetIndex = root.selectedPresetIndex
        if (root.inhibit) {
            if (root.selectedDurationMs > 0) inhibitUntilEpochMs = Date.now() + root.selectedDurationMs
            else inhibitUntilEpochMs = 0
        }
    }

    function toggleInhibit() {
        setInhibit(!root.inhibit)
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.inhibit
        onTriggered: {
            if (!root.inhibit) return
            if (root.inhibitUntilEpochMs > 0 && Date.now() >= root.inhibitUntilEpochMs) {
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
