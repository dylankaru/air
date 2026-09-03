//
//  StreakSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct StreakSettingsPanel: View {
    @AppStorage("streak_primary_colour") private var primaryHex: String = "#3498DB"
    @AppStorage("streak_secondary_colour") private var secondaryHex: String = "#2ECC71"

    @AppStorage("streak_does_goal_have_colour") private var useCustomGoalColor: Bool = false
    @AppStorage("streak_goal_colour") private var goalUnitHex: String = "#E74C3C"

    @AppStorage("streak_mode") private var streakSetting: StreakSetting = .countUpVis

    @AppStorage("streak_increment_mode") private var incrementMode: IncrementMode = .manual

    @AppStorage("streak_increase_interval") private var timeInterval: StreakTimeInterval = .daily

    @AppStorage("streak_has_goal") private var hasTargetUnit: Bool = true
    @AppStorage("streak_goal_unit") private var targetUnit: Int = 154
    @AppStorage("streak_completed_units") private var completedUnits: Int = 0

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
        SettingsPanel(name: "Steak") {
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
                                .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
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
        .onAppear {
            primaryColor = Color(hex: primaryHex) ?? .blue
            secondaryColor = Color(hex: secondaryHex) ?? .green
            goalUnitColor = Color(hex: goalUnitHex) ?? .red
        }
    }
}
