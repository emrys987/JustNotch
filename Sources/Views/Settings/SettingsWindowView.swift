import AppKit
import SwiftUI
import UniformTypeIdentifiers

public struct SettingsWindowView: View {
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var pomodoroService = PomodoroService.shared
    @ObservedObject var loc = LocalizationService.shared

    private let presetColors: [(name: String, hex: String)] = [
        ("Obsidyen", "#18181B"),
        ("Gece Yarısı", "#0F172A"),
        ("Karanlık Safir", "#1E1B4B"),
        ("Mor Nebula", "#3B0764"),
        ("Zümrüt Gece", "#064E3B"),
        ("Koyu Kızıl", "#450A0A")
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AppLogoView(height: 24)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.settingsTitle)
                        .font(.system(size: 16, weight: .bold))
                    Text(loc.settingsSub)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(18)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(loc.settingsThemeSection, systemImage: "paintbrush.pointed.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.38, green: 0.65, blue: 1.0))

                        Text(loc.settingsThemeDesc)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            styleButton(style: .appleGlass, title: loc.styleAppleGlass, icon: "macwindow.on.rectangle")
                            styleButton(style: .solidBlack, title: loc.styleSolidBlack, icon: "moon.fill")
                            styleButton(style: .customColor, title: loc.styleCustomColor, icon: "paintpalette.fill")
                            styleButton(style: .customImage, title: loc.styleCustomImage, icon: "photo.fill")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            switch settings.notchBackgroundStyle {
                            case .appleGlass:
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(loc.settingsGlassOpacity)
                                            .font(.system(size: 11))
                                        Spacer()
                                        Text("%\(Int(settings.glassOpacity * 100))")
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    }
                                    Slider(value: $settings.glassOpacity, in: 0.35...0.92, step: 0.05)
                                    Text(loc.settingsGlassDesc)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }

                            case .solidBlack:
                                Text(loc.settingsSolidBlackDesc)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                            case .customColor:
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(loc.isTurkish ? "Hazır Renk Paletleri:" : "Preset Color Palettes:")
                                        .font(.system(size: 11, weight: .semibold))

                                    HStack(spacing: 8) {
                                        ForEach(presetColors, id: \.hex) { preset in
                                            let isChosen = settings.customColorHex.lowercased() == preset.hex.lowercased()
                                            Button {
                                                settings.customColorHex = preset.hex
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Circle()
                                                        .fill(Color(hex: preset.hex))
                                                        .frame(width: 12, height: 12)
                                                    Text(preset.name)
                                                        .font(.system(size: 10))
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .fill(isChosen ? Color.white.opacity(0.2) : Color.white.opacity(0.06))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(isChosen ? Color.white : Color.clear, lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    HStack(spacing: 16) {
                                        ColorPicker(loc.isTurkish ? "Paletten Özel Renk Seç..." : "Choose Custom Color...", selection: Binding(
                                            get: { Color(hex: settings.customColorHex) },
                                            set: { newColor in
                                                if let hex = newColor.toHex() {
                                                    settings.customColorHex = hex
                                                }
                                            }
                                        ))
                                        .font(.system(size: 11))

                                        Spacer()

                                        HStack(spacing: 6) {
                                            Text("\(loc.isTurkish ? "Opaklık" : "Opacity"): %\(Int(settings.customColorOpacity * 100))")
                                                .font(.system(size: 10, design: .monospaced))
                                            Slider(value: $settings.customColorOpacity, in: 0.3...1.0, step: 0.05)
                                                .frame(width: 100)
                                        }
                                    }
                                }

                            case .customImage:
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 12) {
                                        Button {
                                            selectImageFile()
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: "folder.badge.plus")
                                                Text(loc.settingsChooseImage)
                                            }
                                            .font(.system(size: 11, weight: .semibold))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Capsule().fill(Color(red: 0.38, green: 0.65, blue: 1.0)))
                                            .foregroundStyle(.white)
                                        }
                                        .buttonStyle(.plain)

                                        if let path = settings.customImagePath, let img = settings.cachedCustomImage {
                                            HStack(spacing: 6) {
                                                Image(nsImage: img)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 28, height: 28)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                                    .font(.system(size: 10))
                                                    .lineLimit(1)
                                                    .frame(maxWidth: 160, alignment: .leading)

                                                Button {
                                                    settings.removeCustomImage()
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(.secondary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        } else {
                                            Text(loc.settingsNoImage)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if let img = settings.cachedCustomImage {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ZStack {
                                                Image(nsImage: img)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .scaleEffect(settings.customImageScale)
                                                    .offset(x: settings.customImageOffsetX, y: settings.customImageOffsetY)
                                                    .blur(radius: settings.customImageBlur * 0.5)

                                                Color.black.opacity(settings.customImageDarkness)

                                                Text(loc.isTurkish ? "Çentik Önizlemesi" : "Notch Preview")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundStyle(.white.opacity(0.6))
                                                    .padding(4)
                                                    .background(Capsule().fill(Color.black.opacity(0.5)))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 70)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )

                                            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                                                GridRow {
                                                    Text(loc.settingsZoom)
                                                        .font(.system(size: 11))
                                                    Slider(value: $settings.customImageScale, in: 0.8...3.0, step: 0.05)
                                                    Text(String(format: "%.2fx", settings.customImageScale))
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .frame(width: 44, alignment: .trailing)
                                                }

                                                GridRow {
                                                    Text(loc.settingsPanX)
                                                        .font(.system(size: 11))
                                                    Slider(value: $settings.customImageOffsetX, in: -150...150, step: 2)
                                                    Text("\(Int(settings.customImageOffsetX)) px")
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .frame(width: 44, alignment: .trailing)
                                                }

                                                GridRow {
                                                    Text(loc.settingsPanY)
                                                        .font(.system(size: 11))
                                                    Slider(value: $settings.customImageOffsetY, in: -100...100, step: 2)
                                                    Text("\(Int(settings.customImageOffsetY)) px")
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .frame(width: 44, alignment: .trailing)
                                                }

                                                GridRow {
                                                    Text(loc.settingsBlur)
                                                        .font(.system(size: 11))
                                                    Slider(value: $settings.customImageBlur, in: 0...25, step: 1)
                                                    Text("\(Int(settings.customImageBlur)) px")
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .frame(width: 44, alignment: .trailing)
                                                }

                                                GridRow {
                                                    Text(loc.settingsTint)
                                                        .font(.system(size: 11))
                                                    Slider(value: $settings.customImageDarkness, in: 0.1...0.85, step: 0.05)
                                                    Text("%\(Int(settings.customImageDarkness * 100))")
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .frame(width: 44, alignment: .trailing)
                                                }
                                            }

                                            HStack(spacing: 12) {
                                                Button {
                                                    settings.removeCustomImage()
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "trash")
                                                        Text(loc.settingsRemoveImage)
                                                    }
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(Color.red.opacity(0.85))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.12)))
                                                }
                                                .buttonStyle(.plain)

                                                Spacer()

                                                Button {
                                                    settings.customImageScale = 1.0
                                                    settings.customImageOffsetX = 0.0
                                                    settings.customImageOffsetY = 0.0
                                                } label: {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "arrow.counterclockwise")
                                                        Text(loc.settingsResetFraming)
                                                    }
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.secondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))

                    VStack(alignment: .leading, spacing: 10) {
                        Label(loc.settingsWidgetsSection, systemImage: "square.grid.2x2.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.45))

                        Text(loc.settingsWidgetsDesc)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 8) {
                            widgetToggleRow(
                                title: loc.settingsMusicTitle,
                                description: loc.settingsMusicDesc,
                                icon: "music.note",
                                iconColor: Color(red: 0.18, green: 0.84, blue: 0.45),
                                isOn: $settings.enableMusicWidget
                            )

                            widgetToggleRow(
                                title: loc.settingsPomodoroTitle,
                                description: loc.settingsPomodoroDesc,
                                icon: "timer",
                                iconColor: Color(red: 1.0, green: 0.42, blue: 0.38),
                                isOn: $settings.enablePomodoroWidget
                            )

                            widgetToggleRow(
                                title: loc.settingsClipboardTitle,
                                description: loc.settingsClipboardDesc,
                                icon: "doc.on.clipboard.fill",
                                iconColor: Color(red: 0.38, green: 0.65, blue: 1.0),
                                isOn: $settings.enableClipboardTab
                            )
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))

                    VStack(alignment: .leading, spacing: 12) {
                        Label(loc.pomodoroWorkDuration, systemImage: "clock.badge.checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.38))

                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                            GridRow {
                                Text(loc.pomodoroWorkDuration)
                                    .font(.system(size: 12))
                                HStack(spacing: 8) {
                                    Slider(value: Binding(
                                        get: { Double(settings.pomodoroWorkMinutes) },
                                        set: { settings.pomodoroWorkMinutes = Int($0); pomodoroService.refreshDurationsFromSettings() }
                                    ), in: 5...60, step: 5)
                                    Text("\(settings.pomodoroWorkMinutes) \(loc.isTurkish ? "dk" : "min")")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .frame(width: 52, alignment: .trailing)
                                }
                            }

                            GridRow {
                                Text(loc.pomodoroShortBreakDuration)
                                    .font(.system(size: 12))
                                HStack(spacing: 8) {
                                    Slider(value: Binding(
                                        get: { Double(settings.pomodoroShortBreakMinutes) },
                                        set: { settings.pomodoroShortBreakMinutes = Int($0); pomodoroService.refreshDurationsFromSettings() }
                                    ), in: 1...20, step: 1)
                                    Text("\(settings.pomodoroShortBreakMinutes) \(loc.isTurkish ? "dk" : "min")")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .frame(width: 52, alignment: .trailing)
                                }
                            }

                            GridRow {
                                Text(loc.pomodoroLongBreakDuration)
                                    .font(.system(size: 12))
                                HStack(spacing: 8) {
                                    Slider(value: Binding(
                                        get: { Double(settings.pomodoroLongBreakMinutes) },
                                        set: { settings.pomodoroLongBreakMinutes = Int($0); pomodoroService.refreshDurationsFromSettings() }
                                    ), in: 5...45, step: 5)
                                    Text("\(settings.pomodoroLongBreakMinutes) \(loc.isTurkish ? "dk" : "min")")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .frame(width: 52, alignment: .trailing)
                                }
                            }
                        }

                        Toggle(loc.pomodoroSoundAlert, isOn: $settings.pomodoroSoundEnabled)
                            .font(.system(size: 12))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))

                    VStack(alignment: .leading, spacing: 10) {
                        Label(loc.settingsLanguageSection, systemImage: "globe")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.18, green: 0.84, blue: 0.45))

                        Text(loc.settingsLanguageDesc)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Picker("", selection: $settings.appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.title).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))

                    VStack(alignment: .leading, spacing: 12) {
                        Label(loc.settingsSizeSection, systemImage: "rectangle.topthird.inset.filled")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.38, green: 0.65, blue: 1.0))

                        Toggle(loc.settingsOpenOnHover, isOn: $settings.openOnHover)
                            .font(.system(size: 12))

                        HStack {
                            Text(loc.settingsExpandedWidth)
                                .font(.system(size: 12))
                            Slider(value: Binding(
                                get: { Double(settings.notchExpandedWidth) },
                                set: { settings.notchExpandedWidth = CGFloat($0) }
                            ), in: 400...580, step: 20)
                            Text("\(Int(settings.notchExpandedWidth)) px")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 54, alignment: .trailing)
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
                }
                .padding(18)
            }
        }
        .frame(width: 560, height: 540)
    }

    private func styleButton(style: NotchBackgroundStyle, title: String, icon: String) -> some View {
        let isSelected = settings.notchBackgroundStyle == style
        return Button {
            settings.notchBackgroundStyle = style
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(red: 0.38, green: 0.65, blue: 1.0).opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(red: 0.38, green: 0.65, blue: 1.0) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func widgetToggleRow(title: String, description: String, icon: String, iconColor: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.windowBackgroundColor)))
    }

    private func selectImageFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image, .png, .jpeg]
        panel.message = loc.isTurkish ? "JustNotch İçin Arka Plan Görseli Seçin" : "Choose Background Image for JustNotch"
        panel.prompt = loc.isTurkish ? "Seç" : "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            settings.customImagePath = url.path
            settings.notchBackgroundStyle = .customImage
            settings.customImageScale = 1.0
            settings.customImageOffsetX = 0.0
            settings.customImageOffsetY = 0.0
        }
    }
}

private extension Color {
    func toHex() -> String? {
        let uic = NSColor(self)
        guard let rgbColor = uic.usingColorSpace(.sRGB) else { return nil }
        let red = Int(round(rgbColor.redComponent * 0xFF))
        let green = Int(round(rgbColor.greenComponent * 0xFF))
        let blue = Int(round(rgbColor.blueComponent * 0xFF))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
