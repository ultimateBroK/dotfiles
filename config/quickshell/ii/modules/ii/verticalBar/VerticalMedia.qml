import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    // Keep media progress updates snappy and closer to real playback
    readonly property int positionUpdateInterval: Math.max(250, Math.min(Config.options.resources.updateInterval, 1000))
    readonly property real progress: {
        const len = activePlayer?.length ?? 0;
        if (!activePlayer || len <= 0) return 0;
        const p = (activePlayer?.position ?? 0) / len;
        return Math.max(0, Math.min(1, p));
    }

    Layout.fillHeight: true
    implicitHeight: mediaCircProg.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: positionUpdateInterval
        repeat: true
        onTriggered: {
            if (activePlayer) activePlayer.positionChanged()
        }
    }

    acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
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

    ClippedFilledCircularProgress {
        id: mediaCircProg
        anchors.centerIn: parent
        implicitSize: 20

        lineWidth: Appearance.rounding.unsharpen
        value: root.progress
        colPrimary: Appearance.colors.colOnSecondaryContainer
        enableAnimation: false

        Item {
            anchors.centerIn: parent
            width: mediaCircProg.implicitSize
            height: mediaCircProg.implicitSize
            
            MaterialSymbol {
                anchors.centerIn: parent
                fill: 1
                text: activePlayer ? (activePlayer.isPlaying ? "pause" : "play_arrow") : "music_note"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3onSecondaryContainer
            }
        }
    }

    Bar.StyledPopup {
        hoverTarget: root
        active: GlobalStates.mediaControlsOpen ? false : root.containsMouse

        Column {
            anchors.centerIn: parent
            spacing: 4

            Bar.StyledPopupHeaderRow {
                icon: "music_note"
                label: Translation.tr("Media")
            }

            StyledText {
                color: Appearance.colors.colOnSurfaceVariant
                text: `${cleanedTitle}${activePlayer?.trackArtist ? '\n' + activePlayer.trackArtist : ''}`
            }
        }
    }

}
