import AppKit
import SwiftUI

@main
struct JustNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var shelfService = ZDRShelfService.shared

    var body: some Scene {
        MenuBarExtra {
            Button(coordinator.isExpanded ? "Çentiği Kapat" : "Çentiği Genişlet") {
                coordinator.toggleExpanded()
            }
            .keyboardShortcut("N", modifiers: [.command, .shift])

            Divider()

            Button("Ana Kısım") {
                coordinator.open(mode: .main)
            }
            Button("Dosya Rafı") {
                coordinator.open(mode: .shelf)
            }
            if UserSettings.shared.enableClipboardTab {
                Button("Pano Geçmişi") {
                    coordinator.open(mode: .clipboard)
                }
            }

            Divider()

            Button("Ayarlar...") {
                SettingsWindowController.shared.showWindow()
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Rafı Temizle") {
                shelfService.wipeAllFiles()
                coordinator.showHUD(message: "Raf Temizlendi")
            }

            Divider()

            Button("JustNotch'tan Çık", role: .destructive) {
                shelfService.wipeAllFiles()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("Q", modifiers: .command)
        } label: {
            Image(nsImage: AppLogo.menuBarImage)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        Task { @MainActor in
            NotchWindowController.shared.setupAndShowWindow()
            MediaService.shared.startMonitoring()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            ZDRShelfService.shared.wipeAllFiles()
        }
    }
}
