import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

Rectangle {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Qt.rgba(1, 1, 1, 0.06)
    property real verticalPadding: 6
    property real horizontalPadding: 10

    Column {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }
        spacing: 3

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showBrightness
            sourceComponent: QuickSliderItem {
                materialSymbol: "brightness_6"
                sliderLabel: Translation.tr("Brightness")
                value: root.brightnessMonitor.brightness
                onMoved: {
                    root.brightnessMonitor.setBrightness(value)
                }
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showVolume
            sourceComponent: QuickSliderItem {
                materialSymbol: "volume_up"
                sliderLabel: Translation.tr("Volume")
                value: Audio.sink.audio.volume
                onMoved: {
                    Audio.sink.audio.volume = value
                }
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showMic
            sourceComponent: QuickSliderItem {
                materialSymbol: "mic"
                sliderLabel: Translation.tr("Microphone")
                value: Audio.source.audio.volume
                onMoved: {
                    Audio.source.audio.volume = value
                }
            }
        }
    }

    component QuickSliderItem: RowLayout {
        id: sliderItem
        required property string materialSymbol
        required property string sliderLabel
        property alias value: quickSlider.value
        signal moved()
        spacing: 8
        
        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: sliderItem.materialSymbol
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colPrimary
        }
        
        StyledSlider {
            id: quickSlider
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            configuration: StyledSlider.Configuration.S
            stopIndicatorValues: []
            onMoved: sliderItem.moved()
        }
        
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 35
            text: `${Math.round(quickSlider.value * 100)}%`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurface
            horizontalAlignment: Text.AlignRight
        }
    }
}
