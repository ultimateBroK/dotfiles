import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root
    required property QsMenuHandle trayItemMenuHandle
    property real popupBackgroundMargin: 0

    signal menuClosed
    signal menuOpened(qsWindow: var) // Correct type is QsWindow, but QML does not like that

    color: "transparent"
    property real padding: Appearance.sizes.elevationMargin

    // Cache implicit dimensions to avoid recalculating on every access
    property real _cachedImplicitHeight: 0
    property real _cachedImplicitWidth: 0

    function updateImplicitDimensions() {
        if (!stackView || stackView.destroyed || !popupBackground) return;
        let maxHeight = 0;
        let maxWidth = 0;
        // Use currentItem instead of iterating all children for better performance
        // StackView only shows currentItem, so we only need its dimensions
        if (stackView.currentItem && !stackView.currentItem.destroyed) {
            maxHeight = stackView.currentItem.implicitHeight || 0;
            maxWidth = stackView.currentItem.implicitWidth || 0;
        }
        root._cachedImplicitHeight = maxHeight + popupBackground.padding * 2 + root.padding * 2;
        root._cachedImplicitWidth = maxWidth + popupBackground.padding * 2 + root.padding * 2;
    }

    implicitHeight: _cachedImplicitHeight
    implicitWidth: _cachedImplicitWidth

    Connections {
        target: stackView
        function onChildrenChanged() {
            root.updateImplicitDimensions();
        }
    }

    Component.onCompleted: updateImplicitDimensions()

    function open() {
        root.visible = true;
        root.menuOpened(root);
    }

    function close() {
        root.visible = false;
        // Ensure all submenu items are properly destroyed
        while (stackView.depth > 1) {
            const item = stackView.currentItem;
            stackView.pop();
            // StackView.onRemoved will call destroy(), but ensure cleanup
            if (item && !item.parent) {
                Qt.callLater(() => {
                    if (item && item.destroy) item.destroy();
                });
            }
        }
        root.menuClosed();
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        z: -1
        propagateComposedEvents: false
        onPressed: event => {
            // Handle back/right button for submenu navigation
            if ((event.button === Qt.BackButton || event.button === Qt.RightButton) && stackView.depth > 1) {
                stackView.pop();
                event.accepted = true;
                return;
            }
            
            // Close menu if clicking outside the popupBackground (in the padding area)
            const clickX = event.x;
            const clickY = event.y;
            const bgX = popupBackground.x;
            const bgY = popupBackground.y;
            const bgWidth = popupBackground.width;
            const bgHeight = popupBackground.height;
            
            if (clickX < bgX || clickX > bgX + bgWidth || 
                clickY < bgY || clickY > bgY + bgHeight) {
                root.close();
                event.accepted = true;
            }
        }

        StyledRectangularShadow {
            target: popupBackground
            opacity: popupBackground.opacity
        }

        Rectangle {
            id: popupBackground
            readonly property real padding: 4
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: Config.options.bar.vertical ? parent.verticalCenter : undefined
                top: Config.options.bar.vertical ? undefined : Config.options.bar.bottom ? undefined : parent.top
                bottom: Config.options.bar.vertical ? undefined : Config.options.bar.bottom ? parent.bottom : undefined
                margins: root.padding
            }

            color: Appearance.colors.colLayer0
            radius: Appearance.rounding.windowRounding
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            clip: true

            opacity: 0
            Component.onCompleted: opacity = 1
            implicitWidth: stackView.implicitWidth + popupBackground.padding * 2
            implicitHeight: stackView.implicitHeight + popupBackground.padding * 2

            // Reuse animation objects to avoid creating new ones on each property change
            property NumberAnimation opacityAnimation: Appearance.animation.elementMoveFast.numberAnimation.createObject(popupBackground)
            property NumberAnimation heightAnimation: Appearance.animation.elementResize.numberAnimation.createObject(popupBackground)
            property NumberAnimation widthAnimation: Appearance.animation.elementResize.numberAnimation.createObject(popupBackground)

            Behavior on opacity {
                animation: popupBackground.opacityAnimation
            }
            Behavior on implicitHeight {
                animation: popupBackground.heightAnimation
            }
            Behavior on implicitWidth {
                animation: popupBackground.widthAnimation
            }

            StackView {
                id: stackView
                anchors {
                    fill: parent
                    margins: popupBackground.padding
                }
                pushEnter: NoAnim {}
                pushExit: NoAnim {}
                popEnter: NoAnim {}
                popExit: NoAnim {}

                implicitWidth: currentItem ? currentItem.implicitWidth : 0
                implicitHeight: currentItem ? currentItem.implicitHeight : 0

                initialItem: SubMenu {
                    handle: root.trayItemMenuHandle
                }

                onCurrentItemChanged: {
                    // Update cached dimensions when current item changes
                    if (root && !root.destroyed) {
                        Qt.callLater(() => {
                            if (root && !root.destroyed) {
                                root.updateImplicitDimensions();
                            }
                        });
                    }
                }
            }
        }
    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    component SubMenu: ColumnLayout {
        id: submenu
        required property QsMenuHandle handle
        property bool isSubMenu: false
        property bool shown: false
        opacity: shown ? 1 : 0

        // Reuse animation object to avoid creating new ones
        property NumberAnimation opacityAnimation: Appearance.animation.elementMoveFast.numberAnimation.createObject(submenu)

        Behavior on opacity {
            animation: submenu.opacityAnimation
        }

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: {
            // Ensure proper cleanup, check if already destroyed
            if (!submenu.destroyed) {
                destroy();
            }
        }

        QsMenuOpener {
            id: menuOpener
            menu: submenu.handle
        }

        spacing: 0

        Loader {
            Layout.fillWidth: true
            visible: submenu.isSubMenu
            active: visible
            sourceComponent: RippleButton {
                id: backButton
                buttonRadius: popupBackground.radius - popupBackground.padding
                horizontalPadding: 12
                implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
                implicitHeight: 36

                downAction: () => stackView.pop()

                contentItem: RowLayout {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: backButton.horizontalPadding
                        rightMargin: backButton.horizontalPadding
                    }
                    spacing: 8
                    MaterialSymbol {
                        iconSize: 20
                        text: "chevron_left"
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Back")
                    }
                }
            }
        }

        Repeater {
            id: menuEntriesRepeater
            // Cache computed properties to avoid recalculating on every access
            property bool iconColumnNeeded: false
            property bool specialInteractionColumnNeeded: false

            function updateColumnNeeded() {
                let iconNeeded = false;
                let specialNeeded = false;
                const values = menuOpener.children.values;
                for (let i = 0; i < values.length; i++) {
                    if (values[i].icon.length > 0)
                        iconNeeded = true;
                    if (values[i].buttonType !== QsMenuButtonType.None)
                        specialNeeded = true;
                }
                menuEntriesRepeater.iconColumnNeeded = iconNeeded;
                menuEntriesRepeater.specialInteractionColumnNeeded = specialNeeded;
            }

            Component.onCompleted: updateColumnNeeded()

            Connections {
                target: menuOpener.children
                function onValuesChanged() {
                    if (menuEntriesRepeater && !menuEntriesRepeater.destroyed) {
                        menuEntriesRepeater.updateColumnNeeded();
                    }
                }
            }

            model: menuOpener.children
            delegate: SysTrayMenuEntry {
                required property QsMenuEntry modelData
                forceIconColumn: menuEntriesRepeater.iconColumnNeeded
                forceSpecialInteractionColumn: menuEntriesRepeater.specialInteractionColumnNeeded
                menuEntry: modelData

                buttonRadius: popupBackground.radius - popupBackground.padding

                onDismiss: root.close()
                onOpenSubmenu: handle => {
                    // Use stackView as parent to ensure proper cleanup when menu closes
                    stackView.push(subMenuComponent.createObject(stackView, {
                        handle: handle,
                        isSubMenu: true
                    }));
                }
            }
        }
    }

    Component {
        id: subMenuComponent
        SubMenu {}
    }
}
