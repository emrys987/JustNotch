import SwiftUI

public struct DualNotchDashboardView: View {
    @ObservedObject var mediaService = MediaService.shared
    @ObservedObject var pomodoroService = PomodoroService.shared
    @ObservedObject var lyricsEngine = LyricsSyncEngine.shared
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var loc = LocalizationService.shared

    public init() {}

    public var body: some View {
        let mediaState = mediaService.currentState
        let pomodoroState = pomodoroService.state

        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                ZStack {
                    if let artwork = mediaState.artworkImage {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity)
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                        Image(systemName: mediaState.hasActiveTrack ? mediaState.player.iconName : "music.note")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.4))
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: mediaState.artworkImage != nil)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(mediaState.hasActiveTrack ? mediaState.title : loc.musicWaiting)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(mediaState.hasActiveTrack ? mediaState.artist : "")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(width: 80, alignment: .leading)
            }

            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    Button {
                        mediaService.toggleShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(mediaState.isShuffling ? Color(red: 0.18, green: 0.84, blue: 0.45) : .white.opacity(0.45))
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
                        Image(systemName: mediaState.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
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
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(mediaState.isRepeating ? Color(red: 0.18, green: 0.84, blue: 0.45) : .white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)

                VStack(spacing: 2) {
                    GeometryReader { geo in
                        let current = mediaState.calculatedCurrentPosition()
                        let ratio = mediaState.duration > 0 ? min(1.0, max(0.0, current / mediaState.duration)) : 0.0

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 3)

                            Capsule()
                                .fill(Color(red: 0.18, green: 0.84, blue: 0.45))
                                .frame(width: geo.size.width * ratio, height: 3)
                        }
                    }
                    .frame(height: 4)

                    if mediaState.hasActiveTrack && mediaState.duration > 0 {
                        HStack {
                            Text(MediaState.formatTime(mediaState.calculatedCurrentPosition()))
                            Spacer()
                            Text(MediaState.formatTime(mediaState.duration))
                        }
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        coordinator.isShowingLyrics = true
                    }
                } label: {
                    Group {
                        if let currentLine = lyricsEngine.currentLine, !currentLine.text.isEmpty {
                            Text(currentLine.text)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        } else if lyricsEngine.isLoading {
                            Text(loc.musicSyncingLyrics)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                        } else if lyricsEngine.noLyricsAvailable {
                            Text(loc.musicNoLyrics)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.35))
                        } else {
                            Text(mediaState.hasActiveTrack ? mediaState.title : "")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: CGFloat(pomodoroState.progress))
                    .stroke(
                        pomodoroState.phase.themeColor.gradient,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.8), value: pomodoroState.progress)

                VStack(spacing: 3) {
                    Text(pomodoroState.formattedTime)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 6) {
                        Button {
                            pomodoroService.toggle()
                        } label: {
                            Image(systemName: pomodoroState.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 9, weight: .bold))
                                .padding(4.5)
                                .background(
                                    Circle()
                                        .fill(pomodoroState.isRunning ? Color.white.opacity(0.25) : pomodoroState.phase.themeColor)
                                )
                                .foregroundStyle(pomodoroState.isRunning ? Color.white : Color.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            pomodoroService.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 8))
                                .padding(4)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)

                        Button {
                            pomodoroService.skipToNextPhase()
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 8))
                                .padding(4)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 80, height: 80)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
