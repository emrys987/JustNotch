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

            Button(coordinator.keepNotchOpen ? "◉  Çentiği Sürekli Açık Bırak" : "○  Çentiği Sürekli Açık Bırak") {
                coordinator.keepNotchOpen.toggle()
            }

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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMainMenu()

        checkIfShouldMoveToApplicationsFolder()

        Task { @MainActor in
            NotchWindowController.shared.setupAndShowWindow()
            MediaService.shared.startMonitoring()
        }
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func checkIfShouldMoveToApplicationsFolder() {
        let bundlePath = Bundle.main.bundleURL.path
        let isInsideApplications = bundlePath.hasPrefix("/Applications") || (bundlePath.hasPrefix("/Users/") && bundlePath.contains("/Applications"))
        let isDevelopmentFolder = bundlePath.contains(".build") || bundlePath.contains("newnotch-main")
        if isInsideApplications || isDevelopmentFolder {
            return
        }

        guard bundlePath.contains("/Downloads/") || bundlePath.contains("/Temp/") || bundlePath.contains("/var/folders/") else {
            return
        }

        let isTurkish = LocalizationService.shared.isTurkish
        let alert = NSAlert()
        alert.messageText = isTurkish ? "Uygulamalar Klasörüne Taşınsın mı?" : "Move to Applications Folder?"
        alert.informativeText = isTurkish
            ? "JustNotch'un düzenli çalışması ve menü çubuğunda kalıcı olması için Uygulamalar klasörüne taşınması önerilir."
            : "Moving JustNotch to your Applications folder ensures it stays accessible and works seamlessly."
        alert.addButton(withTitle: isTurkish ? "Uygulamalar'a Taşı" : "Move to Applications")
        alert.addButton(withTitle: isTurkish ? "Burada Bırak" : "Do Not Move")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            moveToApplicationsFolder()
        }
    }

    private func moveToApplicationsFolder() {
        let currentURL = Bundle.main.bundleURL
        let targetURL = URL(fileURLWithPath: "/Applications/JustNotch.app")
        let fileManager = FileManager.default

        do {
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.copyItem(at: currentURL, to: targetURL)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            process.arguments = ["-cr", targetURL.path]
            try? process.run()
            process.waitUntilExit()

            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: targetURL, configuration: config) { _, _ in
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
            }
        } catch {
            print("Failed to move to Applications: \(error)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            ZDRShelfService.shared.wipeAllFiles()
        }
    }
}
