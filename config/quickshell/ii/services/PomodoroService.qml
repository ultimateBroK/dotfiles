pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Io
import QtQuick

/**
 * Simple Pomodoro timer service with basic logic
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

    // Basic timer state
    property bool running: false
    property int currentPhase: PomodoroService.Phase.Work
    property int remainingSeconds: workDuration * 60
    property int completedSessions: 0

    function getPhaseDuration() {
        if (currentPhase === PomodoroService.Phase.Work) {
            return workDuration * 60;
        }
        if (currentPhase === PomodoroService.Phase.ShortBreak) {
            return shortBreakDuration * 60;
        }
        return longBreakDuration * 60;
    }

    function playAlert(soundOverride = "") {
        const soundName = (soundOverride && soundOverride.length > 0) ? soundOverride : alertSound;
        if (!soundEnabled || !soundName) return;
        Audio.playSystemSound(soundName);
    }

    Timer {
        id: pomodoroTimer
        interval: 1000 // Update every second
        running: root.running
        repeat: true
        onTriggered: {
            if (remainingSeconds > 0) {
                remainingSeconds = remainingSeconds - 1;
            } else {
                completeSession();
            }
        }
    }

    function startTimer() {
        if (remainingSeconds <= 0) {
            remainingSeconds = getPhaseDuration();
        }
        running = true;
    }

    function pauseTimer() {
        running = false;
    }

    function toggleTimer() {
        if (running) {
            pauseTimer();
        } else {
            startTimer();
        }
    }

    function resetTimer() {
        running = false;
        currentPhase = PomodoroService.Phase.Work;
        remainingSeconds = workDuration * 60;
        completedSessions = 0;
    }

    function completeSession() {
        running = false;
        
        if (currentPhase === PomodoroService.Phase.Work) {
            completedSessions = completedSessions + 1;
            
            // Determine next phase
            if (completedSessions >= sessionsUntilLongBreak) {
                currentPhase = PomodoroService.Phase.LongBreak;
                completedSessions = 0;
            } else {
                currentPhase = PomodoroService.Phase.ShortBreak;
            }
        } else {
            // Break finished, start work session
            currentPhase = PomodoroService.Phase.Work;
        }
        
        remainingSeconds = getPhaseDuration();
        
        // Show notification
        if (Notifications.available) {
            const phaseName = currentPhase === PomodoroService.Phase.Work ? 
                Translation.tr("Work") : 
                (currentPhase === PomodoroService.Phase.LongBreak ? 
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
        running = false;
        
        if (currentPhase === PomodoroService.Phase.Work) {
            currentPhase = PomodoroService.Phase.ShortBreak;
        } else {
            currentPhase = PomodoroService.Phase.Work;
        }
        
        remainingSeconds = getPhaseDuration();
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

    // Update duration when config changes
    onWorkDurationChanged: {
        if (!running && currentPhase === PomodoroService.Phase.Work) {
            remainingSeconds = workDuration * 60;
        }
    }
    onShortBreakDurationChanged: {
        if (!running && currentPhase === PomodoroService.Phase.ShortBreak) {
            remainingSeconds = shortBreakDuration * 60;
        }
    }
    onLongBreakDurationChanged: {
        if (!running && currentPhase === PomodoroService.Phase.LongBreak) {
            remainingSeconds = longBreakDuration * 60;
        }
    }
}
