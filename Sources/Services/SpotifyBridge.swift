import AppKit
import Foundation

public final class SpotifyBridge: Sendable {
    public static let shared = SpotifyBridge()
    private let bundleID = "com.spotify.client"

    private init() {}

    public var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    public func fetchCurrentPlayback() async -> MediaState? {
        guard isRunning else { return nil }

        let scriptSource = """
        tell application "Spotify"
            if not running then return "NOT_RUNNING"
            set pState to player state as string
            if pState is "stopped" then return "STOPPED"
            
            set tName to name of current track
            set tArtist to artist of current track
            set tAlbum to album of current track
            set tDuration to (duration of current track) / 1000
            set tPosition to player position
            set tArtwork to artwork url of current track
            set tVolume to sound volume
            set tRepeating to repeating as string
            set tShuffling to shuffling as string
            
            return tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tDuration as string) & "|||" & (tPosition as string) & "|||" & pState & "|||" & tArtwork & "|||" & (tVolume as string) & "|||" & tRepeating & "|||" & tShuffling
        end tell
        """

        guard let resultString = await executeAppleScript(scriptSource) else {
            return nil
        }

        if resultString == "NOT_RUNNING" || resultString == "STOPPED" {
            return nil
        }

        let parts = resultString.components(separatedBy: "|||")
        guard parts.count >= 8 else { return nil }

        let title = parts[0]
        let artist = parts[1]
        let album = parts[2]
        let duration = Double(parts[3].replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let position = Double(parts[4].replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let isPlaying = parts[5].lowercased() == "playing"
        let artworkURLString = parts[6]
        let volume = (Double(parts[7].replacingOccurrences(of: ",", with: ".")) ?? 100.0) / 100.0
        let isRepeating = parts.count > 8 ? (parts[8].lowercased() == "true") : false
        let isShuffling = parts.count > 9 ? (parts[9].lowercased() == "true") : false

        var artworkData: Data? = nil
        if !artworkURLString.isEmpty, let cached = ArtworkCache.shared.get(for: artworkURLString) {
            artworkData = cached.0
        } else if let artURL = URL(string: artworkURLString), artURL.scheme != nil {
            Task.detached(priority: .userInitiated) {
                if let (downloadedData, _) = try? await URLSession.shared.data(from: artURL) {
                    ArtworkCache.shared.set(data: downloadedData, for: artworkURLString)
                    await MediaService.shared.updateArtworkIfCurrent(key: artworkURLString, data: downloadedData)
                }
            }
        }

        return MediaState(
            player: .spotify,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            position: position,
            positionTimestamp: Date(),
            isPlaying: isPlaying,
            artworkData: artworkData,
            artworkKey: artworkURLString,
            volume: volume,
            isRepeating: isRepeating,
            isShuffling: isShuffling
        )
    }

    public func togglePlayPause() async {
        await executeVoidScript("""
        tell application "Spotify"
            playpause
        end tell
        """)
    }

    public func nextTrack() async {
        await executeVoidScript("""
        tell application "Spotify"
            next track
        end tell
        """)
    }

    public func previousTrack() async {
        await executeVoidScript("""
        tell application "Spotify"
            previous track
        end tell
        """)
    }

    public func toggleRepeat() async {
        await executeVoidScript("""
        tell application "Spotify"
            set repeating to not repeating
        end tell
        """)
    }

    public func toggleShuffle() async {
        await executeVoidScript("""
        tell application "Spotify"
            set shuffling to not shuffling
        end tell
        """)
    }

    public func seek(to seconds: TimeInterval) async {
        await executeVoidScript("""
        tell application "Spotify"
            set player position to \(seconds)
        end tell
        """)
    }

    public func setVolume(_ volume: Double) async {
        let intVol = Int(max(0, min(100, volume * 100)))
        await executeVoidScript("""
        tell application "Spotify"
            set sound volume to \(intVol)
        end tell
        """)
    }

    private func executeAppleScript(_ source: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: source) {
                    let output = scriptObject.executeAndReturnError(&error)
                    if error == nil {
                        continuation.resume(returning: output.stringValue)
                        return
                    }
                }
                continuation.resume(returning: nil)
            }
        }
    }

    private func executeVoidScript(_ source: String) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let scriptObject = NSAppleScript(source: source) {
                    var error: NSDictionary?
                    scriptObject.executeAndReturnError(&error)
                }
                continuation.resume()
            }
        }
    }
}
