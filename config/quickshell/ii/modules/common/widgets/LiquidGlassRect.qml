import QtQuick
import qs.modules.common
import qs.modules.common.functions

/**
 * Liquid-glass style surface:
 * - Semi-transparent tint (lets compositor blur show through)
 * - Specular highlight + bottom shade + subtle edge rim for "liquid glass" feel
 * - Thin border tuned for dark/light mode
 *
 * Note: Actual background blur is provided by compositor (e.g. Hyprland blur rules)
 * when the window is translucent. This component focuses on consistent tinting
 * and highlights across bar + sidebar surfaces.
 *
 * Use liquidGlassVariant: true for sidebar/panel surfaces with enhanced glass effect.
 */
Rectangle {
    id: root

    // Transparency amount for ColorUtils.transparentize() (0 = opaque, 1 = fully transparent).
    property real glassTransparency: {
        if (root.liquidGlassVariant) {
            const base = Appearance?.contentTransparency ?? 0.18;
            const t = base * 0.35 + 0.10;  // Slightly more transparent for liquid glass
            return Math.max(0.10, Math.min(0.22, t));
        }
        const base = Appearance?.contentTransparency ?? 0.18;
        const t = base * 0.25 + 0.06;
        return Math.max(0.08, Math.min(0.14, t));
    }

    // Base tint color (override per-surface if needed).
    property color glassColor: Appearance?.m3colors?.m3surfaceContainer ?? Appearance.colors.colLayer0

    // Whether to draw the "specular" highlight overlays.
    property bool highlightEnabled: true

    // Enable enhanced liquid glass variant (sidebar/panel) - stronger highlights, edge rim.
    property bool liquidGlassVariant: false

    // Control highlight strength.
    property real highlightOpacity: (Appearance?.isDarkMode ?? true)
        ? (root.liquidGlassVariant ? 0.14 : 0.10)
        : (root.liquidGlassVariant ? 0.09 : 0.06)
    property real shadeOpacity: (Appearance?.isDarkMode ?? true)
        ? (root.liquidGlassVariant ? 0.10 : 0.08)
        : (root.liquidGlassVariant ? 0.06 : 0.04)

    color: ColorUtils.transparentize(root.glassColor, root.glassTransparency)

    border.width: 1
    border.color: ColorUtils.applyAlpha(
        Appearance.colors.colLayer0Border,
        (Appearance?.isDarkMode ?? true) ? 0.32 : 0.18
    )

    // Top "specular" sheen - smoother multi-stop gradient for liquid glass
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

    // Subtle top-edge rim (light catching on glass edge) - liquid glass variant only
    Rectangle {
        visible: root.highlightEnabled && root.liquidGlassVariant
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.5) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.7) }
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

