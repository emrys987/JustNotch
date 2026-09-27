import Combine
import Foundation
import SwiftUI

@MainActor
public final class NotchCoordinator: ObservableObject {
    public static let shared = NotchCoordinator()

    @Published public var isExpanded: Bool = false
    @Published public var activeMode: NotchViewMode = .main
    @Published public var activeMainWidget: MainWidgetType = .music
    @Published public var isHovering: Bool = false
    @Published public var isShowingLyrics: Bool = false
    @Published public var temporaryHUDMessage: String? = nil

    @Published public var keepNotchOpen: Bool = false {
        didSet {
            if keepNotchOpen {
                closeTask?.cancel()
                closeTask = nil
                open()
            }
        }
    }

    @Published public var isDraggingFileOut: Bool = false {
        didSet {
            if isDraggingFileOut {
                closeTask?.cancel()
                closeTask = nil
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    self?.isDraggingFileOut = false
                }
            }
        }
    }

    private var closeTask: Task<Void, Never>?
    private var hudDismissTask: Task<Void, Never>?
    private let notchAnimation = Animation.timingCurve(0.16, 1.0, 0.30, 1.0, duration: 0.28)

    private init() {}

    public func onMouseEnter() {
        closeTask?.cancel()
        closeTask = nil
        isHovering = true

        guard UserSettings.shared.openOnHover else { return }

        if !isExpanded {
            open()
        }
    }

    public func onDragEnter() {
        closeTask?.cancel()
        closeTask = nil
        isHovering = true
        activeMode = .shelf
        withAnimation(notchAnimation) {
            isExpanded = true
        }
    }

    public func onDragExit() {
        onMouseExit()
    }

    public func onMouseExit() {
        isHovering = false

        if keepNotchOpen || isDraggingFileOut {
            return
        }

        guard UserSettings.shared.openOnHover else { return }

        closeTask?.cancel()
        closeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            guard let self = self, !self.keepNotchOpen, !self.isDraggingFileOut else { return }

            if let panel = NotchWindowController.shared.window {
                let mouseLocation = NSEvent.mouseLocation
                let safeRect = panel.frame.insetBy(dx: -4, dy: -4)
                if !NSMouseInRect(mouseLocation, safeRect, false) {
                    self.close()
                }
            } else {
                self.close()
            }
        }
    }

    public func toggleExpanded() {
        closeTask?.cancel()
        closeTask = nil
        withAnimation(notchAnimation) {
            isExpanded.toggle()
        }
    }

    public func open(mode: NotchViewMode? = nil) {
        closeTask?.cancel()
        closeTask = nil
        if let mode = mode {
            self.activeMode = mode
        }
        withAnimation(notchAnimation) {
            isExpanded = true
        }
    }

    public func close() {
        closeTask?.cancel()
        closeTask = nil
        keepNotchOpen = false
        isShowingLyrics = false
        withAnimation(notchAnimation) {
            isExpanded = false
        }
    }

    public func switchMode(to mode: NotchViewMode) {
        isShowingLyrics = false
        withAnimation(.easeInOut(duration: 0.2)) {
            self.activeMode = mode
        }
    }

    public func switchMainWidget(to widget: MainWidgetType) {
        withAnimation(.easeInOut(duration: 0.2)) {
            self.activeMainWidget = widget
        }
    }

    public func showHUD(message: String, durationSeconds: Double = 2.0) {
        temporaryHUDMessage = message
        hudDismissTask?.cancel()
        hudDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(durationSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                self?.temporaryHUDMessage = nil
            }
        }
    }
}
