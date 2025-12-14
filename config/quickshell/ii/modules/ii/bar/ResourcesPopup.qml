import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }
    
    function getUsagePercent(used, total) {
        if (total <= 0) return 0;
        return ((used / total) * 100).toFixed(1);
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10
        
        // Header
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("System Resources")
            font {
                pixelSize: Appearance.font.pixelSize.normal
                weight: Font.Medium
            }
            color: Appearance.colors.colOnSurfaceVariant
        }

        // Resources in Cards
        RowLayout {
            spacing: 8
            
            // CPU Card
            Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 100
                radius: Appearance.rounding.medium
                color: Appearance.colors.colSurfaceContainer
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        fill: 1
                        text: "memory_alt"
                        iconSize: 32
                        color: Appearance.colors.colPrimary
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "CPU"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                        font {
                            pixelSize: Appearance.font.pixelSize.large
                            weight: Font.Bold
                        }
                        color: Appearance.colors.colOnSurface
                    }
                }
            }
            
            // RAM Card
            Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 100
                radius: Appearance.rounding.medium
                color: Appearance.colors.colSurfaceContainer
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        fill: 1
                        text: "memory"
                        iconSize: 32
                        color: Appearance.colors.colTertiary
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "RAM"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${root.getUsagePercent(ResourceUsage.memoryUsed, ResourceUsage.memoryTotal)}%`
                        font {
                            pixelSize: Appearance.font.pixelSize.large
                            weight: Font.Bold
                        }
                        color: Appearance.colors.colOnSurface
                    }
                }
            }
            
            // Swap Card (if available)
            Rectangle {
                visible: ResourceUsage.swapTotal > 0
                Layout.preferredWidth: 120
                Layout.preferredHeight: 100
                radius: Appearance.rounding.medium
                color: Appearance.colors.colSurfaceContainer
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        fill: 1
                        text: "swap_horiz"
                        iconSize: 32
                        color: Appearance.colors.colSecondary
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Swap"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${root.getUsagePercent(ResourceUsage.swapUsed, ResourceUsage.swapTotal)}%`
                        font {
                            pixelSize: Appearance.font.pixelSize.large
                            weight: Font.Bold
                        }
                        color: Appearance.colors.colOnSurface
                    }
                }
            }
        }
        
        // Detailed Information Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            StyledText {
                text: Translation.tr("Memory Details")
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.Medium
                }
                color: Appearance.colors.colOnSurfaceVariant
                Layout.leftMargin: 5
            }
            
            GridLayout {
                columns: 2
                rowSpacing: 4
                columnSpacing: 10
                
                StyledPopupValueRow {
                    icon: "memory"
                    label: Translation.tr("RAM Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }
                
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("RAM Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }
                
                StyledPopupValueRow {
                    visible: ResourceUsage.swapTotal > 0
                    icon: "swap_horiz"
                    label: Translation.tr("Swap Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                
                StyledPopupValueRow {
                    visible: ResourceUsage.swapTotal > 0
                    icon: "check_circle"
                    label: Translation.tr("Swap Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }
            }
        }
    }
}
