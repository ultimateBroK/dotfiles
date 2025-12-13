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

    // Improve readability on bright wallpapers when the bar has no global background.
    // Keep title/subtitle as two distinct tones in both modes.
    readonly property bool brightWallpaper: Appearance.wallpaperLightness >= 0.60

    // On bright wallpapers: use dark text (high contrast) with a light outline.
    // On non-bright wallpapers: keep existing theme colors with a dark outline.
    readonly property color titleColor: brightWallpaper ? Appearance.m3colors.m3shadow : Appearance.colors.colOnLayer0
    readonly property color subtitleColor: brightWallpaper
        ? ColorUtils.transparentize(Appearance.m3colors.m3shadow, 0.35)
        : Appearance.colors.colSubtext

    readonly property color outlineColor: brightWallpaper
        ? ColorUtils.transparentize(
              (Appearance.isDarkMode ? Appearance.m3colors.m3onBackground : Appearance.m3colors.m3inverseOnSurface),
              0.25
          )
        : ColorUtils.transparentize(Appearance.m3colors.m3shadow, 0.15)

    implicitWidth: colLayout.implicitWidth

    ColumnLayout {
        id: colLayout

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: -4

        StyledText {
            Layout.preferredWidth: 300
            Layout.alignment: Qt.AlignLeft
            font.pixelSize: Appearance.font.pixelSize.normal
            color: root.subtitleColor
            outlineEnabled: true
            outlineColor: root.outlineColor
            elide: Text.ElideRight
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                root.activeWindow?.appId :
                (root.biggestWindow?.class) ?? Translation.tr("Desktop")

        }

        PingPongScrollingText {
            Layout.preferredWidth: 300
            Layout.alignment: Qt.AlignLeft
            fontPixelSize: Appearance.font.pixelSize.normal
            color: root.titleColor
            outlineEnabled: true
            outlineColor: root.outlineColor
            text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? 
                root.activeWindow?.title :
                (root.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${monitor?.activeWorkspace?.id ?? 1}`
        }

    }

}
