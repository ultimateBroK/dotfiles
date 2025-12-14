import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.bar
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // Gentle pulsing animation
    property real pulseScale: 1.0
    SequentialAnimation on pulseScale {
        running: Config.options?.adhd?.animations?.enable ?? true
        loops: Animation.Infinite
        NumberAnimation {
            to: 1.03
            duration: 2500
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1.0
            duration: 2500
            easing.type: Easing.InOutSine
        }
    }

    transform: Scale {
        origin.x: rowLayout.width / 2
        origin.y: rowLayout.height / 2
        xScale: root.pulseScale
        yScale: root.pulseScale
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        // Time (sử dụng code gốc từ ClockWidget)
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Bold
            color: Appearance.colors.colPrimary
            text: DateTime.time
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
            text: " • "
        }

        // Date
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
            text: Qt.locale().toString(DateTime.clock.date, Config.options?.time?.shortDateFormat ? "ddd, " + Config.options?.time?.shortDateFormat : "ddd, dd/MM")
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
