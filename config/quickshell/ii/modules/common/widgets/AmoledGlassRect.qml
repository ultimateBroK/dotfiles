import QtQuick
import qs.modules.common
import qs.modules.common.functions

/**
 * AMOLED glassmorphism surface:
 * - Semi-transparent black tint (lets compositor blur show through)
 * - Subtle specular highlight + bottom shade for glass feel
 * - Thin white border for glass edge
 *
 * Note: Actual background blur is provided by compositor (e.g. Hyprland blur rules)
 * when the window is translucent.
 *
 * Use amoledVariant: true for sidebar/panel surfaces with enhanced glass effect.
 */
Rectangle {
    id: root

    // Transparency amount for ColorUtils.transparentize() (0 = opaque, 1 = fully transparent).
    property real glassTransparency: 0.55

    // Base tint color (override per-surface if needed).
    property color glassColor: "#000000"

    // Whether to draw the "specular" highlight overlays.
    property bool highlightEnabled: true

    // Enable enhanced AMOLED glass variant (sidebar/panel) - stronger highlights, edge rim.
    property bool amoledVariant: false

    // Control highlight strength (AMOLED: lower values for amoledVariant).
    property real highlightOpacity: (Appearance?.isDarkMode ?? true)
        ? (root.amoledVariant ? 0.06 : 0.10)
        : (root.amoledVariant ? 0.09 : 0.06)
    property real shadeOpacity: (Appearance?.isDarkMode ?? true)
        ? (root.amoledVariant ? 0.04 : 0.08)
        : (root.amoledVariant ? 0.06 : 0.04)

    color: ColorUtils.transparentize(root.glassColor, root.glassTransparency)

    border.width: 1
    border.color: ColorUtils.applyAlpha("#ffffff", 0.08)

    // Top "specular" sheen - smoother multi-stop gradient for AMOLED glass
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.highlightEnabled
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.highlightOpacity) }
            GradientStop { position: 0.12; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.7) }
            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.2) }
            GradientStop { position: 0.65; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.05) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    // Subtle top-edge rim (light catching on glass edge) - amoled variant only
    Rectangle {
        visible: root.highlightEnabled && root.amoledVariant
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.5) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.35) }
            GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.5) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
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
