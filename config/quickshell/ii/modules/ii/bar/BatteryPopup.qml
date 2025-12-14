import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root
    
    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 10

        // Header with Battery Icon and Percentage
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 80
                radius: Appearance.rounding.medium
                color: Appearance.colors.colSurfaceContainer
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    MaterialSymbol {
                        fill: 1
                        text: {
                            if (Battery.chargeState == 4) return "battery_full";
                            if (Battery.isCharging) return "battery_charging_full";
                            if (Battery.percentage > 0.8) return "battery_full";
                            if (Battery.percentage > 0.5) return "battery_5_bar";
                            if (Battery.percentage > 0.3) return "battery_3_bar";
                            if (Battery.percentage > 0.1) return "battery_2_bar";
                            return "battery_1_bar";
                        }
                        iconSize: 48
                        color: {
                            if (Battery.percentage <= 0.1) return Appearance.colors.colError;
                            if (Battery.percentage <= 0.3) return Appearance.colors.colWarning;
                            if (Battery.isCharging) return Appearance.colors.colPrimary;
                            return Appearance.colors.colOnSurface;
                        }
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        
                        StyledText {
                            text: `${Math.round(Battery.percentage * 100)}%`
                            font {
                                pixelSize: Appearance.font.pixelSize.huge
                                weight: Font.Bold
                            }
                            color: Appearance.colors.colOnSurface
                        }
                        
                        StyledText {
                            text: {
                                if (Battery.chargeState == 4) return Translation.tr("Fully Charged");
                                if (Battery.isCharging) return Translation.tr("Charging");
                                return Translation.tr("Discharging");
                            }
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }

        // Battery Details Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            
            StyledText {
                text: Translation.tr("Battery Details")
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.Medium
                }
                color: Appearance.colors.colOnSurfaceVariant
                Layout.leftMargin: 5
            }
            
            ColumnLayout {
                spacing: 4
                
                StyledPopupValueRow {
                    visible: {
                        let timeValue = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                        let power = Battery.energyRate;
                        return !(Battery.chargeState == 4 || timeValue <= 0 || power <= 0.01);
                    }
                    icon: "schedule"
                    label: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:")
                    value: {
                        function formatTime(seconds) {
                            var h = Math.floor(seconds / 3600);
                            var m = Math.floor((seconds % 3600) / 60);
                            if (h > 0)
                                return `${h}h ${m}m`;
                            else
                                return `${m}m`;
                        }
                        if (Battery.isCharging)
                            return formatTime(Battery.timeToFull);
                        else
                            return formatTime(Battery.timeToEmpty);
                    }
                }

                StyledPopupValueRow {
                    visible: !(Battery.chargeState != 4 && Battery.energyRate == 0)
                    icon: "bolt"
                    label: Translation.tr("Power:")
                    value: Battery.chargeState == 4 ? "--" : `${Battery.energyRate.toFixed(2)} W`
                }

                StyledPopupValueRow {
                    icon: "heart_check"
                    label: Translation.tr("Battery Health:")
                    value: `${Battery.health.toFixed(1)}%`
                }
            }
        }
    }
}
