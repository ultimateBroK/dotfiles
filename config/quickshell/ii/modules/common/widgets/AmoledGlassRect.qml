import QtQuick
import qs.modules.common
import qs.modules.common.functions

/**
 * Tahoe Liquid Glass surface:
 * - Semi-transparent tint (lets compositor blur show through)
 * - Specular highlight + bottom shade for glass depth
 * - Prismatic edge highlights (subtle chromatic refraction at borders)
 * - Inner glow for Tahoe liquid glass luminosity
 * - Top and bottom edge rim lights for glass edge catching
 *
 * Note: Actual background blur is provided by compositor (e.g. Hyprland blur rules)
 * when the window is translucent.
 *
 * Use amoledVariant: true for sidebar/panel/dock surfaces with enhanced Tahoe glass effect.
 */
Rectangle {
    id: root

    // Transparency amount for ColorUtils.transparentize() (0 = opaque, 1 = fully transparent).
    property real glassTransparency: 0.55

    // Base tint color (override per-surface if needed).
    property color glassColor: "#000000"

    // Whether to draw the "specular" highlight overlays.
    property bool highlightEnabled: true

    // Enable enhanced Tahoe Liquid Glass variant (sidebar/panel/dock) - stronger highlights, edge rim, prismatic.
    property bool amoledVariant: false

    // Control highlight strength (Tahoe: enhanced specular for amoledVariant).
    property real highlightOpacity: (Appearance?.isDarkMode ?? true)
        ? (root.amoledVariant ? 0.10 : 0.10)
        : (root.amoledVariant ? 0.12 : 0.06)
    property real shadeOpacity: (Appearance?.isDarkMode ?? true)
        ? (root.amoledVariant ? 0.06 : 0.08)
        : (root.amoledVariant ? 0.05 : 0.04)

    // Prismatic/chromatic edge intensity (Tahoe refraction effect)
    property real prismaticIntensity: (Appearance?.isDarkMode ?? true)
        ? (root.amoledVariant ? 0.06 : 0.03)
        : (root.amoledVariant ? 0.08 : 0.04)

    // When blur is disabled globally or for shell surfaces, use solid background (reduces compositor/GPU blur load).
    color: ((Config?.options?.blur?.globalEnable !== false) && (Config?.options?.appearance?.blurInShell?.enable !== false))
        ? ColorUtils.transparentize(root.glassColor, root.glassTransparency)
        : root.glassColor

    border.width: 1
    border.color: (Appearance?.isDarkMode ?? true)
        ? ColorUtils.applyAlpha("#ffffff", root.amoledVariant ? 0.12 : 0.08)
        : ColorUtils.applyAlpha("#ffffff", root.amoledVariant ? 0.45 : 0.35)

    // Top "specular" sheen - Tahoe multi-stop gradient with enhanced luminosity
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.highlightEnabled
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.highlightOpacity) }
            GradientStop { position: 0.08; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.85) }
            GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.55) }
            GradientStop { position: 0.40; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.18) }
            GradientStop { position: 0.65; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.04) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    // Subtle top-edge rim (light catching on glass edge) - Tahoe amoled variant
    Rectangle {
        visible: root.highlightEnabled && root.amoledVariant
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1.5
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.15; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.6) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.4) }
            GradientStop { position: 0.85; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.6) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    // Bottom-edge rim light (light refracting through bottom glass edge) - Tahoe amoled variant
    Rectangle {
        visible: root.highlightEnabled && root.amoledVariant
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.25) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.15) }
            GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.25) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    // Prismatic/chromatic left edge highlight (Tahoe refraction - light splits at glass edges)
    Rectangle {
        visible: root.highlightEnabled && root.amoledVariant
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.6, 0.8, 1.0, root.prismaticIntensity * 0.8) }
            GradientStop { position: 0.3; color: Qt.rgba(0.7, 0.85, 1.0, root.prismaticIntensity * 0.5) }
            GradientStop { position: 0.5; color: Qt.rgba(0.9, 0.7, 1.0, root.prismaticIntensity * 0.3) }
            GradientStop { position: 0.7; color: Qt.rgba(1.0, 0.8, 0.7, root.prismaticIntensity * 0.4) }
            GradientStop { position: 1.0; color: Qt.rgba(1.0, 0.9, 0.6, root.prismaticIntensity * 0.6) }
        }
    }

    // Prismatic/chromatic right edge highlight (Tahoe refraction)
    Rectangle {
        visible: root.highlightEnabled && root.amoledVariant
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1.0, 0.9, 0.6, root.prismaticIntensity * 0.6) }
            GradientStop { position: 0.3; color: Qt.rgba(1.0, 0.8, 0.7, root.prismaticIntensity * 0.4) }
            GradientStop { position: 0.5; color: Qt.rgba(0.9, 0.7, 1.0, root.prismaticIntensity * 0.3) }
            GradientStop { position: 0.7; color: Qt.rgba(0.7, 0.85, 1.0, root.prismaticIntensity * 0.5) }
            GradientStop { position: 1.0; color: Qt.rgba(0.6, 0.8, 1.0, root.prismaticIntensity * 0.8) }
        }
    }

    // Inner glow (Tahoe liquid glass luminosity - subtle ambient light within glass)
    Rectangle {
        visible: root.highlightEnabled && root.amoledVariant
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(0, root.radius - 2)
        color: "transparent"
        border.width: 1
        border.color: ColorUtils.applyAlpha("#ffffff", (Appearance?.isDarkMode ?? true) ? 0.04 : 0.06)
    }

    // Bottom shade for depth
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.highlightEnabled
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 0.85; color: Qt.rgba(0, 0, 0, root.shadeOpacity * 0.5) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.shadeOpacity) }
        }
    }
}
