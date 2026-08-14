//
//  SettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 12/8/2026.
//

import SwiftUI
import AppKit

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    func toHex() -> String? {
        let nsColor = NSColor(self)
        guard let srgbColor = nsColor.usingColorSpace(.extendedSRGB)
            ?? nsColor.usingColorSpace(.sRGB)
            ?? nsColor.usingColorSpace(.deviceRGB)
        else { return nil }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        srgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        let clampedR = max(0, min(1, Float(r)))
        let clampedG = max(0, min(1, Float(g)))
        let clampedB = max(0, min(1, Float(b)))
        let finalR = clampedR < 0.01 ? 0 : clampedR
        let finalG = clampedG < 0.01 ? 0 : clampedG
        let finalB = clampedB < 0.01 ? 0 : clampedB

        return String(
            format: "#%02X%02X%02X",
            lroundf(finalR * 255),
            lroundf(finalG * 255),
            lroundf(finalB * 255)
        )
    }
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case streak = "Streak"
    case weather = "Weather"
    case audio = "Audio"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .streak: return "flame.fill"
        case .weather: return "cloud.fog"
        case .audio: return "waveform"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section {
                    Label(SettingsTab.general.rawValue, systemImage: SettingsTab.general.icon)
                        .tag(SettingsTab.general)
                }

                Section("Cards") {
                    Label(SettingsTab.weather.rawValue, systemImage: SettingsTab.weather.icon)
                        .tag(SettingsTab.weather)
                    Label(SettingsTab.streak.rawValue, systemImage: SettingsTab.streak.icon)
                        .tag(SettingsTab.streak)
                    Label(SettingsTab.audio.rawValue, systemImage: SettingsTab.audio.icon)
                        .tag(SettingsTab.audio)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            if let selectedTab {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .streak:
                    StreakSettingsView()
                case .weather:
                    WeatherSettingsView()
                case .audio:
                    AudioSettingsView()
                }
            } else {
                Text("Select a category")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 650, height: 420)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("username") private var userName: String = "Friend"
    @AppStorage("autoStart") private var autoStart: Bool = true

    @FocusState private var isNameFocused: Bool
    @State private var showNameHint: Bool = false

    var body: some View {
        Form {
            Section("App Behavior") {
                Toggle("Launch at Login", isOn: $autoStart)
            }

            Section("User Details") {
                VStack {
                    TextField("Enter username", text: $userName, prompt: Text("LeBron James"))
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFocused)
                        .onChange(of: userName) { _, _ in
                            showNameHint = true
                        }

                    if showNameHint {
                        Text("Your name will update upon restarting the app")
                            .font(.system(size: 8).monospaced())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 6)
                            .foregroundStyle(.secondary)
                            .opacity(showNameHint ? 1 : 0)
                    }
                }
                .animation(.easeInOut(duration: 0.8), value: showNameHint)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        .onAppear {
            isNameFocused = false
        }
    }
}

struct StreakSettingsView: View {
    @AppStorage("streakCardPrimaryColor") private var primaryHex: String = "#3498DB"
    @AppStorage("streakCardSecondaryColor") private var secondaryHex: String = "#2ECC71"

    @AppStorage("useCustomGoalColor") private var useCustomGoalColor: Bool = false
    @AppStorage("goalUnitColor") private var goalUnitHex: String = "#E74C3C"

    @AppStorage("streakSetting") private var streakSetting: StreakSetting = .countUpVis

    @AppStorage("incrementMode") private var incrementMode: IncrementMode = .manual

    @AppStorage("timeInterval") private var timeInterval: StreakTimeInterval = .daily

    @AppStorage("hasTargetUnit") private var hasTargetUnit: Bool = true
    @AppStorage("targetUnit") private var targetUnit: Int = 154
    @AppStorage("completedUnits") private var completedUnits: Int = 0

    @State private var showResetStreakConfirmation: Bool = false
    @State private var showResetTargetConfirmation: Bool = false

    @State private var primaryColor: Color = .blue
    @State private var secondaryColor: Color = .green
    @State private var goalUnitColor: Color = .red

    private func liveBinding(
        _ live: Binding<Color>,
        writingTo hexKey: Binding<String>
    ) -> Binding<Color> {
        Binding(
            get: { live.wrappedValue },
            set: { newColor in
                live.wrappedValue = newColor
                if let hex = newColor.toHex() {
                    hexKey.wrappedValue = hex
                }
            }
        )
    }

    var body: some View {
        Form {
            Section("Render Settings") {
                Picker("Streak Type", selection: $streakSetting) {
                    ForEach(StreakSetting.allCases) { setting in
                        Text(setting.rawValue).tag(setting)
                    }
                }

                Picker("Incrementation Type", selection: $incrementMode) {
                    ForEach(IncrementMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                if incrementMode == .automatic {
                    Picker("Time Interval", selection: $timeInterval) {
                        ForEach(StreakTimeInterval.allCases) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                }

                ColorPicker(
                    "Completed Unit Tint",
                    selection: liveBinding($primaryColor, writingTo: $primaryHex),
                    supportsOpacity: false
                )

                ColorPicker(
                    "Remaining Unit Tint",
                    selection: liveBinding($secondaryColor, writingTo: $secondaryHex),
                    supportsOpacity: false
                )

                if hasTargetUnit {
                    Toggle("Target Unit Tint?", isOn: $useCustomGoalColor)
                    if useCustomGoalColor {
                        ColorPicker(
                            "Target Unit Tint",
                            selection: liveBinding($goalUnitColor, writingTo: $goalUnitHex),
                            supportsOpacity: false
                        )
                    }
                }
            }

            Section("Streak Details") {
                Toggle("Set a Target Unit", isOn: $hasTargetUnit)
                    .onChange(of: hasTargetUnit) { _, isEnabled in
                        if !isEnabled {
                            targetUnit = 154
                        }
                    }

                if hasTargetUnit {
                    Stepper(value: $targetUnit, in: 1...1000) {
                        HStack {
                            Text("Target Unit")
                            Spacer()
                            Text("\(targetUnit)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .onChange(of: targetUnit) { _, newGoal in
                        if completedUnits > newGoal {
                            completedUnits = newGoal
                        }
                    }
                }

                Stepper(
                    value: $completedUnits,
                    in: 0...(hasTargetUnit ? max(1, targetUnit) : Int.max)
                ) {
                    HStack {
                        Text("Completed Units")
                        Spacer()
                        Text("\(completedUnits)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Button(role: .destructive) {
                    showResetStreakConfirmation = true
                } label: {
                    Label("Reset Completed Units", systemImage: "arrow.clockwise")
                }
                .confirmationDialog(
                    "Are you sure you want to reset your completed units?",
                    isPresented: $showResetStreakConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset", role: .destructive) {
                        completedUnits = 0
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("You will have to manually re-adjust via the stepper.")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                if hasTargetUnit {
                    Button(role: .destructive) {
                        showResetTargetConfirmation = true
                    } label: {
                        Label("Reset Target Unit", systemImage: "arrow.clockwise")
                    }
                    .confirmationDialog(
                        "Are you sure you want to reset your target units?",
                        isPresented: $showResetTargetConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            targetUnit = 154
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("You will have to manually re-adjust via the stepper.")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Streak Card")
        .onAppear {
            primaryColor = Color(hex: primaryHex) ?? .blue
            secondaryColor = Color(hex: secondaryHex) ?? .green
            goalUnitColor = Color(hex: goalUnitHex) ?? .red
        }
    }
}

struct WeatherSettingsView: View {
    @AppStorage("selectedWeatherMetrics") private var selectedMetrics: [WeatherMetric] = [
        .windSpeed,
        .humidity,
        .uvIndex,
        .futureForecast
    ]

    private let maxSlots = 6

    private var currentUsedSlots: Int {
        selectedMetrics.reduce(0) { $0 + $1.slotCost }
    }

    var body: some View {
        Form {
            Section {
                Text("\(currentUsedSlots) of \(maxSlots) display slots used")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Selection Limit")
            } footer: {
                Text("You can select up to 6 metric slots. Standard metrics use 1 slot, while the Future Day Forecast uses 3 slots.")
            }

            Section("Weather Details") {
                ForEach(WeatherMetric.allCases) { metric in
                    Toggle(metric.rawValue, isOn: binding(for: metric))
                        .disabled(!selectedMetrics.contains(metric) && (currentUsedSlots + metric.slotCost > maxSlots))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Weather Card")
    }

    private func binding(for metric: WeatherMetric) -> Binding<Bool> {
        Binding(
            get: {
                selectedMetrics.contains(metric)
            },
            set: { isSelected in
                if isSelected {
                    if currentUsedSlots + metric.slotCost <= maxSlots {
                        selectedMetrics.append(metric)
                    }
                } else {
                    selectedMetrics.removeAll { $0 == metric }
                }
            }
        )
    }
}

struct AudioSettingsView: View {
    @AppStorage("audioSource") private var audioSourceRaw: String = AudioSourceSetting.spotify.rawValue

    private var audioSource: AudioSourceSetting {
        AudioSourceSetting(rawValue: audioSourceRaw) ?? .spotify
    }

    var body: some View {
        Form {
            Section {
                Picker("Audio Source", selection: Binding(
                    get: { audioSource },
                    set: { audioSourceRaw = $0.rawValue }
                )) {
                    ForEach(AudioSourceSetting.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Source")
            } footer: {
                footerText
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Audio Card")
    }

    private var footerText: some View {
        Group {
            switch audioSource {
            case .spotify:
                Text("air will open Spotify and resume your most recently played queue.")
            case .appleMusic:
                Text("air will open Music and resume your most recently played music.")
            case .systemNowPlaying:
                Text("air will control whatever app currently owns the system media session, for example a browser tab playing YouTube.")
            }
        }
        .font(.system(size: 11))
    }
}
