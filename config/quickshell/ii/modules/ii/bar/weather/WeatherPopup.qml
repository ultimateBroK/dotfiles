import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        implicitWidth: Math.max(header.implicitWidth, mainContent.implicitWidth)
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
                Layout.preferredWidth: 280
                Layout.preferredHeight: 80
                radius: Appearance.rounding.medium
                color: Appearance.colors.colSurfaceContainer
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    MaterialSymbol {
                        fill: 0
                        text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
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
        }
        
        // Main Content with Grouped Sections
        ColumnLayout {
            id: mainContent
            spacing: 8

            // Atmospheric Conditions Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                StyledText {
                    text: Translation.tr("Atmospheric Conditions")
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                    Layout.leftMargin: 5
                }
                
                GridLayout {
                    columns: 3
                    rowSpacing: 5
                    columnSpacing: 5
                    uniformCellWidths: true
                    
                    WeatherCard {
                        title: Translation.tr("Temperature")
                        symbol: "device_thermostat"
                        value: Weather.data.heatIndex
                    }
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
                        title: Translation.tr("Pressure")
                        symbol: "readiness_score"
                        value: Weather.data.press
                    }
                    WeatherCard {
                        title: Translation.tr("Cloud Cover")
                        symbol: "cloud"
                        value: Weather.data.cloudCover
                    }
                    WeatherCard {
                        title: Translation.tr("UV Index")
                        symbol: "wb_sunny"
                        value: Weather.data.uv
                    }
                }
            }
            
            // Wind & Precipitation Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                StyledText {
                    text: Translation.tr("Wind & Precipitation")
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                    Layout.leftMargin: 5
                }
                
                GridLayout {
                    columns: 3
                    rowSpacing: 5
                    columnSpacing: 5
                    uniformCellWidths: true
                    
                    WeatherCard {
                        title: Translation.tr("Wind")
                        symbol: "air"
                        value: `${Weather.data.windDir} ${Weather.data.wind}`
                    }
                    WeatherCard {
                        title: Translation.tr("Precipitation")
                        symbol: "rainy_light"
                        value: Weather.data.precip
                    }
                    WeatherCard {
                        title: Translation.tr("Visibility")
                        symbol: "visibility"
                        value: Weather.data.visib
                    }
                }
            }
            
            // Sun & Moon Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                StyledText {
                    text: Translation.tr("Celestial Events")
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                    Layout.leftMargin: 5
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    GridLayout {
                        columns: 2
                        rowSpacing: 5
                        columnSpacing: 5
                        uniformCellWidths: true
                        Layout.fillWidth: true
                        
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
                    
                    GridLayout {
                        columns: 1
                        rowSpacing: 5
                        columnSpacing: 5
                        Layout.fillWidth: true
                        
                        WeatherCard {
                            title: Translation.tr("Moon Phase")
                            symbol: "nights_stay"
                            value: Weather.data.moonPhase
                        }
                    }
                }
                
                GridLayout {
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 5
                    uniformCellWidths: true
                    
                    WeatherCard {
                        title: Translation.tr("Moonrise")
                        symbol: "clear_night"
                        value: Weather.data.moonrise
                    }
                    WeatherCard {
                        title: Translation.tr("Moonset")
                        symbol: "mode_night"
                        value: Weather.data.moonset
                    }
                }
            }
        }
    }
}
