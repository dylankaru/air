import SwiftUI
internal import Combine
import AudioToolbox

enum TimerMode: String, CaseIterable, Identifiable {
    case work
    case rest
    case off
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .work: return "Focus"
        case .rest: return "Break"
        case .off: return "Rest"
        }
    }
    
    var defaultDuration: Int {
        switch self {
        case .work: return 2700
        case .rest: return 300
        case .off: return 900
        }
    }
}

struct TimerCard: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    @AppStorage("timer_work_duration") private var workDuration: Int = TimerMode.work.defaultDuration
    @AppStorage("timer_rest_duration") private var restDuration: Int = TimerMode.rest.defaultDuration
    @AppStorage("timer_off_duration") private var offDuration: Int = TimerMode.off.defaultDuration
    @AppStorage("timer_use_flashy_timer") private var useSlidingAnimation: Bool = true
    
    @State private var timeLeft: Int = TimerMode.work.defaultDuration
    @State private var totalDuration: Int = TimerMode.work.defaultDuration
    @State private var isRunning: Bool = false
    @State private var selectedMode: TimerMode = .work
    @State private var completedSessions: Int = 0
    
    @AppStorage("timer_target_date") private var targetDateTimestamp: Double = 0
    @AppStorage("timer_total_duration") private var savedTotalDuration: Int = TimerMode.work.defaultDuration
    @AppStorage("timer_is_running") private var savedIsRunning: Bool = false
    
    private let maxCycleSessions: Int = 4
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private func duration(for mode: TimerMode) -> Int {
        switch mode {
        case .work: return workDuration
        case .rest: return restDuration
        case .off: return offDuration
        }
    }
    
    var body: some View {
        Card {
            VStack() {
                if #available(macOS 27, *) {
                    HStack(spacing: 8) {
                        Picker("Timer Mode", selection: $selectedMode) {
                            ForEach(TimerMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.tabs)
                        .labelsHidden()
                        .onChange(of: selectedMode) { oldMode, newMode in
                            let selectedDuration = duration(for: newMode)
                            totalDuration = selectedDuration
                            timeLeft = selectedDuration
                            isRunning = false
                            savedIsRunning = false
                            targetDateTimestamp = 0
                        }
                        
                        HStack(spacing: 5) {
                            ForEach(0..<maxCycleSessions, id: \.self) { index in
                                Circle()
                                    .fill(index < (completedSessions % maxCycleSessions) ? Color.green : Color.primary.opacity(0.15))
                                    .frame(width: 6, height: 6)
                                    .animation(.snappy, value: completedSessions)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                    .padding(3)
                    .background(theme.textColour, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.top, 6)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 7)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timeLeft)
                        
                        Button(action: toggleTimer) {
                            let text = Text(formattedTime(timeLeft))
                                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                                .foregroundColor(theme.textColour)
                            
                            if useSlidingAnimation {
                                text
                                    .contentTransition(.numericText(value: Double(timeLeft)))
                                    .animation(.snappy(duration: 0.3), value: timeLeft)
                            } else {
                                text
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                    .frame(width: 105, height: 105)
                    
                    HStack(spacing: 10) {
                        Button(action: toggleTimer) {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .foregroundColor(theme.textColour)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: resetTimer) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .foregroundColor(theme.textColour)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    HStack(spacing: 8) {
                        Picker("Timer Mode", selection: $selectedMode) {
                            ForEach(TimerMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: selectedMode) { oldMode, newMode in
                            let selectedDuration = duration(for: newMode)
                            totalDuration = selectedDuration
                            timeLeft = selectedDuration
                            isRunning = false
                            savedIsRunning = false
                            targetDateTimestamp = 0
                        }
                        
                        HStack(spacing: 5) {
                            ForEach(0..<maxCycleSessions, id: \.self) { index in
                                Circle()
                                    .fill(index < (completedSessions % maxCycleSessions) ? Color.green : Color.primary.opacity(0.15))
                                    .frame(width: 6, height: 6)
                                    .animation(.snappy, value: completedSessions)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                    .padding(3)
                    .background(theme.textColour, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.top, 6)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 7)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timeLeft)
                        
                        Button(action: toggleTimer) {
                            let text = Text(formattedTime(timeLeft))
                                .font(.system(size: 26, weight: .semibold, design: .monospaced))
                                .foregroundColor(theme.textColour)
                            
                            if useSlidingAnimation {
                                text
                                    .contentTransition(.numericText(value: Double(timeLeft)))
                                    .animation(.snappy(duration: 0.3), value: timeLeft)
                            } else {
                                text
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                    .frame(width: 105, height: 105)
                    
                    HStack(spacing: 10) {
                        Button(action: toggleTimer) {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .foregroundColor(theme.textColour)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: resetTimer) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .foregroundColor(theme.textColour)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                }
//            .padding(6)
            .frame(maxWidth: .infinity)
            .onAppear {
                totalDuration = savedTotalDuration
                isRunning = savedIsRunning
                
                if isRunning && targetDateTimestamp > 0 {
                    let remaining = Int(targetDateTimestamp - Date().timeIntervalSince1970)
                    timeLeft = max(0, remaining)
                } else if isRunning {
                    timeLeft = 0
                } else {
                    timeLeft = duration(for: selectedMode)
                }
            }
            .onReceive(timer) { _ in
                guard isRunning else { return }
                
                let remaining: Int
                if targetDateTimestamp > 0 {
                    remaining = Int(targetDateTimestamp - Date().timeIntervalSince1970)
                } else {
                    remaining = timeLeft - 1
                }
                
                if remaining <= 0 {
                    timeLeft = 0
                    isRunning = false
                    savedIsRunning = false
                    targetDateTimestamp = 0
                    
                    playCompletionSound()
                    
                    if selectedMode == .work {
                        completedSessions += 1
                    }
                } else {
                    timeLeft = remaining
                }
            }
        }
    }
    
    private func playCompletionSound() {
        NSSound(named: "Glass")?.play()
    }

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        let raw = Double(timeLeft) / Double(totalDuration)
        return max(0, min(1, raw))
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let absSeconds = abs(seconds)
        let mins = absSeconds / 60
        let secs = absSeconds % 60
        let prefix = seconds < 0 ? "-" : ""
        return String(format: "%@%02d:%02d", prefix, mins, secs)
    }

    private func toggleTimer() {
        if isRunning {
            isRunning = false
            savedIsRunning = false
        } else {
            let currentModeDuration = duration(for: selectedMode)
            if timeLeft <= 0 {
                timeLeft = currentModeDuration
                totalDuration = currentModeDuration
            }
            
            isRunning = true
            savedIsRunning = true
            savedTotalDuration = totalDuration
            targetDateTimestamp = Date().timeIntervalSince1970 + Double(timeLeft)
        }
    }

    private func resetTimer() {
        let currentModeDuration = duration(for: selectedMode)
        isRunning = false
        savedIsRunning = false
        totalDuration = currentModeDuration
        timeLeft = currentModeDuration
        savedTotalDuration = currentModeDuration
        targetDateTimestamp = 0
    }
}
