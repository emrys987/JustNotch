import SwiftUI

public struct PomodoroNotchView: View {
    @ObservedObject var pomodoroService = PomodoroService.shared
    @ObservedObject var settings = UserSettings.shared
    @ObservedObject var loc = LocalizationService.shared

    public init() {}

    public var body: some View {
        let state = pomodoroService.state

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 5)

                Circle()
                    .trim(from: 0, to: CGFloat(state.progress))
                    .stroke(
                        state.phase.themeColor.gradient,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.8), value: state.progress)

                VStack(spacing: 4) {
                    Text(state.formattedTime)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 7) {
                        Button {
                            pomodoroService.toggle()
                        } label: {
                            Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))
                                .padding(5)
                                .background(
                                    Circle()
                                        .fill(state.isRunning ? Color.white.opacity(0.25) : state.phase.themeColor)
                                )
                                .foregroundStyle(state.isRunning ? Color.white : Color.black)
                        }
                        .buttonStyle(.plain)
                        .help(state.isRunning ? loc.pomodoroPause : loc.pomodoroStart)

                        Button {
                            pomodoroService.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9))
                                .padding(4)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .help(loc.pomodoroReset)

                        Button {
                            pomodoroService.skipToNextPhase()
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 9))
                                .padding(4)
                                .background(Circle().fill(Color.white.opacity(0.12)))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .help(loc.pomodoroSkip)
                    }
                }
            }
            .frame(width: 82, height: 82)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }
}
