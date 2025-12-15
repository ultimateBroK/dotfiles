import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    implicitWidth: pomodoroContent.implicitWidth + 16
    implicitHeight: Appearance.sizes.barHeight

    readonly property var pomodoro: PomodoroService
    readonly property bool isRunning: pomodoro.running
    readonly property string timeText: pomodoro.formattedTime
    readonly property string phaseText: pomodoro.phaseName

    MouseArea {
        id: pomodoroMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // Chuột trái -> mở/đóng cửa sổ Pomodoro (giống media widget)
                GlobalStates.pomodoroMenuOpen = !GlobalStates.pomodoroMenuOpen
            } else if (mouse.button === Qt.RightButton) {
                // Chuột phải -> bắt đầu/tạm dừng timer
                pomodoro.toggleTimer()
            } else if (mouse.button === Qt.MiddleButton) {
                // Chuột giữa -> skip session
                pomodoro.skipToNextPhase()
            }
        }
    }

    // Hiển thị trên 1 hàng
    RowLayout {
        id: pomodoroContent
        anchors.centerIn: parent
        spacing: 8

        // Phase indicator với color coding
        Rectangle {
            id: phaseIndicator
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 10
            implicitHeight: 10
            radius: 5
            color: {
                if (pomodoro.currentPhase === PomodoroService.Phase.Work)
                    return Appearance.colors.colError
                else if (pomodoro.currentPhase === PomodoroService.Phase.LongBreak)
                    return Appearance.colors.colPrimary
                return Appearance.colors.colSecondary
            }

            SequentialAnimation on opacity {
                running: isRunning && (Config.options?.adhd?.animations?.enable ?? true)
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 800 }
                NumberAnimation { to: 1.0; duration: 800 }
            }
        }

        // Timer và phase trên cùng 1 hàng
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
            text: timeText
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
            text: "(" + phaseText + ")"
        }

        // Play/Pause icon
        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: isRunning ? "pause_circle" : "play_circle"
            iconSize: Appearance.font.pixelSize.large
            color: isRunning ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
        }
    }
}
