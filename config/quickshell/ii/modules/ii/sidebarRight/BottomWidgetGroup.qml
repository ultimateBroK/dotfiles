import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight.calendar
import qs.modules.ii.sidebarRight.todo
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Qt.rgba(1, 1, 1, 0.06)
    clip: false
    implicitHeight: collapsed ? (collapsedBottomWidgetGroupRow.implicitHeight + 16) : bottomWidgetGroupRow.implicitHeight
    property int selectedTab: Persistent.states.sidebar.bottomGroup.tab
    property bool collapsed: Persistent.states.sidebar.bottomGroup.collapsed
    property var tabs: [
        {"type": "calendar", "name": Translation.tr("Calendar"), "icon": "calendar_month", "widget": calendarWidget}, 
        {"type": "todo", "name": Translation.tr("To Do"), "icon": "done_outline", "widget": todoWidget},
    ]

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    function setCollapsed(state) {
        Persistent.states.sidebar.bottomGroup.collapsed = state
        if (collapsed) {
            bottomWidgetGroupRow.opacity = 0
        }
        else {
            collapsedBottomWidgetGroupRow.opacity = 0
        }
        collapseCleanFadeTimer.start()
    }

    Timer {
        id: collapseCleanFadeTimer
        interval: Appearance.animation.elementMove.duration / 2
        repeat: false
        onTriggered: {
            if(collapsed) collapsedBottomWidgetGroupRow.opacity = 1
            else bottomWidgetGroupRow.opacity = 1
        }
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                root.selectedTab = Math.min(root.selectedTab + 1, root.tabs.length - 1)
            } else if (event.key === Qt.Key_PageUp) {
                root.selectedTab = Math.max(root.selectedTab - 1, 0)
            }
            event.accepted = true;
        }
    }

    // The thing when collapsed
    RowLayout {
        id: collapsedBottomWidgetGroupRow
        opacity: collapsed ? 1 : 0
        visible: opacity > 0
        anchors.fill: parent
        anchors.margins: 8
        Behavior on opacity {
            NumberAnimation {
                id: collapsedBottomWidgetGroupRowFade
                duration: Appearance.animation.elementMove.duration / 2
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        spacing: 8
        
        // Expand button
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 16
            color: Appearance.colors.colSurfaceContainerHigh
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: "keyboard_arrow_up"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnSurfaceVariant
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setCollapsed(false)
            }
        }
        
        // Calendar icon
        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            text: "calendar_today"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colPrimary
        }

        StyledText {
            property int remainingTasks: Todo.list.filter(task => !task.done).length;
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: DateTime.collapsedCalendarFormat
            font {
                pixelSize: Appearance.font.pixelSize.normal
                weight: Font.Medium
            }
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
        }
        
        // Tasks badge
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: Todo.list.filter(task => !task.done).length > 0
            Layout.preferredWidth: taskBadgeLayout.implicitWidth + 12
            Layout.preferredHeight: 24
            radius: 12
            color: Appearance.colors.colPrimaryContainer
            
            RowLayout {
                id: taskBadgeLayout
                anchors.centerIn: parent
                spacing: 4
                
                MaterialSymbol {
                    text: "checklist"
                    iconSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimaryContainer
                }
                
                StyledText {
                    text: Todo.list.filter(task => !task.done).length.toString()
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Bold
                    }
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }
    }

    // The thing when expanded
    RowLayout {
        id: bottomWidgetGroupRow

        opacity: collapsed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                id: bottomWidgetGroupRowFade
                duration: Appearance.animation.elementMove.duration / 2
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        anchors.fill: parent 
        height: tabStack.height
        spacing: 8
        
        // Navigation rail
        Item {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.leftMargin: 8
            Layout.topMargin: 8
            width: tabBar.width
            // Navigation rail buttons
            NavigationRailTabArray {
                id: tabBar
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                currentIndex: root.selectedTab
                expanded: false
                Repeater {
                    model: root.tabs
                    NavigationRailButton {
                        showToggledHighlight: false
                        toggled: root.selectedTab == index
                        buttonText: modelData.name
                        buttonIcon: modelData.icon
                        onPressed: {
                            root.selectedTab = index
                            Persistent.states.sidebar.bottomGroup.tab = index
                        }
                    }
                }
            }
            // Collapse button
            CalendarHeaderButton {
                anchors.left: parent.left
                anchors.top: parent.top
                forceCircle: true
                downAction: () => {
                    root.setCollapsed(true)
                }
                contentItem: MaterialSymbol {
                    text: "keyboard_arrow_down"
                    iconSize: Appearance.font.pixelSize.larger
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Content area
        StackLayout {
            id: tabStack
            Layout.fillWidth: true
            // Take the highest one, because the TODO list has no implicit height. This way the heigth of the calendar is used when it's initially loaded with the TODO list
            height: Math.max(...tabStack.children.map(child => child.tabLoader?.implicitHeight || 0)) // TODO: make this less stupid
            Layout.alignment: Qt.AlignVCenter
            property int realIndex: root.selectedTab
            property int animationDuration: Appearance.animation.elementMoveFast.duration * 1.5
            currentIndex: root.selectedTab

            // Switch the tab on halfway of the anim duration
            Connections {
                target: root
                function onSelectedTabChanged() {
                    delayedStackSwitch.start()
                    tabStack.realIndex = root.selectedTab
                }
            }
            Timer {
                id: delayedStackSwitch
                interval: tabStack.animationDuration / 2
                repeat: false
                onTriggered: {
                    tabStack.currentIndex = root.selectedTab
                }
            }

            Repeater {
                model: tabs
                Item { // TODO: make behavior on y also act for the item that's switched to
                    id: tabItem
                    property int tabIndex: index
                    property string tabType: modelData.type
                    property int animDistance: 5
                    property var tabLoader: tabLoader
                    // Opacity: show up only when being animated to
                    opacity: (tabStack.currentIndex === tabItem.tabIndex && tabStack.realIndex === tabItem.tabIndex) ? 1 : 0
                    // Y: starts animating when user selects a different tab
                    y: (tabStack.realIndex === tabItem.tabIndex) ? 0 : (tabStack.realIndex < tabItem.tabIndex) ? animDistance : -animDistance
                    Behavior on opacity { NumberAnimation { duration: tabStack.animationDuration / 2; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: tabStack.animationDuration; easing.type: Easing.OutExpo } }
                    Loader {
                        id: tabLoader
                        anchors.fill: parent
                        sourceComponent: modelData.widget
                        focus: root.selectedTab === tabItem.tabIndex
                    }
                }
            }
        }
    }

    // Calendar component
    Component {
        id: calendarWidget

        CalendarWidget {
            anchors.fill: parent
            anchors.margins: 5
        }
    }

    // To Do component
    Component {
        id: todoWidget
        TodoWidget {
            anchors.fill: parent
            anchors.margins: 5
        }
    }
}
