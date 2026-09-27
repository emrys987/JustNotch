import Combine
import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case turkish = "tr"
    case english = "en"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: return "Otomatik (Sistem Dili) / Automatic"
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
}

@MainActor
public final class LocalizationService: ObservableObject {
    public static let shared = LocalizationService()

    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            self.currentLanguage = .system
        }
    }

    public var isTurkish: Bool {
        switch currentLanguage {
        case .turkish:
            return true
        case .english:
            return false
        case .system:
            if let preferred = Locale.preferredLanguages.first, preferred.hasPrefix("tr") {
                return true
            }
            if let code = Locale.current.language.languageCode?.identifier, code.hasPrefix("tr") {
                return true
            }
            return false
        }
    }

    public var tabMain: String { isTurkish ? "Ana Kısım" : "Main View" }
    public var tabShelf: String { isTurkish ? "Dosya Rafı" : "File Shelf" }
    public var btnSettings: String { isTurkish ? "JustNotch Ayarları..." : "JustNotch Settings..." }
    public var btnClose: String { isTurkish ? "Çentiği Kapat" : "Close Notch" }

    public var musicNotPlaying: String { isTurkish ? "Müzik Çalmıyor" : "No Music Playing" }
    public var musicStartHint: String { isTurkish ? "Medya oynatıcı üzerinden bir parça başlatın." : "Start playback in a supported media player." }
    public var musicWaiting: String { isTurkish ? "Müzik Bekleniyor" : "Waiting for Music" }
    public var musicSyncingLyrics: String { isTurkish ? "Sözler senkronize ediliyor..." : "Syncing lyrics..." }
    public var musicNoLyrics: String { isTurkish ? "Enstrümantal veya söz bulunamadı" : "Instrumental or no lyrics found" }
    public var musicLiveLyrics: String { isTurkish ? "Canlı Sözler" : "Live Lyrics" }

    public var pomodoroFocus: String { isTurkish ? "Odaklanma" : "Focus" }
    public var pomodoroShortBreak: String { isTurkish ? "Kısa Mola" : "Short Break" }
    public var pomodoroLongBreak: String { isTurkish ? "Uzun Mola" : "Long Break" }
    public var pomodoroStart: String { isTurkish ? "Başlat" : "Start" }
    public var pomodoroPause: String { isTurkish ? "Durdur" : "Pause" }
    public var pomodoroReset: String { isTurkish ? "Sıfırla" : "Reset" }
    public var pomodoroSkip: String { isTurkish ? "Sonraki Aşama" : "Next Phase" }
    public var pomodoroSession: String { isTurkish ? "Seans" : "Session" }
    public var pomodoroWorkDuration: String { isTurkish ? "Odaklanma Süresi:" : "Focus Duration:" }
    public var pomodoroShortBreakDuration: String { isTurkish ? "Kısa Mola:" : "Short Break:" }
    public var pomodoroLongBreakDuration: String { isTurkish ? "Uzun Mola:" : "Long Break:" }
    public var pomodoroSoundAlert: String { isTurkish ? "Süre bittiğinde sesli uyarı çal" : "Play sound alert when timer ends" }

    public var shelfDropHint: String { isTurkish ? "Dosyaları Buraya Sürükleyip Bırakın" : "Drop Files Here" }
    public var shelfDropSub: String { isTurkish ? "Dosyalar geçici olarak hazır tutulur. Başka bir yere sürükleyebilir veya tıklayıp açabilirsiniz." : "Files are kept ready temporarily. Drag them anywhere or click to open." }
    public var shelfClearAll: String { isTurkish ? "Tümünü Temizle" : "Clear All" }
    public var shelfClearedHUD: String { isTurkish ? "Raf Temizlendi" : "Shelf Cleared" }
    public var shelfPrivacyNotice: String { isTurkish ? "Dosyalar yerel kalır." : "Files remain local." }
    public var shelfOpen: String { isTurkish ? "Aç" : "Open" }
    public var shelfRevealInFinder: String { isTurkish ? "Finder'da Göster" : "Reveal in Finder" }
    public var shelfRemove: String { isTurkish ? "Raftan Kaldır" : "Remove from Shelf" }

    public var settingsTitle: String { isTurkish ? "JustNotch Tercihleri" : "JustNotch Preferences" }
    public var settingsSub: String { isTurkish ? "Arka plan teması, eklentiler, süreler ve görünüm ayarları." : "Background theme, widgets, timers, and appearance settings." }
    public var settingsThemeSection: String { isTurkish ? "Çentik Teması ve Arka Plan" : "Notch Theme & Background" }
    public var settingsThemeDesc: String { isTurkish ? "Çentik açıldığında arka planın görünümünü kişiselleştirin:" : "Customize the background appearance when notch is expanded:" }
    public var styleAppleGlass: String { isTurkish ? "Buzlu Cam (Şeffaf)" : "Frosted Glass (Blur)" }
    public var styleSolidBlack: String { isTurkish ? "OLED Saf Siyah" : "OLED Pitch Black" }
    public var styleCustomColor: String { isTurkish ? "Özel Renk Tonu" : "Custom Color Tint" }
    public var styleCustomImage: String { isTurkish ? "Özel Görsel / Duvar Kağıdı" : "Custom Image / Wallpaper" }
    public var settingsGlassOpacity: String { isTurkish ? "Cam Karartma / Şeffaflık Oranı:" : "Glass Tint / Transparency:" }
    public var settingsGlassDesc: String { isTurkish ? "Derin buzlu cam. Masaüstü duvar kağıdını arkada bulanıklaştırarak şık bir derinlik hissi verir." : "Frosted glass. Softly blurs your desktop wallpaper underneath for deep translucency." }
    public var settingsSolidBlackDesc: String { isTurkish ? "MacBook donanım çentiği ve ekran çerçevesiyle tam bütünleşen sıfır şeffaflıklı OLED saf siyah." : "Pure OLED black matching your MacBook hardware notch and bezel seamlessly." }

    public var settingsChooseImage: String { isTurkish ? "Görsel Seç..." : "Choose Image..." }
    public var settingsNoImage: String { isTurkish ? "Henüz bir görsel seçilmedi" : "No image selected yet" }
    public var settingsZoom: String { isTurkish ? "Yakınlaştırma (Zoom):" : "Zoom (Scale):" }
    public var settingsPanX: String { isTurkish ? "Yatay Konum (X):" : "Horizontal Position (X):" }
    public var settingsPanY: String { isTurkish ? "Dikey Konum (Y):" : "Vertical Position (Y):" }
    public var settingsBlur: String { isTurkish ? "Bulanıklık (Blur):" : "Blur:" }
    public var settingsTint: String { isTurkish ? "Karartma (Tint):" : "Darkness (Tint):" }
    public var settingsResetFraming: String { isTurkish ? "Konumu Sıfırla" : "Reset Framing" }
    public var settingsRemoveImage: String { isTurkish ? "Görseli Kaldır" : "Remove Image" }

    public var settingsWidgetsSection: String { isTurkish ? "Modüler Eklentiler ve Menüler" : "Modular Widgets & Menus" }
    public var settingsWidgetsDesc: String { isTurkish ? "Çentikte etkinleştirmek istediğiniz bileşenleri seçin:" : "Select the components you wish to enable in the notch:" }
    public var settingsMusicTitle: String { isTurkish ? "Müzik & Canlı Şarkı Sözleri" : "Music & Synced Lyrics" }
    public var settingsMusicDesc: String { isTurkish ? "Medya oynatıcı kontrolleri ve milisaniyelik senkronize söz akışı" : "Media playback controls with millisecond-synced lyrics" }
    public var settingsPomodoroTitle: String { isTurkish ? "Pomodoro Odaklanma Sayacı" : "Pomodoro Focus Timer" }
    public var settingsPomodoroDesc: String { isTurkish ? "Çentik üzerinde dairesel ilerleme çemberi, sayaç ve hızlı kontroller" : "Circular progress ring, timer display, and quick controls" }
    public var settingsClipboardTitle: String { isTurkish ? "Pano Geçmişi (3. Menü)" : "Clipboard History (3rd Tab)" }
    public var settingsClipboardDesc: String { isTurkish ? "Çentik üzerinde son kopyalanan metin ve görselleri yatay kaydırılabilir 4 karede gösterir" : "Displays recent copied text and images in a horizontally scrollable 4-card row" }

    public var settingsSizeSection: String { isTurkish ? "Çentik Boyutu ve Davranışı" : "Notch Sizing & Behavior" }
    public var settingsOpenOnHover: String { isTurkish ? "Fare imleci çentiğin üzerine geldiğinde otomatik olarak genişlet" : "Automatically expand when cursor hovers over the notch" }
    public var settingsExpandedWidth: String { isTurkish ? "Açık Çentik Genişliği:" : "Expanded Notch Width:" }
    public var settingsLanguageSection: String { isTurkish ? "Uygulama Dili (Language)" : "App Language" }
    public var settingsLanguageDesc: String { isTurkish ? "Bilgisayarın sistem diline göre otomatik optimize edilir (Türkçe ve İngilizce desteklenir)." : "Automatically optimized to your Mac's language (Turkish and English supported)." }
}
