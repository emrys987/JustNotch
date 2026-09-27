import SwiftUI

public struct SyncedLyricsView: View {
    @ObservedObject var lyricsEngine = LyricsSyncEngine.shared
    @ObservedObject var mediaService = MediaService.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            if lyricsEngine.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Sözler senkronize ediliyor...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if lyricsEngine.noLyricsAvailable || lyricsEngine.lyrics.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "music.mic")
                        .font(.system(size: 20))
                        .foregroundStyle(.tertiary)
                    Text("Bu parça için senkronize söz bulunamadı")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("\(mediaService.currentState.title) - \(mediaService.currentState.artist)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(lyricsEngine.lyrics.enumerated()), id: \.element.id) { index, line in
                                let isCurrent = (index == lyricsEngine.activeIndex)
                                let isPassed = (index < lyricsEngine.activeIndex)

                                Text(line.text.isEmpty ? "•••" : line.text)
                                    .font(.system(size: isCurrent ? 15 : 13, weight: isCurrent ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(
                                        isCurrent
                                            ? Color.white
                                            : (isPassed ? Color.white.opacity(0.35) : Color.white.opacity(0.65))
                                    )
                                    .multilineTextAlignment(.center)
                                    .scaleEffect(isCurrent ? 1.05 : 0.98)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
                                    .id(index)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 24)
                    }
                    .onChange(of: lyricsEngine.activeIndex) { _, newIndex in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
