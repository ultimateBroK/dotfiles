import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: root
    toggled: Idle.inhibit
    buttonIcon: "coffee"
    altAction: () => {
        Idle.cyclePreset()
    }
    onClicked: {
        Idle.toggleInhibit()
    }
    StyledToolTip {
        text: Translation.tr("Keep system awake (%1)").arg(Idle.selectedPresetLabel)
    }

}
