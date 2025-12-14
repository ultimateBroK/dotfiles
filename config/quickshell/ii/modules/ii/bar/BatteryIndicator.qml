import qs.modules.common
import qs.modules.common.widgets
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
        width: batteryProgress.width + 40
        height: batteryProgress.height + 40
        radius: width / 2
        visible: isCharging
        opacity: 0
        color: "transparent"
        
        layer.enabled: true
        layer.effect: RadialGradient {
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.4) }
                GradientStop { position: 0.5; color: Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        
        SequentialAnimation on opacity {
            running: isCharging
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.8
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 0.3
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
        }
        
        SequentialAnimation on scale {
            running: isCharging
            loops: Animation.Infinite
            NumberAnimation {
                to: 1.1
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 0.95
                duration: root.pulseDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        valueBarWidth: 36
        value: percentage

        Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        
        property color baseColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer
        property color chargingColor: Appearance.colors.colPrimary
        
        highlightColor: isCharging ? chargingColor : baseColor
        
        pulsing: isCharging
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
                    visible: isCharging && percentage < 1
                    opacity: isCharging ? 1 : 0
                    
                    SequentialAnimation on opacity {
                        running: isCharging && percentage < 1
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
                }
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
