import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property real padding: 5
    // Tahoe Liquid Glass (dark/light mode aware)
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    StyledRectangularShadow {
        // Keep depth on vertical bar, but flatten topbar look.
        visible: root.vertical
        target: background
    }
    AmoledGlassRect {
        id: background
        // Keep vertical bar richer; keep topbar flatter but still subtly highlighted.
        amoledVariant: root.vertical
        highlightEnabled: true
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 1
            bottomMargin: root.vertical ? 0 : 1
            leftMargin: root.vertical ? 3 : 0
            rightMargin: root.vertical ? 3 : 0
        }
        glassColor: (Config.options?.bar.borderless ?? false)
            ? "transparent"
            : (Appearance.isDarkMode ? "#000000" : "#e8e4e4")
        // Increase transparency on horizontal topbar groups so compositor blur is visible.
        glassTransparency: root.vertical
            ? (Appearance.isDarkMode ? 0.45 : 0.35)
            : (Appearance.isDarkMode ? 0.38 : 0.32)
        highlightOpacity: root.vertical
            ? ((Appearance?.isDarkMode ?? true) ? 0.10 : 0.12)
            : ((Appearance?.isDarkMode ?? true) ? 0.035 : 0.03)
        shadeOpacity: root.vertical
            ? ((Appearance?.isDarkMode ?? true) ? 0.06 : 0.05)
            : ((Appearance?.isDarkMode ?? true) ? 0.03 : 0.02)
        border.width: Config.options?.bar.borderless ? 0 : 1
        border.color: Appearance.isDarkMode
            ? ColorUtils.applyAlpha("#ffffff", 0.10)
            : ColorUtils.applyAlpha("#ffffff", 0.32)
        // Match dock corner curvature.
        radius: Appearance.rounding.large

        Behavior on glassColor {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on glassTransparency {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors {
            verticalCenter: root.vertical ? undefined : parent.verticalCenter
            horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
            left: root.vertical ? undefined : parent.left
            right: root.vertical ? undefined : parent.right
            top: root.vertical ? parent.top : undefined
            bottom: root.vertical ? parent.bottom : undefined
            margins: root.padding
        }
        columnSpacing: 4
        rowSpacing: 12
    }
}