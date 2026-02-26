import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Io

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
        }
    }
    
    Connections {
        target: SystemTray.items
        function onValuesChanged() {
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
            
            // Final fallback: completely restart the Quickshell daemon to prevent QML memory leak
            console.warn("[SysTrayWatchdog] Detected missing tray items after resume; completely reloading Quickshell to recover")
            
            // Execute shell command to restart the OS process detached
            // Using sleep to allow this function block to exit cleanly before sigterm
            restartProcess.running = true
            attempts = 0
        }
    }

    Process {
        id: restartProcess
        // Quickshell does not have a --replace flag.
        // We use pkill to kill the current process, wait 1 second, and start a new instance natively.
        command: ["bash", "-c", "pkill quickshell; sleep 1; quickshell &"]
        running: false
    }
}
