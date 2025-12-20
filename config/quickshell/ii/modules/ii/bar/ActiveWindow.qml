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
    readonly property int monitorWorkspaceId: {
        // HyprlandData.monitors is an array; the monitor id isn't guaranteed to be a valid array index.
        // Resolve by name, then fallback to whatever we have.
        const name = monitor?.name ?? "";
        const mons = HyprlandData.monitors || [];
        const found = mons.find(m => String(m?.name || "") === String(name));
        const ws = found?.activeWorkspace?.id ?? monitor?.activeWorkspace?.id ?? HyprlandData.activeWorkspace?.id ?? -1;
        return Number(ws ?? -1);
    }
    property var biggestWindow: (monitorWorkspaceId > 0) ? HyprlandData.biggestWindowForWorkspace(monitorWorkspaceId) : null

    readonly property bool showFocusedWindow: root.focusingThisMonitor && root.activeWindow?.activated
    readonly property string indicatorTitle: showFocusedWindow && root.biggestWindow ?
        (root.activeWindow?.title || "") :
        (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`

    implicitWidth: Math.min(titleText.contentWidth, 250)
    implicitHeight: Appearance.sizes.barHeight

    PingPongScrollingText {
        id: titleText
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.width, 250)
        fontPixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colOnLayer1
        centerStaticText: true
        text: root.indicatorTitle
    }
}
