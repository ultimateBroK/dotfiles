import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

/**
 * Watchdog component to detect and recover missing tray items after sleep/resume or reload.
 * This component monitors SystemTray.items and attempts recovery if items disappear.
 */
Item {
    id: root
    
    // Watchdog: detect if tray items disappear after sleep/resume and attempt recovery
    property int _lastKnownCount: 0
    
    Component.onCompleted: {
        // Initialize last known count once the component is ready
        // Give it a small delay to allow SystemTray service to initialize
        initTimer.start()
    }
    
    Timer {
        id: initTimer
        interval: 1000
        repeat: false
        onTriggered: {
            root._lastKnownCount = SystemTray.items.values.length
            pollTimer.start()
        }
    }
    
    Timer {
        id: pollTimer
        interval: 5000
        repeat: true
        running: false
        onTriggered: {
            const current = SystemTray.items.values.length
            // If we previously had items and now have none, attempt recovery
            if (root._lastKnownCount > 0 && current === 0) {
                // Start a small retry sequence before performing a reload
                recoveryAttempt.attempts = 0
                recoveryAttempt.start()
            }
            root._lastKnownCount = current
        }
    }
    
    Timer {
        id: recoveryAttempt
        interval: 2000
        repeat: false
        property int attempts: 0
        onTriggered: {
            attempts++
            if (SystemTray.items.values.length > 0) {
                // Recovered on its own
                attempts = 0
                return
            }
            if (attempts < 3) {
                // Retry a few times to allow tray daemons/apps to re-register
                recoveryAttempt.start()
                return
            }
            
            // Final fallback: reload Quickshell to reinitialize the tray implementation
            console.warn("[SysTrayWatchdog] Detected missing tray items after resume; reloading Quickshell to recover")
            Quickshell.reload(true)
            attempts = 0
        }
    }
}
