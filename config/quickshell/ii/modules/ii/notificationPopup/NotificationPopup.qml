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
            item: listview
        }

        color: "transparent"
        implicitWidth: Appearance.sizes.notificationPopupWidth

        NotificationListView {
            id: listview
            anchors {
                top: Config.options.notifications.position.startsWith("top") ? parent.top : undefined
                bottom: Config.options.notifications.position.startsWith("bottom") ? parent.bottom : undefined
                right: Config.options.notifications.position.endsWith("right") ? parent.right : undefined
                left: Config.options.notifications.position.endsWith("left") ? parent.left : undefined
                rightMargin: Config.options.notifications.position.endsWith("right") ? 10 : 0
                leftMargin: Config.options.notifications.position.endsWith("left") ? 10 : 0
                topMargin: Config.options.notifications.position.startsWith("top") ? 10 : 0
                bottomMargin: Config.options.notifications.position.startsWith("bottom") ? 10 : 0
            }
            height: Math.min(contentHeight + 10, parent.height - 20)
            verticalLayoutDirection: Config.options.notifications.position.startsWith("bottom") ? ListView.BottomToTop : ListView.TopToBottom
            implicitWidth: parent.width - Appearance.sizes.elevationMargin * 2
            popup: true
            bottomAlign: Config.options.notifications.position.startsWith("bottom")
        }
    }
}