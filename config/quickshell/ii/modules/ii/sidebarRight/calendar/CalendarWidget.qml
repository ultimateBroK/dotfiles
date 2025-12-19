import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "calendar_layout.js" as CalendarLayout
import "vn_lunar.js" as LunarVN
import QtQuick
import QtQuick.Layouts

Item {
    // Layout.topMargin: 10
    anchors.topMargin: 10
    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
    property var selectedDate: new Date()
    property string selectedSpecialDayName: {
        const d = selectedDate;
        if (!d) return "";
        return LunarVN.getVietnamSpecialDayEnFromSolar(d.getDate(), d.getMonth() + 1, d.getFullYear(), 7);
    }
    property string selectedWeekText: {
        const info = CalendarLayout.getISOWeekInfo(selectedDate);
        return `W${info.week}`;
    }
    width: calendarColumn.width
    implicitHeight: calendarColumn.height + 10 * 2

    onMonthShiftChanged: {
        // Keep the "selected date" in sync so week label is not stale.
        if (monthShift === 0) {
            selectedDate = new Date();
        } else {
            selectedDate = new Date(viewingDate.getFullYear(), viewingDate.getMonth(), 1);
        }
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                monthShift++;
            } else if (event.key === Qt.Key_PageUp) {
                monthShift--;
            }
            event.accepted = true;
        }
    }
    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                monthShift--;
            } else if (event.angleDelta.y < 0) {
                monthShift++;
            }
        }
    }

    ColumnLayout {
        id: calendarColumn
        anchors.centerIn: parent
        spacing: 5

        // Calendar header
        RowLayout {
            Layout.fillWidth: true
            spacing: 5
            CalendarHeaderButton {
                clip: true
                buttonText: `${monthShift != 0 ? "• " : ""}${viewingDate.getMonth() + 1}/${viewingDate.getFullYear()}`
                tooltipText: (monthShift === 0) ? "" : Translation.tr("Jump to current month")
                downAction: () => {
                    monthShift = 0;
                }
            }
            CalendarHeaderButton {
                clip: true
                buttonText: selectedWeekText
                tooltipText: `Week ${CalendarLayout.getISOWeekInfo(selectedDate).week} of ${CalendarLayout.getISOWeekInfo(selectedDate).year}`
                enabled: false
                pointingHandCursor: false
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: false
            }
            CalendarHeaderButton {
                forceCircle: true
                downAction: () => {
                    monthShift--;
                }
                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
            CalendarHeaderButton {
                forceCircle: true
                downAction: () => {
                    monthShift++;
                }
                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Fixed-height caption line (prevents layout jumps)
        StyledText {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            text: selectedSpecialDayName.length > 0 ? `• ${selectedSpecialDayName}` : ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: Appearance.colors.colPrimary
            opacity: selectedSpecialDayName.length > 0 ? 1 : 0
            elide: Text.ElideRight
        }

        // Week days row
        RowLayout {
            id: weekDaysRow
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: false
            spacing: 5
            Repeater {
                model: CalendarLayout.weekDays
                delegate: CalendarDayButton {
                    day: Translation.tr(modelData.day)
                    isToday: modelData.today
                    bold: true
                    enabled: false
                }
            }
        }

        // Real week rows
        Repeater {
            id: calendarRows
            // model: calendarLayout
            model: 6
            delegate: RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: 5
                Repeater {
                    model: Array(7).fill(modelData)
                    delegate: CalendarDayButton {
                        day: calendarLayout[modelData][index].day
                        isToday: calendarLayout[modelData][index].today
                        year: calendarLayout[modelData][index].year
                        month: calendarLayout[modelData][index].month
                        releaseAction: () => {
                            const d = parseInt(day);
                            if (isNaN(d)) return;
                            selectedDate = new Date(year, month - 1, d);
                        }
                    }
                }
            }
        }
    }
}