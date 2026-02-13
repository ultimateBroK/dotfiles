pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath
    property string modeFilePath: Directories.generatedMaterialThemeModePath

    function reapplyTheme() {
        themeFileView.reload()
        modeFileView.reload()
    }

    function applyColors(fileContent, modeContent) {
        const json = JSON.parse(fileContent)
        let flatColors
        let darkmode

        // matugen v4+ new format: { colors: { dark: {...}, light: {...} } }
        if (json.colors && (json.colors.dark || json.colors.light)) {
            const scheme = (modeContent || "dark").trim().toLowerCase()
            const schemeColors = json.colors[scheme] || json.colors.dark || json.colors.light
            flatColors = schemeColors
            darkmode = (scheme === "dark")
        } else {
            // Legacy flat format: { background: "#...", ... }
            flatColors = json
            darkmode = false // will be set from background lightness
        }

        for (const key in flatColors) {
            if (flatColors.hasOwnProperty(key)) {
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                Appearance.m3colors[m3Key] = flatColors[key]
            }
        }

        Appearance.m3colors.darkmode = (typeof darkmode === "boolean")
            ? darkmode
            : (Appearance.m3colors.m3background.hslLightness < 0.5)
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: applyColorsFromFiles()
    }

    function applyColorsFromFiles() {
        const modeContent = (modeFileView.loaded ? modeFileView.text() : "") || "dark"
        root.applyColors(themeFileView.text(), modeContent)
    }

    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: applyColorsFromFiles()
        onLoadFailed: root.resetFilePathNextTime()
    }

    FileView {
        id: modeFileView
        path: Qt.resolvedUrl(root.modeFilePath)
        watchChanges: true
        onFileChanged: this.reload()
        onLoadedChanged: {
            if (themeFileView.loaded) applyColorsFromFiles()
        }
    }
}
