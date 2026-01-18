import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: notificationPopup

    PanelWindow {
        id: root
        visible: (Notifications.popupList.length > 0) && !GlobalStates.screenLocked
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.namespace: "quickshell:notificationPopup"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0

        property bool isTopPosition: Config.options.notifications.position.startsWith("top")
        property bool isRightPosition: Config.options.notifications.position.endsWith("right")

        anchors {
            top: isTopPosition
            bottom: !isTopPosition
            left: !isRightPosition
            right: isRightPosition
        }

        mask: Region {
            item: listview.contentItem
        }

        color: "transparent"
        implicitWidth: Appearance.sizes.notificationPopupWidth

        NotificationListView {
            id: listview
            anchors {
                top: root.isTopPosition ? parent.top : undefined
                bottom: !root.isTopPosition ? parent.bottom : undefined
                left: !root.isRightPosition ? parent.left : undefined
                right: root.isRightPosition ? parent.right : undefined
                leftMargin: !root.isRightPosition ? 4 : 0
                rightMargin: root.isRightPosition ? 4 : 0
                topMargin: root.isTopPosition ? 4 : 0
                bottomMargin: !root.isTopPosition ? 4 : 0
            }
            implicitWidth: parent.width - Appearance.sizes.elevationMargin * 2
            popup: true
        }
    }
}
