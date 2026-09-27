import SwiftUI

public struct MusicNotchView: View {
    @ObservedObject var mediaService = MediaService.shared
    @ObservedObject var lyricsEngine = LyricsSyncEngine.shared
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var loc = LocalizationService.shared

    public init() {}

    public var body: some View {
        let state = mediaService.currentState

        Group {
            if !state.hasActiveTrack {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 26))
                        .foregroundStyle(.tertiary)
                    Text(loc.musicNotPlaying)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(loc.musicStartHint)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        if let art = state.artworkImage {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .transition(.opacity)
                        } else {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                            Image(systemName: state.player.iconName)
                                .font(.system(size: 30))
                                .foregroundStyle(.secondary)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: state.artworkImage != nil)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(state.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                Text(state.artist.isEmpty ? state.album : (state.album.isEmpty ? state.artist : "\(state.artist) — \(state.album)"))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.65))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 11) {
                                Button {
                                    mediaService.toggleShuffle()
                                } label: {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(state.isShuffling ? Color(red: 0.18, green: 0.84, blue: 0.45) : .white.opacity(0.45))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    mediaService.previousTrack()
                                } label: {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    mediaService.togglePlayPause()
                                } label: {
                                    Image(systemName: state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    mediaService.nextTrack()
                                } label: {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    mediaService.toggleRepeat()
                                } label: {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(state.isRepeating ? Color(red: 0.18, green: 0.84, blue: 0.45) : .white.opacity(0.45))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(spacing: 3) {
                            GeometryReader { geo in
                                let current = state.calculatedCurrentPosition()
                                let ratio = state.duration > 0 ? min(1.0, max(0.0, current / state.duration)) : 0.0

                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(height: 4)

                                    Capsule()
                                        .fill(Color(red: 0.18, green: 0.84, blue: 0.45))
                                        .frame(width: geo.size.width * ratio, height: 4)
                                }
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onEnded { value in
                                             let newRatio = Double(value.location.x / geo.size.width)
                                             mediaService.seek(to: newRatio)
                                        }
                                )
                            }
                            .frame(height: 4)

                            HStack {
                                Text(MediaState.formatTime(state.calculatedCurrentPosition()))
                                Spacer()
                                Text(MediaState.formatTime(state.duration))
                            }
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                coordinator.isShowingLyrics = true
                            }
                        } label: {
                            Group {
                                if let currentLine = lyricsEngine.currentLine, !currentLine.text.isEmpty {
                                    Text(currentLine.text)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                } else if lyricsEngine.isLoading {
                                    Text(loc.musicSyncingLyrics)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.5))
                                } else if lyricsEngine.noLyricsAvailable {
                                    Text(loc.musicNoLyrics)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.35))
                                } else {
                                    Text(state.title)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}
