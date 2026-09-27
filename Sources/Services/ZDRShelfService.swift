import AppKit
import Combine
import Foundation
import QuickLook

@MainActor
public final class ZDRShelfService: ObservableObject {
    public static let shared = ZDRShelfService()

    @Published public private(set) var items: [ShelfFileItem] = []
    @Published public var isTargeted: Bool = false

    private let volatileTempDirectory: URL

    private init() {
        self.volatileTempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("JustNotch_Shelf", isDirectory: true)

        try? FileManager.default.createDirectory(at: volatileTempDirectory, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: volatileTempDirectory)
    }

    public func addFiles(_ urls: [URL]) {
        for url in urls {
            guard !items.contains(where: { $0.fileURL.standardizedFileURL == url.standardizedFileURL }) else {
                continue
            }
            let item = ShelfFileItem(fileURL: url)
            items.insert(item, at: 0)
        }
    }

    public func addVolatileText(_ text: String, suggestedName: String = "Note.txt") {
        let uniqueName = "\(UUID().uuidString.prefix(8))_\(suggestedName)"
        let fileURL = volatileTempDirectory.appendingPathComponent(uniqueName)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            let item = ShelfFileItem(fileURL: fileURL, fileName: suggestedName)
            items.insert(item, at: 0)
        } catch {
            print("ZDRShelf: Failed to write text: \(error)")
        }
    }

    public func removeItem(with id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items[index]
            if item.fileURL.path.hasPrefix(volatileTempDirectory.path) {
                try? FileManager.default.removeItem(at: item.fileURL)
            }
            items.remove(at: index)
        }
    }

    public func wipeAllFiles() {
        for item in items where item.fileURL.path.hasPrefix(volatileTempDirectory.path) {
            try? FileManager.default.removeItem(at: item.fileURL)
        }
        items.removeAll()
    }

    public func openFile(_ item: ShelfFileItem) {
        NSWorkspace.shared.open(item.fileURL)
    }

    public func revealInFinder(_ item: ShelfFileItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.fileURL])
    }
}
