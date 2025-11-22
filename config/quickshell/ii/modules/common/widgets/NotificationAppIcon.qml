import qs.modules.common
import qs.services
import "notification_utils.js" as NotificationUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

MaterialShape { // App icon
    id: root
    property var appIcon: ""
    property var summary: ""
    property var appName: ""
    property var urgency: NotificationUrgency.Normal
    property bool isUrgent: urgency === NotificationUrgency.Critical
    property var image: ""
    property bool imageLoadFailed: false
    property bool appIconLoadFailed: false
    readonly property bool showNotificationImage: image != "" && !imageLoadFailed

    // Normalize app name/icon to handle edge cases in a generic way
    function normalizeAppIdentifier(identifier) {
        if (!identifier || typeof identifier !== "string")
            return "";

        // Remove whitespace and normalize
        let normalized = identifier.trim();
        if (normalized === "")
            return "";

        // Handle file paths (get file name without extension)
        if (normalized.includes("/")) {
            const parts = normalized.split("/");
            normalized = parts[parts.length - 1];
            // Remove extension if present
            if (normalized.includes(".")) {
                const nameParts = normalized.split(".");
                normalized = nameParts.slice(0, -1).join(".");
            }
        }

        // Handle domain names (com.example.app -> app)
        if (normalized.includes(".")) {
            const parts = normalized.split(".");
            // If multiple segments, get the last one (usually app name)
            if (parts.length > 1) {
                normalized = parts[parts.length - 1];
            }
        }

        // Remove invalid/special characters for icon name
        normalized = normalized
            .toLowerCase()
            .replace(/[^a-z0-9._-]/g, "-"); // safe for icon name

        return normalized;
    }

    // Try resolving icon from a single identifier (appIcon, appName, etc.)
    function resolveIconFromIdentifier(identifier) {
        if (!identifier || typeof identifier !== "string" || !AppSearch)
            return "";

        const lowercased = identifier.toLowerCase();

        // Special handling for Microsoft Edge - highest priority & avoid incorrect fuzzy search
        if (lowercased.includes("edge") || lowercased.includes("microsoft")) {
            // Try common Edge icon names first
            const edgeCandidates = ["microsoft-edge", "edge", "msedge", "com.microsoft.edge"];
            for (let i = 0; i < edgeCandidates.length; i++) {
                const candidate = edgeCandidates[i];
                // Check directly if icon exists
                if (AppSearch.iconExists(candidate)) {
                    return candidate;
                }
                // Try using guessIcon (will check substitutions)
                const guessed = AppSearch.guessIcon(candidate);
                if (guessed && AppSearch.iconExists(guessed) &&
                    (guessed.includes("edge") || guessed.includes("microsoft"))) {
                    return guessed;
                }
            }
            // If Edge icon not found, return empty instead of allowing fuzzy search to find "hp"
            return "";
        }

        // Special handling for Brave Browser
        if (lowercased.includes("brave")) {
            const braveCandidates = ["brave-browser", "brave", "com.brave.Browser"];
            for (let i = 0; i < braveCandidates.length; i++) {
                const candidate = braveCandidates[i];
                if (AppSearch.iconExists(candidate)) {
                    return candidate;
                }
                const guessed = AppSearch.guessIcon(candidate);
                if (guessed && AppSearch.iconExists(guessed) && guessed.includes("brave")) {
                    return guessed;
                }
            }
            return "";
        }

        const normalized = normalizeAppIdentifier(identifier);
        const candidates = [];

        // Prefer normalized id if different, then the raw id
        if (normalized && normalized !== identifier)
            candidates.push(normalized);
        candidates.push(identifier);

        for (let i = 0; i < candidates.length; i++) {
            const candidate = candidates[i];
            if (!candidate)
                continue;

            // 1. Use directly if icon exists
            if (AppSearch.iconExists(candidate))
                return candidate;

            // 2. Let AppSearch guess best icon (checks substitutions & fuzzy search)
            const guessed = AppSearch.guessIcon(candidate);
            if (guessed && AppSearch.iconExists(guessed) && guessed !== "application-x-executable") {
                return guessed;
            }
        }

        return "";
    }

    // Automatically resolve the best icon from several sources, concise code
    readonly property string resolvedAppIcon: {
        try {
            // Priority order: appIcon -> appName -> special keyword based on summary
            const sources = [
                appIcon,
                appName,
                // Certain keywords help map correct icon (e.g. system-update)
                (summary && typeof summary === "string" && summary.toLowerCase().includes("update"))
                    ? "system-update"
                    : ""
            ];

            for (let i = 0; i < sources.length; i++) {
                const icon = resolveIconFromIdentifier(sources[i]);
                if (icon && icon !== "")
                    return icon;
            }
        } catch (error) {
            console.warn("[NotificationAppIcon] Error resolving icon:", error);
        }

        // No valid icon found
        return "";
    }
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale
    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale

    implicitSize: 38 * scale
    property list<var> urgentShapes: [
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.SoftBurst,
    ]
    shape: isUrgent ? urgentShapes[Math.floor(Math.random() * urgentShapes.length)] : MaterialShape.Shape.Circle

    color: isUrgent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
    onImageChanged: imageLoadFailed = false
    onAppIconChanged: appIconLoadFailed = false
    onAppNameChanged: appIconLoadFailed = false
    onResolvedAppIconChanged: {
        // Reset load failed when resolved icon changes
        if (resolvedAppIcon !== "") {
            appIconLoadFailed = false;
        }
    }

    Loader {
        id: materialSymbolLoader
        // Only use Material icon if no valid icon or app icon load failed and no valid image
        active: (root.resolvedAppIcon === "" || root.appIconLoadFailed) && !root.showNotificationImage
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const combinedSummary = (root.summary + " " + (root.appName || "")).trim()
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(combinedSummary)
                return (root.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                    "priority_high" : guessedIcon
            }
            anchors.fill: parent
            color: isUrgent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
            iconSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        id: appIconLoader
        // Use app icon if valid and no separate image, or image failed
        active: (!root.showNotificationImage) && root.resolvedAppIcon !== "" && !root.appIconLoadFailed
        anchors.centerIn: parent
        sourceComponent: IconImage {
            id: appIconImage
            implicitSize: root.appIconSize
            asynchronous: true
            source: Quickshell.iconPath(root.resolvedAppIcon, "image-missing")

            onStatusChanged: {
                if (status === IconImage.Error || status === IconImage.Null) {
                    console.warn("[NotificationAppIcon] Failed to load app icon:", root.resolvedAppIcon);
                    root.appIconLoadFailed = true;
                }
            }
        }
    }
    Loader {
        id: notifImageLoader
        // When a valid image is present, give priority and optionally overlay small appIcon
        active: root.showNotificationImage
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            Image {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width

                source: root.image
                fillMode: Image.PreserveAspectCrop
                cache: false
                antialiasing: true
                asynchronous: true

                width: size
                height: size
                sourceSize.width: size
                sourceSize.height: size

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }

                onStatusChanged: {
                    if (status === Image.Error) {
                        console.warn("[NotificationAppIcon] Failed to load notification image:", root.image);
                        root.imageLoadFailed = true;
                    }
                }
            }
            Loader {
                id: notifImageAppIconLoader
                active: root.resolvedAppIcon !== "" && root.showNotificationImage && !root.appIconLoadFailed
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: IconImage {
                    implicitSize: root.smallAppIconSize
                    asynchronous: true
                    source: Quickshell.iconPath(root.resolvedAppIcon, "image-missing")

                    onStatusChanged: {
                        if (status === IconImage.Error || status === IconImage.Null) {
                            // No warning here, as this is just a small overlay icon
                            root.appIconLoadFailed = true;
                        }
                    }
                }
            }
        }
    }
}