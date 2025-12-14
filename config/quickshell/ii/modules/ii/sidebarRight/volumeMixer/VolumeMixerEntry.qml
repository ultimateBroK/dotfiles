import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root
    required property PwNode node
    PwObjectTracker {
        objects: [node]
    }

    implicitHeight: mainLayout.implicitHeight + 12
    
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainerLow
        
        ColumnLayout {
            id: mainLayout
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Image {
                    property real size: 36
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    visible: source != ""
                    sourceSize.width: size
                    sourceSize.height: size
                    source: {
                        let icon;
                        icon = AppSearch.guessIcon(root.node?.properties["application.icon-name"] ?? "");
                        if (AppSearch.iconExists(icon))
                            return Quickshell.iconPath(icon, "image-missing");
                        icon = AppSearch.guessIcon(root.node?.properties["node.name"] ?? "");
                        return Quickshell.iconPath(icon, "image-missing");
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurface
                        elide: Text.ElideRight
                        text: {
                            // application.name -> description -> name
                            const app = root.node?.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
                            const media = root.node.properties["media.name"];
                            return media != undefined ? `${app} • ${media}` : app;
                        }
                    }
                    
                    StyledText {
                        text: `${Math.round((root.node?.audio.volume ?? 0) * 100)}%`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
                
                // Mute button
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: (root.node?.audio.muted ?? false) ? Appearance.colors.colErrorContainer : Appearance.colors.colSurfaceContainerHigh
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: (root.node?.audio.muted ?? false) ? "volume_off" : "volume_up"
                        iconSize: 18
                        color: (root.node?.audio.muted ?? false) ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnSurfaceVariant
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.node?.audio) {
                                root.node.audio.muted = !root.node.audio.muted;
                            }
                        }
                    }
                }
            }
            
            StyledSlider {
                id: slider
                Layout.fillWidth: true
                value: root.node?.audio.volume ?? 0
                onMoved: root.node.audio.volume = value
                configuration: StyledSlider.Configuration.S
            }
        }
    }
}
