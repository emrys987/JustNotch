import SwiftUI

public struct MainContainerView: View {
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var mediaService = MediaService.shared

    public init() {}

    public var body: some View {
        Group {
            if coordinator.isShowingLyrics {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                coordinator.isShowingLyrics = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .bold))
                                Text(mediaService.currentState.hasActiveTrack ? mediaService.currentState.title : "Geri")
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                coordinator.isShowingLyrics = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)

                    SyncedLyricsView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else if settings.enableMusicWidget && settings.enablePomodoroWidget {
                DualNotchDashboardView()
            } else if settings.enableMusicWidget {
                MusicNotchView()
            } else if settings.enablePomodoroWidget {
                PomodoroNotchView()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22))
                        .foregroundStyle(.tertiary)
                    Text("Tüm Eklentiler Devre Dışı")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Ayarlar penceresinden Müzik veya Pomodoro eklentilerini etkinleştirebilirsiniz.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
