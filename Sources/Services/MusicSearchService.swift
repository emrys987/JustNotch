import Foundation

public struct MusicSearchResult: Identifiable, Sendable {
    public let id: Int
    public let trackName: String
    public let artistName: String
    public let collectionName: String
    public let artworkUrl: String?
    public let previewUrl: String?
    public let trackViewUrl: String?
    public let durationMillis: Int

    public init(
        id: Int,
        trackName: String,
        artistName: String,
        collectionName: String,
        artworkUrl: String?,
        previewUrl: String?,
        trackViewUrl: String?,
        durationMillis: Int
    ) {
        self.id = id
        self.trackName = trackName
        self.artistName = artistName
        self.collectionName = collectionName
        self.artworkUrl = artworkUrl
        self.previewUrl = previewUrl
        self.trackViewUrl = trackViewUrl
        self.durationMillis = durationMillis
    }
}

public final class MusicSearchService: Sendable {
    public static let shared = MusicSearchService()

    private init() {}

    public func search(query: String) async -> [MusicSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var comp = URLComponents(string: "https://itunes.apple.com/search")
        comp?.queryItems = [
            URLQueryItem(name: "term", value: trimmed),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = comp?.url else {
            return []
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            request.setValue("JustNotch/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return []
            }

            return results.compactMap { dict in
                guard let trackName = dict["trackName"] as? String,
                      let artistName = dict["artistName"] as? String else {
                    return nil
                }

                let id = (dict["trackId"] as? Int) ?? Int.random(in: 1000...999999)
                let collection = (dict["collectionName"] as? String) ?? ""
                let artUrl = (dict["artworkUrl60"] as? String) ?? (dict["artworkUrl100"] as? String)
                let preview = dict["previewUrl"] as? String
                let trackView = dict["trackViewUrl"] as? String
                let duration = (dict["trackTimeMillis"] as? Int) ?? 0

                return MusicSearchResult(
                    id: id,
                    trackName: trackName,
                    artistName: artistName,
                    collectionName: collection,
                    artworkUrl: artUrl,
                    previewUrl: preview,
                    trackViewUrl: trackView,
                    durationMillis: duration
                )
            }
        } catch {
            return []
        }
    }
}
