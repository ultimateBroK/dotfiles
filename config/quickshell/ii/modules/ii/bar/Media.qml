import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    // Media progress should update faster than the generic resource interval
    readonly property int positionUpdateInterval: Math.max(250, Math.min(Config.options.resources.updateInterval, 1000))
    // Last-known position + timestamp (ms) to allow smooth estimation while playing
    property real lastKnownPosition: activePlayer?.position ?? 0
    property int lastPositionTimestamp: Date.now()

    Connections {
        target: activePlayer
        function onPositionChanged() {
            root.lastKnownPosition = activePlayer.position ?? root.lastKnownPosition;
            root.lastPositionTimestamp = Date.now();
        }
        function onPlaybackStateChanged() {
            root.lastKnownPosition = activePlayer?.position ?? root.lastKnownPosition;
            root.lastPositionTimestamp = Date.now();
        }
    }

    readonly property real progress: MprisUtils.smoothProgress(activePlayer, root.lastKnownPosition, root.lastPositionTimestamp)

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: positionUpdateInterval
        repeat: true
        onTriggered: {
            // Quickshell's MPRIS position can be "lazy"; poke bindings while playing.
            if (activePlayer) activePlayer.positionChanged()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            // Left click toggles the popup. Right click always opens it.
            if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
                return;
            }
            if (event.button === Qt.RightButton) {
                GlobalStates.mediaControlsOpen = true;
                return;
            }

            // No active player -> ignore media control buttons (avoid QML errors).
            if (!activePlayer) return;

            if (event.button === Qt.MiddleButton) {
                MprisController.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                MprisController.previous();
            } else if (event.button === Qt.ForwardButton) {
                MprisController.next();
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        ClippedFilledCircularProgress {
            id: mediaCircProg
            visible: !!activePlayer
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: root.progress
            implicitSize: 20
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "play_arrow"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        PingPongScrollingText {
            visible: Config.options.bar.verbose && !!activePlayer
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: rowLayout.spacing
            color: Appearance.colors.colOnLayer1
            fontPixelSize: Appearance.font.pixelSize.normal
            // Center text when it fits; PingPongScrollingText will automatically
            // switch to scrolling when the text overflows its width.
            centerStaticText: true
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }

        StyledText {
            visible: Config.options.bar.verbose && !activePlayer
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.normal
            text: cleanedTitle
        }

    }

}
