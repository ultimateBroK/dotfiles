pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    property string audioTheme: Config.options.sounds.theme

    signal sinkProtectionTriggered(string reason);

    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    function playSystemSound(soundName) {
        // Try local sounds first, then system sounds - only play one file
        const localOgaPath = `${Quickshell.env("HOME")}/.local/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const localOggPath = `${Quickshell.env("HOME")}/.local/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;
        const systemOgaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const systemOggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        // Use a single shell command to find and play the first existing file
        // This avoids spawning multiple ffplay processes
        Quickshell.execDetached(["sh", "-c", 
            `test -f "${localOgaPath}" && ffplay -nodisp -autoexit "${localOgaPath}" || ` +
            `test -f "${localOggPath}" && ffplay -nodisp -autoexit "${localOggPath}" || ` +
            `test -f "${systemOgaPath}" && ffplay -nodisp -autoexit "${systemOgaPath}" || ` +
            `test -f "${systemOggPath}" && ffplay -nodisp -autoexit "${systemOggPath}" || ` +
            `true`
        ]);
    }
}
