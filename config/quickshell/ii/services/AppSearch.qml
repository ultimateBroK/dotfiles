pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtCore
import QtQuick
import Quickshell

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    /** XDG data dir (usually ~/.local/share); Chrome/Brave/Edge PWAs install hicolor PNGs here */
    readonly property string genericDataHome: {
        const locs = StandardPaths.standardLocations(StandardPaths.GenericDataLocation)
        if (locs.length > 0)
            return FileUtils.trimFileProtocol(locs[0].toString())
        return FileUtils.trimFileProtocol(Directories.home) + "/.local/share"
    }
    readonly property var _chromiumPwaIconPrefixes: ["chrome-", "brave-", "msedge-", "microsoft-edge-"]

    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        // Common aliases / odd desktop IDs
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",

        // Chromium-based browsers & Microsoft Edge aliases
        "edge": "microsoft-edge",
        "msedge": "microsoft-edge",
        "microsoft edge": "microsoft-edge",
        "microsoft-edge-dev": "microsoft-edge",
        "com.microsoft.edge": "microsoft-edge",
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]

    // Cache desktop entries list
    property list<DesktopEntry> _cachedList: []
    property var _cachedPreppedNames: []
    property var _cachedPreppedIcons: []
    property int _lastApplicationsCount: -1

    // Pure binding used only as a change trigger (no side effects).
    // When the app list changes, this should update and we recompute caches imperatively.
    readonly property int applicationsCount: (DesktopEntries?.applications?.values?.length ?? 0)
    
    function updateCache() {
        const currentList = Array.from(DesktopEntries.applications.values)
            .sort((a, b) => a.name.localeCompare(b.name));
        
        // Only recalculate if applications changed
        if (_lastApplicationsCount === currentList.length && _cachedList.length > 0) {
            return;
        }
        
        _cachedList = currentList;
        _lastApplicationsCount = currentList.length;
        _cachedPreppedNames = currentList.map(a => ({
            name: Fuzzy.prepare(`${a.name} `),
            entry: a
        }));
        _cachedPreppedIcons = currentList.map(a => ({
            name: Fuzzy.prepare(`${a.icon} `),
            entry: a
        }));
    }
    
    // NOTE: Avoid side effects in bindings to prevent binding loops.
    readonly property list<DesktopEntry> list: _cachedList
    readonly property var preppedNames: _cachedPreppedNames
    readonly property var preppedIcons: _cachedPreppedIcons

    onApplicationsCountChanged: updateCache()
    Component.onCompleted: updateCache()

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        let results;
        if (root.sloppySearch) {
            const scoredResults = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            results = scoredResults
                .map(item => item.entry)
        } else {
            results = Fuzzy.go(search, preppedNames, {
                all: true,
                key: "name"
            }).map(r => {
                return r.obj.entry
            });
        }

        // Deduplicate entries by ID
        const seenIds = new Set();
        return results.filter(entry => {
            if (seenIds.has(entry.id)) {
                return false;
            }
            seenIds.add(entry.id);
            return true;
        });
    }

    function isChromiumStylePwaIconName(iconName) {
        if (!iconName || typeof iconName !== "string")
            return false;
        const n = iconName.trim();
        if (n.length === 0 || n.includes("/") || n.startsWith("file:"))
            return false;
        const lower = n.toLowerCase();
        for (let i = 0; i < root._chromiumPwaIconPrefixes.length; i++) {
            if (lower.startsWith(root._chromiumPwaIconPrefixes[i]))
                return true;
        }
        return false;
    }

    /** Freedesktop hicolor path for PWA icons (Threads, X, etc.): Icon=chrome-…-Default in .desktop */
    function chromiumPwaHicolorFileUrl(iconName) {
        if (!root.isChromiumStylePwaIconName(iconName))
            return "";
        const n = String(iconName).trim();
        const base = root.genericDataHome;
        if (!base)
            return "";
        // Chrome writes PNGs under hicolor/<size>/apps/; Quickshell.iconPath often misses ~/.local icons.
        const path = `${base}/icons/hicolor/48x48/apps/${n}.png`;
        return "file://" + path;
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        const s = String(iconName).trim();
        // .desktop Icon= may be an absolute path (common for Chrome/Chromium PWAs)
        if (s.startsWith("file://") || s.startsWith("/") || s.startsWith("~/"))
            return true;
        if (root.isChromiumStylePwaIconName(s))
            return true;
        return (Quickshell.iconPath(iconName, true).length > 0)
            && !iconName.includes("image-missing");
    }

    /**
     * IconImage.source for theme icon names, file:// URLs, or absolute paths.
     * Chromium web apps often ship Icon=/home/.../.local/share/icons/.../chrome-....png in .desktop.
     */
    function resolvedIconSource(icon, fallback) {
        const fb = fallback ?? "image-missing";
        if (!icon || String(icon).length == 0)
            return Quickshell.iconPath(fb, "image-missing");
        const s = String(icon).trim();
        if (s.startsWith("file://"))
            return s;
        if (s.startsWith("/"))
            return "file://" + s;
        if (s.startsWith("~/")) {
            const home = FileUtils.trimFileProtocol(Directories.home);
            return "file://" + home + s.slice(1);
        }
        if (root.isChromiumStylePwaIconName(s)) {
            const themed = Quickshell.iconPath(s, true);
            if (themed && themed.length > 0)
                return Quickshell.iconPath(s, fb);
            const pwaUrl = root.chromiumPwaHicolorFileUrl(s);
            if (pwaUrl)
                return pwaUrl;
        }
        return Quickshell.iconPath(s, fb);
    }

    function _isPathIcon(s) {
        if (!s || typeof s !== "string") return false;
        const t = s.trim();
        return t.startsWith("file://") || t.startsWith("/") || t.startsWith("~/");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0]
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    function guessIcon(str) {
        if (!str || str.length == 0) return "image-missing";

        // Chromium PWA windows: StartupWMClass / Hyprland class is often crx_<id>
        if (typeof str === "string" && str.startsWith("crx_")) {
            const pwa = DesktopEntries.heuristicLookup(str);
            if (pwa && pwa.icon)
                return pwa.icon;
        }

        // Quickshell's desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry) return entry.icon;

        // Normal substitutions
        if (substitutions[str]) return substitutions[str];
        if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str)) return str;


        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased)) return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

        const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
        if (iconExists(undescoreToKebabGuess)) return undescoreToKebabGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon
            if (_isPathIcon(guess) || iconExists(guess)) return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon
            if (_isPathIcon(guess) || iconExists(guess)) return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry && heuristicEntry.icon)
            return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
