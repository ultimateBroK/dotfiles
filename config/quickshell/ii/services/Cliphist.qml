pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    // property string cliphistBinary: FileUtils.trimFileProtocol(`${Directories.home}/.cargo/bin/stash`)
    property string cliphistBinary: "cliphist"
    property real pasteDelay: 0.05
    property string pressPasteCommand: "ydotool key -d 1 29:1 47:1 47:0 29:0"
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property real scoreThreshold: 0.2
    property list<string> entries: []
    readonly property var preparedEntries: entries.map(a => ({
        name: Fuzzy.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
    }))
    function fuzzyQuery(search: string): var {
        if (search.trim() === "") {
            return entries;
        }
        if (root.sloppySearch) {
            const results = entries.slice(0, 100).map(str => ({
                entry: str,
                score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preparedEntries, {
            all: true,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function entryIsImage(entry) {
        return !!(/^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$/.test(entry))
    }

    function entryMime(entry) {
        // Extract mime inside [[mime;...]] if present
        const match = entry.match(/\[\[([^;\]]+);/)
        return match ? match[1] : ""
    }

    function refresh() {
        readProc.buffer = []
        readProc.running = true
    }

    function copy(entry) {
        const mime = entryMime(entry)
        if (root.cliphistBinary.includes("cliphist")) { // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy${mime ? ` -t ${mime}` : ""}`]);
        } else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy${mime ? ` -t ${mime}` : ""}`]);
        }
    }

    function paste(entry) {
        const mime = entryMime(entry)
        if (root.cliphistBinary.includes("cliphist")) { // Classic cliphist
            Quickshell.execDetached(["bash", "-c", `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy${mime ? ` -t ${mime}` : ""} && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`]);
        } else { // Stash
            const entryNumber = entry.split("\t")[0];
            Quickshell.execDetached(["bash", "-c", `${root.cliphistBinary} decode ${entryNumber} | wl-copy${mime ? ` -t ${mime}` : ""} && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`]);
        }
    }

    function superpaste(count, isImage = false) {
        // Find entries
        const targetEntries = entries.filter(entry => {
            if (!isImage) return true;
            return entryIsImage(entry);
        }).slice(0, count)
        const pasteCommands = [...targetEntries].reverse().map(entry => {
            const mime = entryMime(entry)
            if (root.cliphistBinary.includes("cliphist")) {
                return `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(entry)}' | ${root.cliphistBinary} decode | wl-copy${mime ? ` -t ${mime}` : ""} && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`
            } else {
                const entryNumber = entry.split("\t")[0]
                return `${root.cliphistBinary} decode ${entryNumber} | wl-copy${mime ? ` -t ${mime}` : ""} && sleep ${root.pasteDelay} && ${root.pressPasteCommand}`
            }
        })
        // Act
        Quickshell.execDetached(["bash", "-c", pasteCommands.join(` && sleep ${root.pasteDelay} && `)]);
    }

    Process {
        id: deleteProc
        property string entry: ""
        command: ["bash", "-c", `printf '%s\\n' '${StringUtils.shellSingleQuoteEscape(deleteProc.entry)}' | ${root.cliphistBinary} delete`]
        function deleteEntry(entry) {
            deleteProc.entry = entry;
            deleteProc.running = true;
            deleteProc.entry = "";
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function deleteEntry(entry) {
        deleteProc.deleteEntry(entry);
    }

    Process {
        id: wipeProc
        command: [root.cliphistBinary, "wipe"]
        onExited: (exitCode, exitStatus) => {
            root.refresh();
        }
    }

    function wipe() {
        wipeProc.running = true;
    }

    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            delayedUpdateTimer.restart()
        }
    }

    Timer {
        id: delayedUpdateTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: {
            root.refresh()
        }
    }

    Process {
        id: readProc
        property list<string> buffer: []

        command: [root.cliphistBinary, "list"]

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = readProc.buffer
            } else {
                console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus)
            }
        }
    }

    IpcHandler {
        target: "cliphistService"

        function update(): void {
            root.refresh()
        }
    }
}
