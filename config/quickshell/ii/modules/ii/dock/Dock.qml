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
                        Rectangle { // The real rectangle that is visible
                            id: dockVisualBackground
                            property real margin: dockRoot.dockShadowPad
                            anchors.fill: parent
                            anchors.topMargin: dockRoot.dockAtTop ? dockRoot.dockEdgeGap : dockRoot.dockShadowPad
                            anchors.bottomMargin: dockRoot.dockAtTop ? dockRoot.dockShadowPad : dockRoot.dockEdgeGap
                            implicitWidth: dockRow.implicitWidth + dockRow.padding * 2
                            // macOS-like "frosted" dock:
                            // - compositor blur comes from Hyprland layerrules
                            // - we keep the background semi-transparent + add a subtle highlight gradient
                            clip: true
                            color: ColorUtils.applyAlpha(
                                // "Smoky glass" tint (dark instead of milky/white)
                                ColorUtils.mix(
                                    Appearance.colors.colLayer0,
                                    Appearance.m3colors.m3background,
                                    Appearance.isDarkMode ? 0.22 : 0.30
                                ),
                                // Lower alpha = clearer glass
                                Appearance.isDarkMode ? 0.34 : 0.26
                            )
                            border.width: 1
                            border.color: ColorUtils.applyAlpha(
                                Appearance.colors.colLayer0Border,
                                Appearance.isDarkMode ? 0.32 : 0.24
                            )

                            radius: 15

                            // Subtle glass highlight (top) + shade (bottom)
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: Appearance.isDarkMode
                                            ? Qt.rgba(1, 1, 1, 0.08)
                                            : Qt.rgba(1, 1, 1, 0.10)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Appearance.isDarkMode
                                            ? Qt.rgba(0, 0, 0, 0.12)
                                            : Qt.rgba(0, 0, 0, 0.08)
                                    }
                                }
                            }

                            // Inner highlight stroke for "glass" edge
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Math.max(0, parent.radius - 1)
                                color: "transparent"
                                border.width: 1
                                border.color: Appearance.isDarkMode
                                    ? Qt.rgba(1, 1, 1, 0.07)
                                    : Qt.rgba(1, 1, 1, 0.09)
                            }

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