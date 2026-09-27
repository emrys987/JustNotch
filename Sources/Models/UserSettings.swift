import AppKit
import Combine
import Foundation
import ImageIO
import SwiftUI

public enum NotchBackgroundStyle: String, CaseIterable, Identifiable {
    case appleGlass = "appleGlass"
    case solidBlack = "solidBlack"
    case customColor = "customColor"
    case customImage = "customImage"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .appleGlass: return "Buzlu Cam (Şeffaf)"
        case .solidBlack: return "OLED Saf Siyah"
        case .customColor: return "Özel Renk Tonu"
        case .customImage: return "Özel Görsel / Duvar Kağıdı"
        }
    }

    public var iconName: String {
        switch self {
        case .appleGlass: return "macwindow.on.rectangle"
        case .solidBlack: return "moon.fill"
        case .customColor: return "paintpalette.fill"
        case .customImage: return "photo.fill"
        }
    }
}

@MainActor
public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()

    @Published public var enableMusicWidget: Bool {
        didSet { UserDefaults.standard.set(enableMusicWidget, forKey: "enableMusicWidget") }
    }

    @Published public var enablePomodoroWidget: Bool {
        didSet { UserDefaults.standard.set(enablePomodoroWidget, forKey: "enablePomodoroWidget") }
    }

    @Published public var enableClipboardTab: Bool {
        didSet { UserDefaults.standard.set(enableClipboardTab, forKey: "enableClipboardTab") }
    }

    @Published public var notchBackgroundStyle: NotchBackgroundStyle {
        didSet { UserDefaults.standard.set(notchBackgroundStyle.rawValue, forKey: "notchBackgroundStyle") }
    }

    @Published public var glassOpacity: Double {
        didSet { UserDefaults.standard.set(glassOpacity, forKey: "glassOpacity") }
    }

    @Published public var customColorHex: String {
        didSet { UserDefaults.standard.set(customColorHex, forKey: "customColorHex") }
    }

    @Published public var customColorOpacity: Double {
        didSet { UserDefaults.standard.set(customColorOpacity, forKey: "customColorOpacity") }
    }

    @Published public var cachedCustomImage: NSImage? = nil

    @Published public var customImagePath: String? {
        didSet {
            UserDefaults.standard.set(customImagePath, forKey: "customImagePath")
            reloadCustomImage()
        }
    }

    @Published public var customImageBlur: Double {
        didSet { UserDefaults.standard.set(customImageBlur, forKey: "customImageBlur") }
    }

    @Published public var customImageDarkness: Double {
        didSet { UserDefaults.standard.set(customImageDarkness, forKey: "customImageDarkness") }
    }

    @Published public var customImageScale: Double {
        didSet { UserDefaults.standard.set(customImageScale, forKey: "customImageScale") }
    }

    @Published public var customImageOffsetX: Double {
        didSet { UserDefaults.standard.set(customImageOffsetX, forKey: "customImageOffsetX") }
    }

    @Published public var customImageOffsetY: Double {
        didSet { UserDefaults.standard.set(customImageOffsetY, forKey: "customImageOffsetY") }
    }

    @Published public var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage")
            LocalizationService.shared.currentLanguage = appLanguage
        }
    }

    @Published public var pomodoroWorkMinutes: Int {
        didSet { UserDefaults.standard.set(pomodoroWorkMinutes, forKey: "pomodoroWorkMinutes") }
    }

    @Published public var pomodoroShortBreakMinutes: Int {
        didSet { UserDefaults.standard.set(pomodoroShortBreakMinutes, forKey: "pomodoroShortBreakMinutes") }
    }

    @Published public var pomodoroLongBreakMinutes: Int {
        didSet { UserDefaults.standard.set(pomodoroLongBreakMinutes, forKey: "pomodoroLongBreakMinutes") }
    }

    @Published public var pomodoroSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(pomodoroSoundEnabled, forKey: "pomodoroSoundEnabled") }
    }

    @Published public var enableSpotify: Bool {
        didSet { UserDefaults.standard.set(enableSpotify, forKey: "enableSpotify") }
    }

    @Published public var enableAppleMusic: Bool {
        didSet { UserDefaults.standard.set(enableAppleMusic, forKey: "enableAppleMusic") }
    }

    @Published public var showSyncedLyrics: Bool {
        didSet { UserDefaults.standard.set(showSyncedLyrics, forKey: "showSyncedLyrics") }
    }

    @Published public var notchExpandedWidth: CGFloat {
        didSet { UserDefaults.standard.set(notchExpandedWidth, forKey: "notchExpandedWidth") }
    }

    @Published public var notchExpandedHeight: CGFloat {
        didSet { UserDefaults.standard.set(notchExpandedHeight, forKey: "notchExpandedHeight") }
    }

    @Published public var openOnHover: Bool {
        didSet { UserDefaults.standard.set(openOnHover, forKey: "openOnHover") }
    }

    private init() {
        let defaults = UserDefaults.standard

        self.enableMusicWidget = defaults.object(forKey: "enableMusicWidget") != nil
            ? defaults.bool(forKey: "enableMusicWidget") : true
        self.enablePomodoroWidget = defaults.object(forKey: "enablePomodoroWidget") != nil
            ? defaults.bool(forKey: "enablePomodoroWidget") : true
        self.enableClipboardTab = defaults.object(forKey: "enableClipboardTab") != nil
            ? defaults.bool(forKey: "enableClipboardTab") : true

        if let rawStyle = defaults.string(forKey: "notchBackgroundStyle"),
           let style = NotchBackgroundStyle(rawValue: rawStyle) {
            self.notchBackgroundStyle = style
        } else {
            self.notchBackgroundStyle = .appleGlass
        }

        self.glassOpacity = defaults.object(forKey: "glassOpacity") != nil
            ? defaults.double(forKey: "glassOpacity") : 0.65
        self.customColorHex = defaults.string(forKey: "customColorHex") ?? "#18181B"
        self.customColorOpacity = defaults.object(forKey: "customColorOpacity") != nil
            ? defaults.double(forKey: "customColorOpacity") : 0.85
        self.customImagePath = defaults.string(forKey: "customImagePath")
        self.customImageBlur = defaults.object(forKey: "customImageBlur") != nil
            ? defaults.double(forKey: "customImageBlur") : 8.0
        self.customImageDarkness = defaults.object(forKey: "customImageDarkness") != nil
            ? defaults.double(forKey: "customImageDarkness") : 0.50
        self.customImageScale = defaults.object(forKey: "customImageScale") != nil
            ? defaults.double(forKey: "customImageScale") : 1.0
        self.customImageOffsetX = defaults.object(forKey: "customImageOffsetX") != nil
            ? defaults.double(forKey: "customImageOffsetX") : 0.0
        self.customImageOffsetY = defaults.object(forKey: "customImageOffsetY") != nil
            ? defaults.double(forKey: "customImageOffsetY") : 0.0

        if let savedLang = defaults.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: savedLang) {
            self.appLanguage = lang
        } else {
            self.appLanguage = .system
        }

        self.pomodoroWorkMinutes = defaults.object(forKey: "pomodoroWorkMinutes") != nil
            ? defaults.integer(forKey: "pomodoroWorkMinutes") : 25
        self.pomodoroShortBreakMinutes = defaults.object(forKey: "pomodoroShortBreakMinutes") != nil
            ? defaults.integer(forKey: "pomodoroShortBreakMinutes") : 5
        self.pomodoroLongBreakMinutes = defaults.object(forKey: "pomodoroLongBreakMinutes") != nil
            ? defaults.integer(forKey: "pomodoroLongBreakMinutes") : 15
        self.pomodoroSoundEnabled = defaults.object(forKey: "pomodoroSoundEnabled") != nil
            ? defaults.bool(forKey: "pomodoroSoundEnabled") : true

        self.enableSpotify = defaults.object(forKey: "enableSpotify") != nil
            ? defaults.bool(forKey: "enableSpotify") : true
        self.enableAppleMusic = defaults.object(forKey: "enableAppleMusic") != nil
            ? defaults.bool(forKey: "enableAppleMusic") : true
        self.showSyncedLyrics = defaults.object(forKey: "showSyncedLyrics") != nil
            ? defaults.bool(forKey: "showSyncedLyrics") : true

        self.notchExpandedWidth = defaults.object(forKey: "notchExpandedWidth") != nil
            ? CGFloat(defaults.double(forKey: "notchExpandedWidth")) : 460
        self.notchExpandedHeight = defaults.object(forKey: "notchExpandedHeight") != nil
            ? CGFloat(defaults.double(forKey: "notchExpandedHeight")) : 190
        self.openOnHover = defaults.object(forKey: "openOnHover") != nil
            ? defaults.bool(forKey: "openOnHover") : true

        reloadCustomImage()
    }

    public func reloadCustomImage() {
        guard let path = customImagePath, !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
            self.cachedCustomImage = nil
            return
        }

        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else {
            self.cachedCustomImage = nil
            return
        }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 1600,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
            self.cachedCustomImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        } else if let fallback = NSImage(contentsOfFile: path) {
            self.cachedCustomImage = fallback
        } else {
            self.cachedCustomImage = nil
        }
    }

    public func removeCustomImage() {
        self.customImagePath = nil
        self.cachedCustomImage = nil
        if self.notchBackgroundStyle == .customImage {
            self.notchBackgroundStyle = .appleGlass
        }
    }
}
