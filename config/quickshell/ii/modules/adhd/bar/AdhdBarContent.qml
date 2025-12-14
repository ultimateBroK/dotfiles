import qs.modules.ii.bar
import qs.modules.adhd.bar
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property var screen: root.QsWindow.window?.screen

    // Background
    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
    }

    // Left side: Media Player and DateTime
    RowLayout {
        id: leftSection
        anchors {
            left: parent.left
            leftMargin: Appearance.rounding.screenRounding
            verticalCenter: parent.verticalCenter
        }
        spacing: 10

        // Media Player Widget
        BarGroup {
            id: mediaGroup
            Layout.alignment: Qt.AlignVCenter
            padding: 8

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 220
                implicitHeight: Appearance.sizes.barHeight

                AdhdMediaWidget {
                    id: mediaWidget
                    anchors.fill: parent
                }
            }
        }

        // DateTime Widget
        BarGroup {
            id: dateTimeGroup
            Layout.alignment: Qt.AlignVCenter
            padding: 8

            AdhdDateTimeWidget {
                id: dateTimeWidget
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Right side: Pomodoro Timer
    RowLayout {
        id: rightSection
        anchors {
            right: parent.right
            rightMargin: Appearance.rounding.screenRounding
            verticalCenter: parent.verticalCenter
        }
        spacing: 0
        layoutDirection: Qt.RightToLeft

        BarGroup {
            id: pomodoroGroup
            Layout.alignment: Qt.AlignVCenter
            padding: 8

            PomodoroWidget {
                id: pomodoroWidget
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
