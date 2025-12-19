import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "../sidebarRight/calendar/vn_lunar.js" as LunarVN

StyledPopup {
    id: root
    property string formattedDate: Qt.locale("en_US").toString(DateTime.clock.date, "dddd, dd/MM/yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property var unfinishedTodos: Todo.list.filter(function (item) { return !item.done; })
    
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
    property string specialDayText: {
        const date = DateTime.clock.date;
        return LunarVN.getVietnamSpecialDayEnFromSolar(
            date.getDate(),
            date.getMonth() + 1,
            date.getFullYear(),
            7
        );
    }
    property bool isSpecialDay: specialDayText.length > 0

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 10

        // Date & Time Header
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 280
            Layout.preferredHeight: root.isSpecialDay ? 118 : 88
            radius: Appearance.rounding.medium
            color: Appearance.colors.colSurfaceContainer
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    MaterialSymbol {
                        fill: 0
                        text: "schedule"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        text: root.formattedTime
                        font {
                            pixelSize: Appearance.font.pixelSize.hugeass
                            weight: Font.Bold
                        }
                        color: Appearance.colors.colOnSurface
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    
                    MaterialSymbol {
                        fill: 0
                        text: "calendar_month"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colPrimary
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        
                        StyledText {
                            text: root.formattedDate
                            font {
                                pixelSize: Appearance.font.pixelSize.normal
                                weight: Font.Medium
                            }
                            color: Appearance.colors.colOnSurface
                        }
                        
                        RowLayout {
                            spacing: 4
                            
                            StyledText {
                                text: `Lunar: ${root.lunarDateText}/${root.lunarDate.month}/${root.lunarDate.year}`
                                font {
                                    pixelSize: Appearance.font.pixelSize.smaller
                                    weight: Font.Normal
                                }
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                            
                            StyledText {
                                visible: root.isSpecialDay
                                text: `• ${root.specialDayText}`
                                font {
                                    pixelSize: Appearance.font.pixelSize.smaller
                                    weight: Font.Medium
                                }
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }
                }
            }
        }

        // System Info Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            StyledText {
                text: Translation.tr("System Information")
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.Medium
                }
                color: Appearance.colors.colOnSurfaceVariant
                Layout.leftMargin: 5
            }
            
            StyledPopupValueRow {
                icon: "timelapse"
                label: Translation.tr("System Uptime:")
                value: root.formattedUptime
            }
        }

        // Tasks Section
        ColumnLayout {
            visible: root.unfinishedTodos.length > 0
            Layout.fillWidth: true
            spacing: 6
            
            RowLayout {
                Layout.fillWidth: true
                
                StyledText {
                    text: Translation.tr("Pending Tasks")
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                    Layout.leftMargin: 5
                }
                
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: Appearance.colors.colPrimary
                    
                    StyledText {
                        anchors.centerIn: parent
                        text: root.unfinishedTodos.length.toString()
                        font {
                            pixelSize: Appearance.font.pixelSize.smaller
                            weight: Font.Bold
                        }
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(todoList.implicitHeight + 16, 200)
                radius: Appearance.rounding.small
                color: Appearance.colors.colSurfaceContainerHigh
                
                ColumnLayout {
                    id: todoList
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 4
                    
                    Repeater {
                        model: root.unfinishedTodos.slice(0, 5)
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            
                            MaterialSymbol {
                                fill: 0
                                text: "radio_button_unchecked"
                                iconSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colPrimary
                            }
                            
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.content
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                    
                    StyledText {
                        visible: root.unfinishedTodos.length > 5
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("... and %1 more").arg(root.unfinishedTodos.length - 5)
                        font {
                            pixelSize: Appearance.font.pixelSize.smaller
                            italic: true
                        }
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }
        
        // No tasks message
        Rectangle {
            visible: root.unfinishedTodos.length === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 240
            Layout.preferredHeight: 60
            radius: Appearance.rounding.small
            color: Appearance.colors.colSurfaceContainerHigh
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                
                MaterialSymbol {
                    fill: 1
                    text: "task_alt"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
                
                StyledText {
                    text: Translation.tr("No pending tasks")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }
    }
}
