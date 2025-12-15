pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Pomodoro timer service for ADHD focus management.
 * Standard pomodoro: 25 minutes work, 5 minutes break
 */
Singleton {
    id: root

    enum Phase {
        Work,
        ShortBreak,
        LongBreak
    }

    property int workDuration: Config.options?.adhd?.pomodoro?.workDuration ?? 25 // minutes
    property int shortBreakDuration: Config.options?.adhd?.pomodoro?.shortBreakDuration ?? 5 // minutes
    property int longBreakDuration: Config.options?.adhd?.pomodoro?.longBreakDuration ?? 15 // minutes
    property int sessionsUntilLongBreak: Config.options?.adhd?.pomodoro?.sessionsUntilLongBreak ?? 4
    property bool soundEnabled: Config.options?.adhd?.pomodoro?.sound?.enable ?? true
    property string alertSound: Config.options?.adhd?.pomodoro?.sound?.name ?? "complete"

    // Use explicit bindings to Persistent state for reactivity
    property bool running: false
    property int currentPhase: 0
    property int remainingSeconds: workDuration * 60
    property int startTime: 0
    property int totalDuration: workDuration * 60
    property int completedSessions: 0

    function currentPhaseDurationSeconds() {
        if (currentPhase === PomodoroService.Phase.Work) {
            return workDuration * 60;
        }
        if (currentPhase === PomodoroService.Phase.ShortBreak) {
            return shortBreakDuration * 60;
        }
        return longBreakDuration * 60;
    }

    function resyncDurationIfIdle() {
        if (running) return;
        const duration = currentPhaseDurationSeconds();
        totalDuration = duration;
        remainingSeconds = duration;
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.totalDuration = duration;
            Persistent.states.pomodoro.startTime = 0;
            Persistent.states.pomodoro.running = false;
        }
    }

    function playAlert(soundOverride = "") {
        const soundName = (soundOverride && soundOverride.length > 0) ? soundOverride : alertSound;
        if (!soundEnabled || !soundName) return;
        Audio.playSystemSound(soundName);
    }

    // Sync state from Persistent when it changes
    Connections {
        target: Persistent.states?.pomodoro ?? null
        function onRunningChanged() {
            root.running = Persistent.states.pomodoro.running
        }
        function onCurrentPhaseChanged() {
            root.currentPhase = Persistent.states.pomodoro.currentPhase
        }
        function onStartTimeChanged() {
            root.startTime = Persistent.states.pomodoro.startTime
        }
        function onTotalDurationChanged() {
            root.totalDuration = Persistent.states.pomodoro.totalDuration
        }
        function onCompletedSessionsChanged() {
            root.completedSessions = Persistent.states.pomodoro.completedSessions
        }
    }

    onWorkDurationChanged: resyncDurationIfIdle()
    onShortBreakDurationChanged: resyncDurationIfIdle()
    onLongBreakDurationChanged: resyncDurationIfIdle()

    function getCurrentTimeInSeconds() {
        return Math.floor(Date.now() / 1000);
    }

    function refreshTimer() {
        if (!running) return;
        const elapsed = getCurrentTimeInSeconds() - startTime;
        remainingSeconds = Math.max(0, totalDuration - elapsed);
        
        if (remainingSeconds <= 0) {
            completeSession();
        }
    }

    Timer {
        id: pomodoroTimer
        interval: 1000 // Update every second
        running: root.running
        repeat: true
        onTriggered: refreshTimer()
    }

    Component.onCompleted: {
        // Initialize state from Persistent
        if (Persistent.states?.pomodoro) {
            running = Persistent.states.pomodoro.running ?? false
            currentPhase = Persistent.states.pomodoro.currentPhase ?? 0
            startTime = Persistent.states.pomodoro.startTime ?? 0
            totalDuration = Persistent.states.pomodoro.totalDuration ?? (workDuration * 60)
            completedSessions = Persistent.states.pomodoro.completedSessions ?? 0
            
            if (running && startTime > 0) {
                refreshTimer();
            } else {
                remainingSeconds = totalDuration > 0 ? totalDuration : workDuration * 60;
            }
        }
    }

    function startTimer() {
        const duration = currentPhaseDurationSeconds();
        
        // Update local state
        running = true;
        startTime = getCurrentTimeInSeconds();
        totalDuration = duration;
        remainingSeconds = duration;
        
        // Persist to storage
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.running = true;
            Persistent.states.pomodoro.startTime = startTime;
            Persistent.states.pomodoro.totalDuration = duration;
        }
        
        refreshTimer();
    }

    function pauseTimer() {
        // Update local state
        running = false;
        
        // Persist to storage
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.running = false;
        }
    }

    function resumeTimer() {
        if (remainingSeconds > 0) {
            const newStartTime = getCurrentTimeInSeconds() - (totalDuration - remainingSeconds);
            
            // Update local state
            running = true;
            startTime = newStartTime;
            
            // Persist to storage
            if (Persistent.states?.pomodoro) {
                Persistent.states.pomodoro.running = true;
                Persistent.states.pomodoro.startTime = newStartTime;
            }
            
            refreshTimer();
        }
    }

    function toggleTimer() {
        if (running) {
            pauseTimer();
        } else {
            if (remainingSeconds <= 0) {
                resetTimer();
            }
            startTimer();
        }
    }

    function resetTimer() {
        // Update local state
        running = false;
        currentPhase = PomodoroService.Phase.Work;
        startTime = 0;
        totalDuration = workDuration * 60;
        remainingSeconds = workDuration * 60;
        
        // Persist to storage
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.running = false;
            Persistent.states.pomodoro.currentPhase = PomodoroService.Phase.Work;
            Persistent.states.pomodoro.startTime = 0;
            Persistent.states.pomodoro.totalDuration = workDuration * 60;
        }
    }

    function completeSession() {
        pauseTimer();
        
        const completedPhase = currentPhase;
        let nextPhase = PomodoroService.Phase.Work;
        
        if (completedPhase === PomodoroService.Phase.Work) {
            completedSessions = completedSessions + 1;
            if (Persistent.states?.pomodoro) {
                Persistent.states.pomodoro.completedSessions = completedSessions;
            }
            
            // Determine next phase
            if (completedSessions >= sessionsUntilLongBreak) {
                nextPhase = PomodoroService.Phase.LongBreak;
                completedSessions = 0;
                if (Persistent.states?.pomodoro) {
                    Persistent.states.pomodoro.completedSessions = 0;
                }
            } else {
                nextPhase = PomodoroService.Phase.ShortBreak;
            }
        } else {
            // Break finished, start work session
            nextPhase = PomodoroService.Phase.Work;
        }
        
        // Update local and persistent state
        currentPhase = nextPhase;
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.currentPhase = nextPhase;
        }
        
        // Reset timer for new phase
        running = false;
        startTime = 0;
        
        if (nextPhase === PomodoroService.Phase.Work) {
            totalDuration = workDuration * 60;
        } else if (nextPhase === PomodoroService.Phase.ShortBreak) {
            totalDuration = shortBreakDuration * 60;
        } else {
            totalDuration = longBreakDuration * 60;
        }
        remainingSeconds = totalDuration;
        
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.running = false;
            Persistent.states.pomodoro.startTime = 0;
            Persistent.states.pomodoro.totalDuration = totalDuration;
        }
        
        // Show notification
        if (Notifications.available) {
            const phaseName = completedPhase === PomodoroService.Phase.Work ? 
                Translation.tr("Work") : 
                (completedPhase === PomodoroService.Phase.LongBreak ? 
                    Translation.tr("Long Break") : 
                    Translation.tr("Short Break"));
            Notifications.send({
                summary: Translation.tr("Pomodoro"),
                body: phaseName + " " + Translation.tr("completed!"),
                urgency: "normal"
            });
        }
        playAlert();
    }

    function skipToNextPhase() {
        pauseTimer();
        
        let nextPhase;
        if (currentPhase === PomodoroService.Phase.Work) {
            nextPhase = PomodoroService.Phase.ShortBreak;
        } else {
            nextPhase = PomodoroService.Phase.Work;
        }
        
        // Update local state
        currentPhase = nextPhase;
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.currentPhase = nextPhase;
        }
        
        // Reset timer for new phase
        running = false;
        startTime = 0;
        
        if (nextPhase === PomodoroService.Phase.Work) {
            totalDuration = workDuration * 60;
        } else if (nextPhase === PomodoroService.Phase.ShortBreak) {
            totalDuration = shortBreakDuration * 60;
        } else {
            totalDuration = longBreakDuration * 60;
        }
        remainingSeconds = totalDuration;
        
        if (Persistent.states?.pomodoro) {
            Persistent.states.pomodoro.running = false;
            Persistent.states.pomodoro.startTime = 0;
            Persistent.states.pomodoro.totalDuration = totalDuration;
        }
    }

    function formatTime(seconds) {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }

    readonly property string formattedTime: formatTime(remainingSeconds)
    readonly property string phaseName: {
        if (currentPhase === PomodoroService.Phase.Work) return Translation.tr("Work");
        if (currentPhase === PomodoroService.Phase.LongBreak) return Translation.tr("Long Break");
        return Translation.tr("Break");
    }
}
