pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.ii.bar as Bar

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
    readonly property int colorPulseDuration: Math.round(pulseDuration * 1.2)

    implicitHeight: batteryProgress.implicitHeight
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
        vertical: true
        valueBarWidth: 36
        valueBarHeight: 40
        value: percentage
        
        property color baseColor: (isLow && !root.chargeFxActive) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer
        property color chargingGlowColor: Appearance.colors.colOnSecondaryContainer
        
        highlightColor: root.chargeFxActive ? chargingGlowColor : baseColor
        
        SequentialAnimation on chargingGlowColor {
            running: root.chargeFxActive
            loops: Animation.Infinite
            ColorAnimation {
                from: Appearance.colors.colOnSecondaryContainer
                to: Qt.lighter(Appearance.colors.colOnSecondaryContainer, 1.3)
                duration: root.colorPulseDuration
                easing.type: Easing.InOutQuad
            }
            ColorAnimation {
                from: Qt.lighter(Appearance.colors.colOnSecondaryContainer, 1.3)
                to: Appearance.colors.colOnSecondaryContainer
                duration: root.colorPulseDuration
                easing.type: Easing.InOutQuad
            }
        }

        font {
            pixelSize: text.length > 2 ? 11 : 13
            weight: text.length > 2 ? Font.Medium : Font.DemiBold
        }

        textMask: Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                MaterialSymbol {
                    id: boltIcon
                    Layout.alignment: Qt.AlignHCenter
                    fill: 1
                    text: root.chargeFxActive ? "bolt" : "battery_android_full"
                    iconSize: Appearance.font.pixelSize.normal
                    animateChange: true
                    opacity: 1.0
                    scale: 1.0
                    
                    SequentialAnimation on opacity {
                        running: root.chargeFxActive
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.5
                            duration: root.pulseDuration
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: root.pulseDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                    
                    SequentialAnimation on scale {
                        running: root.chargeFxActive
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 1.15
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
                    Layout.alignment: Qt.AlignHCenter
                    font: batteryProgress.font
                    nativeRendering: true
                    text: batteryProgress.text
                    visible: Config.options.battery.showPercentageInIcon
                }
            }
        }
    }

    Bar.BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
