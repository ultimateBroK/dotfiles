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

        anchors {
            top: true
            bottom: true
            right: Config.options.notifications.position.endsWith("right")
            left: Config.options.notifications.position.endsWith("left")
        }

        mask: Region {
            item: listview.contentItem
        }

        color: "transparent"
        implicitWidth: Appearance.sizes.notificationPopupWidth

        NotificationListView {
            id: listview
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: Config.options.notifications.position.endsWith("right") ? parent.right : undefined
                left: Config.options.notifications.position.endsWith("left") ? parent.left : undefined
                rightMargin: Config.options.notifications.position.endsWith("right") ? 4 : 0
                leftMargin: Config.options.notifications.position.endsWith("left") ? 4 : 0
                topMargin: Config.options.notifications.position.startsWith("top") ? 4 : 0
                bottomMargin: Config.options.notifications.position.startsWith("bottom") ? 4 : 0
            }
            verticalLayoutDirection: Config.options.notifications.position.startsWith("bottom") ? ListView.BottomToTop : ListView.TopToBottom
            implicitWidth: parent.width - Appearance.sizes.elevationMargin * 2
            popup: true
        }
    }
}