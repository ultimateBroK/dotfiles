pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100
    // UPower can report PendingCharge while still plugged; keep visuals stable
    readonly property bool chargeFxActive: isPluggedIn && percentage < 0.999
    
    readonly property real energyRate: Battery.energyRate
    readonly property int pulseDuration: {
        if (energyRate >= 60) return 300; // Very Fast charging (>60W)
        if (energyRate >= 30) return 500; // Fast charging (30-60W)
        if (energyRate >= 10) return 700; // Standard charging (10-30W)
        return 1000;                      // Slow charging (<10W)
    }

    implicitWidth: batteryProgress.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // Smooth display value to avoid jagged jumps when percentage updates
    property real displayPercentage: percentage
    onPercentageChanged: displayPercentage = percentage

    Behavior on displayPercentage { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    // Halo/Glow effect
    Rectangle {
        id: haloEffect
        anchors.centerIn: batteryProgress
        property real glowMargin: 22
        // Use the same color the battery uses while charging
        property color glowColor: batteryProgress.highlightColor
        // Animate "strength" instead of item opacity for smoother look
        property real glowStrength: 0.0

        width: batteryProgress.width + glowMargin * 2
        height: batteryProgress.height + glowMargin * 2
        radius: height / 2
        visible: root.chargeFxActive
        opacity: 1
        color: "transparent"
        antialiasing: true
        
        layer.enabled: true
        layer.samples: 4
        layer.effect: RadialGradient {
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(haloEffect.glowColor.r, haloEffect.glowColor.g, haloEffect.glowColor.b, 0.30 * haloEffect.glowStrength) }
                GradientStop { position: 0.35; color: Qt.rgba(haloEffect.glowColor.r, haloEffect.glowColor.g, haloEffect.glowColor.b, 0.16 * haloEffect.glowStrength) }
                GradientStop { position: 0.65; color: Qt.rgba(haloEffect.glowColor.r, haloEffect.glowColor.g, haloEffect.glowColor.b, 0.06 * haloEffect.glowStrength) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        
        onVisibleChanged: {
            if (!visible) {
                glowStrength = 0.0;
                scale = 1.0;
            }
        }

        SequentialAnimation on glowStrength {
            running: root.chargeFxActive
            loops: Animation.Infinite
            NumberAnimation {
                to: 1.0
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 0.45
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
        }
        
        SequentialAnimation on scale {
            running: root.chargeFxActive
            loops: Animation.Infinite
            NumberAnimation {
                to: 1.08
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 0.98
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        // Make the battery indicator longer on the top bar.
        valueBarWidth: 48
        value: percentage
        showTextMaskOnTop: (root.chargeFxActive || Config.options.battery.showPercentageInIcon)

        Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        
        property color baseColor: {
            // Charging or full: use primary color (from wallpaper)
            if (root.chargeFxActive || percentage >= 0.995) {
                return Appearance.colors.colPrimary;
            }
            
            // Only apply warning color when battery is low and not charging
            // Otherwise use primary color (default)
            if (isLow && !root.chargeFxActive) {
                // Red for low battery - mix primary with error color
                const primaryColor = Appearance.colors.colPrimary;
                return ColorUtils.mix(primaryColor, Appearance.colors.colError, 0.1);
            }
            
            // Default: use primary color when battery is not low
            return Appearance.colors.colPrimary;
        }
        property color chargingColor: Appearance.colors.colPrimary
        
        highlightColor: root.chargeFxActive ? chargingColor : baseColor
        
        pulsing: root.chargeFxActive
        pulseDuration: root.pulseDuration

        Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            RowLayout {
                anchors.centerIn: parent
                spacing: 2

                MaterialSymbol {
                    id: boltIcon
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: -2
                    Layout.rightMargin: -2
                    fill: 1
                    text: "bolt"
                    iconSize: Appearance.font.pixelSize.smaller
                    visible: root.chargeFxActive && percentage < 1
                    opacity: root.chargeFxActive ? 1 : 0
                    
                    SequentialAnimation on opacity {
                        running: root.chargeFxActive && percentage < 1
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.1
                            duration: root.pulseDuration
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: root.pulseDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    font: batteryProgress.font
                    // Use animated displayPercentage (0..1) and convert to percent
                    text: Math.round(root.displayPercentage * 100)
                    color: Appearance.colors.colOnSurface
                    visible: Config.options.battery.showPercentageInIcon
                }
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
