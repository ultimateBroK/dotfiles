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
                    
                    Item {
                        id: batteryIcon
                        width: 72
                        height: 48

                        // clamp percent to [0,1] and guard against invalid values
                        property real percent: (Battery.percentage === undefined || isNaN(Battery.percentage)) ? 0 : Math.max(0, Math.min(1, Battery.percentage))
                        property bool charging: Battery.isCharging
                        // consider battery full either by charge state or near-100% reading
                        property bool full: (Battery.chargeState == 4) || (percent >= 0.995)

                        Rectangle {
                            id: body
                            anchors.centerIn: parent
                            width: 56
                            height: 32
                            radius: 6
                            color: Appearance.colors.colSurface
                            border.color: Appearance.colors.colOnSurfaceVariant
                            border.width: 1

                            // positive terminal / tip
                            Rectangle {
                                id: tip
                                width: 6
                                height: body.height * 0.5
                                radius: 2
                                color: Appearance.colors.colOnSurfaceVariant
                                anchors.left: body.right
                                anchors.verticalCenter: body.verticalCenter
                                anchors.leftMargin: 6
                            }

                            // dynamic fill
                            Rectangle {
                                id: fill
                                x: 4
                                y: 4
                                height: body.height - 8
                                width: Math.max(4, (body.width - 8) * percent)
                                radius: 4
                                color: {
                                    if (full) return Appearance.colors.colPrimary;
                                    if (charging) return Appearance.colors.colPrimary;
                                    if (percent <= 0.1) return Appearance.colors.colError;
                                    if (percent <= 0.3) return Appearance.colors.colWarning;
                                    return Appearance.colors.colPrimary;
                                }
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }

                            // percentage text centered inside the battery
                            StyledText {
                                id: pct
                                text: `${Math.round(percent * 100)}%`
                                anchors.verticalCenter: body.verticalCenter
                                anchors.horizontalCenter: body.horizontalCenter
                                color: (fill.width > body.width * 0.45) ? Appearance.colors.colOnSurface : Appearance.colors.colOnSurface
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            // charging bolt overlay
                            MaterialSymbol {
                                id: bolt
                                text: charging ? "bolt" : ""
                                iconSize: 18
                                anchors.right: body.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: body.verticalCenter
                                color: "white"
                                opacity: charging ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }

                                SequentialAnimation on y {
                                    running: charging
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0; to: -6; duration: 600; easing.type: Easing.InOutQuad }
                                    NumberAnimation { from: -6; to: 0; duration: 600; easing.type: Easing.InOutQuad }
                                }
                            }

                            // low-battery pulsing overlay
                            Rectangle {
                                id: lowOverlay
                                anchors.fill: body
                                color: Appearance.colors.colError
                                opacity: (percent <= 0.1 && !charging) ? 0.12 : 0

                                SequentialAnimation on opacity {
                                    id: lowPulse
                                    running: (percent <= 0.1 && !charging)
                                    loops: Animation.Infinite
                                    PropertyAnimation { to: 0.22; duration: 700; easing.type: Easing.InOutQuad }
                                    PropertyAnimation { to: 0.08; duration: 700; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        
                        StyledText {
                            text: `${Math.round(batteryIcon.percent * 100)}%`
                            font {
                                pixelSize: Appearance.font.pixelSize.huge
                                weight: Font.Bold
                            }
                            color: Appearance.colors.colOnSurface
                        }
                        
                        StyledText {
                            text: {
                                if (batteryIcon.full) return Translation.tr("Fully Charged");
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
                        return (timeValue > 0) && !batteryIcon.full;
                    }
                    icon: "schedule"
                    label: Battery.isCharging ? Translation.tr("Time to full:") : Translation.tr("Time to empty:")
                    value: {
                        function formatTime(seconds) {
                            if (!seconds || seconds <= 0) return "--";
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
                    visible: (Battery.chargeState == 4) || (Number.isFinite(Battery.energyRate) && Battery.energyRate != 0)
                    icon: "bolt"
                    label: Translation.tr("Power:")
                    value: Battery.chargeState == 4 ? "--" : (Number.isFinite(Battery.energyRate) ? `${Battery.energyRate.toFixed(2)} W` : "--")
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
