pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
    id: root
    readonly property bool overlayResourcesEnabled: {
        const open = Persistent?.states?.overlay?.open ?? [];
        return open.includes("resources");
    }

    readonly property bool barResourcesEnabled: Config?.options?.bar?.resources?.enable ?? true
    readonly property bool wantMemory: barResourcesEnabled && (Config?.options?.bar?.resources?.showMemory ?? true)
    readonly property bool wantSwap: barResourcesEnabled && (Config?.options?.bar?.resources?.showSwap ?? true)
    readonly property bool wantCpu: barResourcesEnabled && (Config?.options?.bar?.resources?.showCpu ?? true)
    readonly property bool wantGpu: barResourcesEnabled && (Config?.options?.bar?.resources?.showGpu ?? true)

    // Whether any on-screen consumer currently needs these metrics.
    readonly property bool active: overlayResourcesEnabled || wantMemory || wantSwap || wantCpu || wantGpu

	property real memoryTotal: 0
	property real memoryFree: 0
	property real memoryUsed: Math.max(0, memoryTotal - memoryFree)
    property real memoryUsedPercentage: memoryTotal > 0 ? (memoryUsed / memoryTotal) : 0
    property real swapTotal: 0
	property real swapFree: 0
	property real swapUsed: Math.max(0, swapTotal - swapFree)
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats

    // Thermals / GPU (best effort; may be unavailable depending on drivers/tools)
    property real cpuTempC: NaN
    property real gpuUsage: 0
    property real gpuTempC: NaN
    property string gpuKind: ""
    property string gpuName: ""
    property bool gpuAvailable: false
    // Throttle GPU polling to avoid expensive tools (e.g. nvidia-smi) every tick.
    property int gpuMinIntervalMs: 5000
    property double _lastGpuPollMs: 0
    property int cpuTempMinIntervalMs: 2500
    property double _lastCpuTempPollMs: 0

    property string maxAvailableMemoryString: (ResourceUsage.memoryTotal > 0) ? kbToGbString(ResourceUsage.memoryTotal) : "--"
    property string maxAvailableSwapString: (ResourceUsage.swapTotal > 0) ? kbToGbString(ResourceUsage.swapTotal) : "--"
    property string maxAvailableCpuString: "--"
    property string maxAvailableGpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []
    property list<real> gpuUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        // Use slice instead of spread operator for better performance
        memoryUsageHistory = memoryUsageHistory.slice().concat([memoryUsedPercentage])
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory = memoryUsageHistory.slice(-historyLength)
        }
    }
    function updateSwapUsageHistory() {
        // Use slice instead of spread operator for better performance
        swapUsageHistory = swapUsageHistory.slice().concat([swapUsedPercentage])
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory = swapUsageHistory.slice(-historyLength)
        }
    }
    function updateCpuUsageHistory() {
        // Use slice instead of spread operator for better performance
        cpuUsageHistory = cpuUsageHistory.slice().concat([cpuUsage])
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory = cpuUsageHistory.slice(-historyLength)
        }
    }
    function updateGpuUsageHistory() {
        gpuUsageHistory = gpuUsageHistory.slice().concat([gpuUsage])
        if (gpuUsageHistory.length > historyLength) {
            gpuUsageHistory = gpuUsageHistory.slice(-historyLength)
        }
    }
    function updateHistories() {
        if (!root.active) return;
        const overlay = root.overlayResourcesEnabled;
        if (overlay || root.wantMemory) updateMemoryUsageHistory()
        if (overlay || root.wantSwap) updateSwapUsageHistory()
        if (overlay || root.wantCpu) updateCpuUsageHistory()
        if (root.wantGpu) updateGpuUsageHistory()
    }

    function _clamp01(v) {
        if (!Number.isFinite(v)) return 0;
        return Math.max(0, Math.min(1, v));
    }

    function _parseKeyValueLines(text) {
        const out = {};
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.length === 0) continue;
            const idx = line.indexOf("=");
            if (idx <= 0) continue;
            const k = line.slice(0, idx).trim();
            const v = line.slice(idx + 1).trim();
            out[k] = v;
        }
        return out;
    }

    function _updateCpuTempFromText(text) {
        const kv = root._parseKeyValueLines(text);

        const cpuT = parseFloat(kv.cpu_temp_c);
        root.cpuTempC = Number.isFinite(cpuT) ? cpuT : NaN;
    }

    function _updateGpuFromText(text) {
        const kv = root._parseKeyValueLines(text);

        const gpuU = parseFloat(kv.gpu_util);
        root.gpuUsage = root._clamp01(gpuU);

        const gpuT = parseFloat(kv.gpu_temp_c);
        root.gpuTempC = Number.isFinite(gpuT) ? gpuT : NaN;

        root.gpuKind = kv.gpu_kind || "";
        root.gpuName = kv.gpu_name || "";
        root.gpuAvailable = (root.gpuKind.length > 0) || Number.isFinite(gpuU) || Number.isFinite(gpuT);
    }

    function _maybePollCpuTemp() {
        if (!root.active) return;
        if (!root.wantCpu) return;
        if (cpuTempProc.running) return;
        const now = Date.now();
        const minInterval = Math.max(root.cpuTempMinIntervalMs, Config.options?.resources?.updateInterval ?? 3000);
        if (now - root._lastCpuTempPollMs < minInterval) return;
        root._lastCpuTempPollMs = now;
        cpuTempProc.running = true;
    }

    function _maybePollGpu() {
        if (!root.active) return;
        if (!root.wantGpu) return;
        if (gpuProc.running) return;
        const now = Date.now();
        const minInterval = Math.max(root.gpuMinIntervalMs, Config.options?.resources?.updateInterval ?? 3000);
        if (now - root._lastGpuPollMs < minInterval) return;
        root._lastGpuPollMs = now;
        gpuProc.running = true;
    }

    function refreshNow() {
        if (!root.active) return;
        const overlay = root.overlayResourcesEnabled;

        // Reload files
        if (overlay || root.wantMemory || root.wantSwap) fileMeminfo.reload()
        if (overlay || root.wantCpu) fileStat.reload()

        // Parse memory and swap usage
        if (overlay || root.wantMemory || root.wantSwap) {
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 0)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 0)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)
        }

        // Parse CPU usage
        if (overlay || root.wantCpu) {
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }
        }

        // Poll CPU temp and GPU stats separately (async, throttled)
        root._maybePollCpuTemp();
        root._maybePollGpu();

        root.updateHistories()
    }

	Timer {
		interval: Config.options?.resources?.updateInterval ?? 3000
        running: root.active
        repeat: true
		onTriggered: {
            root.refreshNow()
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }

    Process {
        id: findCpuMaxFreqProc
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: root.active && (root.overlayResourcesEnabled || root.wantCpu)
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                const mhz = parseFloat(outputCollector.text);
                root.maxAvailableCpuString = Number.isFinite(mhz) ? ((mhz / 1000).toFixed(0) + " GHz") : "--";
            }
        }
    }

    Process {
        id: cpuTempProc
        running: false
        command: ["bash", Quickshell.shellPath("scripts/system/get-cpu-temp.sh")]
        stdout: StdioCollector {
            id: cpuTempCollector
            onStreamFinished: {
                root._updateCpuTempFromText(cpuTempCollector.text);
            }
        }
    }

    Process {
        id: gpuProc
        running: false
        command: ["bash", Quickshell.shellPath("scripts/system/get-gpu-stats.sh")]
        stdout: StdioCollector {
            id: gpuCollector
            onStreamFinished: {
                root._updateGpuFromText(gpuCollector.text);
            }
        }
    }

    // Make resources show up immediately after restarting Quickshell (only if needed).
    Component.onCompleted: {
        Qt.callLater(() => {
            if (root.active) root.refreshNow();
            // CPU usage requires two /proc/stat samples; do a quick warmup refresh so CPU/RAM
            // values look correct immediately after startup.
            if (root.active) startupWarmup.restart();
        })
    }

    Timer {
        id: startupWarmup
        interval: 600
        repeat: false
        running: false
        onTriggered: root.refreshNow()
    }

    onActiveChanged: {
        if (root.active) {
            Qt.callLater(() => {
                root.refreshNow();
                startupWarmup.restart();
            })
        }
    }
}
