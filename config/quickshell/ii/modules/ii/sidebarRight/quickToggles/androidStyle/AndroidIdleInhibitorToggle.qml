import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

AndroidQuickToggleButton {
    id: root
    
    name: Translation.tr("Keep awake")

    toggled: Idle.inhibit
    statusText: Idle.statusText
    buttonIcon: "coffee"
    mainAction: () => {
        Idle.toggleInhibit()
    }
    altAction: () => {
        Idle.cyclePreset()
    }
    StyledToolTip {
        text: Translation.tr("Keep system awake (%1)").arg(Idle.activeLabel)
    }
}

