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

    readonly property string indicatorIconId: {
        if (showFocusedWindow) {
            return root.activeWindow?.appId ?? "";
        }
        // hyprctl client objects usually expose `class` for icon lookup
        const cls = root.biggestWindow?.class ?? root.biggestWindow?.initialClass ?? root.biggestWindow?.appId ?? "";
        return AppSearch.guessIcon(cls) ?? cls;
    }
    readonly property string indicatorIconPath: Quickshell.iconPath(indicatorIconId, "image-missing")

    implicitWidth: Math.min(rowLayout.implicitWidth, 320)
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 8

        Image {
            id: appIcon
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: root.indicatorIconPath
            sourceSize.width: 18
            sourceSize.height: 18
            asynchronous: true
            cache: true
            smooth: true
            visible: root.indicatorIconId.length > 0
        }

        PingPongScrollingText {
            id: titleText
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            width: Math.min(parent.width, 300)
            fontPixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
            centerStaticText: true
            text: root.indicatorTitle
        }
    }
}
