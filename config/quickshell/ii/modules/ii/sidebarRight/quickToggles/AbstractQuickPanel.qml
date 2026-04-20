import QtQuick
import qs.modules.common
import qs.modules.common.functions

Rectangle {
    id: root

    radius: Appearance.rounding.normal
    color: Appearance.isDarkMode
        ? Qt.rgba(1, 1, 1, 0.06)
        : Qt.rgba(0, 0, 0, 0.04)

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
}
