import SwiftUI

public enum PomodoroPhase: String, CaseIterable, Sendable {
    case work = "work"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"

    public var title: String {
        switch self {
        case .work:
            return "Odaklanma"
        case .shortBreak:
            return "Kısa Mola"
        case .longBreak:
            return "Uzun Mola"
        }
    }

    public var iconName: String {
        switch self {
        case .work:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "moon.stars.fill"
        }
    }

    public var themeColor: Color {
        switch self {
        case .work:
            return Color(red: 1.0, green: 0.35, blue: 0.32)
        case .shortBreak:
            return Color(red: 0.28, green: 0.82, blue: 0.55)
        case .longBreak:
            return Color(red: 0.38, green: 0.65, blue: 1.00)
        }
    }
}

public struct PomodoroState: Equatable, Sendable {
    public var phase: PomodoroPhase
    public var remainingSeconds: Int
    public var totalSeconds: Int
    public var isRunning: Bool
    public var completedSessions: Int

    public init(
        phase: PomodoroPhase = .work,
        remainingSeconds: Int = 25 * 60,
        totalSeconds: Int = 25 * 60,
        isRunning: Bool = false,
        completedSessions: Int = 0
    ) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.totalSeconds = totalSeconds
        self.isRunning = isRunning
        self.completedSessions = completedSessions
    }

    public var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        let elapsed = Double(totalSeconds - remainingSeconds)
        return min(1.0, max(0.0, elapsed / Double(totalSeconds)))
    }

    public var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
