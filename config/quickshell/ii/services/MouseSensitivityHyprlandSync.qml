pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.common

/**
 * Applies Config.options.interactions.mouse.sensitivity to Hyprland (input:sensitivity)
 * when the shell starts or the value changes.
 */
Singleton {
    id: root

    function apply() {
        if (!Config.ready)
            return;
        const v = Config.options.interactions.mouse.sensitivity;
        Quickshell.execDetached(["hyprctl", "keyword", "input:sensitivity", String(v)]);
    }

    readonly property real _mirror: Config.ready ? Config.options.interactions.mouse.sensitivity : 0
    on_MirrorChanged: {
        if (Config.ready)
            root.apply();
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                Qt.callLater(root.apply);
        }
    }
}
