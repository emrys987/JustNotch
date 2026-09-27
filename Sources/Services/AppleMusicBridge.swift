import AppKit
import Foundation

public final class AppleMusicBridge: Sendable {
    public static let shared = AppleMusicBridge()
    private let bundleID = "com.apple.Music"

    private init() {}

    public var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    public func fetchCurrentPlayback() async -> MediaState? {
        guard isRunning else { return nil }

        let scriptSource = """
        tell application "Music"
            if not running then return "NOT_RUNNING"
            set pState to player state as string
            if pState is "stopped" then return "STOPPED"
            
            try
                set tTrack to current track
                set tName to name of tTrack
                set tArtist to artist of tTrack
                set tAlbum to album of tTrack
                set tDuration to duration of tTrack
                set tPosition to player position
                set tVolume to sound volume
                
                return tName & "|||" & tArtist & "|||" & tAlbum & "|||" & (tDuration as string) & "|||" & (tPosition as string) & "|||" & pState & "|||" & (tVolume as string)
            on error
                return "ERROR"
            end try
        end tell
        """

        guard let resultString = await executeAppleScript(scriptSource) else {
            return nil
        }

        if resultString == "NOT_RUNNING" || resultString == "STOPPED" || resultString == "ERROR" {
            return nil
        }

        let parts = resultString.components(separatedBy: "|||")
        guard parts.count >= 7 else { return nil }

        let title = parts[0]
        let artist = parts[1]
        let album = parts[2]
        let duration = Double(parts[3].replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let position = Double(parts[4].replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let isPlaying = parts[5].lowercased() == "playing"
        let volume = (Double(parts[6].replacingOccurrences(of: ",", with: ".")) ?? 100.0) / 100.0

        let artworkData = await fetchArtworkData()

        return MediaState(
            player: .appleMusic,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            position: position,
            positionTimestamp: Date(),
            isPlaying: isPlaying,
            artworkData: artworkData,
            volume: volume
        )
    }

    private func fetchArtworkData() async -> Data? {
        await Task.detached(priority: .utility) {
            let scriptSource = """
            tell application "Music"
                try
                    if (count of artworks of current track) > 0 then
                        set artData to raw data of artwork 1 of current track
                        return artData
                    end if
                end try
                return missing value
            end tell
            """
            var errorInfo: NSDictionary?
            let script = NSAppleScript(source: scriptSource)
            let descriptor = script?.executeAndReturnError(&errorInfo)
            return descriptor?.data
        }.value
    }

    public func togglePlayPause() async {
        await executeVoidScript("""
        tell application "Music"
            playpause
        end tell
        """)
    }

    public func nextTrack() async {
        await executeVoidScript("""
        tell application "Music"
            next track
        end tell
        """)
    }

    public func previousTrack() async {
        await executeVoidScript("""
        tell application "Music"
            previous track
        end tell
        """)
    }

    public func seek(to seconds: TimeInterval) async {
        await executeVoidScript("""
        tell application "Music"
            set player position to \(seconds)
        end tell
        """)
    }

    public func setVolume(_ volume: Double) async {
        let intVol = Int(max(0, min(100, volume * 100)))
        await executeVoidScript("""
        tell application "Music"
            set sound volume to \(intVol)
        end tell
        """)
    }

    private func executeAppleScript(_ source: String) async -> String? {
        await Task.detached(priority: .userInitiated) {
            var errorInfo: NSDictionary?
            let script = NSAppleScript(source: source)
            let outputDescriptor = script?.executeAndReturnError(&errorInfo)
            return outputDescriptor?.stringValue
        }.value
    }

    private func executeVoidScript(_ source: String) async {
        _ = await executeAppleScript(source)
    }
}
