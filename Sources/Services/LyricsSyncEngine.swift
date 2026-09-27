import Combine
import Foundation

@MainActor
public final class LyricsSyncEngine: ObservableObject {
    public static let shared = LyricsSyncEngine()

    @Published public private(set) var lyrics: [SyncedLyricLine] = []
    @Published public private(set) var activeIndex: Int = 0
    @Published public private(set) var currentLine: SyncedLyricLine?
    @Published public private(set) var nextLine: SyncedLyricLine?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var noLyricsAvailable: Bool = false

    private var lastLoadedTrackKey: String = ""
    private var updateTask: Task<Void, Never>?

    private init() {}

    public func loadLyricsForTrack(title: String, artist: String, album: String, duration: TimeInterval) {
        let trackKey = "\(title)-\(artist)"
        guard !title.isEmpty, trackKey != lastLoadedTrackKey else { return }

        lastLoadedTrackKey = trackKey
        lyrics = []
        activeIndex = 0
        currentLine = nil
        nextLine = nil
        noLyricsAvailable = false
        isLoading = true

        Task {
            let fetchedLyrics = await fetchLRCFromService(title: title, artist: artist, duration: duration)
            if !fetchedLyrics.isEmpty {
                self.lyrics = fetchedLyrics
                self.noLyricsAvailable = false
                self.updateSync(currentTime: 0)
            } else {
                self.lyrics = []
                self.noLyricsAvailable = true
            }
            self.isLoading = false
        }
    }

    public func clear() {
        lastLoadedTrackKey = ""
        lyrics = []
        activeIndex = 0
        currentLine = nil
        nextLine = nil
        noLyricsAvailable = false
        isLoading = false
    }

    public func updateSync(currentTime: TimeInterval) {
        guard !lyrics.isEmpty else { return }

        guard let newIndex = LyricParser.findActiveIndex(in: lyrics, for: currentTime) else {
            return
        }

        if newIndex != activeIndex || currentLine == nil {
            self.activeIndex = newIndex
            self.currentLine = lyrics[newIndex]
            if newIndex + 1 < lyrics.count {
                self.nextLine = lyrics[newIndex + 1]
            } else {
                self.nextLine = nil
            }
        }
    }

    private func fetchLRCFromService(title: String, artist: String, duration: TimeInterval) async -> [SyncedLyricLine] {
        guard let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        var urlString = "https://lrclib.net/api/get?track_name=\(encodedTitle)&artist_name=\(encodedArtist)"
        if duration > 0 {
            urlString += "&duration=\(Int(duration))"
        }

        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6.0
        request.setValue("JustNotch/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let syncedLyricsString = json["syncedLyrics"] as? String,
               !syncedLyricsString.isEmpty {
                return LyricParser.parseLRC(syncedLyricsString)
            }
        } catch {
        }

        return []
    }
}
