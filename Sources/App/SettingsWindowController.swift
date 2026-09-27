import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowController: NSObject {
    public static let shared = SettingsWindowController()

    private var windowController: NSWindowController?

    private override init() {
        super.init()
    }

    public func showWindow() {
        if let existing = windowController, let win = existing.window {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsWindowView()
        let hostingView = NSHostingView(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 540),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "JustNotch"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        self.windowController = controller

        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
