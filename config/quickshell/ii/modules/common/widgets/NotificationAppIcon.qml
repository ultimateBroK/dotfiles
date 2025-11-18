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
    
    // Normalize app name/icon để xử lý các edge cases theo cách tổng quát
    function normalizeAppIdentifier(identifier) {
        if (!identifier || typeof identifier !== "string")
            return "";

        // Loại bỏ whitespace và normalize
        let normalized = identifier.trim();
        if (normalized === "")
            return "";

        // Xử lý file paths (lấy tên file không có extension)
        if (normalized.includes("/")) {
            const parts = normalized.split("/");
            normalized = parts[parts.length - 1];
            // Loại bỏ extension nếu có
            if (normalized.includes(".")) {
                const nameParts = normalized.split(".");
                normalized = nameParts.slice(0, -1).join(".");
            }
        }

        // Xử lý domain names (com.example.app -> app)
        if (normalized.includes(".")) {
            const parts = normalized.split(".");
            // Nếu có nhiều phần, lấy phần cuối cùng (thường là app name)
            if (parts.length > 1) {
                normalized = parts[parts.length - 1];
            }
        }

        // Loại bỏ các ký tự đặc biệt không hợp lệ cho icon name
        normalized = normalized
            .toLowerCase()
            .replace(/[^a-z0-9._-]/g, "-"); // an toàn cho icon name

        return normalized;
    }

    // Thử resolve icon từ một identifier duy nhất (appIcon, appName, ...)
    function resolveIconFromIdentifier(identifier) {
        if (!identifier || typeof identifier !== "string" || !AppSearch)
            return "";

        const lowercased = identifier.toLowerCase();
        
        // Xử lý đặc biệt cho Microsoft Edge - ưu tiên cao nhất và tránh fuzzy search sai
        if (lowercased.includes("edge") || lowercased.includes("microsoft")) {
            // Thử các tên icon Edge phổ biến trước
            const edgeCandidates = ["microsoft-edge", "edge", "msedge", "com.microsoft.edge"];
            for (let i = 0; i < edgeCandidates.length; i++) {
                const candidate = edgeCandidates[i];
                // Kiểm tra trực tiếp xem icon có tồn tại không
                if (AppSearch.iconExists(candidate)) {
                    return candidate;
                }
                // Thử dùng guessIcon (sẽ check substitutions)
                const guessed = AppSearch.guessIcon(candidate);
                if (guessed && AppSearch.iconExists(guessed) && 
                    (guessed.includes("edge") || guessed.includes("microsoft"))) {
                    return guessed;
                }
            }
            // Nếu không tìm thấy Edge icon, trả về rỗng thay vì để fuzzy search tìm "hp"
            return "";
        }

        const normalized = normalizeAppIdentifier(identifier);
        const candidates = [];

        // Ưu tiên id đã normalize, sau đó đến id gốc
        if (normalized && normalized !== identifier)
            candidates.push(normalized);
        candidates.push(identifier);

        for (let i = 0; i < candidates.length; i++) {
            const candidate = candidates[i];
            if (!candidate)
                continue;

            // 1. Nếu icon tồn tại trực tiếp -> dùng luôn
            if (AppSearch.iconExists(candidate))
                return candidate;

            // 2. Để AppSearch đoán icon tốt nhất (sẽ check substitutions và fuzzy search)
            const guessed = AppSearch.guessIcon(candidate);
            if (guessed && AppSearch.iconExists(guessed) && guessed !== "application-x-executable") {
                return guessed;
            }
        }

        return "";
    }

    // Tự động resolve icon tốt nhất với nhiều nguồn vào, nhưng code vẫn gọn
    readonly property string resolvedAppIcon: {
        try {
            // Thứ tự ưu tiên: appIcon -> appName -> một số gợi ý từ summary
            const sources = [
                appIcon,
                appName,
                // Một số từ khóa đặc biệt có lợi cho việc map icon (system-update, v.v.)
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