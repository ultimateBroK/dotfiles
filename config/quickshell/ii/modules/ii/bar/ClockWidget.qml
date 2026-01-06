import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 0

        RowLayout {
            id: rowLayout
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            // Time
            StyledText {
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Medium
                }
                color: Appearance.colors.colOnLayer1
                text: DateTime.time
            }

            // Separator
            StyledText {
                visible: root.showDate
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
                opacity: 0.6
                text: " • "
            }

            // Date
            StyledText {
                visible: root.showDate
                font {
                    pixelSize: Appearance.font.pixelSize.normal
                    weight: Font.Normal
                }
                color: Appearance.colors.colOnLayer1
                // Use a more compact weekday + day/month format (no year)
                // Use en_US locale to display weekday in English (Tue, Wed, etc.)
                text: Qt.locale("en_US").toString(DateTime.clock.date, Config.options?.time?.shortDateFormat ? "ddd, " + Config.options?.time?.shortDateFormat : "ddd, dd/MM")
            }
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
