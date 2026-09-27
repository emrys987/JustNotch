import SwiftUI

public enum NotchViewMode: String, CaseIterable, Identifiable, Sendable {
    case main = "main"
    case shelf = "shelf"
    case clipboard = "clipboard"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .main:
            return "Ana Kısım"
        case .shelf:
            return "Dosya Rafı"
        case .clipboard:
            return "Pano Geçmişi"
        }
    }

    public var iconName: String {
        switch self {
        case .main:
            return "square.grid.2x2.fill"
        case .shelf:
            return "tray.and.arrow.down.fill"
        case .clipboard:
            return "doc.on.clipboard.fill"
        }
    }
}

public enum MainWidgetType: String, CaseIterable, Identifiable, Sendable {
    case music = "music"
    case pomodoro = "pomodoro"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .music:
            return "Müzik & Sözler"
        case .pomodoro:
            return "Pomodoro"
        }
    }

    public var iconName: String {
        switch self {
        case .music:
            return "music.note"
        case .pomodoro:
            return "timer"
        }
    }

    public var accentColor: Color {
        switch self {
        case .music:
            return Color(red: 0.18, green: 0.84, blue: 0.45)
        case .pomodoro:
            return Color(red: 1.0, green: 0.42, blue: 0.38)
        }
    }
}
