import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

LazyLoader {
    id: root

    property Item hoverTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0
    // Tahoe Liquid Glass (dark/light mode aware)
    property real glassTransparency: Appearance.isDarkMode ? 0.55 : 0.45

    active: hoverTarget && hoverTarget.containsMouse

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        // Ensure the popup is placed on the same output as the bar when possible.
        // This also allows us to clamp positioning to the correct screen bounds.
        screen: root.QsWindow?.window?.screen

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        readonly property real _pad: Appearance.sizes.elevationMargin
        readonly property real _screenWidth: popupWindow.screen?.width ?? root.QsWindow?.window?.screen?.width ?? 0
        readonly property real _screenHeight: popupWindow.screen?.height ?? root.QsWindow?.window?.screen?.height ?? 0

        function _clamp(v, lo, hi) {
            if (hi < lo) return lo;
            return Math.max(lo, Math.min(hi, v));
        }

        function _clampX(x) {
            const maxX = Math.max(0, _screenWidth - popupWindow.implicitWidth - _pad);
            return _clamp(x, _pad, maxX);
        }

        function _clampY(y) {
            const maxY = Math.max(0, _screenHeight - popupWindow.implicitHeight - _pad);
            return _clamp(y, _pad, maxY);
        }

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        margins {
            left: {
                if (!Config.options.bar.vertical) {
                    const mapped = root.QsWindow?.mapFromItem(
                        root.hoverTarget,
                        (root.hoverTarget.width - popupBackground.implicitWidth) / 2,
                        0
                    );
                    const x = mapped?.x ?? 0;

                    return popupWindow._clampX(x);
                }
                return Appearance.sizes.verticalBarWidth
            }
            top: {
                // Horizontal bar popups always start after the bar.
                if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;

                // Vertical bar popups are centered on the hover target, but clamped to screen bounds.
                const mapped = root.QsWindow?.mapFromItem(
                    root.hoverTarget,
                    (root.hoverTarget.height - popupBackground.implicitHeight) / 2,
                    0
                );
                const y = mapped?.y ?? 0;

                return popupWindow._clampY(y);
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }
        // Hyprland uses this for layerrule animation direction. Horizontal top bar → slide top
        // (top-down); bottom bar → slide bottom; vertical bar keeps generic namespace.
        WlrLayershell.namespace: Config.options.bar.vertical
            ? "quickshell:popup"
            : (Config.options.bar.bottom ? "quickshell:popupBottom" : "quickshell:popupTop")
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        AmoledGlassRect {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            glassColor: Appearance.isDarkMode ? "#000000" : "#e8e4e4"
            glassTransparency: root.glassTransparency
            radius: Appearance.rounding.large
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.isDarkMode
                ? ColorUtils.applyAlpha("#ffffff", 0.08)
                : ColorUtils.applyAlpha("#ffffff", 0.35)
        }
    }
}
