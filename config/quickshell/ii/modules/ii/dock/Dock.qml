import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root
    property bool pinned: Config.options?.dock.pinnedOnStartup ?? false

    Variants {
        // For each monitor
        model: Quickshell.screens

        PanelWindow {
            id: dockRoot
            // Window
            required property var modelData
            screen: modelData
            visible: !GlobalStates.screenLocked

            // When the horizontal bar is moved to the bottom, move the dock to the top edge.
            // Note: `Config.options.bar.bottom` is overloaded (horizontal: bottom; vertical: right).
            readonly property bool dockAtTop: (!Config.options.bar.vertical && Config.options.bar.bottom)
            readonly property real dockShadowPad: Appearance.sizes.elevationMargin
            // Bring dock closer to the screen edge than the default Hyprland outer gap.
            readonly property real dockEdgeGap: Appearance.sizes.hyprlandGapsOut * 0.5

            property bool reveal: root.pinned || (Config.options?.dock.hoverToReveal && dockMouseArea.containsMouse) || dockApps.requestDockShow || (!ToplevelManager.activeToplevel?.activated)

            anchors {
                top: dockRoot.dockAtTop
                bottom: !dockRoot.dockAtTop
                left: true
                right: true
            }

            // Reserve the visible dock surface (+ edge gap) when pinned.
            exclusiveZone: root.pinned ? ((Config.options?.dock.height ?? 70) + dockRoot.dockEdgeGap) : 0

            implicitWidth: dockBackground.implicitWidth
            WlrLayershell.namespace: "quickshell:dock"
            color: "transparent"

            implicitHeight: (Config.options?.dock.height ?? 70) + dockRoot.dockShadowPad + dockRoot.dockEdgeGap

            mask: Region {
                item: dockMouseArea
            }

            MouseArea {
                id: dockMouseArea
                height: parent.height
                anchors {
                    top: dockRoot.dockAtTop ? undefined : parent.top
                    bottom: dockRoot.dockAtTop ? parent.bottom : undefined
                    topMargin: dockRoot.dockAtTop
                        ? 0
                        : (dockRoot.reveal
                            ? 0
                            : (Config.options?.dock.hoverToReveal
                                ? (dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight)
                                : (dockRoot.implicitHeight + 1)))
                    bottomMargin: dockRoot.dockAtTop
                        ? (dockRoot.reveal
                            ? 0
                            : (Config.options?.dock.hoverToReveal
                                ? (dockRoot.implicitHeight - Config.options.dock.hoverRegionHeight)
                                : (dockRoot.implicitHeight + 1)))
                        : 0
                    horizontalCenter: parent.horizontalCenter
                }
                implicitWidth: dockHoverRegion.implicitWidth + Appearance.sizes.elevationMargin * 2
                hoverEnabled: true

                Behavior on anchors.topMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Behavior on anchors.bottomMargin {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Item {
                    id: dockHoverRegion
                    anchors.fill: parent
                    implicitWidth: dockBackground.implicitWidth

                    Item { // Wrapper for the dock background
                        id: dockBackground
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                        }

                        implicitWidth: dockVisualBackground.implicitWidth

                        height: parent.height - dockRoot.dockShadowPad - dockRoot.dockEdgeGap

                        StyledRectangularShadow {
                            target: dockVisualBackground
                        }
                        Rectangle { // AMOLED glassmorphism (same as topbar/sidebar)
                            id: dockVisualBackground
                            property real margin: dockRoot.dockShadowPad
                            anchors.fill: parent
                            anchors.topMargin: dockRoot.dockAtTop ? dockRoot.dockEdgeGap : dockRoot.dockShadowPad
                            anchors.bottomMargin: dockRoot.dockAtTop ? dockRoot.dockShadowPad : dockRoot.dockEdgeGap
                            implicitWidth: dockRow.implicitWidth + dockRow.padding * 2
                            clip: true
                            color: Qt.rgba(0, 0, 0, 0.45)
                            border.width: 1
                            border.color: ColorUtils.applyAlpha("#ffffff", 0.08)
                            radius: 15

                                RowLayout {
                                    id: dockRow
                                    anchors.fill: parent
                                    anchors.margins: padding
                                    spacing: 3
                                    property real padding: 5

                                    DockApps {
                                        id: dockApps
                                        buttonPadding: dockRow.padding
                                        dockAtTop: dockRoot.dockAtTop
                                    }
                                    DockSeparator {}
                                DockButton {
                                    Layout.fillHeight: true
                                    onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                                    topInset: 0
                                    bottomInset: 0
                                    contentItem: MaterialSymbol {
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: parent.width / 2
                                        text: "apps"
                                        color: Appearance.colors.colOnLayer0
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