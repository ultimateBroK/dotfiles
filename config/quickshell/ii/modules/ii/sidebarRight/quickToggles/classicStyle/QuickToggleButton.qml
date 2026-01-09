import qs.modules.common
import qs.modules.common.widgets
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    readonly property bool isDarkMode: Appearance?.isDarkMode ?? true
    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    toggled: false
    buttonRadius: (altAction && toggled) ? Appearance?.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    buttonRadiusPressed: Appearance?.rounding?.small

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        iconSize: 22
        fill: toggled ? 1 : 0
        color: toggled ? Appearance.m3colors.m3onPrimary : (isDarkMode ? Appearance.colors.colOnLayer1 : Appearance.m3colors.m3onSurfaceVariant)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: buttonIcon

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    // Light mode: make tiles more opaque for better contrast on white surfaces.
    colBackground: isDarkMode ? colBackground : Appearance.m3colors.m3surfaceContainerHigh
    colBackgroundHover: isDarkMode ? colBackgroundHover : ColorUtils.mix(Appearance.m3colors.m3surfaceContainerHigh, Appearance.m3colors.m3onSurface, 0.92)
    colBackgroundActive: isDarkMode ? colBackgroundActive : ColorUtils.mix(Appearance.m3colors.m3surfaceContainerHigh, Appearance.m3colors.m3onSurface, 0.86)

}
