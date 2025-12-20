import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root
    readonly property int popupWidth: 400
    readonly property int maxContentHeight: 560
    readonly property int maxWarningsToShow: 4

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        implicitWidth: root.popupWidth
        spacing: 10

        // Header - Location and Main Weather
        ColumnLayout {
            id: header
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                MaterialSymbol {
                    fill: 0
                    font.weight: Font.Medium
                    text: "location_on"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: Weather.data.city
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
            
            // Main Weather Display
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.popupWidth
                Layout.preferredHeight: 80
                radius: Appearance.rounding.large
                color: Appearance.colors.colSurfaceContainer
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    MaterialSymbol {
                        fill: 0
                        text: Icons.getWeatherIcon(Weather.data.weatherCode, Weather.data.isDay) ?? "cloud"
                        iconSize: 48
                        color: Appearance.colors.colPrimary
                    }
                    
                    ColumnLayout {
                        spacing: 2
                        
                        StyledText {
                            text: Weather.data.temp
                            font {
                                pixelSize: Appearance.font.pixelSize.huge
                                weight: Font.Bold
                            }
                            color: Appearance.colors.colOnSurface
                        }
                        
                        StyledText {
                            text: Weather.data.weatherDesc
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                        
                        StyledText {
                            text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike)
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }

            // Quick meta row
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                StyledText {
                    text: `${Translation.tr("H")} ${Weather.data.tempMax}  ${Translation.tr("L")} ${Weather.data.tempMin}`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    visible: Weather.lastUpdated !== ""
                    text: `${Translation.tr("Updated")} ${Weather.lastUpdated}`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }

        // Warnings (global hazard heuristics)
        Rectangle {
            visible: Weather.warnings && Weather.warnings.length > 0
            Layout.fillWidth: true
            Layout.preferredWidth: root.popupWidth
            implicitHeight: warningContent.implicitHeight + 20
            Layout.preferredHeight: implicitHeight
            radius: Appearance.rounding.small
            color: Appearance.colors.colSurfaceContainerHigh
            border.width: 1
            border.color: warningHeader.anyDanger ? Appearance.colors.colError : Appearance.colors.colSecondary

            ColumnLayout {
                id: warningContent
                anchors.margins: 10
                anchors.fill: parent
                spacing: 6

                RowLayout {
                    id: warningHeader
                    spacing: 6
                    readonly property bool anyDanger: {
                        const arr = Weather.warnings || [];
                        for (let i = 0; i < arr.length; i++) {
                            if ((arr[i].severityLevel ?? 0) >= 2) return true;
                            if (String(arr[i].severity || "").toLowerCase() === "danger") return true;
                        }
                        return false;
                    }
                    MaterialSymbol {
                        fill: 0
                        text: "warning"
                        iconSize: Appearance.font.pixelSize.normal
                        color: warningHeader.anyDanger ? Appearance.colors.colError : Appearance.colors.colSecondary
                    }
                    StyledText {
                        text: "Nearby alerts"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurface
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                Repeater {
                    model: (Weather.warnings || []).slice(0, root.maxWarningsToShow)
                    Rectangle {
                        Layout.fillWidth: true
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colSurfaceContainer
                        border.width: 1
                        border.color: (modelData.severityLevel ?? 0) >= 2 ? Appearance.colors.colError : Appearance.colors.colSecondary
                        implicitHeight: warningItemContent.implicitHeight + 14

                        RowLayout {
                            id: warningItemContent
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 4
                                Layout.fillHeight: true
                                radius: 2
                                color: (modelData.severityLevel ?? 0) >= 2 ? Appearance.colors.colError : Appearance.colors.colSecondary
                            }

                            MaterialSymbol {
                                fill: 0
                                text: modelData.icon || "warning"
                                iconSize: Appearance.font.pixelSize.normal
                                color: (modelData.severityLevel ?? 0) >= 2 ? Appearance.colors.colError : Appearance.colors.colSecondary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.title || "Alert"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnSurface
                                        wrapMode: Text.WordWrap
                                    }

                                    Rectangle {
                                        radius: 999
                                        color: (modelData.severityLevel ?? 0) >= 2 ? Appearance.colors.colError : Appearance.colors.colSecondary
                                        Layout.preferredHeight: 18
                                        Layout.preferredWidth: severityLabel.implicitWidth + 10
                                        opacity: 0.9
                                        StyledText {
                                            id: severityLabel
                                            anchors.centerIn: parent
                                            text: (modelData.severity || "").toUpperCase()
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                }

                                StyledText {
                                    visible: modelData.timeRange && modelData.timeRange.length > 0
                                    Layout.fillWidth: true
                                    text: modelData.timeRange
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSurfaceVariant
                                    wrapMode: Text.WordWrap
                                }

                                StyledText {
                                    visible: modelData.details && modelData.details.length > 0
                                    Layout.fillWidth: true
                                    text: modelData.details
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSurfaceVariant
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                StyledText {
                    visible: (Weather.warnings || []).length > root.maxWarningsToShow
                    text: `+${(Weather.warnings || []).length - root.maxWarningsToShow} more`
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
        }

        // Scrollable main content (keeps popup compact)
        Flickable {
            id: scroll
            Layout.preferredWidth: root.popupWidth
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentColumn.implicitHeight, root.maxContentHeight)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: contentColumn.implicitHeight

            ColumnLayout {
                id: contentColumn
                width: scroll.width
                spacing: 10

                // Quick hourly glance
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        text: Translation.tr("Next hours")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.leftMargin: 5
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colSurfaceContainerHigh
                        Layout.preferredHeight: hourlyGrid.implicitHeight + 16

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 0

                            GridLayout {
                                id: hourlyGrid
                                columns: 5
                                columnSpacing: 6
                                rowSpacing: 6
                                Layout.fillWidth: true

                                Repeater {
                                    // Show 10 hours total => 2 rows, 5 items each row
                                    model: (Weather.hourly || []).slice(0, 10)
                                    Rectangle {
                                        radius: Appearance.rounding.normal
                                        color: Appearance.colors.colSurfaceContainer
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 90
                                        Layout.minimumWidth: 60

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 4

                                            StyledText {
                                                text: modelData.timeLabel
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                color: Appearance.colors.colOnSurfaceVariant
                                                horizontalAlignment: Text.AlignHCenter
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.fillWidth: true
                                            }
                                            MaterialSymbol {
                                                fill: 0
                                                text: Icons.getWeatherIcon(modelData.code, modelData.isDay)
                                                iconSize: 25
                                                color: Appearance.colors.colPrimary
                                                Layout.alignment: Qt.AlignHCenter
                                            }
                                            StyledText {
                                                text: modelData.temp
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                font.weight: Font.Medium
                                                color: Appearance.colors.colOnSurface
                                                horizontalAlignment: Text.AlignHCenter
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Now / atmospheric
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        text: Translation.tr("Now")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.leftMargin: 5
                    }

                    GridLayout {
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6
                        uniformCellWidths: true
                        Layout.fillWidth: true

                        WeatherCard {
                            title: Translation.tr("Humidity")
                            symbol: "humidity_low"
                            value: Weather.data.humidity
                        }
                        WeatherCard {
                            title: Translation.tr("Dew Point")
                            symbol: "water_drop"
                            value: Weather.data.dewPoint
                        }
                        WeatherCard {
                            title: Translation.tr("UV")
                            symbol: "wb_sunny"
                            value: Weather.data.uv
                        }
                        WeatherCard {
                            title: Translation.tr("Pressure")
                            symbol: "speed"
                            value: Weather.data.press
                        }
                        WeatherCard {
                            title: Translation.tr("Cloud")
                            symbol: "cloud"
                            value: Weather.data.cloudCover
                        }
                        WeatherCard {
                            title: Translation.tr("Visibility")
                            symbol: "visibility"
                            value: Weather.data.visib
                        }
                    }
                }

                // Wind & Rain
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        text: Translation.tr("Wind & Rain")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                        Layout.leftMargin: 5
                    }

                    GridLayout {
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6
                        uniformCellWidths: true
                        Layout.fillWidth: true

                        WeatherCard {
                            title: Translation.tr("Wind")
                            symbol: "air"
                            value: `${Weather.data.windDir} ${Weather.data.wind}`
                        }
                        WeatherCard {
                            title: Translation.tr("Gust")
                            symbol: "cyclone"
                            value: Weather.data.gust
                        }
                        WeatherCard {
                            title: Translation.tr("Rain")
                            symbol: "rainy_light"
                            value: Weather.data.precip
                        }
                        WeatherCard {
                            title: Translation.tr("Rain chance")
                            symbol: "umbrella"
                            value: Weather.data.precipProb
                        }
                        WeatherCard {
                            title: Translation.tr("Sunrise")
                            symbol: "wb_twilight"
                            value: Weather.data.sunrise
                        }
                        WeatherCard {
                            title: Translation.tr("Sunset")
                            symbol: "bedtime"
                            value: Weather.data.sunset
                        }
                    }
                }

                // (7-day forecast removed by request)
            }
        }
    }
}
