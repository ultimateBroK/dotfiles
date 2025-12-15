pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property var pomodoro: PomodoroService
    readonly property real widgetWidth: 350
    readonly property real widgetHeight: 280
    property int workDurationInput: Config.options?.adhd?.pomodoro?.workDuration ?? 25
    property int shortBreakInput: Config.options?.adhd?.pomodoro?.shortBreakDuration ?? 5
    property int longBreakInput: Config.options?.adhd?.pomodoro?.longBreakDuration ?? 15
    property int sessionsUntilLongBreakInput: Config.options?.adhd?.pomodoro?.sessionsUntilLongBreak ?? 4
    property bool soundEnabledInput: Config.options?.adhd?.pomodoro?.sound?.enable ?? true
    property string alertSoundInput: Config.options?.adhd?.pomodoro?.sound?.name ?? "complete"
    readonly property list<string> soundOptions: [
        "complete",
        "dialog-information",
        "dialog-warning",
        "alarm-clock-elapsed",
        "system-ready",
        "desktop-login",
        "desktop-logout",
        "message-new-email"
    ]

    function syncInputsFromConfig() {
        workDurationInput = Config.options?.adhd?.pomodoro?.workDuration ?? 25;
        shortBreakInput = Config.options?.adhd?.pomodoro?.shortBreakDuration ?? 5;
        longBreakInput = Config.options?.adhd?.pomodoro?.longBreakDuration ?? 15;
        sessionsUntilLongBreakInput = Config.options?.adhd?.pomodoro?.sessionsUntilLongBreak ?? 4;
        soundEnabledInput = Config.options?.adhd?.pomodoro?.sound?.enable ?? true;
        alertSoundInput = Config.options?.adhd?.pomodoro?.sound?.name ?? "complete";
    }

    function applyPomodoroSettings() {
        Config.options.adhd.pomodoro.workDuration = workDurationInput;
        Config.options.adhd.pomodoro.shortBreakDuration = shortBreakInput;
        Config.options.adhd.pomodoro.longBreakDuration = longBreakInput;
        Config.options.adhd.pomodoro.sessionsUntilLongBreak = sessionsUntilLongBreakInput;
        Config.options.adhd.pomodoro.sound.enable = soundEnabledInput;
        Config.options.adhd.pomodoro.sound.name = alertSoundInput || "complete";
        pomodoro.resetTimer();
    }

    function previewAlertSound() {
        if (!soundEnabledInput) return;
        pomodoro.playAlert(alertSoundInput || pomodoro.alertSound);
    }

    Loader {
        id: pomodoroControlsLoader
        active: GlobalStates.pomodoroMenuOpen
        onActiveChanged: {
            if (active) {
                root.syncInputsFromConfig();
            }
        }

        sourceComponent: PanelWindow {
            id: pomodoroControlsRoot
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth
            implicitHeight: menuContent.implicitHeight + 40
            color: "transparent"
            WlrLayershell.namespace: "quickshell:pomodoroControls"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
                right: true
            }

            margins {
                top: !Config.options.bar.bottom ? Appearance.sizes.barHeight + 10 : 0
                bottom: Config.options.bar.bottom ? Appearance.sizes.barHeight + 10 : 0
                right: 20
            }

            mask: Region {
                item: menuBackground
            }

            HyprlandFocusGrab {
                windows: [pomodoroControlsRoot]
                active: pomodoroControlsLoader.active
                onCleared: () => {
                    if (!active) {
                        GlobalStates.pomodoroMenuOpen = false;
                    }
                }
            }

            Item {
                anchors.fill: parent

                StyledRectangularShadow {
                    target: menuBackground
                }

                Rectangle {
                    id: menuBackground
                    anchors {
                        fill: parent
                        margins: 10
                    }
                    color: Appearance.colors.colLayer1
                    radius: Appearance.rounding.medium
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border

                    ColumnLayout {
                        id: menuContent
                        anchors {
                            fill: parent
                            margins: 16
                        }
                        spacing: 12

                        // Header
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer1
                            text: "🍅 " + Translation.tr("Pomodoro")
                        }

                        // Current status
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: statusColumn.implicitHeight + 16
                            radius: Appearance.rounding.small
                            color: Appearance.colors.colSurfaceContainer

                            ColumnLayout {
                                id: statusColumn
                                anchors {
                                    fill: parent
                                    margins: 8
                                }
                                spacing: 4

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.pixelSize: Appearance.font.pixelSize.hugeass
                                    font.weight: Font.Bold
                                    color: {
                                        if (root.pomodoro.currentPhase === PomodoroService.Phase.Work)
                                            return Appearance.colors.colError
                                        else if (root.pomodoro.currentPhase === PomodoroService.Phase.LongBreak)
                                            return Appearance.colors.colPrimary
                                        return Appearance.colors.colSecondary
                                    }
                                    text: root.pomodoro.formattedTime
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurfaceVariant
                                    text: root.pomodoro.phaseName
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnSurfaceVariant
                                    text: Translation.tr("Sessions") + ": " + root.pomodoro.completedSessions
                                }
                            }
                        }

                        // Control buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: root.pomodoro.running ? Appearance.colors.colError : Appearance.colors.colPrimary
                                colBackgroundHover: root.pomodoro.running ? Appearance.colors.colErrorHover : Appearance.colors.colPrimaryHover
                                
                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: root.pomodoro.running ? "pause" : "play_arrow"
                                        iconSize: 18
                                        color: Appearance.colors.colOnPrimary
                                    }
                                    StyledText {
                                        text: root.pomodoro.running ? Translation.tr("Pause") : Translation.tr("Start")
                                        color: Appearance.colors.colOnPrimary
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                }
                                onClicked: root.pomodoro.toggleTimer()
                            }

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colSurfaceContainer
                                colBackgroundHover: Appearance.colors.colSurfaceContainerHover
                                
                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "skip_next"
                                        iconSize: 18
                                        color: Appearance.colors.colOnSurface
                                    }
                                    StyledText {
                                        text: Translation.tr("Skip")
                                        color: Appearance.colors.colOnSurface
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                }
                                onClicked: root.pomodoro.skipToNextPhase()
                            }

                            RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colSurfaceContainer
                                colBackgroundHover: Appearance.colors.colSurfaceContainerHover
                                
                                contentItem: RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    MaterialSymbol {
                                        text: "refresh"
                                        iconSize: 18
                                        color: Appearance.colors.colOnSurface
                                    }
                                    StyledText {
                                        text: Translation.tr("Reset")
                                        color: Appearance.colors.colOnSurface
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                }
                                onClicked: root.pomodoro.resetTimer()
                            }
                        }

                        // Settings
                        Rectangle {
                            Layout.fillWidth: true
                            color: Appearance.colors.colSurfaceContainer
                            radius: Appearance.rounding.small
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                StyledText {
                                    text: Translation.tr("Settings")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Bold
                                    color: Appearance.colors.colOnSurface
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Translation.tr("Work")
                                        color: Appearance.colors.colOnSurfaceVariant
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                    SpinBox {
                                        id: workDurationSpin
                                        Layout.fillWidth: true
                                        from: 5
                                        to: 180
                                        stepSize: 1
                                        editable: true
                                        value: root.workDurationInput
                                        suffix: "m"
                                        onValueModified: root.workDurationInput = value
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Translation.tr("Short Break")
                                        color: Appearance.colors.colOnSurfaceVariant
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                    SpinBox {
                                        id: shortBreakSpin
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 60
                                        stepSize: 1
                                        editable: true
                                        value: root.shortBreakInput
                                        suffix: "m"
                                        onValueModified: root.shortBreakInput = value
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Translation.tr("Long Break")
                                        color: Appearance.colors.colOnSurfaceVariant
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                    SpinBox {
                                        id: longBreakSpin
                                        Layout.fillWidth: true
                                        from: 5
                                        to: 120
                                        stepSize: 1
                                        editable: true
                                        value: root.longBreakInput
                                        suffix: "m"
                                        onValueModified: root.longBreakInput = value
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Translation.tr("Sessions")
                                        color: Appearance.colors.colOnSurfaceVariant
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                    SpinBox {
                                        id: sessionsSpin
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 10
                                        stepSize: 1
                                        editable: true
                                        value: root.sessionsUntilLongBreakInput
                                        onValueModified: root.sessionsUntilLongBreakInput = value
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    StyledText {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: Translation.tr("Sound")
                                        color: Appearance.colors.colOnSurfaceVariant
                                        font.pixelSize: Appearance.font.pixelSize.small
                                    }
                                    ComboBox {
                                        id: soundCombo
                                        Layout.fillWidth: true
                                        editable: true
                                        model: root.soundOptions
                                        currentIndex: root.soundOptions.indexOf(root.alertSoundInput)
                                        onActivated: (index) => root.alertSoundInput = root.soundOptions[index] ?? root.alertSoundInput
                                        onEditTextChanged: root.alertSoundInput = editText
                                        Component.onCompleted: editText = root.alertSoundInput
                                    }
                                    Switch {
                                        id: soundSwitch
                                        checked: root.soundEnabledInput
                                        onCheckedChanged: root.soundEnabledInput = checked
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: Appearance.colors.colSurfaceContainer
                                        colBackgroundHover: Appearance.colors.colSurfaceContainerHover
                                        
                                        contentItem: RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            MaterialSymbol {
                                                text: "volume_up"
                                                iconSize: 18
                                                color: Appearance.colors.colOnSurface
                                            }
                                            StyledText {
                                                text: Translation.tr("Preview")
                                                color: Appearance.colors.colOnSurface
                                                font.pixelSize: Appearance.font.pixelSize.small
                                            }
                                        }
                                        onClicked: root.previewAlertSound()
                                    }

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.small
                                        colBackground: Appearance.colors.colPrimary
                                        colBackgroundHover: Appearance.colors.colPrimaryHover
                                        
                                        contentItem: RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            MaterialSymbol {
                                                text: "save"
                                                iconSize: 18
                                                color: Appearance.colors.colOnPrimary
                                            }
                                            StyledText {
                                                text: Translation.tr("Apply & Reset")
                                                color: Appearance.colors.colOnPrimary
                                                font.pixelSize: Appearance.font.pixelSize.small
                                            }
                                        }
                                        onClicked: root.applyPomodoroSettings()
                                    }
                                }
                            }
                        }

                        // Help text
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSurfaceVariant
                            text: Translation.tr("Left click: Open menu | Right click: Start/Pause | Middle click: Skip")
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "pomodoroControls"

        function toggle(): void {
            GlobalStates.pomodoroMenuOpen = !GlobalStates.pomodoroMenuOpen;
        }

        function close(): void {
            GlobalStates.pomodoroMenuOpen = false;
        }

        function open(): void {
            GlobalStates.pomodoroMenuOpen = true;
        }
    }

    GlobalShortcut {
        name: "pomodoroControlsToggle"
        description: "Toggles pomodoro controls on press"

        onPressed: {
            GlobalStates.pomodoroMenuOpen = !GlobalStates.pomodoroMenuOpen;
        }
    }
}
