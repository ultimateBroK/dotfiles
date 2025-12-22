pragma Singleton
pragma ComponentBehavior: Bound

// From https://git.outfoxxed.me/outfoxxed/nixnew
// It does not have a license, but the author is okay with redistribution.

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common

/**
 * A service that provides easy access to the active Mpris player.
 */
Singleton {
	id: root;
	property MprisPlayer trackedPlayer: null;
	readonly property MprisPlayer activePlayer: {
		// Force re-evaluation when trackedPlayer or Mpris.players changes
		const _ = trackedPlayer;
		const __ = Mpris.players.count;
		return getBestActivePlayer();
	}
	signal trackChanged(reverse: bool);

	property bool __reverse: false;

	property var activeTrack;

	property bool hasPlasmaIntegration: false
	// NOTE: Don't detect plasma browser integration by checking for the host binary.
	// Many setups may have the package installed but not the browser extension/service active.
	// If we drop native browser MPRIS buses in that case, we end up with "no active player".
	readonly property bool hasPlasmaIntegrationService: {
		// Force re-evaluation when Mpris.players changes
		const _ = Mpris.players.count;
		return Mpris.players.values.some(p =>
			((p?.dbusName ?? "").toLowerCase()).startsWith("org.mpris.mediaplayer2.plasma-browser-integration")
		);
	}

	function isRealPlayer(player) {
		if (!player) return false;
		if (!Config.options.media.filterDuplicatePlayers) return true;
		const dbus = (player.dbusName ?? "").toLowerCase();
		return (
			// Drop native browser buses when plasma integration is available
			!(hasPlasmaIntegrationService && dbus.startsWith("org.mpris.mediaplayer2.firefox")) &&
			!(hasPlasmaIntegrationService && dbus.startsWith("org.mpris.mediaplayer2.chromium")) &&
			// playerctld just mirrors other buses
			!dbus.startsWith("org.mpris.mediaplayer2.playerctld") &&
			// Non-instance mpd bus
			!(dbus.endsWith(".mpd") && !dbus.endsWith("mediaplayer2.mpd"))
		);
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
				const titleMatch =
					p1.trackTitle && p2.trackTitle &&
					(p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle));

				const p1Len = p1.length ?? 0;
				const p2Len = p2.length ?? 0;
				const p1Pos = p1.position ?? 0;
				const p2Pos = p2.position ?? 0;
				const timingMatch =
					(p1Len > 0 && p2Len > 0) &&
					(Math.abs(p1Pos - p2Pos) <= 2) &&
					(Math.abs(p1Len - p2Len) <= 2);

				if (titleMatch || timingMatch) {
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

	function stateRank(player) {
		if (player.playbackState === MprisPlaybackState.Playing)
			return 0;   // highest priority
		return 1;       // Stopped / Paused / others
	}

	function getBestActivePlayer() {
		// If we have a manually tracked player that's still valid, prefer it
		if (trackedPlayer && isRealPlayer(trackedPlayer) && hasUsefulMetadata(trackedPlayer)) {
			return trackedPlayer;
		}

		// Filter to real players
		const realPlayers = Mpris.players.values.filter(player => isRealPlayer(player));
		if (realPlayers.length === 0) return null;

		// Filter to players with useful metadata
		const candidates = realPlayers.filter(hasUsefulMetadata);
		const baseList = candidates.length > 0 ? candidates : realPlayers;

		// Sort by playback state: Playing > Paused > everything else
		const sorted = baseList.slice().sort((a, b) => {
			const ra = stateRank(a);
			const rb = stateRank(b);
			if (ra !== rb)
				return ra - rb;
			// If same state, prefer players with better metadata (artwork, title, artist)
			const aScore = (a.trackArtUrl ? 4 : 0) + (a.trackTitle ? 2 : 0) + (a.trackArtist ? 1 : 0);
			const bScore = (b.trackArtUrl ? 4 : 0) + (b.trackTitle ? 2 : 0) + (b.trackArtist ? 1 : 0);
			return bScore - aScore;
		});

		// Filter duplicates and return the best one
		const filtered = filterDuplicatePlayers(sorted);
		return filtered.length > 0 ? filtered[0] : null;
	}

	Connections {
		target: Mpris
		function onPlayersChanged() {
			// Update tracked player when player list changes
			const bestPlayer = root.getBestActivePlayer();
			if (bestPlayer !== root.trackedPlayer) {
				root.trackedPlayer = bestPlayer;
			}
		}
	}

	Instantiator {
		model: Mpris.players;

		Connections {
			required property MprisPlayer modelData;
			target: modelData;

			Component.onCompleted: {
				// Update tracked player when a better one becomes available
				const bestPlayer = root.getBestActivePlayer();
				if (bestPlayer && (!root.trackedPlayer || bestPlayer.isPlaying)) {
					root.trackedPlayer = bestPlayer;
				}
			}

			Component.onDestruction: {
				// If the destroyed player was the tracked one, find the best replacement
				if (root.trackedPlayer === modelData) {
					root.trackedPlayer = root.getBestActivePlayer();
				}
			}

			function onPlaybackStateChanged() {
				// When playback state changes, update to the best available player
				const bestPlayer = root.getBestActivePlayer();
				if (bestPlayer) {
					// Only switch if current player stopped or new player is playing
					if (!root.trackedPlayer || !root.trackedPlayer.isPlaying || bestPlayer.isPlaying) {
						root.trackedPlayer = bestPlayer;
					}
				}
			}
		}
	}

	Connections {
		target: activePlayer

		function onPostTrackChanged() {
			root.updateTrack();
		}

		function onTrackArtUrlChanged() {
			// console.log("arturl:", activePlayer.trackArtUrl)
			// root.updateTrack();
			if (root.activePlayer.uniqueId == root.activeTrack.uniqueId && root.activePlayer.trackArtUrl != root.activeTrack.artUrl) {
				// cantata likes to send cover updates *BEFORE* updating the track info.
				// as such, art url changes shouldn't be able to break the reverse animation
				const r = root.__reverse;
				root.updateTrack();
				root.__reverse = r;

			}
		}
	}

	onActivePlayerChanged: this.updateTrack();

	function updateTrack() {
		//console.log(`update: ${this.activePlayer?.trackTitle ?? ""} : ${this.activePlayer?.trackArtists}`)
		this.activeTrack = {
			uniqueId: this.activePlayer?.uniqueId ?? 0,
			artUrl: this.activePlayer?.trackArtUrl ?? "",
			title: this.activePlayer?.trackTitle || Translation.tr("Unknown Title"),
			artist: this.activePlayer?.trackArtist || Translation.tr("Unknown Artist"),
			album: this.activePlayer?.trackAlbum || Translation.tr("Unknown Album"),
		};

		this.trackChanged(__reverse);
		this.__reverse = false;
	}

	property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying;
	property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? false;
	function togglePlaying() {
		if (this.canTogglePlaying) this.activePlayer.togglePlaying();
	}

	property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? false;
	function previous() {
		if (this.canGoPrevious) {
			this.__reverse = true;
			this.activePlayer.previous();
		}
	}

	property bool canGoNext: this.activePlayer?.canGoNext ?? false;
	function next() {
		if (this.canGoNext) {
			this.__reverse = false;
			this.activePlayer.next();
		}
	}

	property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl;

	property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl;
	property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None;
	function setLoopState(loopState: var) {
		if (this.loopSupported) {
			this.activePlayer.loopState = loopState;
		}
	}

	property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl;
	property bool hasShuffle: this.activePlayer?.shuffle ?? false;
	function setShuffle(shuffle: bool) {
		if (this.shuffleSupported) {
			this.activePlayer.shuffle = shuffle;
		}
	}

	function setActivePlayer(player: MprisPlayer) {
		const targetPlayer = player ?? Mpris.players[0];
		console.log(`[Mpris] Active player ${targetPlayer} << ${activePlayer}`)

		if (targetPlayer && this.activePlayer) {
			this.__reverse = Mpris.players.indexOf(targetPlayer) < Mpris.players.indexOf(this.activePlayer);
		} else {
			// always animate forward if going to null
			this.__reverse = false;
		}

		this.trackedPlayer = targetPlayer;
	}

	IpcHandler {
		target: "mpris"

		function pauseAll(): void {
			for (const player of Mpris.players.values) {
				if (player.canPause) player.pause();
			}
		}

		function playPause(): void { root.togglePlaying(); }
		function previous(): void { root.previous(); }
		function next(): void { root.next(); }
	}
}
