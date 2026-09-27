import AppKit
import Foundation

public struct ClipboardItem: Identifiable, Equatable {
    public let id: UUID
    public let text: String
    public let copiedAt: Date
    public var isPinned: Bool
    public var pinnedAt: Date?
    public var image: NSImage?

    public init(
        id: UUID = UUID(),
        text: String,
        copiedAt: Date = Date(),
        isPinned: Bool = false,
        pinnedAt: Date? = nil,
        image: NSImage? = nil
    ) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
        self.isPinned = isPinned
        self.pinnedAt = pinnedAt
        self.image = image
    }

    public var isImage: Bool {
        image != nil
    }

    public var previewSnippet: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 120 {
            return String(trimmed.prefix(120)) + "..."
        }
        return trimmed.isEmpty ? "Görsel" : trimmed
    }

    public var timeAgoString: String {
        let seconds = Int(-copiedAt.timeIntervalSinceNow)
        if seconds < 60 { return "şimdi" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)d" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)s" }
        let days = hours / 24
        return "\(days)g"
    }

    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id && lhs.isPinned == rhs.isPinned && lhs.text == rhs.text
    }
}
