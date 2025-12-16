pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    function togglePin(appId) {
        if (Config.options.dock.pinnedApps.indexOf(appId) !== -1) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    // Cache apps list to avoid recalculation
    property list<var> _cachedApps: []
    property var _lastToplevelsHash: ""
    
    function computeAppsHash() {
        // Create a simple hash from toplevels count and pinned apps
        const toplevelsCount = ToplevelManager.toplevels.values.length;
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        return `${toplevelsCount}-${pinnedApps.join(',')}`;
    }
    
    function updateApps() {
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator
        if (pinnedApps.length > 0) {
            map.set("SEPARATOR", { pinned: false, toplevels: [] });
        }

        // Ignored apps
        const ignoredRegexStrings = Config.options?.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        // Open windows
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            if (!map.has(toplevel.appId.toLowerCase())) map.set(toplevel.appId.toLowerCase(), ({
                pinned: false,
                toplevels: []
            }));
            map.get(toplevel.appId.toLowerCase()).toplevels.push(toplevel);
        }

        var values = [];

        for (const [key, value] of map) {
            values.push(appEntryComp.createObject(null, { appId: key, toplevels: value.toplevels, pinned: value.pinned }));
        }

        _cachedApps = values;
        _lastToplevelsHash = computeAppsHash();
        return values;
    }
    
    property list<var> apps: {
        const currentHash = computeAppsHash();
        if (_lastToplevelsHash === currentHash && _cachedApps.length > 0) {
            return _cachedApps;
        }
        return updateApps();
    }
    
    Connections {
        target: ToplevelManager
        function onToplevelsChanged() {
            // Invalidate cache when toplevels change
            _lastToplevelsHash = "";
        }
    }
    
    Connections {
        target: Config.options?.dock ?? null
        function onPinnedAppsChanged() {
            // Invalidate cache when pinned apps change
            _lastToplevelsHash = "";
        }
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}
