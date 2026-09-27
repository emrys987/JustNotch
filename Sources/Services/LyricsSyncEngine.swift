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

    public func retry(title: String, artist: String, album: String, duration: TimeInterval) {
        lastLoadedTrackKey = ""
        loadLyricsForTrack(title: title, artist: artist, album: album, duration: duration)
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

    private func cleanTitleForLyrics(_ title: String) -> String {
        var clean = title
        if let regex = try? NSRegularExpression(
            pattern: "\\s*[\\[\\(](?:feat\\.|ft\\.|with|remaster|remastered|\\d{4}\\s+remaster|deluxe|version|radio edit|live|explicit|clean|mono|stereo|bonus track|from\\s+[^\\]\\)]+|soundtrack)[^\\]\\)]*[\\]\\)]",
            options: .caseInsensitive
        ) {
            clean = regex.stringByReplacingMatches(in: clean, options: [], range: NSRange(location: 0, length: clean.utf16.count), withTemplate: "")
        }
        if let regex = try? NSRegularExpression(
            pattern: "\\s*-\\s*(?:\\d{4}\\s+remaster|remaster|remastered|live|radio edit|deluxe|version|bonus track|edit|single|feat\\.|ft\\.|with\\s|from\\s+.*|soundtrack|anniversary|\\d+th\\s+anniversary).*$",
            options: .caseInsensitive
        ) {
            clean = regex.stringByReplacingMatches(in: clean, options: [], range: NSRange(location: 0, length: clean.utf16.count), withTemplate: "")
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cleanArtistForLyrics(_ artist: String) -> String {
        var clean = artist
        for sep in [",", ";", "/", " & ", " feat.", " ft.", " with "] {
            if let range = clean.range(of: sep, options: .caseInsensitive) {
                clean = String(clean[..<range.lowerBound])
            }
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fetchLRCFromService(title: String, artist: String, duration: TimeInterval) async -> [SyncedLyricLine] {
        let cleanTitle = cleanTitleForLyrics(title)
        let cleanArtist = cleanArtistForLyrics(artist)

        if let lines = await requestLrcDirect(trackName: cleanTitle, artistName: cleanArtist, targetDuration: duration) {
            return lines
        }

        if cleanTitle != title || cleanArtist != artist {
            if let lines = await requestLrcDirect(trackName: title, artistName: artist, targetDuration: duration) {
                return lines
            }
        }

        let searchQuery = "\(cleanArtist) \(cleanTitle)".trimmingCharacters(in: .whitespacesAndNewlines)
        if !searchQuery.isEmpty {
            if let lines = await requestLrcSearch(query: searchQuery, targetDuration: duration) {
                return lines
            }
        }

        let rawSearchQuery = "\(artist) \(title)".trimmingCharacters(in: .whitespacesAndNewlines)
        if rawSearchQuery != searchQuery && !rawSearchQuery.isEmpty {
            if let lines = await requestLrcSearch(query: rawSearchQuery, targetDuration: duration) {
                return lines
            }
        }

        if !cleanTitle.isEmpty && cleanTitle != searchQuery {
            if let lines = await requestLrcSearch(query: cleanTitle, targetDuration: duration) {
                return lines
            }
        }

        if title.contains("-") {
            let baseTitle = title.components(separatedBy: "-").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !baseTitle.isEmpty && baseTitle != cleanTitle {
                if let lines = await requestLrcDirect(trackName: baseTitle, artistName: cleanArtist, targetDuration: duration) {
                    return lines
                }
                if let lines = await requestLrcSearch(query: "\(cleanArtist) \(baseTitle)", targetDuration: duration) {
                    return lines
                }
            }
        }

        return []
    }

    private func requestLrcDirect(trackName: String, artistName: String, targetDuration: TimeInterval) async -> [SyncedLyricLine]? {
        var comp = URLComponents(string: "https://lrclib.net/api/get")
        comp?.queryItems = [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName)
        ]
        guard let url = comp?.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 JustNotch/1.0", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        if let synced = json["syncedLyrics"] as? String, !synced.isEmpty {
            let parsed = LyricParser.parseLRC(synced)
            if !parsed.isEmpty { return parsed }
        }

        if let plain = json["plainLyrics"] as? String, !plain.isEmpty {
            let parsed = LyricParser.parsePlainLyrics(plain, duration: targetDuration)
            if !parsed.isEmpty { return parsed }
        }

        return nil
    }

    private func requestLrcSearch(query: String, targetDuration: TimeInterval) async -> [SyncedLyricLine]? {
        var comp = URLComponents(string: "https://lrclib.net/api/search")
        comp?.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        guard let url = comp?.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 JustNotch/1.0", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let results = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return nil
        }

        let candidates = results.filter { dict in
            if let synced = dict["syncedLyrics"] as? String, !synced.isEmpty { return true }
            if let plain = dict["plainLyrics"] as? String, !plain.isEmpty { return true }
            return false
        }

        guard !candidates.isEmpty else { return nil }

        let sortedCandidates = candidates.sorted { a, b in
            let aHasSynced = (a["syncedLyrics"] as? String)?.isEmpty == false
            let bHasSynced = (b["syncedLyrics"] as? String)?.isEmpty == false
            if aHasSynced != bHasSynced {
                return aHasSynced && !bHasSynced
            }
            if targetDuration > 0 {
                let durA = (a["duration"] as? Double) ?? 0
                let durB = (b["duration"] as? Double) ?? 0
                return abs(durA - targetDuration) < abs(durB - targetDuration)
            }
            return false
        }

        for candidate in sortedCandidates {
            if let synced = candidate["syncedLyrics"] as? String, !synced.isEmpty {
                let parsed = LyricParser.parseLRC(synced)
                if !parsed.isEmpty { return parsed }
            }
            if let plain = candidate["plainLyrics"] as? String, !plain.isEmpty {
                let parsed = LyricParser.parsePlainLyrics(plain, duration: targetDuration)
                if !parsed.isEmpty { return parsed }
            }
        }

        return nil
    }
}
