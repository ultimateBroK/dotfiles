pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.services

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
    
    // Track last known item count to detect when items disappear
    property int _lastItemCount: 0
    
    // Timer to periodically check for SystemTray.items changes
    // This ensures items appear even if SystemTray service initializes after component creation
    Timer {
        id: updateTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            const currentCount = SystemTray.items.values?.length || 0
            root.updateItems()
            
            // If items disappeared after theme change, schedule recovery
            if (root._lastItemCount > 0 && currentCount === 0) {
                themeChangeRecovery.start()
            }
            root._lastItemCount = currentCount
        }
    }
    
    // Recovery timer for theme changes - gives SystemTray time to reconnect
    Timer {
        id: themeChangeRecovery
        interval: 2000
        repeat: true
        running: false
        property int attempts: 0
        onTriggered: {
            attempts++
            const currentCount = SystemTray.items.values?.length || 0
            
            if (currentCount > 0) {
                // Recovered
                root.updateItems()
                attempts = 0
                themeChangeRecovery.stop()
                return
            }
            
            if (attempts >= 5) {
                // After 5 attempts (10 seconds), stop trying
                console.warn("[TrayService] Tray items still missing after theme change recovery attempts")
                attempts = 0
                themeChangeRecovery.stop()
            }
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
            root._lastItemCount = SystemTray.items.values?.length || 0
        }
    }
    
    // Monitor for theme changes that might cause SystemTray to disconnect
    // When KDE System Settings changes color/icon theme, SystemTray service
    // may temporarily disconnect, causing items to disappear
    // The recovery mechanism above handles this, but we also proactively
    // refresh when we detect items have disappeared
    
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
