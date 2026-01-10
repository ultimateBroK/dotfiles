import qs.modules.ii.bar
import qs.modules.ii.bar.weather
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

    // Left side: DateTime and Weather (far left)
    RowLayout {
        id: leftSection
        anchors {
            left: parent.left
            leftMargin: Appearance.rounding.screenRounding
            verticalCenter: parent.verticalCenter
        }
        spacing: 10

        // DateTime Widget (using default ClockWidget)
        BarGroup {
            id: dateTimeGroup
            Layout.alignment: Qt.AlignVCenter
            padding: 8

            ClockWidget {
                id: dateTimeWidget
                showDate: Config.options.bar.verbose
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Weather Widget (using default WeatherBar)
        BarGroup {
            id: weatherGroup
            Layout.alignment: Qt.AlignVCenter
            visible: Config.options.bar.weather.enable
            padding: 8

            WeatherBar {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Middle section: Media Player (centered)
    Item {
        id: middleSection
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        width: Math.max(300, Math.min(400, parent.width - leftSection.implicitWidth - rightSection.implicitWidth - 40))
        implicitHeight: Appearance.sizes.barHeight

        BarGroup {
            id: mediaGroup
            anchors.fill: parent
            padding: 8

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Media Widget (using default Media component)
                Media {
                    id: mediaWidget
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
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
