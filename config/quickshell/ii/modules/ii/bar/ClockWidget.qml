import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "../sidebarRight/calendar/vn_lunar.js" as LunarVN

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: mainLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    // Calculate lunar date
    property var lunarDate: {
        const date = DateTime.clock.date;
        const day = date.getDate();
        const month = date.getMonth() + 1;
        const year = date.getFullYear();
        return LunarVN.solar2lunar(day, month, year, 7);
    }
    property string lunarDateText: {
        if (lunarDate.day === 1) {
            return `${lunarDate.day}/${lunarDate.month}`;
        }
        return lunarDate.day.toString();
    }
    property bool isSpecialDay: {
        const day = lunarDate.day;
        const month = lunarDate.month;
        
        // Tết Nguyên Đán - mùng 1 tháng 1
        if (day === 1 && month === 1) return true;
        // Tết Nguyên Tiêu - rằm tháng 1
        if (day === 15 && month === 1) return true;
        // Giỗ Tổ Hùng Vương - 10/3
        if (day === 10 && month === 3) return true;
        // Lễ Phật Đản - rằm tháng 4
        if (day === 15 && month === 4) return true;
        // Tết Đoan Ngọ - 5/5
        if (day === 5 && month === 5) return true;
        // Rằm tháng 7 (Vu Lan)
        if (day === 15 && month === 7) return true;
        // Tết Trung Thu - rằm tháng 8
        if (day === 15 && month === 8) return true;
        // Tết Ông Táo - 23/12
        if (day === 23 && month === 12) return true;
        // Giao thừa - 30/12 (hoặc 29 nếu tháng thiếu)
        if ((day === 30 || day === 29) && month === 12) return true;
        // Mùng 1 và rằm các tháng khác
        if (day === 1 || day === 15) return true;
        
        return false;
    }
    property string specialDayText: {
        const day = lunarDate.day;
        const month = lunarDate.month;
        
        // Tết Nguyên Đán - mùng 1 tháng 1
        if (day === 1 && month === 1) return "Lunar New Year";
        // Tết Nguyên Tiêu - rằm tháng 1
        if (day === 15 && month === 1) return "Lantern Festival";
        // Giỗ Tổ Hùng Vương - 10/3
        if (day === 10 && month === 3) return "Hung Kings";
        // Lễ Phật Đản - rằm tháng 4
        if (day === 15 && month === 4) return "Buddha's Birthday";
        // Tết Đoan Ngọ - 5/5
        if (day === 5 && month === 5) return "Dragon Boat";
        // Rằm tháng 7 (Vu Lan)
        if (day === 15 && month === 7) return "Ghost Festival";
        // Tết Trung Thu - rằm tháng 8
        if (day === 15 && month === 8) return "Mid-Autumn";
        // Tết Ông Táo - 23/12
        if (day === 23 && month === 12) return "Kitchen God";
        // Giao thừa - 30/12
        if (day === 30 && month === 12) return "New Year's Eve";
        // Giao thừa - 29/12 (nếu tháng thiếu)
        if (day === 29 && month === 12) return "New Year's Eve";
        // Mùng 1 các tháng khác
        if (day === 1) return "New Moon";
        // Rằm các tháng khác
        if (day === 15) return "Full Moon";
        
        return "";
    }

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

        // Lunar date and special day (compact display)
        RowLayout {
            visible: root.showDate
            Layout.alignment: Qt.AlignHCenter
            spacing: 3
            Layout.topMargin: 1

            StyledText {
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.Normal
                }
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
                text: `Lunar: ${root.lunarDateText}/${root.lunarDate.month}`
            }

            StyledText {
                visible: root.isSpecialDay
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.Medium
                }
                color: Appearance.colors.colPrimary
                text: `• ${root.specialDayText}`
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
