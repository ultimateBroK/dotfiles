pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
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
    
    readonly property list<DesktopEntry> list: {
        updateCache();
        return _cachedList;
    }

    readonly property var preppedNames: {
        updateCache();
        return _cachedPreppedNames;
    }

    readonly property var preppedIcons: {
        updateCache();
        return _cachedPreppedIcons;
    }

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

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
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
            if (iconExists(guess)) return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry) return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
