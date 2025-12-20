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
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    // Media progress should update faster than the generic resource interval
    readonly property int positionUpdateInterval: Math.max(250, Math.min(Config.options.resources.updateInterval, 1000))
    readonly property real progress: {
        const len = activePlayer?.length ?? 0;
        if (!activePlayer || len <= 0) return 0;
        const p = (activePlayer?.position ?? 0) / len;
        return Math.max(0, Math.min(1, p));
    }

    Layout.fillHeight: true
    Layout.fillWidth: true
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: positionUpdateInterval
        repeat: true
        onTriggered: {
            if (activePlayer) activePlayer.positionChanged()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
                return;
            }
            if (event.button === Qt.RightButton) {
                GlobalStates.mediaControlsOpen = true;
                return;
            }

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

    RowLayout {
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
            visible: !!activePlayer
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.rightMargin: rowLayout.spacing
            color: Appearance.colors.colOnLayer1
            fontPixelSize: Appearance.font.pixelSize.normal
            centerStaticText: true
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }

        StyledText {
            visible: !activePlayer
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.normal
            text: cleanedTitle
        }
    }
}
