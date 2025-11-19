pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    // All "real" players after basic dedup/filtering (no plasma / playerctld noise)
    readonly property var realPlayers: Mpris.players.values.filter(player => isRealPlayer(player))

    // Final players list shown in the popup:
    // - Drop "empty" sessions (no title / artist / length / position) to avoid noise cards
    // - Order by playback state: Playing > Paused > everything else
    // - Then run duplicate-filtering (plasma, playerctld, etc.)
    readonly property var meaningfulPlayers: {
        function stateRank(player) {
            if (player.playbackState === MprisPlaybackState.Playing)
                return 0;   // highest priority
            return 1;       // Stopped / Paused / others
        }

        function hasUsefulMetadata(player) {
            if (!player) return false;
            if (player.playbackState === MprisPlaybackState.Playing) return true;

            const hasTitle = player.trackTitle && player.trackTitle.length > 0;
            const hasArtist = player.trackArtist && player.trackArtist.length > 0;
            const hasLength = player.length && player.length > 0;
            const hasPosition = player.position && player.position > 0;

            const dbus = (player.dbusName || "").toLowerCase();
            const isBrowser =
                    dbus.startsWith("org.mpris.mediaplayer2.firefox") ||
                    dbus.startsWith("org.mpris.mediaplayer2.chromium") ||
                    dbus.startsWith("org.mpris.mediaplayer2.google-chrome") ||
                    dbus.startsWith("org.mpris.mediaplayer2.brave") ||
                    dbus.startsWith("org.mpris.mediaplayer2.vivaldi") ||
                    dbus.startsWith("org.mpris.mediaplayer2.edge") ||
                    dbus.startsWith("org.mpris.mediaplayer2.opera") ||
                    dbus.startsWith("org.mpris.mediaplayer2.plasma-browser-integration");

            // Browser MPRIS sessions often linger after closing the tab – if stopped at 0s,
            // treat them as empty so they don't stay controllable forever.
            if (isBrowser &&
                player.playbackState === MprisPlaybackState.Stopped &&
                (!player.position || player.position <= 0)) {
                return false;
            }

            return hasTitle || hasArtist || hasLength || hasPosition;
        }

        // Drop empty players when we have at least one with real metadata.
        const candidates = realPlayers.filter(hasUsefulMetadata);
        const baseList = candidates.length > 0 ? candidates : realPlayers;

        // Copy + sort to keep original array untouched
        const sorted = baseList.slice().sort((a, b) => {
            const ra = stateRank(a);
            const rb = stateRank(b);
            if (ra !== rb)
                return ra - rb;
            return 0;
        });

        return filterDuplicatePlayers(sorted);
    }
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property list<real> visualizerPoints: []

    property bool hasPlasmaIntegration: false
    Process { // one-shot check for plasma-browser-integration
        id: plasmaIntegrationAvailabilityCheckProc
        running: true
        command: ["bash", "-c", "command -v plasma-browser-integration-host"]
        onExited: (exitCode, exitStatus) => {
            root.hasPlasmaIntegration = (exitCode === 0);
        }
    }
    function isRealPlayer(player) {
        if (!Config.options.media.filterDuplicatePlayers) return true;
        return (
            // Drop native browser buses when plasma integration is available
            !(hasPlasmaIntegration && player.dbusName.startsWith("org.mpris.MediaPlayer2.firefox")) &&
            !(hasPlasmaIntegration && player.dbusName.startsWith("org.mpris.MediaPlayer2.chromium")) &&
            // playerctld just mirrors other buses
            !player.dbusName?.startsWith("org.mpris.MediaPlayer2.playerctld") &&
            // Non-instance mpd bus
            !(player.dbusName?.endsWith(".mpd") && !player.dbusName.endsWith("MediaPlayer2.mpd"))
        );
    }
    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            // Find duplicates by trackTitle prefix
            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j);
                }
            }

            // Pick the one with non-empty trackArtUrl, or fallback to the first
            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    Process { // CAVA visualizer bridge
        id: cavaProc
        running: mediaControlsLoader.active
        onRunningChanged: {
            if (!cavaProc.running) root.visualizerPoints = [];
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen
        onActiveChanged: {
            if (!mediaControlsLoader.active && Mpris.players.values.filter(player => isRealPlayer(player)).length === 0) {
                GlobalStates.mediaControlsOpen = false;
            }
        }

        sourceComponent: PanelWindow {
            id: mediaControlsRoot
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth
            implicitHeight: playerColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: !Config.options.bar.bottom || Config.options.bar.vertical
                bottom: Config.options.bar.bottom && !Config.options.bar.vertical
                left: !(Config.options.bar.vertical && Config.options.bar.bottom)
                right: Config.options.bar.vertical && Config.options.bar.bottom
            }
            // Position popup just under the top bar and horizontally centered (for horizontal bars)
            margins {
                top: Config.options.bar.vertical
                     ? ((mediaControlsRoot.screen.height / 2) - widgetHeight * 1.5)
                     : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical
                      ? Appearance.sizes.barHeight
                      : (mediaControlsRoot.screen.width - root.widgetWidth) / 2
                right: Appearance.sizes.barHeight
            }

            mask: Region {
                item: playerColumnLayout
            }

            HyprlandFocusGrab {
                windows: [mediaControlsRoot]
                active: mediaControlsLoader.active
                onCleared: () => {
                    if (!active) {
                        GlobalStates.mediaControlsOpen = false;
                    }
                }
            }

            ColumnLayout {
                id: playerColumnLayout
                anchors.fill: parent
                spacing: -Appearance.sizes.elevationMargin // Shadow overlap okay

                Repeater {
                    model: ScriptModel {
                        values: root.meaningfulPlayers
                    }
                    delegate: PlayerControl {
                        required property MprisPlayer modelData
                        player: modelData
                        visualizerPoints: root.visualizerPoints
                        implicitWidth: root.widgetWidth
                        implicitHeight: root.widgetHeight
                        radius: root.popupRounding
                    }
                }

                Item { // Placeholder when there are no players
                    Layout.alignment: {
                        if (mediaControlsRoot.anchors.left) return Qt.AlignLeft;
                        if (mediaControlsRoot.anchors.right) return Qt.AlignRight;
                        return Qt.AlignHCenter;
                    }
                    Layout.leftMargin: Appearance.sizes.hyprlandGapsOut
                    Layout.rightMargin: Appearance.sizes.hyprlandGapsOut
                    visible: root.meaningfulPlayers.length === 0
                    implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                    implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                    StyledRectangularShadow {
                        target: placeholderBackground
                    }

                    Rectangle { 
                        id: placeholderBackground
                        anchors.centerIn: parent
                        color: Appearance.colors.colLayer0
                        radius: root.popupRounding
                        property real padding: 20
                        implicitWidth: placeholderLayout.implicitWidth + padding * 2
                        implicitHeight: placeholderLayout.implicitHeight + padding * 2

                        ColumnLayout {
                            id: placeholderLayout
                            anchors.centerIn: parent

                            StyledText {
                                text: Translation.tr("No active player")
                                font.pixelSize: Appearance.font.pixelSize.large
                            }
                            StyledText {
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if (mediaControlsLoader.active)
                Notifications.timeoutAll();
        }

        function close(): void {
            mediaControlsLoader.active = false;
        }

        function open(): void {
            mediaControlsLoader.active = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
        }
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = true;
        }
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = false;
        }
    }
}
