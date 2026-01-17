import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    component SmallLightDarkPreferenceButton: RippleButton {
        id: smallLightDarkPreferenceButton
        required property bool dark
        property color colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
        padding: 5
        Layout.fillWidth: true
        toggled: Appearance.m3colors.darkmode === dark
        colBackground: Appearance.colors.colLayer2
        onClicked: {
            Quickshell.execDetached(["zsh", "-c", `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`]);
        }
        contentItem: Item {
            anchors.centerIn: parent
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: 30
                    text: dark ? "dark_mode" : "light_mode"
                    color: smallLightDarkPreferenceButton.colText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: dark ? Translation.tr("Dark") : Translation.tr("Light")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: smallLightDarkPreferenceButton.colText
                }
            }
        }
    }

    // Wallpaper selection
    ContentSection {
        icon: "format_paint"
        title: Translation.tr("Wallpaper & Colors")
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            Item {
                implicitWidth: 340
                implicitHeight: 200
                
                StyledImage {
                    id: wallpaperPreview
                    anchors.fill: parent
                    sourceSize.width: parent.implicitWidth
                    sourceSize.height: parent.implicitHeight
                    fillMode: Image.PreserveAspectCrop
                    source: Config.options.background.wallpaperPath
                    cache: false
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 360
                            height: 200
                            radius: Appearance.rounding.normal
                        }
                    }
                }
            }

            ColumnLayout {
                RippleButtonWithIcon {
                    Layout.fillWidth: true
                    materialIcon: "wallpaper"
                    StyledToolTip {
                        text: Translation.tr("Pick wallpaper image on your system")
                    }
                    onClicked: {
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`);
                    }
                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: Translation.tr("Choose file")
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            RowLayout {
                                spacing: 3
                                KeyboardKey {
                                    key: "Ctrl"
                                }
                                KeyboardKey {
                                    key: "󰖳"
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }
                                KeyboardKey {
                                    key: "T"
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    uniformCellSizes: true

                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: false
                    }
                    SmallLightDarkPreferenceButton {
                        Layout.fillHeight: true
                        dark: true
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Color Scheme Type")
            tooltip: Translation.tr("Select how colors are generated from your wallpaper.\nAuto will intelligently detect the best scheme for your image.")
            
            ConfigSelectionArray {
                id: colorTypeSelector
                currentValue: Config.options.appearance.palette.type
                onSelected: newValue => {
                    Config.options.appearance.palette.type = newValue;
                    colorTypeSelector.enabled = false;
                    Quickshell.execDetached(["zsh", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch --type ${newValue}`]);
                    // Re-enable after a delay to allow script to start
                    reenableTimer.restart();
                }
                options: [
                    {
                        "value": "auto",
                        "displayName": Translation.tr("Auto"),
                        "icon": "auto_awesome"
                    },
                    {
                        "value": "scheme-content",
                        "displayName": Translation.tr("Content"),
                        "icon": "palette"
                    },
                    {
                        "value": "scheme-expressive",
                        "displayName": Translation.tr("Expressive"),
                        "icon": "brush"
                    },
                    {
                        "value": "scheme-fidelity",
                        "displayName": Translation.tr("Fidelity"),
                        "icon": "photo"
                    },
                    {
                        "value": "scheme-fruit-salad",
                        "displayName": Translation.tr("Fruit Salad"),
                        "icon": "colorize"
                    },
                    {
                        "value": "scheme-monochrome",
                        "displayName": Translation.tr("Monochrome"),
                        "icon": "invert_colors_off"
                    },
                    {
                        "value": "scheme-neutral",
                        "displayName": Translation.tr("Neutral"),
                        "icon": "tune"
                    },
                    {
                        "value": "scheme-rainbow",
                        "displayName": Translation.tr("Rainbow"),
                        "icon": "gradient"
                    },
                    {
                        "value": "scheme-tonal-spot",
                        "displayName": Translation.tr("Tonal Spot"),
                        "icon": "circle"
                    },
                    {
                        "value": "scheme-vibrant",
                        "displayName": Translation.tr("Vibrant"),
                        "icon": "flare"
                    }
                ]
                
                Timer {
                    id: reenableTimer
                    interval: 500
                    onTriggered: {
                        colorTypeSelector.enabled = true;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Wallpaper Scale")
            tooltip: Translation.tr("Adjust the zoom level and scaling mode of your wallpaper.\nHigher zoom values allow more parallax movement when switching workspaces.")
            
            ConfigSelectionArray {
                currentValue: Config.options.background.fillMode || "crop"
                onSelected: newValue => {
                    Config.options.background.fillMode = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Crop"),
                        icon: "crop",
                        value: "crop"
                    },
                    {
                        displayName: Translation.tr("Fit"),
                        icon: "fit_screen",
                        value: "fit"
                    },
                    {
                        displayName: Translation.tr("Stretch"),
                        icon: "open_in_full",
                        value: "stretch"
                    },
                    {
                        displayName: Translation.tr("Tile"),
                        icon: "grid_on",
                        value: "tile"
                    },
                    {
                        displayName: Translation.tr("Pad"),
                        icon: "crop_free",
                        value: "pad"
                    }
                ]
            }
            
            ConfigSpinBox {
                icon: "loupe"
                text: Translation.tr("Wallpaper zoom (%)")
                value: Config.options.background.parallax.workspaceZoom * 100
                from: 100
                to: 150
                stepSize: 1
                enabled: Config.options.background.fillMode === "crop" || Config.options.background.fillMode === "fit"
                onValueChanged: {
                    Config.options.background.parallax.workspaceZoom = value / 100;
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: parent.containsMouse
                        text: {
                            if (!parent.parent.enabled) {
                                return Translation.tr("Zoom only works with Crop and Fit modes");
                            }
                            return Translation.tr("Controls how much the wallpaper is zoomed in.\n100% = fit to screen, 150% = maximum zoom for parallax effect");
                        }
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Transparency")
            tooltip: Translation.tr("Control transparency of backgrounds and content.\nAutomatic mode adjusts based on wallpaper and color scheme.")
            
            ConfigSwitch {
                buttonIcon: "ev_shadow"
                text: Translation.tr("Enable Transparency")
                checked: Config.options.appearance.transparency.enable
                onCheckedChanged: {
                    Config.options.appearance.transparency.enable = checked;
                }
            }
            
            ConfigSwitch {
                id: autoTransparencySwitch
                enabled: Config.options.appearance.transparency.enable
                buttonIcon: "auto_awesome"
                text: Translation.tr("Automatic")
                checked: Config.options.appearance.transparency.automatic
                onCheckedChanged: {
                    Config.options.appearance.transparency.automatic = checked;
                    // Sync manual values with current auto values when switching to auto
                    if (checked) {
                        Config.options.appearance.transparency.backgroundTransparency = Appearance.autoBackgroundTransparency;
                        Config.options.appearance.transparency.contentTransparency = Appearance.autoContentTransparency;
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: parent.containsMouse
                        text: {
                            if (autoTransparencySwitch.checked && Config.options.appearance.transparency.enable) {
                                let bg = (Appearance.autoBackgroundTransparency * 100).toFixed(1);
                                let content = (Appearance.autoContentTransparency * 100).toFixed(1);
                                let schemeType = Config?.options?.appearance?.palette?.type ?? "auto";
                                return Translation.tr("Auto: Background %1%, Content %2%\nBased on wallpaper and %3 scheme").arg(bg).arg(content).arg(schemeType === "auto" ? Translation.tr("auto-detected") : schemeType.replace("scheme-", ""));
                            }
                            return Translation.tr("Automatically adjust transparency based on wallpaper and color scheme");
                        }
                    }
                }
            }
            
            ConfigSpinBox {
                id: backgroundTransparencySpinBox
                enabled: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
                icon: "layers"
                text: Translation.tr("Background Transparency (%)")
                value: Config.options.appearance.transparency.automatic 
                    ? (Appearance.autoBackgroundTransparency * 100)
                    : (Config.options.appearance.transparency.backgroundTransparency * 100)
                from: 0
                to: 100
                stepSize: 1
                onValueChanged: {
                    if (!Config.options.appearance.transparency.automatic) {
                        Config.options.appearance.transparency.backgroundTransparency = value / 100;
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: parent.containsMouse
                        text: Translation.tr("Transparency of background layers (0% = opaque, 100% = fully transparent)")
                    }
                }
            }
            
            ConfigSpinBox {
                id: contentTransparencySpinBox
                enabled: Config.options.appearance.transparency.enable && !Config.options.appearance.transparency.automatic
                icon: "layers"
                text: Translation.tr("Content Transparency (%)")
                value: Config.options.appearance.transparency.automatic 
                    ? (Appearance.autoContentTransparency * 100)
                    : (Config.options.appearance.transparency.contentTransparency * 100)
                from: 0
                to: 100
                stepSize: 1
                onValueChanged: {
                    if (!Config.options.appearance.transparency.automatic) {
                        Config.options.appearance.transparency.contentTransparency = value / 100;
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    StyledToolTip {
                        extraVisibleCondition: false
                        alternativeVisibleCondition: parent.containsMouse
                        text: Translation.tr("Transparency of content layers like panels and cards (0% = opaque, 100% = fully transparent)")
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "screenshot_monitor"
        title: Translation.tr("Bar & screen")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Bar style")

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")

                ConfigSelectionArray {
                    currentValue: Config.options.appearance.fakeScreenRounding
                    onSelected: newValue => {
                        Config.options.appearance.fakeScreenRounding = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("When not fullscreen"),
                            icon: "fullscreen_exit",
                            value: 2
                        }
                    ]
                }
            }
            
        }

        ContentSubsection {
            title: Translation.tr("System resources")

            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr("Show resources on bar")
                checked: Config.options.bar.resources.enable
                onCheckedChanged: {
                    Config.options.bar.resources.enable = checked;
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("RAM")
                    checked: Config.options.bar.resources.showMemory
                    enabled: Config.options.bar.resources.enable
                    onCheckedChanged: {
                        Config.options.bar.resources.showMemory = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "developer_board"
                    text: Translation.tr("GPU")
                    checked: Config.options.bar.resources.showGpu
                    enabled: Config.options.bar.resources.enable
                    onCheckedChanged: {
                        Config.options.bar.resources.showGpu = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "planner_review"
                    text: Translation.tr("CPU")
                    checked: Config.options.bar.resources.showCpu
                    enabled: Config.options.bar.resources.enable
                    onCheckedChanged: {
                        Config.options.bar.resources.showCpu = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "swap_horiz"
                    text: Translation.tr("Swap (popup)")
                    checked: Config.options.bar.resources.showSwap
                    enabled: Config.options.bar.resources.enable
                    onCheckedChanged: {
                        Config.options.bar.resources.showSwap = checked;
                    }
                }
            }
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr('Not all options are available in this app. You should also check the config file by hitting the "Config file" button on the topleft corner or opening %1 manually.').arg(Directories.shellConfigPath)

        Item {
            Layout.fillWidth: true
        }
        RippleButtonWithIcon {
            id: copyPathButton
            property bool justCopied: false
            Layout.fillWidth: false
            buttonRadius: Appearance.rounding.small
            materialIcon: justCopied ? "check" : "content_copy"
            mainText: justCopied ? Translation.tr("Path copied") : Translation.tr("Copy path")
            onClicked: {
                copyPathButton.justCopied = true
                Quickshell.clipboardText = FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse/config.json`);
                revertTextTimer.restart();
            }
            colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive

            Timer {
                id: revertTextTimer
                interval: 1500
                onTriggered: {
                    copyPathButton.justCopied = false
                }
            }
        }
    }
}
