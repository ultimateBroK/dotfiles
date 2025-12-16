import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Hyprland

QuickToggleButton {
    id: root
    visible: BluetoothStatus.available
    toggled: BluetoothStatus.enabled
    buttonIcon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
    onClicked: {
        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    }
    altAction: () => {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.bluetooth}`])
        GlobalStates.sidebarRightOpen = false
    }
    StyledToolTip {
        text: {
            const device = BluetoothStatus.firstActiveDevice;
            let deviceText = device?.name ?? Translation.tr("Bluetooth");
            if (BluetoothStatus.activeDeviceCount > 1) {
                deviceText += ` +${BluetoothStatus.activeDeviceCount - 1}`;
            }
            // Add battery percentage if available
            const battery = device?.battery;
            const batteryAvailable = device?.batteryAvailable;
            if (batteryAvailable && battery !== undefined && battery !== null && !isNaN(battery) && battery >= 0) {
                deviceText += ` • ${Math.round(battery * 100)}%`;
            }
            return Translation.tr("%1 | Right-click to configure").arg(deviceText);
        }
    }
}
