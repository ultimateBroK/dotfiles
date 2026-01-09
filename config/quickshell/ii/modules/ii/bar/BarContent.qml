import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.bar

Item { // Bar content region
    id: root

    // Global topbar background is disabled by default; individual groups provide surfaces.
    // When autoHide is enabled we want a subtle translucent background so the bar
    // remains readable when it appears over the wallpaper.
    readonly property bool topbarHasBackground: (Config.options.bar.showBackground || Config.options.bar.autoHide.enable)

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    BarBackdrop {
        anchors.fill: parent
        hasBackground: root.topbarHasBackground
        vertical: false
    }

    FocusedScrollMouseArea { // Left side | scroll to change brightness
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

        // Visual content
        ScrollHint {
            reveal: barLeftSideMouseArea.hovered
            icon: "light_mode"
            tooltipText: Translation.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: leftSectionRowLayout
            anchors.fill: parent
            spacing: 10

            BarGroup {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: Appearance.rounding.screenRounding
                Layout.fillWidth: false
                Layout.fillHeight: false
                padding: 5
                
                LeftSidebarButton { // Left sidebar button
                    Layout.alignment: Qt.AlignVCenter
                    colBackground: "transparent"
                    colBackgroundHover: "transparent"
                }
            }

            BarGroup {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: false
                Layout.fillHeight: false
                anchors.verticalCenter: parent.verticalCenter
                padding: 8
                
                ActiveWindow {
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            Item {
                visible: root.useShortenedForm === 0
                Layout.fillWidth: true
            }
            
            Item {
                visible: root.useShortenedForm === 0
                Layout.preferredWidth: Appearance.rounding.screenRounding
            }
        }
    }

    Row { // Middle section
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        Item {
            id: leftCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: root.centerSideModuleWidth
            width: implicitWidth
            implicitHeight: Appearance.sizes.baseBarHeight
            height: implicitHeight

            RowLayout {
                anchors.fill: parent
                spacing: 4

                // Group 1: system resources
                BarGroup {
                    id: resourcesGroup
                    visible: Config.options.bar.resources.enable && (
                        Config.options.bar.resources.showMemory ||
                        Config.options.bar.resources.showGpu ||
                        Config.options.bar.resources.showCpu
                    )
                    Layout.fillHeight: true
                    Layout.fillWidth: root.useShortenedForm === 2

                    Resources {
                        alwaysShowAllResources: true
                        Layout.fillWidth: true
                    }
                }

                // Group 2: media player
                BarGroup {
                    id: mediaGroup
                    visible: root.useShortenedForm < 2
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Media {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        BarGroup {
            id: middleCenterGroup
            anchors.verticalCenter: parent.verticalCenter
            padding: workspacesWidget.widgetPadding

            Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
                    // Right-click to toggle overview
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

        VerticalBarSeparator {
            visible: Config.options?.bar.borderless
        }

        MouseArea {
            id: clockGroup
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clockContent.implicitWidth
            implicitHeight: clockContent.implicitHeight

            onPressed: {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }

            BarGroup {
                id: clockContent
                anchors.fill: parent
                padding: 8

                ClockWidget {
                    showDate: (Config.options.bar.verbose && root.useShortenedForm < 2)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Status group: Weather + Battery
        BarGroup {
            id: statusGroup
            anchors.verticalCenter: parent.verticalCenter
            // Show if either battery is available (and layout allows) or weather is enabled
            visible: ((root.useShortenedForm < 2 && Battery.available) || Config.options.bar.weather.enable)
            padding: 8

            Loader {
                active: Config.options.bar.weather.enable
                sourceComponent: WeatherBar {}
            }

            BatteryIndicator {
                visible: (root.useShortenedForm < 2 && Battery.available)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Utilities group: placed to the right of statusGroup
        BarGroup {
            id: utilsGroup
            anchors.verticalCenter: parent.verticalCenter
            // Show only if any utility button is enabled and allowed by layout state
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
            padding: 8

            UtilButtons {
                // Inner component visibility remains tied to layout state
                visible: (Config.options.bar.verbose && root.useShortenedForm === 0)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    FocusedScrollMouseArea { // Right side | scroll to change volume
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

        // Visual content
        ScrollHint {
            reveal: barRightSideMouseArea.hovered
            icon: "volume_up"
            tooltipText: Translation.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            id: rightSectionRowLayout
            anchors.fill: parent
            spacing: 5
            layoutDirection: Qt.RightToLeft

            BarGroup { // Right side should have a dark surface like the center groups
                id: rightControlsGroup
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.rightMargin: Appearance.rounding.screenRounding
                padding: 8

                SysTray {
                    visible: root.useShortenedForm === 0
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    invertSide: Config?.options.bar.bottom
                }

                RippleButton { // Right sidebar button
                    id: rightSidebarButton

                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.fillWidth: false

                    implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
                    implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

                    buttonRadius: Appearance.rounding.full
                    // Let BarGroup provide the base surface; only show hover/toggled emphasis.
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
                        property real realSpacing: 15
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
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                    HyprlandXkbIndicator {
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
                        NotificationUnreadCount {
                            id: notificationUnreadCount
                        }
                    }
                    MaterialSymbol {
                        Layout.rightMargin: indicatorsRowLayout.realSpacing
                        text: Network.materialSymbol
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                    VolumeStatusIcon {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: indicatorsRowLayout.realSpacing
                        iconPixelSize: Appearance.font.pixelSize.larger
                        iconColor: rightSidebarButton.colText
                    }
                    MaterialSymbol {
                        visible: BluetoothStatus.available
                        text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                        iconSize: Appearance.font.pixelSize.larger
                        color: rightSidebarButton.colText
                    }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Weather moved into middle statusGroup with BatteryIndicator
        }
    }
}
