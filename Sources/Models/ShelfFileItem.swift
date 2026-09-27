import AppKit
import Foundation

public struct ShelfFileItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let fileURL: URL
    public let fileName: String
    public let fileExtension: String
    public let fileSize: Int64
    public let addedDate: Date
    public let isDirectory: Bool

    public init(
        id: UUID = UUID(),
        fileURL: URL,
        fileName: String? = nil,
        fileSize: Int64? = nil,
        addedDate: Date = Date()
    ) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileName ?? fileURL.lastPathComponent
        self.fileExtension = fileURL.pathExtension.uppercased()
        self.addedDate = addedDate

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue

        if let explicitSize = fileSize {
            self.fileSize = explicitSize
        } else {
            let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
            self.fileSize = (attributes?[.size] as? Int64) ?? 0
        }
    }

    public var formattedSize: String {
        if isDirectory {
            return "Klasör"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    public var systemIcon: NSImage {
        NSWorkspace.shared.icon(forFile: fileURL.path)
    }
}
