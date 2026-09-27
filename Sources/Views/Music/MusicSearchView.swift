import SwiftUI

public struct MusicSearchView: View {
    @Binding var isPresented: Bool
    @ObservedObject var mediaService = MediaService.shared
    @ObservedObject var loc = LocalizationService.shared
    @FocusState private var isFocused: Bool
    @State private var query: String = ""
    @State private var results: [MusicSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>?

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.45))

                TextField(loc.isTurkish ? "Şarkı veya sanatçı ara..." : "Search song or artist...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .focused($isFocused)
                    .onSubmit {
                        performSearch(immediate: true)
                    }
                    .onChange(of: query) { _, newValue in
                        debounceSearch(newValue)
                    }

                if !query.isEmpty {
                    Button {
                        query = ""
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }

                if isSearching {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.08)))
            .contentShape(Rectangle())
            .onTapGesture {
                NotchWindowController.shared.activateForInput()
                isFocused = true
            }

            if results.isEmpty {
                VStack(spacing: 4) {
                    if isSearching {
                        Text(loc.isTurkish ? "Aranıyor..." : "Searching...")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    } else if !query.isEmpty {
                        Text(loc.isTurkish ? "Sonuç bulunamadı" : "No results found")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.system(size: 11))
                            Text(loc.isTurkish ? "Çalmak istediğin şarkıyı ara ve seç" : "Search and select a song to play")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 4) {
                        ForEach(results) { item in
                            Button {
                                mediaService.playSearchResult(
                                    title: item.trackName,
                                    artist: item.artistName,
                                    trackViewUrl: item.trackViewUrl
                                )
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isPresented = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    AsyncImage(url: URL(string: item.artworkUrl ?? "")) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                        }
                                    }
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.trackName)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)

                                        Text(item.artistName)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.white.opacity(0.6))
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.45))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.04)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            NotchWindowController.shared.activateForInput()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
        .onDisappear {
            isFocused = false
            NotchWindowController.shared.deactivateInput()
        }
        .onExitCommand {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
            }
        }
    }

    private func debounceSearch(_ newText: String) {
        searchTask?.cancel()
        guard !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            let found = await MusicSearchService.shared.search(query: newText)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.results = found
                self.isSearching = false
            }
        }
    }

    private func performSearch(immediate: Bool) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        searchTask = Task {
            let found = await MusicSearchService.shared.search(query: trimmed)
            await MainActor.run {
                self.results = found
                self.isSearching = false
                if let first = found.first, immediate {
                    mediaService.playSearchResult(
                        title: first.trackName,
                        artist: first.artistName,
                        trackViewUrl: first.trackViewUrl
                    )
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
