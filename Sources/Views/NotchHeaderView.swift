import SwiftUI

public struct NotchHeaderView: View {
    @ObservedObject var coordinator = NotchCoordinator.shared
    @ObservedObject var mediaService = MediaService.shared
    @ObservedObject var loc = LocalizationService.shared

    public init() {}

    public var body: some View {
        if coordinator.isExpanded {
            HStack(spacing: 8) {
                Button {
                    coordinator.switchMode(to: .main)
                } label: {
                    AppLogoView(height: 11, opacity: coordinator.activeMode == .main ? 1.0 : 0.6)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(coordinator.activeMode == .main ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .help(loc.tabMain)

                Button {
                    coordinator.switchMode(to: .shelf)
                } label: {
                    Image(systemName: NotchViewMode.shelf.iconName)
                        .font(.system(size: 11, weight: coordinator.activeMode == .shelf ? .bold : .medium))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(coordinator.activeMode == .shelf ? Color(red: 0.38, green: 0.65, blue: 1.0).opacity(0.3) : Color.white.opacity(0.08))
                        )
                        .foregroundStyle(coordinator.activeMode == .shelf ? Color(red: 0.38, green: 0.65, blue: 1.0) : Color.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help(loc.tabShelf)

                if UserSettings.shared.enableClipboardTab {
                    Button {
                        coordinator.switchMode(to: .clipboard)
                    } label: {
                        Image(systemName: NotchViewMode.clipboard.iconName)
                            .font(.system(size: 11, weight: coordinator.activeMode == .clipboard ? .bold : .medium))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(coordinator.activeMode == .clipboard ? Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.3) : Color.white.opacity(0.08))
                            )
                            .foregroundStyle(coordinator.activeMode == .clipboard ? Color(red: 1.0, green: 0.65, blue: 0.15) : Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help(loc.isTurkish ? "Pano Geçmişi" : "Clipboard History")
                }

                Spacer()

                Button {
                    SettingsWindowController.shared.showWindow()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                Button {
                    coordinator.keepNotchOpen.toggle()
                } label: {
                    Image(systemName: coordinator.keepNotchOpen ? "pin.fill" : "pin")
                        .font(.system(size: 10))
                        .padding(6)
                        .background(
                            Circle()
                                .fill(coordinator.keepNotchOpen ? Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.3) : Color.white.opacity(0.1))
                        )
                        .foregroundStyle(coordinator.keepNotchOpen ? Color(red: 1.0, green: 0.65, blue: 0.15) : Color.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(coordinator.keepNotchOpen ? (loc.isTurkish ? "Sabitlemeyi Kaldır" : "Unpin") : (loc.isTurkish ? "Çentiği Açık Tut" : "Keep Open"))

                Button {
                    coordinator.close()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(loc.btnClose)
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 2)
        } else {
            HStack(spacing: 0) {
                if mediaService.currentState.isPlaying && mediaService.currentState.hasActiveTrack {
                    ZStack {
                        if let artwork = mediaService.currentState.artworkImage {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: mediaService.currentState.player.iconName)
                                .font(.system(size: 10))
                                .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.45))
                        }
                    }
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .padding(.leading, 8)
                }

                Spacer()
            }
            .frame(height: NotchSizing.getClosedNotchSize().height)
            .contentShape(Rectangle())
            .onTapGesture {
                coordinator.toggleExpanded()
            }
        }
    }
}
