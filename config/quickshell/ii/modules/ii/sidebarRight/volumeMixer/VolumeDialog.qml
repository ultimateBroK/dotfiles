pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

WindowDialog {
    id: root
    property bool isSink: true
    backgroundHeight: 600
    
    // Safe property accessors with null checks
    property real currentVolume: {
        if (root.isSink) {
            return Audio.sink?.audio?.volume ?? 0;
        } else {
            return Audio.source?.audio?.volume ?? 0;
        }
    }
    property bool isMuted: {
        if (root.isSink) {
            return Audio.sink?.audio?.muted ?? false;
        } else {
            return Audio.source?.audio?.muted ?? false;
        }
    }
    property bool audioAvailable: root.isSink ? (Audio.sink !== null) : (Audio.source !== null)
    property string currentDeviceName: {
        if (root.isSink) {
            return Audio.sink?.description ?? Translation.tr("Unknown Device");
        } else {
            return Audio.source?.description ?? Translation.tr("Unknown Device");
        }
    }

    WindowDialogTitle {
        text: root.isSink ? Translation.tr("Sound") : Translation.tr("Microphone")
    }
    
    // Current volume status - only show when audio device is available
    Rectangle {
        visible: root.audioAvailable
        Layout.fillWidth: true
        Layout.preferredHeight: volumeStatusLayout.implicitHeight + 20
        Layout.topMargin: -10
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainer
        
        ColumnLayout {
            id: volumeStatusLayout
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 12
            
            // Header with volume icon and info
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                MaterialSymbol {
                    Layout.alignment: Qt.AlignTop
                    text: {
                        if (root.isSink) {
                            if (root.isMuted) return "volume_off";
                            if (root.currentVolume > 0.66) return "volume_up";
                            if (root.currentVolume > 0.33) return "volume_down";
                            return "volume_mute";
                        } else {
                            if (root.isMuted) return "mic_off";
                            return "mic";
                        }
                    }
                    iconSize: 40
                    color: root.isMuted ? Appearance.colors.colError : Appearance.colors.colPrimary
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        StyledText {
                            text: `${Math.round(root.currentVolume * 100)}%`
                            font {
                                pixelSize: Appearance.font.pixelSize.large
                                weight: Font.Bold
                            }
                            color: Appearance.colors.colOnSurface
                        }
                        
                        StyledText {
                            text: root.isSink ? Translation.tr("Output") : Translation.tr("Input")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: root.currentDeviceName
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
                
                // Mute button
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: root.isMuted ? Appearance.colors.colErrorContainer : Appearance.colors.colSurfaceContainerHigh
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: {
                            if (root.isSink) {
                                return root.isMuted ? "volume_off" : "volume_up";
                            } else {
                                return root.isMuted ? "mic_off" : "mic";
                            }
                        }
                        iconSize: 20
                        color: root.isMuted ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSurface
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isSink && Audio.sink?.audio) {
                                Audio.sink.audio.muted = !Audio.sink.audio.muted;
                            } else if (!root.isSink && Audio.source?.audio) {
                                Audio.source.audio.muted = !Audio.source.audio.muted;
                            }
                        }
                    }
                }
            }
            
            // Volume slider
            StyledSlider {
                id: mainVolumeSlider
                Layout.fillWidth: true
                Layout.topMargin: -4
                value: root.currentVolume
                onMoved: {
                    if (root.isSink && Audio.sink?.audio) {
                        Audio.sink.audio.volume = value;
                    } else if (!root.isSink && Audio.source?.audio) {
                        Audio.source.audio.volume = value;
                    }
                }
                configuration: StyledSlider.Configuration.M
            }
        }
    }
    
    // No audio device warning
    Rectangle {
        visible: !root.audioAvailable
        Layout.fillWidth: true
        Layout.preferredHeight: noAudioLayout.implicitHeight + 16
        Layout.topMargin: -10
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        radius: Appearance.rounding.small
        color: Appearance.colors.colErrorContainer
        
        RowLayout {
            id: noAudioLayout
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 10
            
            MaterialSymbol {
                text: root.isSink ? "volume_off" : "mic_off"
                iconSize: 28
                color: Appearance.colors.colOnErrorContainer
            }
            
            StyledText {
                Layout.fillWidth: true
                text: root.isSink ? Translation.tr("No audio output device") : Translation.tr("No audio input device")
                font {
                    pixelSize: Appearance.font.pixelSize.small
                    weight: Font.Medium
                }
                color: Appearance.colors.colOnErrorContainer
            }
        }
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    VolumeDialogContent {
        isSink: root.isSink
    }

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.volumeMixer}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
