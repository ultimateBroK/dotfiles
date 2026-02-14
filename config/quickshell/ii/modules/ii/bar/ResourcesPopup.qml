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
    
    function formatTempC(tempC) {
        return Number.isFinite(tempC) ? `${tempC.toFixed(0)}°C` : "--";
    }

    function formatGpuName(name) {
        const s = String(name || "");
        if (s.length <= 24) return s;
        return s.slice(0, 24) + "…";
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10
        implicitWidth: 400
        
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

        // Resources in Cards (order matches topbar)
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignHCenter

            // RAM Card
            Rectangle {
                visible: Config.options.bar.resources.showMemory
                Layout.preferredWidth: 120
                Layout.preferredHeight: 110
                radius: Appearance.rounding.large
                color: Qt.rgba(1, 1, 1, 0.05)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        fill: 1
                        text: "memory"
                        iconSize: 30
                        color: Appearance.colors.colTertiary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("RAM")
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

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${root.formatKB(ResourceUsage.memoryUsed)} / ${root.formatKB(ResourceUsage.memoryTotal)}`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }

            // GPU Card (if available)
            Rectangle {
                visible: Config.options.bar.resources.showGpu && ResourceUsage.gpuAvailable
                Layout.preferredWidth: 120
                Layout.preferredHeight: 110
                radius: Appearance.rounding.large
                color: Qt.rgba(1, 1, 1, 0.05)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        fill: 1
                        text: "developer_board"
                        iconSize: 30
                        color: Appearance.colors.colSecondary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("GPU")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${Math.round(ResourceUsage.gpuUsage * 100)}%`
                        font {
                            pixelSize: Appearance.font.pixelSize.large
                            weight: Font.Bold
                        }
                        color: Appearance.colors.colOnSurface
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.formatTempC(ResourceUsage.gpuTempC)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }

            // CPU Card
            Rectangle {
                visible: Config.options.bar.resources.showCpu
                Layout.preferredWidth: 120
                Layout.preferredHeight: 110
                radius: Appearance.rounding.large
                color: Qt.rgba(1, 1, 1, 0.05)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        fill: 1
                        text: "planner_review"
                        iconSize: 30
                        color: Appearance.colors.colPrimary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("CPU")
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

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.formatTempC(ResourceUsage.cpuTempC)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
        }
        
        // Detailed Information Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            StyledText {
                text: Translation.tr("Details")
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
                    visible: Config.options.bar.resources.showMemory
                }
                
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("RAM Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                    visible: Config.options.bar.resources.showMemory
                }
                
                StyledPopupValueRow {
                    visible: Config.options.bar.resources.showSwap && ResourceUsage.swapTotal > 0
                    icon: "swap_horiz"
                    label: Translation.tr("Swap Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                
                StyledPopupValueRow {
                    visible: Config.options.bar.resources.showSwap && ResourceUsage.swapTotal > 0
                    icon: "check_circle"
                    label: Translation.tr("Swap Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }

                StyledPopupValueRow {
                    icon: "thermostat"
                    label: Translation.tr("CPU Temp:")
                    value: root.formatTempC(ResourceUsage.cpuTempC)
                    visible: Config.options.bar.resources.showCpu
                }

                StyledPopupValueRow {
                    visible: Config.options.bar.resources.showGpu && ResourceUsage.gpuAvailable
                    icon: "thermostat"
                    label: Translation.tr("GPU Temp:")
                    value: root.formatTempC(ResourceUsage.gpuTempC)
                }

                StyledPopupValueRow {
                    visible: Config.options.bar.resources.showGpu && ResourceUsage.gpuAvailable && (ResourceUsage.gpuName.length > 0)
                    icon: "developer_board"
                    label: Translation.tr("GPU:")
                    value: root.formatGpuName(ResourceUsage.gpuName)
                }
            }
        }
    }
}
