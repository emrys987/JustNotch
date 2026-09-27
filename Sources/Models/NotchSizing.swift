import AppKit
import Foundation

@MainActor
public struct NotchSizing {
    public static func getTargetScreen() -> NSScreen {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens.first!
    }

    public static func getClosedNotchSize() -> CGSize {
        let screen = getTargetScreen()
        var width: CGFloat = 172
        var height: CGFloat = 34

        if let leftPad = screen.auxiliaryTopLeftArea?.width,
           let rightPad = screen.auxiliaryTopRightArea?.width,
           leftPad > 0, rightPad > 0 {
            let calculatedWidth = screen.frame.width - leftPad - rightPad
            if calculatedWidth > 50 && calculatedWidth < 300 {
                width = calculatedWidth
            }
        }

        if screen.safeAreaInsets.top > 0 {
            height = screen.safeAreaInsets.top
        } else {
            let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
            height = menuBarHeight > 0 ? menuBarHeight : 28
            width = 160
        }

        return CGSize(width: width, height: height)
    }

    public static func getExpandedWidth() -> CGFloat {
        UserSettings.shared.notchExpandedWidth
    }

    public static func getExpandedHeight() -> CGFloat {
        UserSettings.shared.notchExpandedHeight
    }
}
