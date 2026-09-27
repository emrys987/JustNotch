import AppKit
import Foundation

public final class ArtworkCache: @unchecked Sendable {
    public static let shared = ArtworkCache()

    private let dataCache = NSCache<NSString, NSData>()
    private let imageCache = NSCache<NSString, NSImage>()
    private let lock = NSLock()

    private init() {
        dataCache.countLimit = 150
        dataCache.totalCostLimit = 60 * 1024 * 1024
        imageCache.countLimit = 150
    }

    public func get(for key: String) -> (Data, NSImage)? {
        guard !key.isEmpty else { return nil }
        lock.lock()
        defer { lock.unlock() }

        let nsKey = key as NSString
        if let img = imageCache.object(forKey: nsKey), let data = dataCache.object(forKey: nsKey) {
            return (data as Data, img)
        }
        if let data = dataCache.object(forKey: nsKey) as Data? {
            if let img = NSImage(data: data) {
                imageCache.setObject(img, forKey: nsKey)
                return (data, img)
            }
        }
        return nil
    }

    public func getImage(for key: String) -> NSImage? {
        guard !key.isEmpty else { return nil }
        lock.lock()
        defer { lock.unlock() }

        let nsKey = key as NSString
        if let img = imageCache.object(forKey: nsKey) {
            return img
        }
        if let data = dataCache.object(forKey: nsKey) as Data? {
            if let img = NSImage(data: data) {
                imageCache.setObject(img, forKey: nsKey)
                return img
            }
        }
        return nil
    }

    @discardableResult
    public func set(data: Data, for key: String) -> NSImage? {
        guard !key.isEmpty else { return nil }
        let nsKey = key as NSString
        let image = NSImage(data: data)

        lock.lock()
        dataCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
        if let image = image {
            imageCache.setObject(image, forKey: nsKey)
        }
        lock.unlock()

        return image
    }
}
