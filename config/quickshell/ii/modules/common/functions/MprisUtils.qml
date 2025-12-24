pragma Singleton
import Quickshell

Singleton {
    id: root

    function clamp01(x) {
        if (x === undefined || x === null || isNaN(x)) return 0;
        return Math.max(0, Math.min(1, x));
    }

    function toNumber0(value) {
        if (value === undefined || value === null || isNaN(value)) return 0;
        return Math.max(0, Number(value));
    }

    // Different stacks expose MPRIS time differently:
    // - On DBus, the MPRIS spec uses microseconds (e.g. mpris:length).
    // - Some wrappers/UIs expose seconds already.
    // We detect based on magnitude of length/position.
    function detectTimeUnit(player) {
        const len = toNumber0(player?.length);
        if (len > 1000000) return "micros";

        const pos = toNumber0(player?.position);
        if (pos > 1000000) return "micros";

        return "seconds";
    }

    function timeToSeconds(value, unit) {
        const v = toNumber0(value);
        return unit === "micros" ? (v / 1000000) : v;
    }

    // Smooth position in the *same unit* as player.position/player.length.
    // - lastKnownPosition and lastTimestampMs are maintained by the caller via onPositionChanged.
    function smoothPosition(player, lastKnownPosition, lastTimestampMs) {
        if (!player) return 0;

        const unit = detectTimeUnit(player);
        const reported = toNumber0(player.position);
        const base = reported > 0 ? reported : toNumber0(lastKnownPosition);

        if (player.isPlaying) {
            const elapsedMs = Math.max(0, Date.now() - (lastTimestampMs ?? Date.now()));
            const delta = unit === "micros" ? (elapsedMs * 1000) : (elapsedMs / 1000);
            return base + delta;
        }

        return base;
    }

    function smoothProgress(player, lastKnownPosition, lastTimestampMs) {
        if (!player) return 0;
        const len = toNumber0(player.length);
        if (len <= 0) return 0;

        const pos = smoothPosition(player, lastKnownPosition, lastTimestampMs);
        return clamp01(pos / len);
    }
}
