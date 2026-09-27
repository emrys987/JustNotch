import AppKit
import Foundation

public enum SupportedMediaPlayer: String, CaseIterable, Sendable {
    case spotify = "com.spotify.client"
    case appleMusic = "com.apple.Music"
    case none = "none"

    public var displayName: String {
        switch self {
        case .spotify:
            return "Spotify"
        case .appleMusic:
            return "Music"
        case .none:
            return ""
        }
    }

    public var iconName: String {
        switch self {
        case .spotify:
            return "headphones"
        case .appleMusic:
            return "music.quarternote.3"
        case .none:
            return "music.slash"
        }
    }
}

public struct MediaState: Equatable, Sendable {
    public var player: SupportedMediaPlayer
    public var title: String
    public var artist: String
    public var album: String
    public var duration: TimeInterval
    public var position: TimeInterval
    public var positionTimestamp: Date
    public var isPlaying: Bool
    public var artworkData: Data?
    public var volume: Double
    public var isRepeating: Bool
    public var isShuffling: Bool

    public init(
        player: SupportedMediaPlayer = .none,
        title: String = "",
        artist: String = "",
        album: String = "",
        duration: TimeInterval = 0,
        position: TimeInterval = 0,
        positionTimestamp: Date = Date(),
        isPlaying: Bool = false,
        artworkData: Data? = nil,
        volume: Double = 1.0,
        isRepeating: Bool = false,
        isShuffling: Bool = false
    ) {
        self.player = player
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.position = position
        self.positionTimestamp = positionTimestamp
        self.isPlaying = isPlaying
        self.artworkData = artworkData
        self.volume = volume
        self.isRepeating = isRepeating
        self.isShuffling = isShuffling
    }

    public static let empty = MediaState()

    public var hasActiveTrack: Bool {
        return player != .none && !title.isEmpty
    }

    public func calculatedCurrentPosition(at referenceDate: Date = Date()) -> TimeInterval {
        guard isPlaying else { return position }
        let elapsedSinceLastSync = max(0, referenceDate.timeIntervalSince(positionTimestamp))
        let livePosition = position + elapsedSinceLastSync
        return duration > 0 ? min(duration, livePosition) : livePosition
    }

    public var artworkImage: NSImage? {
        guard let artworkData = artworkData else { return nil }
        return NSImage(data: artworkData)
    }

    public static func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
