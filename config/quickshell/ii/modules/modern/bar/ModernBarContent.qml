import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.bar as Bar

Item {
    id: root

    readonly property bool topbarHasBackground: true

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    // Standardized icon size for all icons and indicators
    readonly property int iconSize: Appearance.font.pixelSize.medium
    readonly property int iconSizeSmall: Appearance.font.pixelSize.smaller

    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0
        }
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, Config.options.appearance.transparency.enable ? (1 - Config.options.appearance.transparency.contentTransparency) : 0.9)
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: 0
    }

    // Left section: Menu, Active Window, Media
    FocusedScrollMouseArea {
        id: barLeftSideMouseArea
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: middleSection.left
        }
        implicitWidth: leftSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness - 0.05)
        onScrollUp: root.brightnessMonitor.setBrightness(root.brightnessMonitor.brightness + 0.05)
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 6

            Bar.BarGroup {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.rounding.screenRounding
                padding: 4
                Bar.LeftSidebarButton {
                    colBackground: "transparent"
                    colBackgroundHover: "transparent"
                }
            }

            Bar.BarGroup {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: false
                padding: 4
                Bar.ActiveWindow {
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: true
            }
        }
    }

    // Center section: Resources/Media, Workspaces, Clock, Status
    Row {
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        // Resources and Media
        Bar.BarGroup {
            id: leftCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.centerSideModuleWidth
            padding: 4

            Bar.Resources {
                alwaysShowAllResources: true
                Layout.fillWidth: root.useShortenedForm === 2 ? true : false
            }

            Bar.Media {
                visible: root.useShortenedForm < 2
                Layout.fillWidth: true
            }
        }

        // Workspaces
        Bar.BarGroup {
            id: middleCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            padding: 6

            Bar.Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onPressed: event => {
                        if (event.button === Qt.RightButton) {
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                        }
                    }
                }
            }
        }

        // Clock
        MouseArea {
            id: clockGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clockContent.implicitWidth
            implicitHeight: clockContent.implicitHeight

            onPressed: {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }

            Bar.BarGroup {
                id: clockContent
                anchors.fill: parent
                padding: 6

                Bar.ClockWidget {
                    showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Status: Battery
        Bar.BarGroup {
            id: statusGroup
            anchors.verticalCenter: parent.verticalCenter
            visible: (root.useShortenedForm < 2 && Battery.available) || Config.options.bar.weather.enable
            padding: 4

            Bar.BatteryIndicator {
                visible: (root.useShortenedForm < 2 && Battery.available)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Right section: System indicators, Utilities, SysTray, Sidebar button
    FocusedScrollMouseArea {
        id: barRightSideMouseArea
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: middleSection.right
            right: parent.right
        }
        implicitWidth: rightSectionRowLayout.implicitWidth
        implicitHeight: Appearance.sizes.baseBarHeight

        onScrollDown: {
            const currentVolume = Audio.value;
            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
            Audio.sink.audio.volume -= step;
        }
        onScrollUp: {
            const currentVolume = Audio.value;
            const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
            Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
        }
        onMovedAway: GlobalStates.osdVolumeOpen = false;
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 4
            layoutDirection: Qt.RightToLeft

            // Right sidebar button with indicators
            Bar.BarGroup {
                id: rightControlsGroup
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: Appearance.rounding.screenRounding
                padding: 4

                RippleButton {
                    id: rightSidebarButton
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.fillWidth: false

                    implicitWidth: indicatorsRowLayout.implicitWidth + 8
                    implicitHeight: indicatorsRowLayout.implicitHeight + 4

                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: "transparent"
                    colRipple: Appearance.colors.colLayer1Active
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    toggled: GlobalStates.sidebarRightOpen
                    property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colPrimary

                    Behavior on colText {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    onPressed: {
                        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
                    }

                    RowLayout {
                        id: indicatorsRowLayout
                        anchors.centerIn: parent
                        property real realSpacing: 8
                        spacing: 0

                        Revealer {
                            reveal: Audio.source?.audio?.muted ?? false
                            Layout.fillHeight: true
                            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                            Behavior on Layout.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            MaterialSymbol {
                                text: "mic_off"
                                iconSize: root.iconSize
                                color: rightSidebarButton.colText
                            }
                        }
                        Bar.HyprlandXkbIndicator {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: indicatorsRowLayout.realSpacing
                            color: rightSidebarButton.colText
                        }
                        Revealer {
                            reveal: Notifications.silent || Notifications.unread > 0
                            Layout.fillHeight: true
                            Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                            implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
                            implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
                            Behavior on Layout.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Bar.NotificationUnreadCount {
                                id: notificationUnreadCount
                            }
                        }
                        MaterialSymbol {
                            Layout.rightMargin: indicatorsRowLayout.realSpacing
                            text: Network.materialSymbol
                            iconSize: root.iconSize
                            color: rightSidebarButton.colText
                        }
                        MaterialSymbol {
                            id: volumeStatusIcon
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: indicatorsRowLayout.realSpacing
                            property real volumeValue: (Audio?.value ?? Audio.sink?.audio?.volume ?? 0)
                            property bool muted: Audio.sink?.audio?.muted ?? false

                            text: {
                                if (muted || volumeValue <= 0.001)
                                    return "volume_off";
                                if (volumeValue <= 0.40)
                                    return "volume_mute";
                                if (volumeValue <= 0.70)
                                    return "volume_down";
                                return "volume_up";
                            }
                            iconSize: root.iconSize
                            color: rightSidebarButton.colText
                        }
                        MaterialSymbol {
                            visible: BluetoothStatus.available
                            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                            iconSize: root.iconSize
                            color: rightSidebarButton.colText
                        }
                    }
                }
            }

            // SysTray
            Bar.BarGroup {
                visible: root.useShortenedForm === 0
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                padding: 4

                Bar.SysTray {
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    invertSide: Config?.options.bar.bottom
                }
            }

            // Utilities
            Bar.BarGroup {
                id: utilsGroup
                visible: (
                    Config.options.bar.verbose && root.useShortenedForm === 0 && (
                        Config.options.bar.utilButtons.showScreenSnip ||
                        Config.options.bar.utilButtons.showScreenRecord ||
                        Config.options.bar.utilButtons.showColorPicker ||
                        Config.options.bar.utilButtons.showKeyboardToggle ||
                        Config.options.bar.utilButtons.showMicToggle ||
                        Config.options.bar.utilButtons.showDarkModeToggle ||
                        Config.options.bar.utilButtons.showPerformanceProfileToggle
                    )
                )
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                padding: 4

                Bar.UtilButtons {
                    visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
