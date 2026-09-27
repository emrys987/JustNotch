import SwiftUI
import UniformTypeIdentifiers

public struct ZDRShelfView: View {
    @ObservedObject var shelfService = ZDRShelfService.shared
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var loc = LocalizationService.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if shelfService.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(red: 0.38, green: 0.65, blue: 1.0).opacity(0.75))

                    Text(loc.shelfDropHint)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(loc.shelfDropSub)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            Color.white.opacity(shelfService.isTargeted ? 0.45 : 0.12),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                )
                .padding(.horizontal, 12)
            } else {
                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(shelfService.items) { item in
                                ShelfItemCard(item: item) {
                                    shelfService.removeItem(with: item.id)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                    }
                    .frame(height: 84)

                    Button(role: .destructive) {
                        shelfService.wipeAllFiles()
                        coordinator.showHUD(message: loc.shelfClearedHUD)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text(loc.shelfClearAll)
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.red.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.red.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .onDrop(of: [.fileURL, .url, .utf8PlainText, .plainText], isTargeted: $shelfService.isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            shelfService.addFiles([url])
                        }
                    } else if let url = item as? URL {
                        DispatchQueue.main.async {
                            shelfService.addFiles([url])
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    if let text = item as? String {
                        DispatchQueue.main.async {
                            shelfService.addVolatileText(text)
                        }
                    }
                }
            }
        }
        return true
    }
}

private struct ShelfItemCard: View {
    let item: ShelfFileItem
    let onRemove: () -> Void
    @ObservedObject var loc = LocalizationService.shared

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: item.systemIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
                    .padding(.top, 4)

                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -2)
            }

            Text(item.fileName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .frame(width: 68)

            Text(item.formattedSize)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onDrag {
            NotchCoordinator.shared.isDraggingFileOut = true
            let provider = NSItemProvider(object: item.fileURL as NSURL)
            provider.suggestedName = item.fileName
            return provider
        } preview: {
            VStack(spacing: 4) {
                Image(nsImage: item.systemIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                Text(item.fileName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.85)))
        }
        .onTapGesture {
            ZDRShelfService.shared.openFile(item)
        }
        .contextMenu {
            Button(loc.shelfOpen) {
                ZDRShelfService.shared.openFile(item)
            }
            Button(loc.shelfRevealInFinder) {
                ZDRShelfService.shared.revealInFinder(item)
            }
            Divider()
            Button(loc.shelfRemove, role: .destructive) {
                onRemove()
            }
        }
    }
}
