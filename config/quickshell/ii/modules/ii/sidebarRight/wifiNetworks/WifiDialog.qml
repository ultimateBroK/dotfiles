import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 600
    
    // Logic: Check if there's an active wifi connection
    property bool hasActiveConnection: Network.active !== null && Network.wifiEnabled
    property string activeNetworkName: Network.active?.ssid ?? ""
    property int activeNetworkStrength: Network.active?.strength ?? 0

    WindowDialogTitle {
        text: Translation.tr("Wi-Fi")
    }
    
    // Current connection status - only show when actually connected
    Rectangle {
        visible: root.hasActiveConnection && root.activeNetworkName.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: currentWifiLayout.implicitHeight + 16
        Layout.topMargin: -10
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainer
        
        RowLayout {
            id: currentWifiLayout
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 10
            
            MaterialSymbol {
                text: {
                    const strength = root.activeNetworkStrength;
                    if (strength > 80) return "signal_wifi_4_bar";
                    if (strength > 60) return "network_wifi";
                    if (strength > 40) return "network_wifi_3_bar";
                    if (strength > 20) return "network_wifi_2_bar";
                    return "network_wifi_1_bar";
                }
                iconSize: 28
                color: Appearance.colors.colPrimary
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    text: root.activeNetworkName
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    spacing: 6
                    
                    StyledText {
                        text: Translation.tr("Connected")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colPrimary
                    }
                    
                    StyledText {
                        text: "•"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    
                    StyledText {
                        text: Translation.tr("%1% signal").arg(root.activeNetworkStrength)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }
            }
            
            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: Appearance.colors.colPrimary
            }
        }
    }
    
    // Connecting status
    Rectangle {
        visible: Network.wifiConnecting && Network.wifiConnectTarget !== null
        Layout.fillWidth: true
        Layout.preferredHeight: connectingLayout.implicitHeight + 16
        Layout.topMargin: -10
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainer
        
        RowLayout {
            id: connectingLayout
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 10
            
            MaterialSymbol {
                text: "signal_wifi_statusbar_not_connected"
                iconSize: 28
                color: Appearance.colors.colTertiary
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    text: Network.wifiConnectTarget?.ssid ?? Translation.tr("Connecting...")
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurface
                }
                
                StyledText {
                    text: Translation.tr("Connecting...")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colTertiary
                }
            }
            
            StyledIndeterminateProgressBar {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }
        }
    }
    
    WindowDialogSeparator {
        visible: !Network.wifiScanning
    }
    StyledIndeterminateProgressBar {
        visible: Network.wifiScanning
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }
    // Cache sorted networks to avoid sorting on every render
    property var sortedNetworks: {
        const networks = Network.wifiNetworks;
        // Create a copy and sort
        return [...networks].sort((a, b) => {
            // Active networks first
            if (a.active && !b.active) return -1;
            if (!a.active && b.active) return 1;
            // Then by signal strength (descending)
            return b.strength - a.strength;
        });
    }

    Connections {
        target: Network
        function onWifiNetworksChanged() {
            // Update sorted list when networks change
            root.sortedNetworks = [...Network.wifiNetworks].sort((a, b) => {
                if (a.active && !b.active) return -1;
                if (!a.active && b.active) return 1;
                return b.strength - a.strength;
            });
        }
    }

    ListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0

        model: ScriptModel {
            values: root.sortedNetworks
        }
        delegate: WifiNetworkItem {
            required property WifiAccessPoint modelData
            wifiNetwork: modelData
            anchors {
                left: parent?.left
                right: parent?.right
            }
        }
    }
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}