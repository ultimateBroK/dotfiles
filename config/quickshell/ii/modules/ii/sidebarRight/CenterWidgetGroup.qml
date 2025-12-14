import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.notifications
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            MaterialSymbol {
                text: "notifications"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colPrimary
            }
            
            StyledText {
                text: Translation.tr("Notifications")
                font {
                    pixelSize: Appearance.font.pixelSize.small
                    weight: Font.Medium
                }
                color: Appearance.colors.colOnSurfaceVariant
            }
            
            Item { Layout.fillWidth: true }
            
            Rectangle {
                visible: Notifications.list.length > 0
                Layout.preferredWidth: 24
                Layout.preferredHeight: 20
                radius: 10
                color: Appearance.colors.colPrimary
                
                StyledText {
                    anchors.centerIn: parent
                    text: Notifications.list.length.toString()
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Bold
                    }
                    color: Appearance.colors.colOnPrimary
                }
            }
        }

        NotificationList {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
