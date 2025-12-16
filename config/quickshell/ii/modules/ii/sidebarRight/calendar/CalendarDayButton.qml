import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import "vn_lunar.js" as LunarVN

RippleButton {
    id: button
    property string day
    property int isToday
    property bool bold
    // Full Gregorian date for this cell (needed for lunar conversion)
    property int year: 0
    property int month: 0

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38; 
    implicitHeight: 38;

    toggled: (isToday == 1)
    buttonRadius: Appearance.rounding.small
    
    contentItem: Column {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 0
        StyledText {
            id: solarDateText
            anchors.horizontalCenter: parent.horizontalCenter
            text: day
            horizontalAlignment: Text.AlignHCenter
            font.weight: bold ? Font.DemiBold : Font.Normal
            color: (isToday == 1) ? Appearance.m3colors.m3onPrimary : 
                (isToday == 0) ? Appearance.colors.colOnLayer1 : 
                Appearance.colors.colOutlineVariant
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
        // Vietnamese lunar day (Âm lịch) - small secondary text
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: year > 0 && month > 0
            // 20% smaller than solar date (80% of solar date size)
            font.pixelSize: solarDateText.font.pixelSize * 0.8
            color: {
                if (isToday == 1) return Appearance.m3colors.m3onPrimary;

                // Highlight important lunar days (mùng 1 & rằm 15)
                if (year > 0 && month > 0) {
                    const solarDay = parseInt(day);
                    if (!isNaN(solarDay)) {
                        const lunar = LunarVN.solar2lunar(solarDay, month, year, 7);
                        if (lunar.day === 1 || lunar.day === 15) {
                            return Appearance.colors.colPrimary;
                        }
                    }
                }
                return Appearance.colors.colOnLayer3;
            }
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (year <= 0 || month <= 0) return "";
                const solarDay = parseInt(day);
                if (isNaN(solarDay)) return "";
                const lunar = LunarVN.solar2lunar(solarDay, month, year, 7);
                // Format: show day/month for first day of lunar month, otherwise only day
                if (lunar.day === 1) {
                    return `${lunar.day}/${lunar.month}`;
                }
                return lunar.day.toString();
            }
        }
    }
}

