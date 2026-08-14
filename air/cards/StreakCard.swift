//
//  StreakCard.swift
//  air
//
//  Created by Dylan Karunanayake on 11/8/2026.
//

import SwiftUI
internal import Combine

enum StreakSetting: String, CaseIterable, Identifiable {
    case countUpVis = "Count Up (Remaining units visible)"
    case countUpInvis = "Count Up (Remaining units hidden)"
    case countDown = "Count Down"

    var id: String { rawValue }
}

enum StreakTimeInterval: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case biweekly = "Biweekly"
    case weekly = "Weekly"
    case custom = "Monthly"

    var id: String { rawValue }

    var approximateSeconds: TimeInterval {
        switch self {
        case .daily: return 86_400
        case .weekly: return 86_400 * 7
        case .biweekly: return 86_400 * 14
        case .custom: return 86_400 * 30
        }
    }
}

enum IncrementMode: String, CaseIterable, Identifiable {
    case manual = "Manual (Tap dots directly)"
    case automatic = "Automatic (Time-Based)"
    var id: String { rawValue }
}

struct StreakCard: View {
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("streakSetting") private var currentSettingRaw: String = StreakSetting.countUpVis.rawValue
    @AppStorage("timeInterval") private var timeInterval: StreakTimeInterval = .daily
    @AppStorage("incrementMode") private var incrementMode: IncrementMode = .manual

    @AppStorage("completedUnits") private var streakCount: Int = 42
    @AppStorage("targetUnit") private var totalDays: Int = 154

    @AppStorage("streakCardPrimaryColor") private var primaryHex: String = "#3498DB"
    @AppStorage("streakCardSecondaryColor") private var secondaryHex: String = "#2ECC71"

    @AppStorage("useCustomGoalColor") private var useCustomGoalColor: Bool = false
    @AppStorage("goalUnitColor") private var goalUnitHex: String = "#E74C3C"

    @AppStorage("lastProgressionDate") private var lastProgressionTimestamp: Double = 0

    private let maxVisibleUnits: Int = 154

    private var currentSetting: StreakSetting {
        StreakSetting(rawValue: currentSettingRaw) ?? .countUpVis
    }

    private var cardColors: (primary: Color, secondary: Color) {
        (Color(hex: primaryHex) ?? .blue, Color(hex: secondaryHex) ?? .green)
    }

    private var goalColor: Color {
        Color(hex: goalUnitHex) ?? .red
    }

    let columns = [GridItem(.adaptive(minimum: 12), spacing: 8)]

    var body: some View {
        Card {
            CircleThing()
                .clipped()
                .padding(10)
                .contentShape(Rectangle())
                .onTapGesture {
                    handleCardTap()
                }
        }
        .onAppear {
            applyAutomaticProgressionIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                applyAutomaticProgressionIfNeeded()
            }
        }
        .onReceive(Timer.publish(every: 3600, on: .main, in: .common).autoconnect()) { _ in
            applyAutomaticProgressionIfNeeded()
        }
    }

    private func handleCardTap() {
        withAnimation(.easeInOut(duration: 0.2)) {
            streakCount = min(streakCount + 1, totalDays)
        }
    }

    private func toggleUnit(at index: Int) {
        guard incrementMode == .manual else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if index < streakCount {
                streakCount = index
            } else {
                streakCount = index + 1
            }
        }
    }

    private func applyAutomaticProgressionIfNeeded() {
        guard incrementMode == .automatic else { return }

        let now = Date()

        if lastProgressionTimestamp == 0 {
            lastProgressionTimestamp = now.timeIntervalSince1970
            return
        }

        let last = Date(timeIntervalSince1970: lastProgressionTimestamp)
        let calendar = Calendar.current
        let elapsedDays = calendar.dateComponents([.day], from: last, to: now).day ?? 0

        let elapsedUnits: Int
        switch timeInterval {
        case .daily:
            elapsedUnits = elapsedDays
        case .weekly:
            elapsedUnits = elapsedDays / 7
        case .biweekly:
            elapsedUnits = elapsedDays / 14
        case .custom:
            elapsedUnits = calendar.dateComponents([.month], from: last, to: now).month ?? 0
        }

        guard elapsedUnits > 0 else { return }

        streakCount = min(streakCount + elapsedUnits, totalDays)
        lastProgressionTimestamp += Double(elapsedUnits) * timeInterval.approximateSeconds
    }

    @ViewBuilder
    private func CircleThing() -> some View {
        let effectiveTotal = min(totalDays, maxVisibleUnits)

        let isGoalIndex = { (index: Int) -> Bool in
            index == (effectiveTotal - 1) && useCustomGoalColor
        }

        switch currentSetting {
        case .countUpVis:
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<effectiveTotal, id: \.self) { index in
                    Button {
                        toggleUnit(at: index)
                    } label: {
                        Circle()
                            .fill(
                                isGoalIndex(index) ? goalColor :
                                (index < streakCount ? cardColors.primary : cardColors.secondary)
                            )
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(incrementMode != .manual)
                }
            }

        case .countUpInvis:
            let visibleCompleted = min(streakCount, maxVisibleUnits)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<visibleCompleted, id: \.self) { index in
                    Button {
                        toggleUnit(at: index)
                    } label: {
                        Circle()
                            .fill(isGoalIndex(index) ? goalColor : cardColors.primary)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(incrementMode != .manual)
                }
            }

        case .countDown:
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<effectiveTotal, id: \.self) { index in
                    let remainingDays = max(0, totalDays - streakCount)
                    Button {
                        toggleUnit(at: totalDays - 1 - index)
                    } label: {
                        Circle()
                            .fill(
                                isGoalIndex(index) ? goalColor :
                                (index < remainingDays ? cardColors.primary : cardColors.secondary)
                            )
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(incrementMode != .manual)
                }
            }
        }
    }
}
