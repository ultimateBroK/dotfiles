import QtQuick
import Quickshell
import qs.modules.common.functions
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property QtObject m3colors
    property QtObject animation
    property QtObject animationCurves
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes
    property string syntaxHighlightingTheme

    // Transparency. The quadratic functions were derived from analysis of hand-picked transparency values.
    ColorQuantizer {
        id: wallColorQuant
        property string wallpaperPath: Config.options.background.wallpaperPath
        property bool wallpaperIsVideo: wallpaperPath.endsWith(".mp4") || wallpaperPath.endsWith(".webm") || wallpaperPath.endsWith(".mkv") || wallpaperPath.endsWith(".avi") || wallpaperPath.endsWith(".mov")
        source: Qt.resolvedUrl(wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath)
        depth: 0 // 2^0 = 1 color
        rescaleSize: 10
    }
    property real wallpaperVibrancy: (wallColorQuant.colors[0]?.hslSaturation + wallColorQuant.colors[0]?.hslLightness) / 2
    
    // Color scheme type adaptation factors
    readonly property string colorSchemeType: Config?.options?.appearance?.palette?.type ?? "auto"
    readonly property bool isDarkMode: m3colors.darkmode
    
    // Transparency adjustment factor based on color scheme type
    readonly property real schemeTransparencyFactor: {
        switch(colorSchemeType) {
            case "scheme-vibrant": return 1.15;  // More transparency for vibrant schemes
            case "scheme-rainbow": return 1.2;
            case "scheme-fruit-salad": return 1.25;
            case "scheme-expressive": return 1.1;
            case "scheme-fidelity": return 1.0;
            case "scheme-content": return 0.95;
            case "scheme-neutral": return 0.85;  // Less transparency for neutral
            case "scheme-monochrome": return 0.8;  // Less transparency for monochrome
            case "scheme-tonal-spot": return 1.05;
            default: return 1.0;
        }
    }
    
    // Mode-aware transparency calculation with scheme type adjustment
    property real autoBackgroundTransparency: {
        let x = wallpaperVibrancy
        // Base formula: y = 0.5768x^2 - 0.759x + 0.2896
        let baseY = 0.5768 * (x * x) - 0.759 * (x) + 0.2896
        
        // Adjust for dark/light mode
        let modeAdjust = isDarkMode ? 1.0 : 0.85  // Light mode needs less transparency
        
        // Apply scheme type factor
        let adjusted = baseY * modeAdjust * schemeTransparencyFactor
        
        // Clamp with different limits for dark/light mode
        let maxTrans = isDarkMode ? 0.25 : 0.20
        return Math.max(0, Math.min(maxTrans, adjusted))
    }
    
    property real autoContentTransparency: {
        let x = autoBackgroundTransparency
        // Base formula: y = -10.1734x^2 + 3.4457x + 0.1872
        let baseY = -10.1734 * (x * x) + 3.4457 * (x) + 0.1872
        
        // Adjust for dark/light mode
        let modeAdjust = isDarkMode ? 1.0 : 0.9  // Light mode needs less content transparency
        
        // Apply scheme type factor (less aggressive for content)
        let schemeFactor = 0.7 + (schemeTransparencyFactor - 1.0) * 0.3
        let adjusted = baseY * modeAdjust * schemeFactor
        
        // Clamp with different limits for dark/light mode
        let maxTrans = isDarkMode ? 0.65 : 0.55
        return Math.max(0, Math.min(maxTrans, adjusted))
    }
    
    property real backgroundTransparency: Config?.options.appearance.transparency.enable ? Config?.options.appearance.transparency.automatic ? autoBackgroundTransparency : Config?.options.appearance.transparency.backgroundTransparency : 0
    property real contentTransparency: Config?.options.appearance.transparency.enable ? Config?.options.appearance.transparency.automatic ? autoContentTransparency : Config?.options.appearance.transparency.contentTransparency : 0
    readonly property real schemeSaturationBoost: {
        let base = {
            "scheme-vibrant": 1.15,
            "scheme-rainbow": 1.2,
            "scheme-fruit-salad": 1.25,
            "scheme-expressive": 1.1,
            "scheme-fidelity": 1.0,
            "scheme-content": 0.95,
            "scheme-neutral": 0.7,
            "scheme-monochrome": 0.0,
            "scheme-tonal-spot": 1.05
        }[colorSchemeType] ?? 1.0
        
        // Light mode: slightly reduce saturation boost to avoid being too intense
        if (!isDarkMode && base > 1.0) {
            return base * 0.92
        }
        // Dark mode can handle full saturation
        return base
    }
    readonly property real schemePrimaryMix: {
        switch(colorSchemeType) {
            case "scheme-vibrant": return 0.12;
            case "scheme-rainbow": return 0.15;
            case "scheme-fruit-salad": return 0.18;
            case "scheme-expressive": return 0.10;
            case "scheme-fidelity": return 0.08;
            case "scheme-content": return 0.06;
            case "scheme-neutral": return 0.03;
            case "scheme-monochrome": return 0.0;
            case "scheme-tonal-spot": return 0.09;
            default: return 0.08;
        }
    }
    readonly property real schemeContrastBoost: {
        let base = {
            "scheme-vibrant": 1.1,
            "scheme-rainbow": 1.15,
            "scheme-fruit-salad": 1.2,
            "scheme-expressive": 1.05,
            "scheme-fidelity": 1.0,
            "scheme-content": 0.95,
            "scheme-neutral": 0.9,
            "scheme-monochrome": 0.85,
            "scheme-tonal-spot": 1.0
        }[colorSchemeType] ?? 1.0
        
        // Light mode: increase contrast for better readability
        if (!isDarkMode) {
            return Math.min(1.25, base * 1.08)
        }
        return base
    }
    
    // Lightness adjustment for light mode backgrounds
    readonly property real schemeLightnessAdjust: {
        if (!isDarkMode) {
            // Light mode: slightly brighten backgrounds for better contrast with vibrant schemes
            switch(colorSchemeType) {
                case "scheme-vibrant":
                case "scheme-rainbow":
                case "scheme-fruit-salad": return 1.05;
                case "scheme-expressive": return 1.03;
                default: return 1.0;
            }
        }
        return 1.0
    }

    m3colors: QtObject {
        property bool darkmode: true
        property bool transparent: false
        property color m3background: "#141313"
        property color m3onBackground: "#e6e1e1"
        property color m3surface: "#141313"
        property color m3surfaceDim: "#141313"
        property color m3surfaceBright: "#3a3939"
        property color m3surfaceContainerLowest: "#0f0e0e"
        property color m3surfaceContainerLow: "#1c1b1c"
        property color m3surfaceContainer: "#201f20"
        property color m3surfaceContainerHigh: "#2b2a2a"
        property color m3surfaceContainerHighest: "#363435"
        property color m3onSurface: "#e6e1e1"
        property color m3surfaceVariant: "#49464a"
        property color m3onSurfaceVariant: "#cbc5ca"
        property color m3inverseSurface: "#e6e1e1"
        property color m3inverseOnSurface: "#313030"
        property color m3outline: "#948f94"
        property color m3outlineVariant: "#49464a"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#cbc4cb"
        property color m3primary: "#cbc4cb"
        property color m3onPrimary: "#322f34"
        property color m3primaryContainer: "#2d2a2f"
        property color m3onPrimaryContainer: "#bcb6bc"
        property color m3inversePrimary: "#615d63"
        property color m3secondary: "#cac5c8"
        property color m3onSecondary: "#323032"
        property color m3secondaryContainer: "#4d4b4d"
        property color m3onSecondaryContainer: "#ece6e9"
        property color m3tertiary: "#d1c3c6"
        property color m3onTertiary: "#372e30"
        property color m3tertiaryContainer: "#31292b"
        property color m3onTertiaryContainer: "#c1b4b7"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3primaryFixed: "#e7e0e7"
        property color m3primaryFixedDim: "#cbc4cb"
        property color m3onPrimaryFixed: "#1d1b1f"
        property color m3onPrimaryFixedVariant: "#49454b"
        property color m3secondaryFixed: "#e6e1e4"
        property color m3secondaryFixedDim: "#cac5c8"
        property color m3onSecondaryFixed: "#1d1b1d"
        property color m3onSecondaryFixedVariant: "#484648"
        property color m3tertiaryFixed: "#eddfe1"
        property color m3tertiaryFixedDim: "#d1c3c6"
        property color m3onTertiaryFixed: "#211a1c"
        property color m3onTertiaryFixedVariant: "#4e4447"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color term0: "#EDE4E4"
        property color term1: "#B52755"
        property color term2: "#A97363"
        property color term3: "#AF535D"
        property color term4: "#A67F7C"
        property color term5: "#B2416B"
        property color term6: "#8D76AD"
        property color term7: "#272022"
        property color term8: "#0E0D0D"
        property color term9: "#B52755"
        property color term10: "#A97363"
        property color term11: "#AF535D"
        property color term12: "#A67F7C"
        property color term13: "#B2416B"
        property color term14: "#8D76AD"
        property color term15: "#221A1A"
    }

    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        
        // Base layer0 with scheme-aware primary mixing and mode-aware adjustments
        property color colLayer0Base: {
            var bg = ColorUtils.transparentize(m3colors.m3background, root.backgroundTransparency);
            var mixRatio = Config.options.appearance.extraBackgroundTint ? (0.99 - root.schemePrimaryMix) : (1.0 - root.schemePrimaryMix);
            var mixed = ColorUtils.mix(bg, m3colors.m3primary, mixRatio);
            
            // Apply lightness adjustment for light mode
            if (root.schemeLightnessAdjust !== 1.0) {
                var base = Qt.color(mixed);
                var adjusted = Qt.hsla(base.hslHue, base.hslSaturation, Math.min(1.0, base.hslLightness * root.schemeLightnessAdjust), base.a);
                return adjusted;
            }
            return mixed;
        }
        property color colLayer0: {
            if (root.schemeSaturationBoost === 0.0) {
                // Monochrome: desaturate completely
                var base = Qt.color(colLayer0Base);
                var gray = (base.r + base.g + base.b) / 3;
                return Qt.rgba(gray, gray, gray, base.a);
            } else if (root.schemeSaturationBoost !== 1.0) {
                // Adjust saturation based on scheme type
                var base = Qt.color(colLayer0Base);
                var hsl = Qt.hsla(base.hslHue, Math.min(1.0, base.hslSaturation * root.schemeSaturationBoost), base.hslLightness, base.a);
                return hsl;
            }
            return colLayer0Base;
        }
        property color colOnLayer0: {
            if (root.schemeContrastBoost !== 1.0) {
                var base = Qt.color(m3colors.m3onBackground);
                var adjusted = Qt.hsla(base.hslHue, base.hslSaturation, Math.min(1.0, base.hslLightness * root.schemeContrastBoost), base.a);
                return adjusted;
            }
            return m3colors.m3onBackground;
        }
        property color colLayer0Hover: {
            var mixRatio = 0.9 * root.schemeContrastBoost;
            return ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, Math.min(0.95, mixRatio), root.contentTransparency));
        }
        property color colLayer0Active: {
            var mixRatio = 0.8 * root.schemeContrastBoost;
            return ColorUtils.transparentize(ColorUtils.mix(colLayer0, colOnLayer0, Math.min(0.9, mixRatio), root.contentTransparency));
        }
        property color colLayer0Border: {
            var borderColor = root.m3colors.m3outlineVariant;
            if (root.schemeSaturationBoost > 1.0) {
                // Enhance border visibility for vibrant schemes
                var base = Qt.color(borderColor);
                var enhanced = Qt.hsla(base.hslHue, Math.min(1.0, base.hslSaturation * 1.1), base.hslLightness, base.a);
                return ColorUtils.mix(enhanced, colLayer0, 0.4);
            }
            return ColorUtils.mix(borderColor, colLayer0, 0.4);
        }
        property color colLayer1: {
            var base = ColorUtils.transparentize(m3colors.m3surfaceContainerLow, root.contentTransparency);
            // Light mode: slightly brighten layer1 for better separation
            if (!root.isDarkMode && root.schemeLightnessAdjust > 1.0) {
                var c = Qt.color(base);
                return Qt.hsla(c.hslHue, c.hslSaturation, Math.min(1.0, c.hslLightness * 1.02), c.a);
            }
            return base;
        }
        property color colOnLayer1: m3colors.m3onSurfaceVariant;
        property color colOnLayer1Inactive: ColorUtils.mix(colOnLayer1, colLayer1, root.isDarkMode ? 0.45 : 0.50);
        property color colLayer2: {
            var base = ColorUtils.transparentize(m3colors.m3surfaceContainer, root.contentTransparency);
            // Light mode: slightly brighten layer2
            if (!root.isDarkMode && root.schemeLightnessAdjust > 1.0) {
                var c = Qt.color(base);
                return Qt.hsla(c.hslHue, c.hslSaturation, Math.min(1.0, c.hslLightness * 1.03), c.a);
            }
            return base;
        }
        property color colOnLayer2: m3colors.m3onSurface;
        property color colOnLayer2Disabled: ColorUtils.mix(colOnLayer2, m3colors.m3background, root.isDarkMode ? 0.4 : 0.5);
        property color colLayer1Hover: {
            var mixRatio = root.isDarkMode ? 0.92 : 0.94;
            return ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, mixRatio), root.contentTransparency);
        }
        property color colLayer1Active: {
            var mixRatio = root.isDarkMode ? 0.85 : 0.88;
            return ColorUtils.transparentize(ColorUtils.mix(colLayer1, colOnLayer1, mixRatio), root.contentTransparency);
        }
        property color colLayer2Hover: {
            var mixRatio = root.isDarkMode ? 0.90 : 0.92;
            return ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, mixRatio), root.contentTransparency);
        }
        property color colLayer2Active: {
            var mixRatio = root.isDarkMode ? 0.80 : 0.83;
            return ColorUtils.transparentize(ColorUtils.mix(colLayer2, colOnLayer2, mixRatio), root.contentTransparency);
        }
        property color colLayer2Disabled: ColorUtils.transparentize(ColorUtils.mix(colLayer2, m3colors.m3background, root.isDarkMode ? 0.8 : 0.75), root.contentTransparency);
        property color colLayer3: ColorUtils.transparentize(m3colors.m3surfaceContainerHigh, root.contentTransparency)
        property color colOnLayer3: m3colors.m3onSurface;
        property color colLayer3Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer3, colOnLayer3, 0.90), root.contentTransparency)
        property color colLayer3Active: ColorUtils.transparentize(ColorUtils.mix(colLayer3, colOnLayer3, 0.80), root.contentTransparency);
        property color colLayer4: ColorUtils.transparentize(m3colors.m3surfaceContainerHighest, root.contentTransparency)
        property color colOnLayer4: m3colors.m3onSurface;
        property color colLayer4Hover: ColorUtils.transparentize(ColorUtils.mix(colLayer4, colOnLayer4, 0.90), root.contentTransparency)
        property color colLayer4Active: ColorUtils.transparentize(ColorUtils.mix(colLayer4, colOnLayer4, 0.80), root.contentTransparency);
        property color colPrimary: {
            if (root.schemeSaturationBoost === 0.0) {
                // Monochrome: desaturate primary
                var base = Qt.color(m3colors.m3primary);
                var gray = (base.r + base.g + base.b) / 3;
                return Qt.rgba(gray, gray, gray, base.a);
            } else if (root.schemeSaturationBoost !== 1.0) {
                var base = Qt.color(m3colors.m3primary);
                return Qt.hsla(base.hslHue, Math.min(1.0, base.hslSaturation * root.schemeSaturationBoost), base.hslLightness, base.a);
            }
            return m3colors.m3primary;
        }
        property color colOnPrimary: m3colors.m3onPrimary
        property color colPrimaryHover: {
            var baseRatio = root.schemeSaturationBoost > 1.0 ? 0.85 : 0.87;
            // Light mode needs slightly different mixing for better visibility
            var mixRatio = root.isDarkMode ? baseRatio : (baseRatio + 0.02);
            return ColorUtils.mix(colors.colPrimary, colLayer1Hover, mixRatio);
        }
        property color colPrimaryActive: {
            var baseRatio = root.schemeSaturationBoost > 1.0 ? 0.65 : 0.7;
            // Light mode: slightly more mixing for better contrast
            var mixRatio = root.isDarkMode ? baseRatio : (baseRatio + 0.03);
            return ColorUtils.mix(colors.colPrimary, colLayer1Active, mixRatio);
        }
        property color colPrimaryContainer: m3colors.m3primaryContainer
        property color colPrimaryContainerHover: ColorUtils.mix(colors.colPrimaryContainer, colors.colOnPrimaryContainer, 0.9)
        property color colPrimaryContainerActive: ColorUtils.mix(colors.colPrimaryContainer, colors.colOnPrimaryContainer, 0.8)
        property color colOnPrimaryContainer: m3colors.m3onPrimaryContainer
        property color colSecondary: {
            if (root.schemeSaturationBoost === 0.0) {
                var base = Qt.color(m3colors.m3secondary);
                var gray = (base.r + base.g + base.b) / 3;
                return Qt.rgba(gray, gray, gray, base.a);
            } else if (root.schemeSaturationBoost !== 1.0) {
                var base = Qt.color(m3colors.m3secondary);
                return Qt.hsla(base.hslHue, Math.min(1.0, base.hslSaturation * root.schemeSaturationBoost), base.hslLightness, base.a);
            }
            return m3colors.m3secondary;
        }
        property color colOnSecondary: m3colors.m3onSecondary
        property color colSecondaryHover: {
            var baseRatio = root.schemeSaturationBoost > 1.0 ? 0.82 : 0.85;
            // Light mode: slightly more mixing
            var mixRatio = root.isDarkMode ? baseRatio : (baseRatio + 0.02);
            return ColorUtils.mix(colSecondary, colLayer1Hover, mixRatio);
        }
        property color colSecondaryActive: {
            var baseRatio = root.schemeSaturationBoost > 1.0 ? 0.35 : 0.4;
            // Light mode: more mixing for better contrast
            var mixRatio = root.isDarkMode ? baseRatio : (baseRatio + 0.05);
            return ColorUtils.mix(colSecondary, colLayer1Active, mixRatio);
        }
        property color colSecondaryContainer: {
            if (root.schemeSaturationBoost > 1.0) {
                var base = Qt.color(m3colors.m3secondaryContainer);
                return Qt.hsla(base.hslHue, Math.min(1.0, base.hslSaturation * 1.05), base.hslLightness, base.a);
            }
            return m3colors.m3secondaryContainer;
        }
        property color colSecondaryContainerHover: ColorUtils.mix(colSecondaryContainer, m3colors.m3onSecondaryContainer, 0.90)
        property color colSecondaryContainerActive: ColorUtils.mix(colSecondaryContainer, m3colors.m3onSecondaryContainer, 0.54)
        property color colTertiary: m3colors.m3tertiary
        property color colTertiaryHover: ColorUtils.mix(m3colors.m3tertiary, colLayer1Hover, 0.85)
        property color colTertiaryActive: ColorUtils.mix(m3colors.m3tertiary, colLayer1Active, 0.4)
        property color colTertiaryContainer: m3colors.m3tertiaryContainer
        property color colTertiaryContainerHover: ColorUtils.mix(m3colors.m3tertiaryContainer, m3colors.m3onTertiaryContainer, 0.90)
        property color colTertiaryContainerActive: ColorUtils.mix(m3colors.m3tertiaryContainer, colLayer1Active, 0.54)
        property color colOnTertiary: m3colors.m3onTertiary
        property color colOnTertiaryContainer: m3colors.m3onTertiaryContainer
        property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer
        property color colSurfaceContainerLow: ColorUtils.transparentize(m3colors.m3surfaceContainerLow, root.contentTransparency)
        property color colSurfaceContainer: ColorUtils.transparentize(m3colors.m3surfaceContainer, root.contentTransparency)
        property color colBackgroundSurfaceContainer: ColorUtils.transparentize(m3colors.m3surfaceContainer, root.backgroundTransparency)
        property color colSurfaceContainerHigh: ColorUtils.transparentize(m3colors.m3surfaceContainerHigh, root.contentTransparency)
        property color colSurfaceContainerHighest: ColorUtils.transparentize(m3colors.m3surfaceContainerHighest, root.contentTransparency)
        property color colSurfaceContainerHighestHover: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.95)
        property color colSurfaceContainerHighestActive: ColorUtils.mix(m3colors.m3surfaceContainerHighest, m3colors.m3onSurface, 0.85)
        property color colOnSurface: m3colors.m3onSurface
        property color colOnSurfaceVariant: m3colors.m3onSurfaceVariant
        property color colTooltip: m3colors.m3inverseSurface
        property color colOnTooltip: m3colors.m3inverseOnSurface
        property color colScrim: ColorUtils.transparentize(m3colors.m3scrim, 0.5)
        property color colShadow: ColorUtils.transparentize(m3colors.m3shadow, 0.7)
        property color colOutline: m3colors.m3outline
        property color colOutlineVariant: m3colors.m3outlineVariant
        property color colError: m3colors.m3error
        property color colErrorHover: ColorUtils.mix(m3colors.m3error, colLayer1Hover, 0.85)
        property color colErrorActive: ColorUtils.mix(m3colors.m3error, colLayer1Active, 0.7)
        property color colOnError: m3colors.m3onError
        property color colErrorContainer: m3colors.m3errorContainer
        property color colErrorContainerHover: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.90)
        property color colErrorContainerActive: ColorUtils.mix(m3colors.m3errorContainer, m3colors.m3onErrorContainer, 0.70)
        property color colOnErrorContainer: m3colors.m3onErrorContainer
    }

    rounding: QtObject {
        property int unsharpen: 2
        property int unsharpenmore: 6
        property int verysmall: 8
        property int small: 12
        property int normal: 17
        property int large: 23
        property int verylarge: 30
        property int full: 9999
        property int screenRounding: large
        property int windowRounding: 18
    }

    font: QtObject {
        property QtObject family: QtObject {
            property string main: "Roboto Flex"
            property string numbers: "Rubik"
            property string title: "Gabarito"
            property string iconMaterial: "Material Symbols Rounded"
            property string iconNerd: "JetBrains Mono NF"
            property string monospace: "JetBrains Mono NF"
            property string reading: "Readex Pro"
            property string expressive: "Space Grotesk"
        }
        property QtObject variableAxes: QtObject {
            // Roboto Flex is customized to feel geometric, unserious yet not overly kiddy
            property var main: ({
                "YTUC": 716, // Uppercase height (Raised from 712 to be more distinguishable from lowercase)
                "YTFI": 716, // Figure (numbers) height (Lowered from 738 to match uppercase)
                "YTAS": 716, // Ascender height (Lowered from 750 to match uppercase)
                "YTLC": 490, // Lowercase height (Lowered from 514 to be more distinguishable from uppercase)
                "XTRA": 488, // Counter width (Raised from 468 to be less condensed, less serious)
                "wdth": 105, // Width (Space out a tiny bit for readability)
                "GRAD": 175, // Grade (Increased so the 6 and 9 don't look weak)
                "wght": 300, // Weight (Lowered to compensate for increased grade)
            })
            // Rubik simply needs regular weight to override that of the main font where necessary
            property var numbers: ({
                "wght": 400,
            })
            // Slightly bold weight for title
            property var title: ({
                // "YTUC": 716, // Uppercase height (Raised from 712 to be more distinguishable from lowercase)
                // "YTFI": 716, // Figure (numbers) height (Lowered from 738 to match uppercase)
                // "YTAS": 716, // Ascender height (Lowered from 750 to match uppercase)
                // "YTLC": 490, // Lowercase height (Lowered from 514 to be more distinguishable from uppercase)
                // "XTRA": 490, // Counter width (Raised from 468 to be less condensed, less serious)
                // "wdth": 110, // Width (Space out a tiny bit for readability)
                // "GRAD": 150, // Grade (Increased so the 6 and 9 don't look weak)
                "wght": 900, // Weight (Lowered to compensate for increased grade)
            })
        }
        property QtObject pixelSize: QtObject {
            property int smallest: 10
            property int smaller: 12
            property int smallie: 13
            property int small: 15
            property int normal: 16
            property int large: 17
            property int larger: 19
            property int huge: 22
            property int hugeass: 23
            property int title: huge
        }
    }

    animationCurves: QtObject {
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // Default, 350ms
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // Default, 500ms
        readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // Default, 650ms
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // Default, 200ms
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedFirstHalf: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82]
        readonly property list<real> emphasizedLastHalf: [5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property real expressiveFastSpatialDuration: 350
        readonly property real expressiveDefaultSpatialDuration: 500
        readonly property real expressiveSlowSpatialDuration: 650
        readonly property real expressiveEffectsDuration: 200
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: animationCurves.expressiveDefaultSpatialDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }

        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }

        property QtObject elementMoveFast: QtObject {
            property int duration: animationCurves.expressiveEffectsDuration
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property int velocity: 850
            property Component colorAnimation: Component { ColorAnimation {
                duration: root.animation.elementMoveFast.duration
                easing.type: root.animation.elementMoveFast.type
                easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
            property Component numberAnimation: Component { NumberAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
            }}
        }

        property QtObject elementResize: QtObject {
            property int duration: 300
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasized
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementResize.duration
                    easing.type: root.animation.elementResize.type
                    easing.bezierCurve: root.animation.elementResize.bezierCurve
                }
            }
        }

        property QtObject clickBounce: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 850
            property Component numberAnimation: Component { NumberAnimation {
                    duration: root.animation.clickBounce.duration
                    easing.type: root.animation.clickBounce.type
                    easing.bezierCurve: root.animation.clickBounce.bezierCurve
            }}
        }
        
        property QtObject scroll: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.standardDecel
        }

        property QtObject menuDecel: QtObject {
            property int duration: 350
            property int type: Easing.OutExpo
        }
    }

    sizes: QtObject {
        property real baseBarHeight: 40
        property real barHeight: Config.options.bar.cornerStyle === 1 ? 
            (baseBarHeight + root.sizes.hyprlandGapsOut * 2) : baseBarHeight
        property real barCenterSideModuleWidth: Config.options?.bar.verbose ? 396 : 154
        property real barCenterSideModuleWidthShortened: 308
        property real barCenterSideModuleWidthHellaShortened: 209
        property real barShortenScreenWidthThreshold: 1200 // Shorten if screen width is at most this value
        property real barHellaShortenScreenWidthThreshold: 1000 // Shorten even more...
        property real elevationMargin: 10
        property real fabShadowRadius: 5
        property real fabHoveredShadowRadius: 7
        property real hyprlandGapsOut: 5
        property real mediaControlsWidth: 440
        property real mediaControlsHeight: 160
        property real notificationPopupWidth: 410
        property real osdWidth: 180
        property real searchWidthCollapsed: 210
        property real searchWidth: 360
        property real sidebarWidth: 460
        property real sidebarWidthExtended: 750
        property real baseVerticalBarWidth: 46
        property real verticalBarWidth: Config.options.bar.cornerStyle === 1 ? 
            (baseVerticalBarWidth + root.sizes.hyprlandGapsOut * 2) : baseVerticalBarWidth
        property real wallpaperSelectorWidth: 1200
        property real wallpaperSelectorHeight: 690
        property real wallpaperSelectorItemMargins: 8
        property real wallpaperSelectorItemPadding: 6
    }

    syntaxHighlightingTheme: root.m3colors.darkmode ? "Monokai" : "ayu Light"
}
