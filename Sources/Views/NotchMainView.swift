import SwiftUI

public struct NotchMainView: View {
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var settings = UserSettings.shared

    public init() {}

    public var body: some View {
        let closedSize = NotchSizing.getClosedNotchSize()
        let currentWidth = coordinator.isExpanded ? NotchSizing.getExpandedWidth() : closedSize.width
        let currentHeight = coordinator.isExpanded ? NotchSizing.getExpandedHeight() : closedSize.height
        let cornerRadius: CGFloat = coordinator.isExpanded ? 18 : 10
        let headerHeight: CGFloat = coordinator.isExpanded ? 36 : closedSize.height
        let expandedContentHeight = max(100, currentHeight - headerHeight)

        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                NotchHeaderView()
                    .frame(height: headerHeight)

                if coordinator.isExpanded {
                    VStack(spacing: 0) {
                        switch coordinator.activeMode {
                        case .main:
                            MainContainerView()
                        case .shelf:
                            ZDRShelfView()
                        case .clipboard:
                            ClipboardNotchView()
                        }
                    }
                    .frame(width: NotchSizing.getExpandedWidth(), height: expandedContentHeight)
                    .clipped()
                    .transition(.opacity)
                }

                if let hudMessage = coordinator.temporaryHUDMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text(hudMessage)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .padding(.bottom, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(width: currentWidth, height: currentHeight, alignment: .top)
            .background(backgroundContent(cornerRadius: cornerRadius))
            .clipShape(BottomRoundedRectangle(cornerRadius: cornerRadius, topBleed: 4))
        }
        .frame(width: currentWidth, height: currentHeight, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func backgroundContent(cornerRadius: CGFloat) -> some View {
        ZStack {
            if !coordinator.isExpanded {
                BottomRoundedRectangle(cornerRadius: cornerRadius, topBleed: 4)
                    .fill(Color.black)
            } else {
                switch settings.notchBackgroundStyle {
                case .appleGlass:
                    ZStack {
                        VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                        Color.black.opacity(settings.glassOpacity)
                    }

                case .solidBlack:
                    Color.black

                case .customColor:
                    ZStack {
                        VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                        Color(hex: settings.customColorHex).opacity(settings.customColorOpacity)
                    }

                case .customImage:
                    ZStack {
                        if let img = settings.cachedCustomImage {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(settings.customImageScale)
                                .offset(x: settings.customImageOffsetX, y: settings.customImageOffsetY)
                                .blur(radius: settings.customImageBlur)
                        } else {
                            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                        }
                        Color.black.opacity(settings.customImageDarkness)
                    }
                }

                BottomRoundedBorder(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
    }
}
