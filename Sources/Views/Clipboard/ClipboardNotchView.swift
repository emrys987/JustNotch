import SwiftUI

public struct ClipboardNotchView: View {
    @ObservedObject var clipboardService = ClipboardService.shared
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var loc = LocalizationService.shared

    public init() {}

    public var body: some View {
        let items = clipboardService.displayItems

        Group {
            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(red: 0.38, green: 0.65, blue: 1.0).opacity(0.7))

                    Text(loc.isTurkish ? "Pano Geçmişi Boş" : "Clipboard Empty")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(loc.isTurkish ? "Kopyaladığınız metin ve görseller burada kareler halinde listelenir." : "Copied text and images will appear here as squares.")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(items) { item in
                            ClipboardSquareCard(item: item) {
                                clipboardService.copyToPasteboard(item)
                                coordinator.showHUD(message: loc.isTurkish ? "Panoya Kopyalandı" : "Copied to Clipboard")
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ClipboardSquareCard: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    @ObservedObject var clipboardService = ClipboardService.shared
    @ObservedObject var loc = LocalizationService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.15))
                } else {
                    Image(systemName: item.isImage ? "photo.fill" : "doc.text.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Text(item.timeAgoString)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            if let img = item.image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 82, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Text(item.previewSnippet)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(8)
        .frame(width: 98, height: 98)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.isPinned ? Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.12) : Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.isPinned ? Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCopy()
        }
        .contextMenu {
            Button {
                clipboardService.togglePin(item)
            } label: {
                Label(
                    item.isPinned ? (loc.isTurkish ? "Sabitlemeyi Kaldır" : "Unpin") : (loc.isTurkish ? "Başa Sabitle" : "Pin to Left"),
                    systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill"
                )
            }

            Button {
                onCopy()
            } label: {
                Label(loc.isTurkish ? "Kopyala" : "Copy", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                clipboardService.deleteItem(item)
            } label: {
                Label(loc.isTurkish ? "Sil" : "Delete", systemImage: "trash")
            }
        }
    }
}
