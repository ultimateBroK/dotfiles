import QtQuick
import qs.modules.common.widgets
import qs.modules.common
import qs.services

MaterialSymbol {
    id: root

    // Default styling matches other indicator icons.
    property real iconPixelSize: Appearance.font.pixelSize.larger

    // Allow caller to override color (e.g. toggled sidebar button)
    // If left unset, fall back to bar's default text color.
    property color iconColor: Appearance.colors.colOnLayer1

    // Thresholds for different icons
    property real offThreshold: 0.001
    property real muteThreshold: 0.40
    property real downThreshold: 0.70

    readonly property real volumeValue: (Audio?.value ?? Audio.sink?.audio?.volume ?? 0)
    readonly property bool muted: Audio.sink?.audio?.muted ?? false

    fill: 0
    iconSize: root.iconPixelSize
    color: root.iconColor

    text: {
        if (muted || volumeValue <= offThreshold)
            return "volume_off";
        if (volumeValue <= muteThreshold)
            return "volume_mute";
        if (volumeValue <= downThreshold)
            return "volume_down";
        return "volume_up";
    }
}
