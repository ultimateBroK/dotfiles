pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    readonly property var keybinds: HyprlandKeybinds.keybinds
    property real spacing: 16
    property real titleSpacing: 7
    property real padding: 4

    // Portrait detection using Screen attached property
    readonly property bool isPortrait: Screen.height > Screen.width

    // Flatten all sections (skip workspace 11-20) for portrait 2-column grid
    readonly property var portraitSections: {
        var result = [];
        for (var i = 0; i < keybinds.children.length; i++) {
            const group = keybinds.children[i];
            for (var j = 0; j < group.children.length; j++) {
                const section = group.children[j];
                if (/workspace\s+11-20/i.test(section.name || "")) continue;
                result.push(section);
            }
        }
        return result;
    }

    implicitWidth: isPortrait
        ? portraitContainer.implicitWidth + padding * 2
        : row.implicitWidth + padding * 2
    implicitHeight: isPortrait
        ? portraitContainer.implicitHeight + padding * 2
        : row.implicitHeight + padding * 2

    // Excellent symbol explanation and source:
    // http://xahlee.info/comp/unicode_computing_symbols.html
    // https://www.nerdfonts.com/cheat-sheet
    property var macSymbolMap: ({
        "Ctrl": "󰘴",
        "Alt": "󰘵",
        "Shift": "󰘶",
        "Space": "󱁐",
        "Tab": "↹",
        "Equal": "󰇼",
        "Minus": "",
        "Print": "",
        "BackSpace": "󰭜",
        "Delete": "⌦",
        "Return": "󰌑",
        "Period": ".",
        "Escape": "⎋"
      })
    property var functionSymbolMap: ({
        "F1":  "󱊫",
        "F2":  "󱊬",
        "F3":  "󱊭",
        "F4":  "󱊮",
        "F5":  "󱊯",
        "F6":  "󱊰",
        "F7":  "󱊱",
        "F8":  "󱊲",
        "F9":  "󱊳",
        "F10": "󱊴",
        "F11": "󱊵",
        "F12": "󱊶",
    })
    property var mouseSymbolMap: ({
        "mouse_up": "󱕐",
        "mouse_down": "󱕑",
        "mouse:272": "L󰍽",
        "mouse:273": "R󰍽",
        "Scroll ↑/↓": "󱕒",
        "Page_↑/↓": "⇞/⇟",
    })

    property var keyBlacklist: ["Super_L"]
    property var keySubstitutions: Object.assign({
        "Super": "",
        "mouse_up": "Scroll ↓",
        "mouse_down": "Scroll ↑",
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse:275": "MouseBack",
        "Slash": "/",
        "Hash": "#",
        "Return": "Enter",
      },
      !!Config.options.cheatsheet.superKey ? {
          "Super": Config.options.cheatsheet.superKey,
      }: {},
      Config.options.cheatsheet.useMacSymbol ? macSymbolMap : {},
      Config.options.cheatsheet.useFnSymbol ? functionSymbolMap : {},
      Config.options.cheatsheet.useMouseSymbol ? mouseSymbolMap : {},
    )

    // ─── LANDSCAPE: horizontal Row (unchanged) ────────────────────────────────
    Row {
        id: row
        visible: !root.isPortrait
        spacing: root.spacing

        Repeater {
            model: keybinds.children

            delegate: Column {
                spacing: root.spacing
                required property var modelData
                anchors.top: row.top

                Repeater {
                    model: {
                        var filtered = [];
                        for (var i = 0; i < modelData.children.length; i++) {
                            const section = modelData.children[i];
                            if (/workspace\s+11-20/i.test(section.name || "")) continue;
                            filtered.push(section);
                        }
                        return filtered;
                    }

                    delegate: Item {
                        id: keybindSection
                        required property var modelData
                        implicitWidth: sectionColumn.implicitWidth
                        implicitHeight: sectionColumn.implicitHeight

                        Column {
                            id: sectionColumn
                            anchors.centerIn: parent
                            spacing: root.titleSpacing

                            StyledText {
                                font {
                                    family: Appearance.font.family.title
                                    pixelSize: Appearance.font.pixelSize.title
                                    variableAxes: Appearance.font.variableAxes.title
                                }
                                color: Appearance.colors.colOnLayer0
                                text: keybindSection.modelData.name
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 4
                                rowSpacing: 4

                                Repeater {
                                    model: buildKeybindModel(keybindSection.modelData)
                                    delegate: keybindDelegate
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── PORTRAIT: 2-column grid inside Flickable ─────────────────────────────
    Item {
        id: portraitContainer
        visible: root.isPortrait
        width: root.isPortrait ? parent.width : 0
        implicitWidth: portraitFlickable.width
        implicitHeight: portraitFlickable.implicitHeight

        Flickable {
            id: portraitFlickable
            width: parent.width
            implicitHeight: Math.min(portraitGrid.implicitHeight, Screen.height - 120)
            height: implicitHeight
            contentWidth: width
            contentHeight: portraitGrid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            GridLayout {
                id: portraitGrid
                width: parent.width
                columns: 2
                columnSpacing: root.spacing
                rowSpacing: root.spacing

                Repeater {
                    model: root.portraitSections

                    delegate: Item {
                        id: portraitSection
                        required property var modelData
                        // Each cell fills half the grid width
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        implicitHeight: portraitSectionCol.implicitHeight

                        Column {
                            id: portraitSectionCol
                            width: parent.width
                            spacing: root.titleSpacing

                            StyledText {
                                font {
                                    family: Appearance.font.family.title
                                    pixelSize: Appearance.font.pixelSize.title
                                    variableAxes: Appearance.font.variableAxes.title
                                }
                                color: Appearance.colors.colOnLayer0
                                text: portraitSection.modelData.name
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 4
                                rowSpacing: 4

                                Repeater {
                                    model: buildKeybindModel(portraitSection.modelData)
                                    delegate: keybindDelegate
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Helper: build flat key/comment model for a section ───────────────────
    function buildKeybindModel(sectionData) {
        var result = [];
        for (var i = 0; i < sectionData.keybinds.length; i++) {
            const keybind = sectionData.keybinds[i];
            const comment = keybind.comment || "";
            if (/workspace\s+(1[1-9]|20)/i.test(comment)) continue;

            if (!Config.options.cheatsheet.splitButtons) {
                for (var j = 0; j < keybind.mods.length; j++) {
                    keybind.mods[j] = root.keySubstitutions[keybind.mods[j]] || keybind.mods[j];
                }
                keybind.mods = [keybind.mods.join(' ')];
                keybind.mods[0] += !root.keyBlacklist.includes(keybind.key) && keybind.mods[0].length ? ' ' : '';
                keybind.mods[0] += !root.keyBlacklist.includes(keybind.key)
                    ? (root.keySubstitutions[keybind.key] || keybind.key) : '';
            }

            result.push({ "type": "keys",    "mods": keybind.mods, "key": keybind.key });
            result.push({ "type": "comment", "comment": keybind.comment });
        }
        return result;
    }

    // ─── Shared delegate ──────────────────────────────────────────────────────
    Component {
        id: keybindDelegate
        Item {
            required property var modelData
            implicitWidth: keybindLoader.implicitWidth
            implicitHeight: keybindLoader.implicitHeight

            Loader {
                id: keybindLoader
                sourceComponent: (modelData.type === "keys") ? keysComponent : commentComponent
            }

            Component {
                id: keysComponent
                Row {
                    spacing: 4
                    Repeater {
                        model: modelData.mods
                        delegate: KeyboardKey {
                            required property var modelData
                            key: root.keySubstitutions[modelData] || modelData
                            pixelSize: Config.options.cheatsheet.fontSize.key
                        }
                    }
                    StyledText {
                        visible: Config.options.cheatsheet.splitButtons
                            && !root.keyBlacklist.includes(modelData.key)
                            && modelData.mods.length > 0
                        text: "+"
                    }
                    KeyboardKey {
                        visible: Config.options.cheatsheet.splitButtons
                            && !root.keyBlacklist.includes(modelData.key)
                        key: root.keySubstitutions[modelData.key] || modelData.key
                        pixelSize: Config.options.cheatsheet.fontSize.key
                        color: Appearance.colors.colOnLayer0
                    }
                }
            }

            Component {
                id: commentComponent
                Item {
                    implicitWidth: commentText.implicitWidth + 8 * 2
                    implicitHeight: commentText.implicitHeight

                    StyledText {
                        id: commentText
                        anchors.centerIn: parent
                        font.pixelSize: Config.options.cheatsheet.fontSize.comment
                            || Appearance.font.pixelSize.smaller
                        text: modelData.comment
                    }
                }
            }
        }
    }
}
