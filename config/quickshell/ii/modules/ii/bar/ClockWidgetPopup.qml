import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    property string formattedDate: Qt.locale("en_US").toString(DateTime.clock.date, "dddd, dd/MM/yyyy")
    property string formattedTime: DateTime.time
    property string formattedUptime: DateTime.uptime
    property var unfinishedTodos: Todo.list.filter(function (item) { return !item.done; })

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 10

        // Date & Time Header
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 280
            Layout.preferredHeight: 80
            radius: Appearance.rounding.medium
            color: Appearance.colors.colSurfaceContainer
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    
                    MaterialSymbol {
                        fill: 0
                        text: "calendar_month"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colPrimary
                    }
                    
                    StyledText {
                        text: root.formattedDate
                        font {
                            pixelSize: Appearance.font.pixelSize.normal
                            weight: Font.Medium
                        }
                        color: Appearance.colors.colOnSurface
                    }
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.formattedTime
                    font {
                        pixelSize: Appearance.font.pixelSize.huge
                        weight: Font.Bold
                    }
                    color: Appearance.colors.colOnSurface
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
