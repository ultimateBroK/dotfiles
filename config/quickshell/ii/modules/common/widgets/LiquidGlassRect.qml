import QtQuick
import qs.modules.common
import qs.modules.common.functions

/**
 * Liquid-glass style surface:
 * - Semi-transparent tint (lets compositor blur show through)
 * - Subtle specular highlight + bottom shade for "glass" feel
 * - Thin border tuned for dark/light mode
 *
 * Note: Actual background blur is provided by compositor (e.g. Hyprland blur rules)
 * when the window is translucent. This component focuses on consistent tinting
 * and highlights across bar + sidebar surfaces.
 */
Rectangle {
    id: root

    // Transparency amount for ColorUtils.transparentize() (0 = opaque, 1 = fully transparent).
    // Keep it conservative because Hyprland commonly uses `ignorealpha 0.79` for quickshell layers.
    property real glassTransparency: {
        const base = Appearance?.contentTransparency ?? 0.18;
        // Map the global contentTransparency into a narrow range that stays readable.
        const t = base * 0.25 + 0.06;
        return Math.max(0.08, Math.min(0.14, t));
    }

    // Base tint color (override per-surface if needed).
    property color glassColor: Appearance?.m3colors?.m3surfaceContainer ?? Appearance.colors.colLayer0

    // Whether to draw the "specular" highlight overlays.
    property bool highlightEnabled: true

    // Control highlight strength.
    property real highlightOpacity: (Appearance?.isDarkMode ?? true) ? 0.10 : 0.06
    property real shadeOpacity: (Appearance?.isDarkMode ?? true) ? 0.08 : 0.04

    color: ColorUtils.transparentize(root.glassColor, root.glassTransparency)

    border.width: 1
    border.color: ColorUtils.applyAlpha(
        Appearance.colors.colLayer0Border,
        (Appearance?.isDarkMode ?? true) ? 0.32 : 0.18
    )

    // Top "specular" sheen
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.highlightEnabled
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.highlightOpacity) }
            GradientStop { position: 0.28; color: Qt.rgba(1, 1, 1, root.highlightOpacity * 0.25) }
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
            GradientStop { position: 0.65; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.shadeOpacity) }
        }
    }
}

