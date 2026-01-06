import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    // Whether the global bar background should be drawn.
    // Caller typically passes: (Config.options.bar.showBackground || Config.options.bar.autoHide.enable)
    property bool hasBackground: false

    // When true, gradient flows vertically (for vertical bar); otherwise horizontally (topbar)
    property bool vertical: false

    // Background shadow
    Loader {
        active: root.hasBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
        }
    }

    // Background (translucent for wallpaper readability; slightly stronger when autohide is enabled)
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0
        }
        color: root.hasBackground
            ? ColorUtils.transparentize(Appearance.colors.colLayer0, Config.options.bar.autoHide.enable ? 0.2 : 1)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 220 } }
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: 0
        border.color: "transparent"
    }

    // Subtle accent gradient overlay for vibrant schemes
    Rectangle {
        id: barAccentGradient
        anchors.fill: barBackground
        radius: barBackground.radius
        visible: {
            var schemeType = Config?.options?.appearance?.palette?.type ?? "auto";
            return (schemeType === "scheme-vibrant" || schemeType === "scheme-rainbow" || schemeType === "scheme-fruit-salad") && root.hasBackground;
        }
        opacity: 0.35
        gradient: Gradient {
            orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop {
                position: 1.0;
                color: ColorUtils.transparentize(ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.12), 0.5)
            }
        }
        z: -1
    }
}
