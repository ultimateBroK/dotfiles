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
    
    // Normalize app name/icon để xử lý các edge cases
    function normalizeAppIdentifier(identifier) {
        if (!identifier || typeof identifier !== "string") return "";
        // Loại bỏ whitespace và normalize
        let normalized = identifier.trim();
        if (normalized === "") return "";
        
        // Xử lý domain names (com.example.app -> app)
        if (normalized.includes(".")) {
            const parts = normalized.split(".");
            // Nếu có nhiều phần, lấy phần cuối cùng (thường là app name)
            if (parts.length > 1) {
                normalized = parts[parts.length - 1];
            }
        }
        
        // Loại bỏ các ký tự đặc biệt không hợp lệ cho icon name
        normalized = normalized.replace(/[^a-zA-Z0-9._-]/g, "-");
        
        return normalized;
    }
    
    // Tự động resolve icon tốt nhất với nhiều fallback strategies
    readonly property string resolvedAppIcon: {
        try {
            // Strategy 1: Nếu có appIcon và icon tồn tại, dùng nó trực tiếp
            if (appIcon && appIcon !== "" && typeof appIcon === "string") {
                const normalizedIcon = normalizeAppIdentifier(appIcon);
                if (normalizedIcon !== "" && AppSearch && AppSearch.iconExists(normalizedIcon)) {
                    return normalizedIcon;
                }
                // Thử với icon gốc (có thể là full path)
                if (AppSearch && AppSearch.iconExists(appIcon)) {
                    return appIcon;
                }
            }
            
            // Strategy 2: Nếu có appIcon nhưng không hợp lệ, thử guess từ appIcon
            if (appIcon && appIcon !== "" && typeof appIcon === "string") {
                const normalizedIcon = normalizeAppIdentifier(appIcon);
                if (normalizedIcon !== "" && AppSearch) {
                    const guessed = AppSearch.guessIcon(normalizedIcon);
                    if (AppSearch.iconExists(guessed)) {
                        return guessed;
                    }
                    // Thử guess từ icon gốc
                    const guessedOriginal = AppSearch.guessIcon(appIcon);
                    if (AppSearch.iconExists(guessedOriginal)) {
                        return guessedOriginal;
                    }
                }
            }
            
            // Strategy 3: Nếu có appName, thử guess từ appName
            if (appName && appName !== "" && typeof appName === "string") {
                const normalizedName = normalizeAppIdentifier(appName);
                if (normalizedName !== "" && AppSearch) {
                    const guessed = AppSearch.guessIcon(normalizedName);
                    if (AppSearch.iconExists(guessed)) {
                        return guessed;
                    }
                    // Thử guess từ appName gốc
                    const guessedOriginal = AppSearch.guessIcon(appName);
                    if (AppSearch.iconExists(guessedOriginal)) {
                        return guessedOriginal;
                    }
                }
            }
            
            // Strategy 4: Thử từ summary nếu có keyword đặc biệt
            if (summary && summary !== "" && typeof summary === "string" && AppSearch) {
                const lowerSummary = summary.toLowerCase();
                // Một số keywords đặc biệt có thể giúp tìm icon
                if (lowerSummary.includes("update") || lowerSummary.includes("upgrade")) {
                    const guessed = AppSearch.guessIcon("system-update");
                    if (AppSearch.iconExists(guessed)) return guessed;
                }
            }
        } catch (error) {
            console.warn("[NotificationAppIcon] Error resolving icon:", error);
        }
        
        // Không tìm được icon hợp lệ
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
        // Reset load failed khi resolved icon thay đổi
        if (resolvedAppIcon !== "") {
            appIconLoadFailed = false;
        }
    }

    Loader {
        id: materialSymbolLoader
        // Chỉ dùng Material icon khi không có icon hợp lệ (hoặc load fail) và cũng không có image hợp lệ
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
        // Dùng app icon khi có icon hợp lệ và không có image riêng hoặc image lỗi
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
        // Khi có image hợp lệ, ưu tiên hiển thị image làm nền, có thể overlay appIcon nhỏ
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
                            // Không cần warn ở đây vì đây là overlay icon nhỏ
                            root.appIconLoadFailed = true;
                        }
                    }
                }
            }
        }
    }
}