import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    required property bool isSink
    function correctType(node) {
        return (node.isSink === root.isSink) && node.audio
    }
    readonly property list<var> appPwNodes: Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
        return root.correctType(node) && node.isStream
    })
    readonly property list<var> devices: Pipewire.nodes.values.filter(node => {
        return root.correctType(node) && !node.isStream
    })
    readonly property bool hasApps: appPwNodes.length > 0
    spacing: 16
    
    // Applications header
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: -8
        visible: root.hasApps
        spacing: 8
        
        MaterialSymbol {
            text: "graphic_eq"
            iconSize: 18
            color: Appearance.colors.colPrimary
        }
        
        StyledText {
            text: Translation.tr("Applications")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurface
        }
        
        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 20
            radius: 10
            color: Appearance.colors.colPrimaryContainer
            visible: root.hasApps
            
            StyledText {
                anchors.centerIn: parent
                text: root.appPwNodes.length
                font {
                    pixelSize: Appearance.font.pixelSize.smaller
                    weight: Font.Bold
                }
                color: Appearance.colors.colOnPrimaryContainer
            }
        }
        
        Item { Layout.fillWidth: true }
    }

    DialogSectionListView {
        Layout.fillHeight: true
        topMargin: 8

        model: ScriptModel {
            values: root.appPwNodes
        }
        delegate: VolumeMixerEntry {
            anchors {
                left: parent?.left
                right: parent?.right
            }
            required property var modelData
            node: modelData
        }
    }

    // Device selector header
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        MaterialSymbol {
            text: root.isSink ? "speaker" : "mic"
            iconSize: 18
            color: Appearance.colors.colPrimary
        }
        
        StyledText {
            text: Translation.tr("Device")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurface
        }
        
        Item { Layout.fillWidth: true }
    }
    
    StyledComboBox {
        id: deviceSelector
        Layout.fillHeight: false
        Layout.fillWidth: true
        Layout.bottomMargin: 6
        Layout.topMargin: -8
        model: root.devices.map(node => (node.nickname || node.description || Translation.tr("Unknown")))
        currentIndex: root.devices.findIndex(item => {
            if (root.isSink) {
                return item.id === Pipewire.preferredDefaultAudioSink?.id
            } else {
                return item.id === Pipewire.preferredDefaultAudioSource?.id
            }
        })
        onActivated: (index) => {
            print(index)
            const item = root.devices[index]
            if (root.isSink) {
                Pipewire.preferredDefaultAudioSink = item
            } else {
                Pipewire.preferredDefaultAudioSource = item
            }
        }
    }

    component DialogSectionListView: StyledListView {
        Layout.fillWidth: true
        Layout.topMargin: -22
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
        topMargin: 12
        bottomMargin: 12
        leftMargin: 20
        rightMargin: 20

        clip: true
        spacing: 4
        animateAppearance: false
    }

    Component {
        id: listElementComp
        ListElement {}
    }
}
