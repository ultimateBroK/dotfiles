import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

AndroidQuickToggleButton {
    id: root
    
    name: Translation.tr("Internet")
    statusText: Network.networkName || Translation.tr("Not connected")

    toggled: Network.wifiStatus !== "disabled"
    buttonIcon: Network.materialSymbol
    mainAction: () => Network.toggleWifi()
    altAction: () => {
        root.openMenu()
    }
    StyledToolTip {
        text: (Network.networkName || Translation.tr("Not connected")) + " | " + Translation.tr("Right-click to configure")
    }
}

