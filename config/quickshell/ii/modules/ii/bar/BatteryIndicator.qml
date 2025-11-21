import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitWidth: batteryProgress.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        valueBarWidth: 36
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
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            ColorAnimation {
                from: Qt.lighter(Appearance.colors.colOnSecondaryContainer, 1.3)
                to: Appearance.colors.colOnSecondaryContainer
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }

        Item {
            anchors.centerIn: parent
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight

            RowLayout {
                anchors.centerIn: parent
                spacing: 0

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
                            to: 0.4
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    font: batteryProgress.font
                    text: batteryProgress.text
                }
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
