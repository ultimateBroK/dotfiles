pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property real spacing: 16
    property real titleSpacing: 7
    property real padding: 4

    readonly property bool isPortrait: Screen.height > Screen.width

    implicitWidth: isPortrait
        ? portraitContainer.implicitWidth + padding * 2
        : row.implicitWidth + padding * 2
    implicitHeight: isPortrait
        ? portraitContainer.implicitHeight + padding * 2
        : row.implicitHeight + padding * 2

    property var commandGroups: [
        {
            name: "System",
            commands: [
                { cmd: "df -h", desc: "Disk usage" },
                { cmd: "free -h", desc: "Memory usage" },
                { cmd: "ps aux", desc: "List processes" },
                { cmd: "top", desc: "Monitor processes" },
                { cmd: "htop", desc: "Interactive process viewer" },
                { cmd: "uptime", desc: "System uptime" },
                { cmd: "uname -a", desc: "System info" },
                { cmd: "whoami", desc: "Current user" },
                { cmd: "pwd", desc: "Current directory" },
                { cmd: "ls -lah", desc: "List files (detailed)" },
                { cmd: "du -sh *", desc: "Directory sizes" },
                { cmd: "journalctl -xe", desc: "System logs" }
            ]
        },
        {
            name: "Package Management",
            commands: [
                { cmd: "pacman -Syu", desc: "Update system (Arch)" },
                { cmd: "pacman -S <pkg>", desc: "Install package (Arch)" },
                { cmd: "pacman -R <pkg>", desc: "Remove package (Arch)" },
                { cmd: "pacman -Ss <search>", desc: "Search packages (Arch)" },
                { cmd: "yay -S <pkg>", desc: "Install AUR package" },
                { cmd: "flatpak update", desc: "Update Flatpaks" },
                { cmd: "flatpak install <app>", desc: "Install Flatpak" },
                { cmd: "cargo install <pkg>", desc: "Install Rust crate" },
                { cmd: "npm install -g <pkg>", desc: "Install npm package" },
                { cmd: "pip install <pkg>", desc: "Install Python package" }
            ]
        },
        {
            name: "File Operations",
            commands: [
                { cmd: "cp <src> <dest>", desc: "Copy file" },
                { cmd: "mv <src> <dest>", desc: "Move/rename file" },
                { cmd: "rm <file>", desc: "Remove file" },
                { cmd: "rm -rf <dir>", desc: "Remove directory" },
                { cmd: "mkdir <dir>", desc: "Create directory" },
                { cmd: "touch <file>", desc: "Create empty file" },
                { cmd: "cat <file>", desc: "View file content" },
                { cmd: "less <file>", desc: "View file (scrollable)" },
                { cmd: "head -n <file>", desc: "First N lines" },
                { cmd: "tail -n <file>", desc: "Last N lines" },
                { cmd: "grep <pattern> <file>", desc: "Search in file" },
                { cmd: "find . -name '<pattern>'", desc: "Find files" }
            ]
        },
        {
            name: "Network",
            commands: [
                { cmd: "ping <host>", desc: "Test connectivity" },
                { cmd: "curl <url>", desc: "Download/request URL" },
                { cmd: "wget <url>", desc: "Download file" },
                { cmd: "ip addr", desc: "Show IP addresses" },
                { cmd: "ip route", desc: "Show routing table" },
                { cmd: "ss -tulpn", desc: "Show listening ports" },
                { cmd: "nmcli device status", desc: "Network status" },
                { cmd: "nmap <target>", desc: "Network scan" }
            ]
        },
        {
            name: "Archives",
            commands: [
                { cmd: "tar -czf <archive.tar.gz> <dir>", desc: "Create tar.gz" },
                { cmd: "tar -xzf <archive.tar.gz>", desc: "Extract tar.gz" },
                { cmd: "zip -r <archive.zip> <dir>", desc: "Create zip" },
                { cmd: "unzip <archive.zip>", desc: "Extract zip" },
                { cmd: "7z x <archive.7z>", desc: "Extract 7z" }
            ]
        }
    ]

    // ─── LANDSCAPE: horizontal Row (unchanged) ────────────────────────────────
    Row {
        id: row
        visible: !root.isPortrait
        spacing: root.spacing

        Repeater {
            model: root.commandGroups

            delegate: Column {
                spacing: root.spacing
                required property var modelData
                anchors.top: row.top

                Column {
                    id: sectionColumn
                    spacing: root.titleSpacing

                    StyledText {
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.title
                            variableAxes: Appearance.font.variableAxes.title
                        }
                        color: Appearance.colors.colOnLayer0
                        text: sectionColumn.parent.modelData.name
                    }

                    Column {
                        spacing: 4
                        Repeater {
                            model: sectionColumn.parent.modelData.commands
                            delegate: commandItemDelegate
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
                    model: root.commandGroups

                    delegate: Column {
                        id: cmdGroup
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: root.titleSpacing

                        StyledText {
                            font {
                                family: Appearance.font.family.title
                                pixelSize: Appearance.font.pixelSize.title
                                variableAxes: Appearance.font.variableAxes.title
                            }
                            color: Appearance.colors.colOnLayer0
                            text: cmdGroup.modelData.name
                        }

                        Column {
                            spacing: 4
                            Repeater {
                                model: cmdGroup.modelData.commands
                                delegate: commandItemDelegate
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Shared command item delegate ─────────────────────────────────────────
    Component {
        id: commandItemDelegate
        RippleButton {
            required property var modelData
            implicitWidth: commandRow.implicitWidth + 8 * 2
            implicitHeight: commandRow.implicitHeight + 4 * 2
            buttonRadius: Appearance.rounding.small
            colBackground: Appearance.colors.colLayer1

            onClicked: {
                Quickshell.clipboardText = modelData.cmd;
            }

            contentItem: Row {
                id: commandRow
                anchors.centerIn: parent
                spacing: 8
                StyledText {
                    font {
                        family: Appearance.font.family.monospace
                        pixelSize: Config.options.cheatsheet.fontSize.key
                            || Appearance.font.pixelSize.smaller
                    }
                    color: Appearance.colors.colPrimary
                    text: modelData.cmd
                }
                StyledText {
                    text: "→"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Config.options.cheatsheet.fontSize.key
                        || Appearance.font.pixelSize.smaller
                }
                StyledText {
                    font.pixelSize: Config.options.cheatsheet.fontSize.comment
                        || Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer0
                    text: modelData.desc
                }
            }
        }
    }
}
