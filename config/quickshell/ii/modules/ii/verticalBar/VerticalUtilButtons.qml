import qs
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

import qs.services
import qs.modules.ii.bar as Bar

Item {
    id: root

    implicitWidth: columnLayout.implicitWidth
    implicitHeight: columnLayout.implicitHeight

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        Loader {
            active: Config.options.bar.utilButtons.showScreenSnip
            visible: Config.options.bar.utilButtons.showScreenSnip
            sourceComponent: Bar.CircleUtilButton {
                Layout.alignment: Qt.AlignHCenter
                onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "screenshot_region"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showScreenRecord
            visible: Config.options.bar.utilButtons.showScreenRecord
            sourceComponent: Bar.CircleUtilButton {
                Layout.alignment: Qt.AlignHCenter
                onClicked: Quickshell.execDetached([Directories.recordScriptPath])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "videocam"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showColorPicker
            visible: Config.options.bar.utilButtons.showColorPicker
            sourceComponent: Bar.CircleUtilButton {
                Layout.alignment: Qt.AlignHCenter
                onClicked: Quickshell.execDetached(["hyprpicker", "-a"])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 1
                    text: "colorize"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showKeyboardToggle
            visible: Config.options.bar.utilButtons.showKeyboardToggle
            sourceComponent: Bar.CircleUtilButton {
                Layout.alignment: Qt.AlignHCenter
                onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: "keyboard"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showMicToggle
            visible: Config.options.bar.utilButtons.showMicToggle
            sourceComponent: Bar.CircleUtilButton {
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    if (Audio.source?.audio) Audio.source.audio.muted = !Audio.source.audio.muted
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Pipewire.defaultAudioSource?.audio?.muted ? "mic_off" : "mic"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showDarkModeToggle
            visible: Config.options.bar.utilButtons.showDarkModeToggle
            sourceComponent: Bar.CircleUtilButton {
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    if (Appearance.m3colors.darkmode) {
                        Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath} --mode light --noswitch`)
                    } else {
                        Hyprland.dispatch(`exec ${Directories.wallpaperSwitchScriptPath} --mode dark --noswitch`)
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: Appearance.m3colors.darkmode ? "light_mode" : "dark_mode"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Loader {
            active: Config.options.bar.utilButtons.showPerformanceProfileToggle
            visible: Config.options.bar.utilButtons.showPerformanceProfileToggle
            sourceComponent: Bar.CircleUtilButton {
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    if (PowerProfiles.hasPerformanceProfile) {
                        switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver:
                            PowerProfiles.profile = PowerProfile.Balanced
                            break
                        case PowerProfile.Balanced:
                            PowerProfiles.profile = PowerProfile.Performance
                            break
                        case PowerProfile.Performance:
                            PowerProfiles.profile = PowerProfile.PowerSaver
                            break
                        }
                    } else {
                        PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
                    }
                }
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: switch (PowerProfiles.profile) {
                    case PowerProfile.PowerSaver: return "energy_savings_leaf"
                    case PowerProfile.Balanced: return "settings_slow_motion"
                    case PowerProfile.Performance: return "local_fire_department"
                    }
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colPrimary
                }
            }
        }
    }
}
