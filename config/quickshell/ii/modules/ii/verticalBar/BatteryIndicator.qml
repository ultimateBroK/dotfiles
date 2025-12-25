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

    implicitHeight: batteryProgress.implicitHeight
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
                duration: 900
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 0.3
                duration: 900
                easing.type: Easing.InOutQuad
            }
        }
        
        SequentialAnimation on scale {
            running: isCharging
            loops: Animation.Infinite
            NumberAnimation {
                to: 1.1
                duration: 900
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                to: 0.95
                duration: 900
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
        
        property color baseColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colOnSecondaryContainer
        property color chargingGlowColor: Appearance.colors.colOnSecondaryContainer
        
        highlightColor: isCharging ? chargingGlowColor : baseColor
        
        SequentialAnimation on chargingGlowColor {
            running: isCharging
            loops: Animation.Infinite
            ColorAnimation {
                from: Appearance.colors.colOnSecondaryContainer
                to: Qt.lighter(Appearance.colors.colOnSecondaryContainer, 1.3)
                duration: 1100
                easing.type: Easing.InOutQuad
            }
            ColorAnimation {
                from: Qt.lighter(Appearance.colors.colOnSecondaryContainer, 1.3)
                to: Appearance.colors.colOnSecondaryContainer
                duration: 1100
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
                    text: isCharging ? "bolt" : "battery_android_full"
                    iconSize: Appearance.font.pixelSize.normal
                    animateChange: true
                    opacity: 1.0
                    scale: 1.0
                    
                    SequentialAnimation on opacity {
                        running: isCharging
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.5
                            duration: 900
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 900
                            easing.type: Easing.InOutQuad
                        }
                    }
                    
                    SequentialAnimation on scale {
                        running: isCharging
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 1.15
                            duration: 900
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 900
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font: batteryProgress.font
                    nativeRendering: true
                    text: batteryProgress.text
                }
            }
        }
    }

    Bar.BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
