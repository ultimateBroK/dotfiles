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
    // Track the maximum page size while the menu is open.
    // This avoids iterating `stackView.children` (which can include internal items),
    // and prevents old pages from artificially inflating the popup size if they linger.
    property real _maxPageImplicitWidth: 0
    property real _maxPageImplicitHeight: 0

    function _resetMaxPageSize() {
        root._maxPageImplicitWidth = 0;
        root._maxPageImplicitHeight = 0;
    }

    function _updateMaxPageSize() {
        const item = stackView.currentItem;
        if (!item) return;
        root._maxPageImplicitWidth = Math.max(root._maxPageImplicitWidth, item.implicitWidth ?? 0);
        root._maxPageImplicitHeight = Math.max(root._maxPageImplicitHeight, item.implicitHeight ?? 0);
    }

    implicitHeight: {
        return root._maxPageImplicitHeight + popupBackground.padding * 2 + root.padding * 2;
    }
    implicitWidth: {
        return root._maxPageImplicitWidth + popupBackground.padding * 2 + root.padding * 2;
    }

    function open() {
        root._resetMaxPageSize();
        root._updateMaxPageSize();
        root.visible = true;
        root.menuOpened(root);
    }

    function close() {
        root.visible = false;
        while (stackView.depth > 1)
            stackView.pop();
        root._resetMaxPageSize();
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

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on implicitHeight {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
            Behavior on implicitWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
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

                implicitWidth: currentItem.implicitWidth
                implicitHeight: currentItem.implicitHeight

                onCurrentItemChanged: root._updateMaxPageSize()
                Connections {
                    target: stackView.currentItem
                    function onImplicitWidthChanged() { root._updateMaxPageSize(); }
                    function onImplicitHeightChanged() { root._updateMaxPageSize(); }
                }

                initialItem: SubMenu {
                    handle: root.trayItemMenuHandle
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

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false

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
            property bool iconColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].icon.length > 0)
                        return true;
                }
                return false;
            }
            property bool specialInteractionColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].buttonType !== QsMenuButtonType.None)
                        return true;
                }
                return false;
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
                    // Let StackView own the item lifecycle to avoid leaks from unparented objects.
                    stackView.push(subMenuComponent, {
                        handle: handle,
                        isSubMenu: true
                    });
                }
            }
        }
    }

    Component {
        id: subMenuComponent
        SubMenu {}
    }
}
