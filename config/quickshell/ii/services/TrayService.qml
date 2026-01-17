pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    // Filter items based on configuration
    function filterItems(items) {
        const smartTray = Config.options.bar.tray.filterPassive
        return items.filter(i => {
            const inPinnedList = Config.options.bar.tray.pinnedItems.includes(i.id)
            const isActive = !smartTray || i.status !== Status.Passive
            return inPinnedList && isActive
        })
    }
    
    function filterUnpinnedItems(items) {
        const smartTray = Config.options.bar.tray.filterPassive
        return items.filter(i => {
            const notInPinnedList = !Config.options.bar.tray.pinnedItems.includes(i.id)
            const isActive = !smartTray || i.status !== Status.Passive
            return notInPinnedList && isActive
        })
    }
    
    function updateItems() {
        const allItems = SystemTray.items.values || []
        if (invertPins) {
            pinnedItems = filterUnpinnedItems(allItems)
            unpinnedItems = filterItems(allItems)
        } else {
            pinnedItems = filterItems(allItems)
            unpinnedItems = filterUnpinnedItems(allItems)
        }
    }
    
    // Computed properties for pinned and unpinned items
    readonly property bool invertPins: Config.options.bar.tray.invertPinnedItems
    
    property list<var> pinnedItems: []
    property list<var> unpinnedItems: []
    
    // Timer to periodically check for SystemTray.items changes
    // This ensures items appear even if SystemTray service initializes after component creation
    Timer {
        id: updateTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            root.updateItems()
        }
    }
    
    Component.onCompleted: {
        // Initial update with a small delay to allow SystemTray service to initialize
        initTimer.start()
    }
    
    Timer {
        id: initTimer
        interval: 1000
        repeat: false
        onTriggered: {
            root.updateItems()
        }
    }
    
    // Get tooltip text for a tray item
    function getTooltipForItem(item) {
        if (!item) return ""
        
        let text = item.tooltipTitle.length > 0 
            ? item.tooltipTitle
            : (item.title.length > 0 ? item.title : item.id)
        
        if (item.tooltipDescription.length > 0) {
            text += " • " + item.tooltipDescription
        }
        
        if (Config.options.bar.tray.showItemId) {
            text += "\n[" + item.id + "]"
        }
        
        return text
    }
}
