import Combine
import Foundation

@MainActor
public final class MediaService: ObservableObject {
    public static let shared = MediaService()

    @Published public private(set) var currentState: MediaState = .empty

    private let spotify = SpotifyBridge.shared
    private let appleMusic = AppleMusicBridge.shared
    private let lyricsEngine = LyricsSyncEngine.shared
    private let settings = UserSettings.shared

    private var pollingTask: Task<Void, Never>?
    private var lyricsTimerTask: Task<Void, Never>?

    private init() {
        startMonitoring()
    }

    public func startMonitoring() {
        stopMonitoring()

        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.pollMediaState()
                let interval: UInt64 = (self?.currentState.isPlaying == true) ? 800_000_000 : 2_000_000_000
                try? await Task.sleep(nanoseconds: interval)
            }
        }

        lyricsTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                if let state = self?.currentState, state.isPlaying {
                    let currentPos = state.calculatedCurrentPosition()
                    self?.lyricsEngine.updateSync(currentTime: currentPos)
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    public func stopMonitoring() {
        pollingTask?.cancel()
        pollingTask = nil
        lyricsTimerTask?.cancel()
        lyricsTimerTask = nil
    }

    private func pollMediaState() async {
        var detectedState: MediaState? = nil

        if settings.enableSpotify && spotify.isRunning {
            if let spotState = await spotify.fetchCurrentPlayback(), spotState.hasActiveTrack {
                detectedState = spotState
            }
        }

        if detectedState == nil || !detectedState!.isPlaying {
            if settings.enableAppleMusic && appleMusic.isRunning {
                if let musicState = await appleMusic.fetchCurrentPlayback(), musicState.hasActiveTrack {
                    if musicState.isPlaying || detectedState == nil {
                        detectedState = musicState
                    }
                }
            }
        }

        let newState = detectedState ?? .empty

        if newState.title != currentState.title || newState.artist != currentState.artist {
            if newState.hasActiveTrack {
                lyricsEngine.loadLyricsForTrack(
                    title: newState.title,
                    artist: newState.artist,
                    album: newState.album,
                    duration: newState.duration
                )
            } else {
                lyricsEngine.clear()
            }
        }

        self.currentState = newState
    }

    public func togglePlayPause() {
        Task {
            switch currentState.player {
            case .spotify:
                await spotify.togglePlayPause()
            case .appleMusic:
                await appleMusic.togglePlayPause()
            case .none:
                break
            }
            await pollMediaState()
        }
    }

    public func nextTrack() {
        Task {
            switch currentState.player {
            case .spotify:
                await spotify.nextTrack()
            case .appleMusic:
                await appleMusic.nextTrack()
            case .none:
                break
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await pollMediaState()
        }
    }

    public func previousTrack() {
        Task {
            switch currentState.player {
            case .spotify:
                await spotify.previousTrack()
            case .appleMusic:
                await appleMusic.previousTrack()
            case .none:
                break
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await pollMediaState()
        }
    }

    public func seek(to progressRatio: Double) {
        guard currentState.duration > 0 else { return }
        let targetSeconds = currentState.duration * max(0, min(1, progressRatio))
        Task {
            switch currentState.player {
            case .spotify:
                await spotify.seek(to: targetSeconds)
            case .appleMusic:
                await appleMusic.seek(to: targetSeconds)
            case .none:
                break
            }
            await pollMediaState()
        }
    }

    public func toggleRepeat() {
        Task {
            switch currentState.player {
            case .spotify:
                await spotify.toggleRepeat()
            case .appleMusic:
                await appleMusic.toggleRepeat()
            case .none:
                break
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            await pollMediaState()
        }
    }

    public func toggleShuffle() {
        Task {
            switch currentState.player {
            case .spotify:
                await spotify.toggleShuffle()
            case .appleMusic:
                await appleMusic.toggleShuffle()
            case .none:
                break
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
            await pollMediaState()
        }
    }
}
