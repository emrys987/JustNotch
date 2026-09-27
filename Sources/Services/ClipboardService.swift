import AppKit
import Combine
import Foundation

@MainActor
public final class ClipboardService: ObservableObject {
    public static let shared = ClipboardService()

    @Published public private(set) var items: [ClipboardItem] = []

    private var lastChangeCount: Int = 0
    private var monitorTimer: Timer?
    private let maxHistoryLimit: Int = 50

    private init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }

    public func startMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForPasteboardChanges()
            }
        }
    }

    public func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func checkForPasteboardChanges() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if let string = pasteboard.string(forType: .string), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let first = items.first, first.text == string {
                return
            }
            items.removeAll { !$0.isPinned && $0.text == string }
            let newItem = ClipboardItem(text: string, copiedAt: Date())
            items.insert(newItem, at: 0)
            trimHistory()
            return
        }

        if let image = NSImage(pasteboard: pasteboard) {
            let newItem = ClipboardItem(text: "Görsel", copiedAt: Date(), image: image)
            items.insert(newItem, at: 0)
            trimHistory()
        }
    }

    private func trimHistory() {
        if items.count > maxHistoryLimit {
            let unpinnedIndices = items.indices.filter { !items[$0].isPinned }
            if unpinnedIndices.count > maxHistoryLimit - 10 {
                let toRemove = unpinnedIndices.suffix(unpinnedIndices.count - (maxHistoryLimit - 10))
                for index in toRemove.reversed() {
                    items.remove(at: index)
                }
            }
        }
    }

    public var displayItems: [ClipboardItem] {
        let pinned = items.filter { $0.isPinned }.sorted { ($0.pinnedAt ?? $0.copiedAt) < ($1.pinnedAt ?? $1.copiedAt) }
        let unpinned = items.filter { !$0.isPinned }.sorted { $0.copiedAt > $1.copiedAt }
        return pinned + unpinned
    }

    public func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let img = item.image {
            pasteboard.writeObjects([img])
        } else {
            pasteboard.setString(item.text, forType: .string)
        }

        self.lastChangeCount = pasteboard.changeCount
    }

    public func togglePin(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            items[index].pinnedAt = items[index].isPinned ? Date() : nil
        }
    }

    public func deleteItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    public func clearUnpinned() {
        items.removeAll { !$0.isPinned }
    }
}
