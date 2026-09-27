import AppKit
import Combine
import Foundation

@MainActor
public final class PomodoroService: ObservableObject {
    public static let shared = PomodoroService()

    @Published public private(set) var state: PomodoroState

    private var timerTask: Task<Void, Never>?
    private let settings = UserSettings.shared

    private init() {
        let workDuration = UserSettings.shared.pomodoroWorkMinutes * 60
        self.state = PomodoroState(
            phase: .work,
            remainingSeconds: workDuration,
            totalSeconds: workDuration,
            isRunning: false,
            completedSessions: 0
        )
    }

    public func start() {
        guard !state.isRunning else { return }
        state.isRunning = true

        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self, self.state.isRunning else { break }
                self.tick()
            }
        }
    }

    public func pause() {
        state.isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    public func toggle() {
        if state.isRunning {
            pause()
        } else {
            start()
        }
    }

    public func reset() {
        pause()
        let duration = targetDuration(for: state.phase)
        state.remainingSeconds = duration
        state.totalSeconds = duration
    }

    public func skipToNextPhase() {
        advancePhase()
    }

    public func refreshDurationsFromSettings() {
        if !state.isRunning {
            let duration = targetDuration(for: state.phase)
            state.remainingSeconds = duration
            state.totalSeconds = duration
        }
    }

    private func tick() {
        if state.remainingSeconds > 1 {
            state.remainingSeconds -= 1
        } else {
            state.remainingSeconds = 0
            completePhase()
        }
    }

    private func completePhase() {
        if settings.pomodoroSoundEnabled {
            NSSound(named: "Glass")?.play()
        }

        if state.phase == .work {
            state.completedSessions += 1
        }

        advancePhase()
    }

    private func advancePhase() {
        pause()

        let nextPhase: PomodoroPhase
        if state.phase == .work {
            if state.completedSessions > 0 && state.completedSessions % 4 == 0 {
                nextPhase = .longBreak
            } else {
                nextPhase = .shortBreak
            }
        } else {
            nextPhase = .work
        }

        let duration = targetDuration(for: nextPhase)
        state.phase = nextPhase
        state.totalSeconds = duration
        state.remainingSeconds = duration
    }

    private func targetDuration(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .work:
            return max(1, settings.pomodoroWorkMinutes) * 60
        case .shortBreak:
            return max(1, settings.pomodoroShortBreakMinutes) * 60
        case .longBreak:
            return max(1, settings.pomodoroLongBreakMinutes) * 60
        }
    }
}
