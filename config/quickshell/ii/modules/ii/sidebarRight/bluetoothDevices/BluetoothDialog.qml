import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    backgroundHeight: 600
    
    // Logic: Get connected devices with proper null checks
    property var connectedDevices: {
        if (!Bluetooth.devices || !Bluetooth.devices.values) return [];
        return [...Bluetooth.devices.values].filter(d => d && d.connected);
    }
    property bool hasConnectedDevices: root.connectedDevices.length > 0
    property bool bluetoothEnabled: Bluetooth.defaultAdapter?.enabled ?? false

    WindowDialogTitle {
        text: Translation.tr("Bluetooth")
    }
    
    // Bluetooth disabled warning
    Rectangle {
        visible: !root.bluetoothEnabled
        Layout.fillWidth: true
        Layout.preferredHeight: disabledLayout.implicitHeight + 16
        Layout.topMargin: -10
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        radius: Appearance.rounding.small
        color: Appearance.colors.colErrorContainer
        
        RowLayout {
            id: disabledLayout
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 10
            
            MaterialSymbol {
                text: "bluetooth_disabled"
                iconSize: 28
                color: Appearance.colors.colOnErrorContainer
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    text: Translation.tr("Bluetooth is Off")
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnErrorContainer
                }
                
                StyledText {
                    text: Translation.tr("Tap to enable")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnErrorContainer
                }
            }
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Bluetooth.defaultAdapter.enabled = true
        }
    }
    
    // Connected devices summary - only show when bluetooth enabled AND has connected devices
    Rectangle {
        visible: root.bluetoothEnabled && root.hasConnectedDevices
        Layout.fillWidth: true
        Layout.preferredHeight: connectedLayout.implicitHeight + 16
        Layout.topMargin: -10
        Layout.leftMargin: 0
        Layout.rightMargin: 0
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainer
        
        RowLayout {
            id: connectedLayout
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 10
            
            MaterialSymbol {
                text: "bluetooth_connected"
                iconSize: 28
                color: Appearance.colors.colPrimary
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    text: {
                        if (root.connectedDevices.length === 0) return "";
                        if (root.connectedDevices.length === 1) {
                            return root.connectedDevices[0]?.name ?? Translation.tr("Unknown Device");
                        }
                        return Translation.tr("%1 devices").arg(root.connectedDevices.length);
                    }
                    font {
                        pixelSize: Appearance.font.pixelSize.small
                        weight: Font.Medium
                    }
                    color: Appearance.colors.colOnSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                StyledText {
                    text: root.connectedDevices.length === 1 
                        ? Translation.tr("Connected")
                        : Translation.tr("All connected")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colPrimary
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
    
    WindowDialogSeparator {
        visible: !(Bluetooth.defaultAdapter?.discovering ?? false)
    }
    StyledIndeterminateProgressBar {
        visible: Bluetooth.defaultAdapter?.discovering ?? false
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -8
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
    }
    StyledListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -15
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0
        animateAppearance: false

        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => {
                // Connected -> paired -> others
                let conn = (b.connected - a.connected) || (b.paired - a.paired);
                if (conn !== 0) return conn;

                // Ones with meaningful names before MAC addresses
                const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
                const aIsMac = macRegex.test(a.name);
                const bIsMac = macRegex.test(b.name);
                if (aIsMac !== bIsMac) return aIsMac ? 1 : -1;

                // Alphabetical by name
                return a.name.localeCompare(b.name);
            })
        }
        delegate: BluetoothDeviceItem {
            required property BluetoothDevice modelData
            device: modelData
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
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.bluetooth}`]);
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
