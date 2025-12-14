import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
    property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    implicitWidth: Math.min(titleText.contentWidth, 300)
    implicitHeight: Appearance.sizes.barHeight

    PingPongScrollingText {
        id: titleText
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.width, 300)
        fontPixelSize: Appearance.font.pixelSize.normal
        color: Appearance.colors.colOnLayer1
        text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
            root.activeWindow?.title :
            (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`
    }
}
