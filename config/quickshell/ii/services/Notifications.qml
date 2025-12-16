pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

/**
 * Provides extra features not in Quickshell.Services.Notifications:
 *  - Persistent storage
 *  - Popup notifications, with timeout
 *  - Notification groups by app
 */
Singleton {
	id: root
    function stringOrEmpty(value) {
        if (value === null || value === undefined)
            return "";
        if (typeof value === "string")
            return value;
        try {
            return value.toString();
        } catch (error) {
            console.warn("[Notifications] Failed to stringify value:", error);
            return "";
        }
    }

    function normalizeImageSource(image) {
        if (!image)
            return "";
        if (typeof image === "string") {
            // Xử lý các edge cases cho image string
            const trimmed = image.trim();
            if (trimmed === "" || trimmed === "null" || trimmed === "undefined") {
                return "";
            }
            return trimmed;
        }
        if (typeof image === "object") {
            // Xử lý object với nhiều trường hợp
            try {
                if (typeof image.url === "string" && image.url.trim() !== "") {
                    return image.url.trim();
                }
                if (typeof image.dataUrl === "string" && image.dataUrl.trim() !== "") {
                    return image.dataUrl.trim();
                }
                if (typeof image.path === "string" && image.path.trim() !== "") {
                    return image.path.trim();
                }
            } catch (error) {
                console.warn("[Notifications] Error normalizing image object:", error);
            }
        }
        console.warn("[Notifications] Unsupported image payload received, ignoring.");
        return "";
    }

    component Notif: QtObject {
        id: wrapper
        required property int notificationId // Could just be `id` but it conflicts with the default prop in QtObject
        property Notification notification
        property list<var> actions: notification?.actions?.map((action) => ({
            "identifier": action.identifier,
            "text": action.text,
        })) ?? []
        property bool popup: false
        property bool isTransient: notification?.hints?.transient ?? false
        property string appIcon: stringOrEmpty(notification?.appIcon)
        property string appName: stringOrEmpty(notification?.appName)
        property string body: stringOrEmpty(notification?.body)
        property string image: normalizeImageSource(notification?.image)
        property string summary: stringOrEmpty(notification?.summary)
        property double time
        property string urgency: notification?.urgency?.toString?.() ?? "normal"
        property Timer timer

        onNotificationChanged: {
            if (notification === null) {
                root.discardNotification(notificationId);
            }
        }
    }

    function notifToJSON(notif) {
        return {
            "notificationId": notif.notificationId,
            "actions": notif.actions,
            "appIcon": stringOrEmpty(notif.appIcon),
            "appName": stringOrEmpty(notif.appName),
            "body": stringOrEmpty(notif.body),
            "image": stringOrEmpty(notif.image),
            "summary": stringOrEmpty(notif.summary),
            "time": notif.time,
            "urgency": notif.urgency,
        }
    }
    function notifToString(notif) {
        return JSON.stringify(notifToJSON(notif), null, 2);
    }

    component NotifTimer: Timer {
        required property int notificationId
        interval: 7000
        running: true
        onTriggered: () => {
            const index = root.list.findIndex((notif) => notif.notificationId === notificationId);
            const notifObject = root.list[index];
            print("[Notifications] Notification timer triggered for ID: " + notificationId + ", transient: " + notifObject?.isTransient);
            if (notifObject.isTransient) root.discardNotification(notificationId);
            else root.timeoutNotification(notificationId);
            destroy()
        }
    }

    property bool silent: false
    property int unread: 0
    property var filePath: Directories.notificationsPath
    property list<Notif> list: []
    property var popupList: list.filter((notif) => notif.popup);
    property bool popupInhibited: (GlobalStates?.sidebarRightOpen ?? false) || silent
    property var latestTimeForApp: ({})
    Component {
        id: notifComponent
        Notif {}
    }
    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    function stringifyList(list) {
        return JSON.stringify(list.map((notif) => notifToJSON(notif)), null, 2);
    }
    
    onListChanged: {
        // Update latest time for each app
        root.list.forEach((notif) => {
            if (!root.latestTimeForApp[notif.appName] || notif.time > root.latestTimeForApp[notif.appName]) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time);
            }
        });
        // Remove apps that no longer have notifications
        Object.keys(root.latestTimeForApp).forEach((appName) => {
            if (!root.list.some((notif) => notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => {
            // Sort by time, descending
            return groups[b].time - groups[a].time;
        });
    }

    function groupsForList(list) {
        const groups = {};
        list.forEach((notif) => {
            if (!groups[notif.appName]) {
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    notifications: [],
                    time: 0
                };
            }
            groups[notif.appName].notifications.push(notif);
            // Always set to the latest time in the group
            groups[notif.appName].time = latestTimeForApp[notif.appName] || notif.time;
        });
        return groups;
    }

    // Cache groups to avoid recalculation
    property var _cachedGroupsByAppName: ({})
    property var _cachedPopupGroupsByAppName: ({})
    property var _cachedAppNameList: []
    property var _cachedPopupAppNameList: []
    property int _lastListLength: -1
    
    function updateGroupsCache() {
        if (_lastListLength === root.list.length && Object.keys(_cachedGroupsByAppName).length > 0) {
            return;
        }
        _cachedGroupsByAppName = groupsForList(root.list);
        _cachedPopupGroupsByAppName = groupsForList(root.popupList);
        _cachedAppNameList = appNameListForGroups(_cachedGroupsByAppName);
        _cachedPopupAppNameList = appNameListForGroups(_cachedPopupGroupsByAppName);
        _lastListLength = root.list.length;
    }
    
    property var groupsByAppName: {
        updateGroupsCache();
        return _cachedGroupsByAppName;
    }
    property var popupGroupsByAppName: {
        updateGroupsCache();
        return _cachedPopupGroupsByAppName;
    }
    property var appNameList: {
        updateGroupsCache();
        return _cachedAppNameList;
    }
    property var popupAppNameList: {
        updateGroupsCache();
        return _cachedPopupAppNameList;
    }

    // Quickshell's notification IDs starts at 1 on each run, while saved notifications
    // can already contain higher IDs. This is for avoiding id collisions
    property int idOffset
    signal initDone();
    signal notify(notification: var);
    signal discard(id: int);
    signal discardAll();
    signal timeout(id: var);

	NotificationServer {
        id: notifServer
        // actionIconsSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: (notification) => {
            try {
                notification.tracked = true
                const newNotifObject = notifComponent.createObject(root, {
                    "notificationId": notification.id + root.idOffset,
                    "notification": notification,
                    "time": Date.now(),
                });
                
                // Validate notification object trước khi thêm vào list
                if (!newNotifObject) {
                    console.warn("[Notifications] Failed to create notification object");
                    return;
                }
                
                root.list = [...root.list, newNotifObject];

                // Popup
                if (!root.popupInhibited) {
                    newNotifObject.popup = true;
                    if (notification.expireTimeout != 0) {
                        try {
                            newNotifObject.timer = notifTimerComponent.createObject(root, {
                                "notificationId": newNotifObject.notificationId,
                                "interval": notification.expireTimeout < 0 ? (Config?.options.notifications.timeout ?? 7000) : notification.expireTimeout,
                            });
                        } catch (error) {
                            console.warn("[Notifications] Failed to create notification timer:", error);
                        }
                    }
                    root.unread++;
                }
                root.notify(newNotifObject);
                // console.log(notifToString(newNotifObject));
                
                try {
                    notifFileView.setText(stringifyList(root.list));
                } catch (error) {
                    console.warn("[Notifications] Failed to save notification to file:", error);
                }
            } catch (error) {
                console.error("[Notifications] Error processing notification:", error);
            }
        }
    }

    function markAllRead() {
        root.unread = 0;
    }

    function discardNotification(id) {
        console.log("[Notifications] Discarding notification with ID: " + id);
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex((notif) => notif.id + root.idOffset === id);
        if (index !== -1) {
            root.list.splice(index, 1);
            notifFileView.setText(stringifyList(root.list));
            triggerListChange()
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss()
        }
        root.discard(id); // Emit signal
    }

    function discardAllNotifications() {
        root.list = []
        triggerListChange()
        notifFileView.setText(stringifyList(root.list));
        notifServer.trackedNotifications.values.forEach((notif) => {
            notif.dismiss()
        })
        root.discardAll();
    }

    function cancelTimeout(id) {
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        if (root.list[index] != null)
            root.list[index].timer.stop();
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex((notif) => notif.notificationId === id);
        if (root.list[index] != null)
            root.list[index].popup = false;
        root.timeout(id);
    }

    function timeoutAll() {
        root.popupList.forEach((notif) => {
            root.timeout(notif.notificationId);
        })
        root.popupList.forEach((notif) => {
            notif.popup = false;
        });
    }

    function attemptInvokeAction(id, notifIdentifier) {
        console.log("[Notifications] Attempting to invoke action with identifier: " + notifIdentifier + " for notification ID: " + id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex((notif) => notif.id + root.idOffset === id);
        console.log("Notification server index: " + notifServerIndex);
        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find((action) => action.identifier === notifIdentifier);
            // console.log("Action found: " + JSON.stringify(action));
            action.invoke()
        } 
        else {
            console.log("Notification not found in server: " + id)
        }
        root.discardNotification(id);
    }

    function triggerListChange() {
        // Invalidate cache when list changes
        _lastListLength = -1;
        root.list = root.list.slice(0)
    }

    function refresh() {
        notifFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: notifFileView
        path: Qt.resolvedUrl(filePath)
        onLoaded: {
            const fileContents = notifFileView.text()
            let parsedList = [];
            try {
                parsedList = JSON.parse(fileContents);
            } catch (error) {
                console.warn("[Notifications] Failed to parse cached notification file:", error);
                parsedList = [];
            }
            root.list = parsedList.map((notif) => {
                return notifComponent.createObject(root, {
                    "notificationId": notif.notificationId,
                    "actions": [], // Notification actions are meaningless if they're not tracked by the server or the sender is dead
                    "appIcon": stringOrEmpty(notif.appIcon),
                    "appName": stringOrEmpty(notif.appName),
                    "body": stringOrEmpty(notif.body),
                    "image": stringOrEmpty(notif.image),
                    "summary": stringOrEmpty(notif.summary),
                    "time": notif.time,
                    "urgency": notif.urgency,
                });
            });
            // Find largest notificationId
            let maxId = 0
            root.list.forEach((notif) => {
                maxId = Math.max(maxId, notif.notificationId)
            })

            console.log("[Notifications] File loaded")
            root.idOffset = maxId
            root.initDone()
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[Notifications] File not found, creating new file.")
                root.list = []
                notifFileView.setText(stringifyList(root.list));
            } else {
                console.log("[Notifications] Error loading file: " + error)
            }
        }
    }
}
