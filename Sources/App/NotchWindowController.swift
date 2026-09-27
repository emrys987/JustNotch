import AppKit
import Combine
import Foundation
import SwiftUI

final class NotchPanel: NSPanel {
    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: flag)
        isFloatingPanel = true
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = .clear
        isMovable = false
        hasShadow = false
        level = .mainMenu + 3
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            .tiff,
            .png
        ])
    }

    override var hasShadow: Bool {
        get { false }
        set { super.hasShadow = false }
    }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }

    override var canBecomeKey: Bool {
        return NotchCoordinator.shared.isExpanded
    }
    override var canBecomeMain: Bool {
        return NotchCoordinator.shared.isExpanded
    }
}

final class NotchHostingView<Content: View>: NSHostingView<Content> {
    override var acceptsFirstResponder: Bool { true }
    private var trackingArea: NSTrackingArea?

    @MainActor required init(rootView: Content) {
        super.init(rootView: rootView)
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            .tiff,
            .png
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            .tiff,
            .png
        ])
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways,
            .inVisibleRect
        ]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        NotchCoordinator.shared.onMouseEnter()
    }

    override func mouseExited(with event: NSEvent) {
        NotchCoordinator.shared.onMouseExit()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        Task { @MainActor in
            NotchCoordinator.shared.onDragEnter()
            ZDRShelfService.shared.isTargeted = true
        }
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        Task { @MainActor in
            ZDRShelfService.shared.isTargeted = false
            NotchCoordinator.shared.onDragExit()
        }
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        Task { @MainActor in
            ZDRShelfService.shared.isTargeted = false

            if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
                ZDRShelfService.shared.addFiles(urls)
                NotchCoordinator.shared.showHUD(message: LocalizationService.shared.isTurkish ? "Dosyalar Rafa Eklendi" : "Files Added to Shelf")
                return
            }

            if let strings = pboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], let text = strings.first, !text.isEmpty {
                ZDRShelfService.shared.addVolatileText(text)
                NotchCoordinator.shared.showHUD(message: LocalizationService.shared.isTurkish ? "Not Rafa Eklendi" : "Note Added to Shelf")
            }
        }
        return true
    }
}

@MainActor
public final class NotchWindowController: NSObject, ObservableObject {
    public static let shared = NotchWindowController()

    public private(set) var window: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
    }

    public func setupAndShowWindow() {
        guard window == nil else {
            window?.orderFrontRegardless()
            return
        }

        let closedSize = NotchSizing.getClosedNotchSize()

        let panel = NotchPanel(
            contentRect: NSRect(x: 0, y: 0, width: closedSize.width, height: closedSize.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentView = NotchHostingView(rootView: NotchMainView().ignoresSafeArea())
        panel.hasShadow = false
        panel.invalidateShadow()

        self.window = panel
        repositionWindow()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.repositionWindow()
            }
        }

        NotchCoordinator.shared.$isExpanded
            .sink { [weak self] isExpanded in
                self?.updateWindowFrame(isExpanded: isExpanded)
            }
            .store(in: &cancellables)

        panel.orderFrontRegardless()
    }

    public func repositionWindow() {
        guard let panel = window else { return }

        let screen = NotchSizing.getTargetScreen()
        let screenFrame = screen.frame
        let isExpanded = NotchCoordinator.shared.isExpanded

        let closedSize = NotchSizing.getClosedNotchSize()
        let width: CGFloat = isExpanded ? NotchSizing.getExpandedWidth() : closedSize.width
        let height: CGFloat = isExpanded ? NotchSizing.getExpandedHeight() : closedSize.height

        let originX: CGFloat
        if !isExpanded, let leftPad = screen.auxiliaryTopLeftArea?.width, leftPad > 0 {
            originX = screenFrame.origin.x + leftPad
        } else {
            originX = screenFrame.origin.x + (screenFrame.width / 2) - (width / 2)
        }

        let originY = screenFrame.origin.y + screenFrame.height - height

        panel.setFrame(NSRect(x: originX, y: originY, width: width, height: height), display: true, animate: false)
        panel.invalidateShadow()
    }

    private func updateWindowFrame(isExpanded: Bool) {
        guard let panel = window else { return }
        let screen = NotchSizing.getTargetScreen()
        let screenFrame = screen.frame

        let closedSize = NotchSizing.getClosedNotchSize()
        let width: CGFloat = isExpanded ? NotchSizing.getExpandedWidth() : closedSize.width
        let height: CGFloat = isExpanded ? NotchSizing.getExpandedHeight() : closedSize.height

        let originX: CGFloat
        if !isExpanded, let leftPad = screen.auxiliaryTopLeftArea?.width, leftPad > 0 {
            originX = screenFrame.origin.x + leftPad
        } else {
            originX = screenFrame.origin.x + (screenFrame.width / 2) - (width / 2)
        }
        let originY = screenFrame.origin.y + screenFrame.height - height

        if !isExpanded {
            panel.resignKey()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.30, 1.0)
            panel.animator().setFrame(NSRect(x: originX, y: originY, width: width, height: height), display: true)
        }
    }

    public func activateForInput() {
        guard let panel = window else { return }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    public func deactivateInput() {
        guard let panel = window else { return }
        panel.resignKey()
    }
}
