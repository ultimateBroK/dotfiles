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
            tooltip: Translation.tr("Select how colors are generated from your wallpaper.\nAuto will intelligently detect the best scheme for your image.\n\nEach scheme type produces different color characteristics:\n• Auto: Intelligently selects the best scheme\n• Content: Natural, content-focused colors\n• Expressive: Bold and artistic colors\n• Fidelity: Accurate color representation\n• Fruit Salad: Bright, colorful palette\n• Monochrome: Grayscale only\n• Neutral: Subtle, muted tones\n• Rainbow: Full spectrum colors\n• Tonal Spot: Single accent color\n• Vibrant: High saturation colors")
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                
                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    text: Translation.tr("Choose a color generation method that matches your style preference")
                    wrapMode: Text.WordWrap
                }
                
                ConfigSelectionArray {
                    id: colorTypeSelector
                    Layout.fillWidth: true
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
                            "icon": "auto_awesome",
                            "description": Translation.tr("Intelligently detects the best color scheme for your wallpaper")
                        },
                        {
                            "value": "scheme-content",
                            "displayName": Translation.tr("Content"),
                            "icon": "palette",
                            "description": Translation.tr("Natural colors optimized for content readability")
                        },
                        {
                            "value": "scheme-expressive",
                            "displayName": Translation.tr("Expressive"),
                            "icon": "brush",
                            "description": Translation.tr("Bold and artistic colors with high visual impact")
                        },
                        {
                            "value": "scheme-fidelity",
                            "displayName": Translation.tr("Fidelity"),
                            "icon": "photo",
                            "description": Translation.tr("Accurate color representation from your wallpaper")
                        },
                        {
                            "value": "scheme-fruit-salad",
                            "displayName": Translation.tr("Fruit Salad"),
                            "icon": "colorize",
                            "description": Translation.tr("Bright, colorful palette with multiple vibrant hues")
                        },
                        {
                            "value": "scheme-monochrome",
                            "displayName": Translation.tr("Monochrome"),
                            "icon": "invert_colors_off",
                            "description": Translation.tr("Grayscale only - no color saturation")
                        },
                        {
                            "value": "scheme-neutral",
                            "displayName": Translation.tr("Neutral"),
                            "icon": "tune",
                            "description": Translation.tr("Subtle, muted tones for a calm aesthetic")
                        },
                        {
                            "value": "scheme-rainbow",
                            "displayName": Translation.tr("Rainbow"),
                            "icon": "gradient",
                            "description": Translation.tr("Full spectrum colors across the entire palette")
                        },
                        {
                            "value": "scheme-tonal-spot",
                            "displayName": Translation.tr("Tonal Spot"),
                            "icon": "circle",
                            "description": Translation.tr("Single accent color with neutral base")
                        },
                        {
                            "value": "scheme-vibrant",
                            "displayName": Translation.tr("Vibrant"),
                            "icon": "flare",
                            "description": Translation.tr("High saturation colors for maximum vibrancy")
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
                
                // Current selection info
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8
                    visible: Config.options.appearance.palette.type !== "auto"
                    
                    MaterialSymbol {
                        iconSize: Appearance.font.pixelSize.small
                        text: "info"
                        color: Appearance.colors.colSubtext
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        text: {
                            let current = Config.options.appearance.palette.type;
                            let option = colorTypeSelector.options.find(opt => opt.value === current);
                            return option ? option.description : "";
                        }
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Wallpaper Scale")
            tooltip: Translation.tr("Adjust the zoom level and scaling mode of your wallpaper.\nHigher zoom values allow more parallax movement when switching workspaces.")
            Layout.topMargin: 16
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                
                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    text: Translation.tr("Choose how your wallpaper is scaled and displayed on screen")
                    wrapMode: Text.WordWrap
                }
                
                ConfigSelectionArray {
                    id: fillModeSelector
                    Layout.fillWidth: true
                    currentValue: Config.options.background.fillMode || "crop"
                    onSelected: newValue => {
                        Config.options.background.fillMode = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Crop"),
                            icon: "crop",
                            value: "crop",
                            description: Translation.tr("Crops the image to fill the screen while maintaining aspect ratio")
                        },
                        {
                            displayName: Translation.tr("Fit"),
                            icon: "fit_screen",
                            value: "fit",
                            description: Translation.tr("Fits the entire image on screen, may show letterboxing")
                        },
                        {
                            displayName: Translation.tr("Stretch"),
                            icon: "open_in_full",
                            value: "stretch",
                            description: Translation.tr("Stretches the image to fill the entire screen, may distort aspect ratio")
                        },
                        {
                            displayName: Translation.tr("Tile"),
                            icon: "grid_on",
                            value: "tile",
                            description: Translation.tr("Repeats the image in a grid pattern across the screen")
                        },
                        {
                            displayName: Translation.tr("Pad"),
                            icon: "crop_free",
                            value: "pad",
                            description: Translation.tr("Centers the image and fills remaining space with background color")
                        }
                    ]
                }
                
                // Current selection info
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8
                    
                    MaterialSymbol {
                        iconSize: Appearance.font.pixelSize.small
                        text: "info"
                        color: Appearance.colors.colSubtext
                    }
                    
                    StyledText {
                        Layout.fillWidth: true
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        text: {
                            let current = Config.options.background.fillMode || "crop";
                            let option = fillModeSelector.options.find(opt => opt.value === current);
                            return option ? option.description : "";
                        }
                        wrapMode: Text.WordWrap
                    }
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
        }

        ContentSubsection {
            title: Translation.tr("Transparency")
            tooltip: Translation.tr("Control transparency of backgrounds and content.\nAutomatic mode adjusts based on wallpaper and color scheme.")
            Layout.topMargin: 16
            
            Component.onCompleted: {
                // Initialize null transparency values on component load
                if (Config.options.appearance.transparency.enable) {
                    if (Config.options.appearance.transparency.backgroundTransparency === null || Config.options.appearance.transparency.backgroundTransparency === undefined) {
                        Config.options.appearance.transparency.backgroundTransparency = Appearance.autoBackgroundTransparency;
                    }
                    if (Config.options.appearance.transparency.contentTransparency === null || Config.options.appearance.transparency.contentTransparency === undefined) {
                        Config.options.appearance.transparency.contentTransparency = Appearance.autoContentTransparency;
                    }
                }
            }
            
            ConfigSwitch {
                buttonIcon: "ev_shadow"
                text: Translation.tr("Enable Transparency")
                checked: Config.options.appearance.transparency.enable
                onCheckedChanged: {
                    Config.options.appearance.transparency.enable = checked;
                    // Initialize transparency values if they are null when enabling
                    if (checked) {
                        if (Config.options.appearance.transparency.backgroundTransparency === null || Config.options.appearance.transparency.backgroundTransparency === undefined) {
                            Config.options.appearance.transparency.backgroundTransparency = Appearance.autoBackgroundTransparency;
                        }
                        if (Config.options.appearance.transparency.contentTransparency === null || Config.options.appearance.transparency.contentTransparency === undefined) {
                            Config.options.appearance.transparency.contentTransparency = Appearance.autoContentTransparency;
                        }
                    }
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
                    } else {
                        // When switching to manual mode, initialize null values with current auto values
                        if (Config.options.appearance.transparency.backgroundTransparency === null || Config.options.appearance.transparency.backgroundTransparency === undefined) {
                            Config.options.appearance.transparency.backgroundTransparency = Appearance.autoBackgroundTransparency;
                        }
                        if (Config.options.appearance.transparency.contentTransparency === null || Config.options.appearance.transparency.contentTransparency === undefined) {
                            Config.options.appearance.transparency.contentTransparency = Appearance.autoContentTransparency;
                        }
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
                value: {
                    if (Config.options.appearance.transparency.automatic) {
                        return Appearance.autoBackgroundTransparency * 100;
                    }
                    let manualValue = Config.options.appearance.transparency.backgroundTransparency;
                    // Handle null/undefined values by using auto value as fallback
                    if (manualValue === null || manualValue === undefined) {
                        manualValue = Appearance.autoBackgroundTransparency;
                        Config.options.appearance.transparency.backgroundTransparency = manualValue;
                    }
                    return manualValue * 100;
                }
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
                value: {
                    if (Config.options.appearance.transparency.automatic) {
                        return Appearance.autoContentTransparency * 100;
                    }
                    let manualValue = Config.options.appearance.transparency.contentTransparency;
                    // Handle null/undefined values by using auto value as fallback
                    if (manualValue === null || manualValue === undefined) {
                        manualValue = Appearance.autoContentTransparency;
                        Config.options.appearance.transparency.contentTransparency = manualValue;
                    }
                    return manualValue * 100;
                }
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
                tooltip: Translation.tr("Choose where the bar appears on your screen")
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    ConfigSelectionArray {
                        id: barPositionSelector
                        Layout.fillWidth: true
                        currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                        onSelected: newValue => {
                            Config.options.bar.bottom = (newValue & 1) !== 0;
                            Config.options.bar.vertical = (newValue & 2) !== 0;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Top"),
                                icon: "arrow_upward",
                                value: 0,
                                description: Translation.tr("Bar appears at the top of the screen")
                            },
                            {
                                displayName: Translation.tr("Left"),
                                icon: "arrow_back",
                                value: 2,
                                description: Translation.tr("Bar appears on the left side of the screen")
                            },
                            {
                                displayName: Translation.tr("Bottom"),
                                icon: "arrow_downward",
                                value: 1,
                                description: Translation.tr("Bar appears at the bottom of the screen")
                            },
                            {
                                displayName: Translation.tr("Right"),
                                icon: "arrow_forward",
                                value: 3,
                                description: Translation.tr("Bar appears on the right side of the screen")
                            }
                        ]
                    }
                    
                    // Current selection info
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8
                        visible: barPositionSelector.currentValue !== null
                        
                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.small
                            text: "info"
                            color: Appearance.colors.colSubtext
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            text: {
                                let current = barPositionSelector.currentValue;
                                let option = barPositionSelector.options.find(opt => opt.value === current);
                                return option ? option.description : "";
                            }
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
            ContentSubsection {
                title: Translation.tr("Bar style")
                tooltip: Translation.tr("Choose the visual style of the bar")

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    ConfigSelectionArray {
                        id: barStyleSelector
                        Layout.fillWidth: true
                        currentValue: Config.options.bar.cornerStyle
                        onSelected: newValue => {
                            Config.options.bar.cornerStyle = newValue; // Update local copy
                        }
                        options: [
                            {
                                displayName: Translation.tr("Hug"),
                                icon: "line_curve",
                                value: 0,
                                description: Translation.tr("Bar hugs the screen edges with rounded corners")
                            },
                            {
                                displayName: Translation.tr("Float"),
                                icon: "page_header",
                                value: 1,
                                description: Translation.tr("Bar floats above the screen with margins and shadow")
                            },
                            {
                                displayName: Translation.tr("Rect"),
                                icon: "toolbar",
                                value: 2,
                                description: Translation.tr("Bar has rectangular shape with sharp corners")
                            }
                        ]
                    }
                    
                    // Current selection info
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8
                        visible: barStyleSelector.currentValue !== null
                        
                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.small
                            text: "info"
                            color: Appearance.colors.colSubtext
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            text: {
                                let current = barStyleSelector.currentValue;
                                let option = barStyleSelector.options.find(opt => opt.value === current);
                                return option ? option.description : "";
                            }
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Screen round corner")
                tooltip: Translation.tr("Adds rounded corners to the screen edges for a modern look.\nThis creates a visual effect that makes the screen appear rounded.")
                Layout.topMargin: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        text: Translation.tr("Enable rounded screen corners for a modern aesthetic")
                        wrapMode: Text.WordWrap
                    }
                    
                    ConfigSelectionArray {
                        id: screenRoundingSelector
                        Layout.fillWidth: true
                        currentValue: Config.options.appearance.fakeScreenRounding
                        onSelected: newValue => {
                            Config.options.appearance.fakeScreenRounding = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("No"),
                                icon: "close",
                                value: 0,
                                description: Translation.tr("No rounded corners - sharp screen edges")
                            },
                            {
                                displayName: Translation.tr("Yes"),
                                icon: "check",
                                value: 1,
                                description: Translation.tr("Always show rounded corners on screen edges")
                            },
                            {
                                displayName: Translation.tr("When not fullscreen"),
                                icon: "fullscreen_exit",
                                value: 2,
                                description: Translation.tr("Show rounded corners only when windows are not fullscreen")
                            }
                        ]
                    }
                    
                    // Current selection info
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8
                        visible: screenRoundingSelector.currentValue !== null
                        
                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.small
                            text: "info"
                            color: Appearance.colors.colSubtext
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            text: {
                                let current = screenRoundingSelector.currentValue;
                                let option = screenRoundingSelector.options.find(opt => opt.value === current);
                                return option ? option.description : "";
                            }
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
            
        }

        ContentSubsection {
            title: Translation.tr("System resources")
            tooltip: Translation.tr("Monitor system resource usage and display it on the bar.\nConfigure which resources to track and display.")
            Layout.topMargin: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                
                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    text: Translation.tr("Enable system resource monitoring and choose which metrics to display on the bar")
                    wrapMode: Text.WordWrap
                }

                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("Show resources on bar")
                    checked: Config.options.bar.resources.enable
                    onCheckedChanged: {
                        Config.options.bar.resources.enable = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Enable or disable system resource monitoring on the bar")
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
                        StyledToolTip {
                            text: Translation.tr("Display RAM (memory) usage percentage on the bar")
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
                        StyledToolTip {
                            text: Translation.tr("Display GPU (graphics card) usage percentage on the bar")
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
                        StyledToolTip {
                            text: Translation.tr("Display CPU (processor) usage percentage on the bar")
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
                        StyledToolTip {
                            text: Translation.tr("Show swap usage in a popup when hovering over resource indicators")
                        }
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
