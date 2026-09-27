import Foundation

public struct SyncedLyricLine: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let time: TimeInterval
    public let text: String

    public init(id: UUID = UUID(), time: TimeInterval, text: String) {
        self.id = id
        self.time = time
        self.text = text
    }
}

public struct LyricParser {
    public static func parseLRC(_ lrcContent: String) -> [SyncedLyricLine] {
        var lines: [SyncedLyricLine] = []
        let rawLines = lrcContent.components(separatedBy: .newlines)

        let regexPattern = "\\[(\\d{1,2}):(\\d{2})(?:[.:](\\d{2,3}))?\\]"
        guard let regex = try? NSRegularExpression(pattern: regexPattern) else {
            return []
        }

        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("[ar:") || trimmed.hasPrefix("[ti:") ||
               trimmed.hasPrefix("[al:") || trimmed.hasPrefix("[by:") ||
               trimmed.hasPrefix("[length:") || trimmed.hasPrefix("[offset:") {
                continue
            }

            let nsString = trimmed as NSString
            let matches = regex.matches(in: trimmed, range: NSRange(location: 0, length: nsString.length))
            guard !matches.isEmpty else { continue }

            guard let lastMatch = matches.last else { continue }
            let textStartIndex = lastMatch.range.location + lastMatch.range.length
            let lyricText = nsString.substring(from: min(textStartIndex, nsString.length))
                .trimmingCharacters(in: .whitespaces)

            for match in matches {
                guard match.numberOfRanges >= 3 else { continue }

                let minString = nsString.substring(with: match.range(at: 1))
                let secString = nsString.substring(with: match.range(at: 2))
                var msString = "0"
                if match.numberOfRanges >= 4 && match.range(at: 3).location != NSNotFound {
                    msString = nsString.substring(with: match.range(at: 3))
                }

                guard let minutes = Double(minString),
                      let seconds = Double(secString) else { continue }

                var milliseconds = Double(msString) ?? 0.0
                if msString.count == 2 {
                    milliseconds *= 10.0
                }

                let totalSeconds = (minutes * 60.0) + seconds + (milliseconds / 1000.0)

                lines.append(SyncedLyricLine(time: totalSeconds, text: lyricText))
            }
        }

        return lines.sorted { $0.time < $1.time }
    }

    public static func findActiveIndex(in lyrics: [SyncedLyricLine], for currentTime: TimeInterval) -> Int? {
        guard !lyrics.isEmpty else { return nil }

        if currentTime < lyrics[0].time {
            return 0
        }

        var activeIndex = 0
        for (index, line) in lyrics.enumerated() {
            if line.time <= currentTime {
                activeIndex = index
            } else {
                break
            }
        }
        return activeIndex
    }

    public static func parsePlainLyrics(_ plain: String, duration: TimeInterval) -> [SyncedLyricLine] {
        let rawLines = plain.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !rawLines.isEmpty else { return [] }
        let validDuration = duration > 0 ? duration : Double(rawLines.count * 4)
        let step = validDuration / Double(rawLines.count)
        return rawLines.enumerated().map { index, text in
            SyncedLyricLine(time: step * Double(index), text: text)
        }
    }
}
