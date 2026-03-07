pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property real spacing: 20
    property real titleSpacing: 7
    property real padding: 4
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: row.implicitHeight + padding * 2

    property var commandGroups: [
        {
            name: "Init & Config",
            commands: [
                { cmd: "git init", desc: "Initialize a new repository" },
                { cmd: "git clone <url>", desc: "Clone a repository" },
                { cmd: "git config --global user.name <name>", desc: "Set username" },
                { cmd: "git config --global user.email <email>", desc: "Set email" }
            ]
        },
        {
            name: "Basic Snapshotting",
            commands: [
                { cmd: "git status", desc: "Check repository status" },
                { cmd: "git add .", desc: "Stage all changes" },
                { cmd: "git add <file>", desc: "Stage specific file" },
                { cmd: "git commit -m 'msg'", desc: "Commit changes" },
                { cmd: "git diff", desc: "Show unstaged changes" },
                { cmd: "git diff --staged", desc: "Show staged changes" }
            ]
        },
        {
            name: "Branching & Merging",
            commands: [
                { cmd: "git branch", desc: "List branches" },
                { cmd: "git checkout -b <branch>", desc: "Create and switch branch" },
                { cmd: "git checkout <branch>", desc: "Switch branch" },
                { cmd: "git merge <branch>", desc: "Merge branch into current" },
                { cmd: "git branch -d <branch>", desc: "Delete local branch" }
            ]
        },
        {
            name: "Sharing & Updating",
            commands: [
                { cmd: "git fetch", desc: "Download all history from remote" },
                { cmd: "git pull", desc: "Fetch and merge from remote" },
                { cmd: "git push", desc: "Push to remote" },
                { cmd: "git remote -v", desc: "List remote connections" }
            ]
        },
        {
            name: "Inspect & Compare",
            commands: [
                { cmd: "git log", desc: "View commit history" },
                { cmd: "git log --oneline", desc: "View compact commit history" },
                { cmd: "git show <commit>", desc: "View changes of a commit" }
            ]
        }
    ]

    Row { // Command columns
        id: row
        spacing: root.spacing
        
        Repeater {
            model: root.commandGroups
            
            delegate: Column { // Command sections
                spacing: root.spacing
                required property var modelData
                anchors.top: row.top

                Column {
                    id: sectionColumn
                    spacing: root.titleSpacing
                    
                    StyledText {
                        id: sectionTitle
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.title
                            variableAxes: Appearance.font.variableAxes.title
                        }
                        color: Appearance.colors.colOnLayer0
                        text: sectionColumn.parent.modelData.name
                    }

                    Column {
                        id: commandColumn
                        spacing: 4

                        Repeater {
                            model: sectionColumn.parent.modelData.commands
                            
                            delegate: RippleButton {
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
                                        id: commandText
                                        font {
                                            family: Appearance.font.family.monospace
                                            pixelSize: Config.options.cheatsheet.fontSize.key || Appearance.font.pixelSize.smaller
                                        }
                                        color: Appearance.colors.colPrimary
                                        text: modelData.cmd
                                    }
                                    StyledText {
                                        text: "→"
                                        color: Appearance.colors.colSubtext
                                        font.pixelSize: Config.options.cheatsheet.fontSize.key || Appearance.font.pixelSize.smaller
                                    }
                                    StyledText {
                                        id: descText
                                        font.pixelSize: Config.options.cheatsheet.fontSize.comment || Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colOnLayer0
                                        text: modelData.desc
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
