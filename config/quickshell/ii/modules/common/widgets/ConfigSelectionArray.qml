import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Flow {
    id: root
    Layout.fillWidth: true
    spacing: 2
    property list<var> options: [
        {
            "displayName": "Option 1",
            "icon": "check",
            "value": 1
        },
        {
            "displayName": "Option 2",
            "icon": "close",
            "value": 2
        },
    ]
    property var currentValue: null

    signal selected(var newValue)
    
    // Store references to all buttons for proper leftmost/rightmost detection
    property var buttonInstances: []
    
    function updateButtonPositions() {
        if (buttonInstances.length === 0) return
        
        // Group buttons by row (same Y position, with small tolerance for rounding)
        var rows = {}
        var tolerance = 2 // pixels
        
        for (var i = 0; i < buttonInstances.length; i++) {
            var btn = buttonInstances[i]
            if (!btn || !btn.visible) continue
            
            // Find matching row or create new one
            var foundRow = false
            for (var rowY in rows) {
                if (Math.abs(btn.y - parseFloat(rowY)) < tolerance) {
                    rows[rowY].push(btn)
                    foundRow = true
                    break
                }
            }
            if (!foundRow) {
                rows[btn.y] = [btn]
            }
        }
        
        // Set leftmost/rightmost for each row
        for (var rowY in rows) {
            var rowButtons = rows[rowY]
            // Sort by X position
            rowButtons.sort(function(a, b) { 
                return a.x - b.x 
            })
            
            // Set leftmost/rightmost
            for (var j = 0; j < rowButtons.length; j++) {
                var button = rowButtons[j]
                button.leftmost = (j === 0)
                button.rightmost = (j === rowButtons.length - 1)
            }
        }
    }

    Repeater {
        id: repeater
        model: root.options
        delegate: SelectionGroupButton {
            id: paletteButton
            required property var modelData
            required property int index
            
            Component.onCompleted: {
                root.buttonInstances.push(paletteButton)
            }
            
            Component.onDestruction: {
                var idx = root.buttonInstances.indexOf(paletteButton)
                if (idx !== -1) {
                    root.buttonInstances.splice(idx, 1)
                }
            }
            
            onXChanged: {
                // Use a timer to batch updates after layout is complete
                positionUpdateTimer.restart()
            }
            onYChanged: {
                positionUpdateTimer.restart()
            }
            
            onVisibleChanged: {
                positionUpdateTimer.restart()
            }
            
            Timer {
                id: positionUpdateTimer
                interval: 10
                onTriggered: {
                    root.updateButtonPositions()
                }
            }
            
            buttonIcon: modelData.icon || ""
            buttonText: modelData.displayName
            toggled: root.currentValue == modelData.value
            onClicked: {
                root.selected(modelData.value);
            }
        }
    }
    
    Component.onCompleted: {
        // Initial update after all buttons are created
        Qt.callLater(function() {
            root.updateButtonPositions()
        })
    }
    
    onWidthChanged: {
        // Update positions when width changes (buttons may wrap)
        Qt.callLater(function() {
            root.updateButtonPositions()
        })
    }
}
