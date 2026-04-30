import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property bool dockAtTop: false
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton
    property bool buttonHovered: false
    property bool requestDockShow: previewPopup.show

    Layout.fillHeight: true
    implicitWidth: listView.implicitWidth
    
    StyledListView {
        id: listView
        spacing: 2
        orientation: ListView.Horizontal
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        implicitWidth: contentWidth

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: TaskbarApps.apps
        }
        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root

            topInset: 0
            bottomInset: 0
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel
        property bool allPreviewsReady: false
        property bool hasPreviewItems: (previewRowLayout.children.length > 0)
        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                previewPopup.allPreviewsReady = false; // Reset readiness when the hovered button changes
                previewPopup.updatePreviewReadiness();
            } 
        }
        function updatePreviewReadiness() {
            if (previewRowLayout.children.length === 0) {
                allPreviewsReady = false;
                return;
            }
            for(var i = 0; i < previewRowLayout.children.length; i++) {
                const view = previewRowLayout.children[i];
                if (view.hasContent === false) {
                    allPreviewsReady = false;
                    return;
                }
            }
            allPreviewsReady = true;
        }
        property bool shouldShow: {
            const hoverConditions = (popupMouseArea.containsMouse || root.buttonHovered)
            return hoverConditions && hasPreviewItems;
        }
        property bool show: false

        onShouldShowChanged: {
            previewPopup.show = previewPopup.shouldShow
        }
        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: (root.dockAtTop ? Edges.Bottom : Edges.Top) | Edges.Right
            edges: (root.dockAtTop ? Edges.Bottom : Edges.Top) | Edges.Left

        }
        visible: popupBackground.visible
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: root.dockAtTop ? undefined : parent.bottom
            anchors.top: root.dockAtTop ? parent.top : undefined
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            x: {
                const itemCenter = root.QsWindow?.mapFromItem(root.lastHoveredButton, root.lastHoveredButton?.width / 2, 0);
                return itemCenter.x - width / 2
            }
            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
            AmoledGlassRect {
                id: popupBackground
                // Keep preview popup in glass mode for consistent frosted look with dock.
                amoledVariant: true
                highlightEnabled: true
                property real padding: 5
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                clip: true
                glassColor: Appearance.isDarkMode ? "#000000" : "#e8e4e4"
                glassTransparency: Appearance.isDarkMode ? 0.38 : 0.32
                highlightOpacity: (Appearance?.isDarkMode ?? true) ? 0.035 : 0.03
                shadeOpacity: (Appearance?.isDarkMode ?? true) ? 0.03 : 0.02
                border.width: 1
                border.color: Appearance.isDarkMode
                    ? ColorUtils.applyAlpha("#ffffff", 0.10)
                    : ColorUtils.applyAlpha("#ffffff", 0.32)
                radius: Appearance.rounding.large

                Behavior on glassColor {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on glassTransparency {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on border.color {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                anchors.bottom: root.dockAtTop ? undefined : parent.bottom
                anchors.top: root.dockAtTop ? parent.top : undefined
                anchors.bottomMargin: root.dockAtTop ? 0 : Appearance.sizes.elevationMargin
                anchors.topMargin: root.dockAtTop ? Appearance.sizes.elevationMargin : 0
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on implicitHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent
                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }
                        RippleButton {
                            id: windowButton
                            required property var modelData
                            padding: 0
                            middleClickAction: () => {
                                windowButton.modelData?.close();
                            }
                            onClicked: {
                                windowButton.modelData?.activate();
                            }
                            contentItem: ColumnLayout {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    WrapperRectangle {
                                        Layout.fillWidth: true
                                        color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        radius: Appearance.rounding.large
                                        margin: 5
                                        StyledText {
                                            Layout.fillWidth: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            text: windowButton.modelData?.title
                                            elide: Text.ElideRight
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                    }
                                    GroupButton {
                                        id: closeButton
                                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        baseWidth: windowControlsHeight
                                        baseHeight: windowControlsHeight
                                        buttonRadius: Appearance.rounding.large
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: {
                                            windowButton.modelData?.close();
                                        }
                                    }
                                }
                                ScreencopyView {
                                    id: screencopyView
                                    captureSource: previewPopup ? windowButton.modelData : null
                                    live: true
                                    paintCursor: true
                                    constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                    onHasContentChanged: {
                                        previewPopup.updatePreviewReadiness();
                                    }
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: screencopyView.width
                                            height: screencopyView.height
                                            radius: Appearance.rounding.large
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
}