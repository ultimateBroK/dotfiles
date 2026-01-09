import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool vertical: false
    property real padding: 5
    // Keep alpha high because Hyprland has `ignorealpha 0.79, quickshell:.*`.
    // Also adapt to bright wallpapers so text stays readable.
    readonly property real glassTransparency: {
        // Balance readability vs "not too dark".
        // Bright wallpaper -> slightly more opaque, but never "heavy".
        // Dark mode range: [0.10..0.16] (alpha [0.90..0.84])
        // Light mode: slightly more transparent so the bar doesn't look "muddy".
        const l = Math.max(0, Math.min(1, Appearance?.wallpaperLightness ?? 0.5));
        const base = 0.16 - l * 0.06; // l=1 => 0.10, l=0 => 0.16
        const isDark = Appearance?.isDarkMode ?? true;
        const t = isDark ? base : (base + 0.02);
        const lo = isDark ? 0.10 : 0.12;
        const hi = isDark ? 0.16 : 0.18;
        return Math.max(lo, Math.min(hi, t));
    }
    readonly property color adaptiveGroupColor: {
        // Very gently darken the surface on *very bright* wallpapers for extra contrast.
        // Keep this subtle so the bar doesn't look "too dark".
        const l = Math.max(0, Math.min(1, Appearance?.wallpaperLightness ?? 0.5));
        const isDark = Appearance?.isDarkMode ?? true;
        // IMPORTANT: use an *opaque* base surface here. Appearance.colors.colLayer1 already
        // includes contentTransparency; applying another transparentize() on top makes the
        // group background effectively double-transparent and can look like a dark overlay
        // in light mode (dark wallpaper bleeds through).
        const baseSurface = Appearance?.m3colors?.m3surfaceContainerLow ?? Appearance.colors.colLayer1;
        // Light mode should stay airy: start later and cap lower.
        const start = isDark ? 0.70 : 0.82;
        const cap = isDark ? 0.12 : 0.06;
        const slope = isDark ? 0.60 : 0.45;
        const darken = Math.max(0, Math.min(cap, (l - start) * slope));
        // ColorUtils.mix( a, b, p ) => p=1 all a, p=0 all b.
        // We want "slight darken" => mostly colLayer1 with a small amount of black.
        return ColorUtils.mix(baseSurface, "#000000", 1 - darken);
    }
    implicitWidth: vertical ? Appearance.sizes.baseVerticalBarWidth : (gridLayout.implicitWidth + padding * 2)
    implicitHeight: vertical ? (gridLayout.implicitHeight + padding * 2) : Appearance.sizes.baseBarHeight
    default property alias items: gridLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: root.vertical ? 0 : 4
            bottomMargin: root.vertical ? 0 : 4
            leftMargin: root.vertical ? 4 : 0
            rightMargin: root.vertical ? 4 : 0
        }
        color: Config.options?.bar.borderless
            ? "transparent"
            : ColorUtils.transparentize(root.adaptiveGroupColor, root.glassTransparency)
        radius: Appearance.rounding.small
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